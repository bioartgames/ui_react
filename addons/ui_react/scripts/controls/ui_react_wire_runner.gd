## Scene wiring runner: collects [member wire_rules] on descendant [UiReact*] controls, connects triggers, applies rules ([code]docs/WIRING_LAYER.md[/code] §3).
class_name UiReactWireRunner
extends Node

var _connections: Array[Dictionary] = []


func _enter_tree() -> void:
	call_deferred(&"_register_wires")


func _exit_tree() -> void:
	_unregister_wires()


func _register_wires() -> void:
	_unregister_wires()
	var scene: Node = get_tree().current_scene if get_tree() != null else null
	if scene != null:
		var runners: Array[UiReactWireRunner] = []
		_find_runners(scene, runners)
		if runners.size() > 1:
			push_warning(
				"UiReactWireRunner: %d runners under the current scene; use exactly one per wired scene (see docs/WIRING_LAYER.md §3)."
				% runners.size()
			)
	var entries := _collect_sorted_entries()
	for e in entries:
		_bind_entry(e)
	for e in entries:
		_apply_rule(e)


func _unregister_wires() -> void:
	for c in _connections:
		var sig: Signal = c.get("signal", null)
		var cb: Callable = c.get("callable", Callable())
		if sig is Signal and cb.is_valid() and sig.is_connected(cb):
			sig.disconnect(cb)
	_connections.clear()


func _find_runners(n: Node, acc: Array[UiReactWireRunner]) -> void:
	if n is UiReactWireRunner:
		acc.append(n as UiReactWireRunner)
	for child in n.get_children():
		_find_runners(child, acc)


func _collect_sorted_entries() -> Array[Dictionary]:
	var raw: Array[Dictionary] = []
	## Rules live on sibling controls under the same screen root; walk from parent (see docs/WIRING_LAYER.md §3).
	var scope: Node = get_parent() if get_parent() != null else self
	_collect_from(scope, raw)
	raw.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.sort_key) < str(b.sort_key)
	)
	return raw


func _collect_from(n: Node, acc: Array[Dictionary]) -> void:
	for child in n.get_children():
		_collect_from(child, acc)
	var wr_variant: Variant = n.get("wire_rules")
	if wr_variant == null or not (wr_variant is Array):
		return
	var wr: Array = wr_variant
	for idx in range(wr.size()):
		var r_variant: Variant = wr[idx]
		if r_variant == null or not (r_variant is UiReactWireRule):
			continue
		var r := r_variant as UiReactWireRule
		if not r.enabled:
			continue
		var sort_key := "%s|%05d|%s" % [str(n.get_path()), idx, r.rule_id if r.rule_id != "" else "rule"]
		acc.append({"node": n, "index": idx, "rule": r, "sort_key": sort_key})


func _bind_entry(e: Dictionary) -> void:
	var n: Node = e["node"]
	var rule: UiReactWireRule = e["rule"]
	if rule is UiReactWireMapIntToString:
		_bind_map_int_to_string(n, rule as UiReactWireMapIntToString)
	elif rule is UiReactWireRefreshItemsFromCatalog:
		_bind_refresh_items(n, rule as UiReactWireRefreshItemsFromCatalog)
	elif rule is UiReactWireCopySelectionDetail:
		_bind_copy_detail(n, rule as UiReactWireCopySelectionDetail)
	elif rule is UiReactWireSetStringOnBoolPulse:
		_bind_set_string_on_bool_pulse(n, rule as UiReactWireSetStringOnBoolPulse)
	elif rule is UiReactWireSyncBoolStateDebugLine:
		_bind_sync_bool_debug_line(n, rule as UiReactWireSyncBoolStateDebugLine)


## Godot passes **signal arguments first**, then bound args — so do not use [method Callable.bind] with
## [code](rule, source)[/code] on a method that expects [code](rule, source)[/code] first. Lambdas close over rule/source.
func _make_rule_cb(rule: UiReactWireRule, source: Node) -> Callable:
	return func (_arg0: Variant = null, _arg1: Variant = null) -> void:
		if not is_inside_tree():
			return
		if not is_instance_valid(source):
			return
		_apply_rule({"node": source, "rule": rule})


func _apply_rule(e: Dictionary) -> void:
	var source: Node = e["node"]
	var rule: UiReactWireRule = e["rule"]
	if not rule.enabled:
		return
	var rid: String = rule.rule_id if rule.rule_id != "" else rule.resource_path
	if not is_instance_valid(source):
		push_warning("UiReactWireRunner: rule '%s' skipped; source node freed." % rid)
		return
	rule.apply(source)


func _safe_connect(sig: Signal, cb: Callable) -> void:
	if not cb.is_valid():
		return
	if sig.is_connected(cb):
		return
	sig.connect(cb)
	_connections.append({"signal": sig, "callable": cb})


func _bind_map_int_to_string(n: Node, rule: UiReactWireMapIntToString) -> void:
	var cb := _make_rule_cb(rule, n)
	if rule.trigger != UiReactWireRule.TriggerKind.SELECTION_CHANGED:
		push_warning(
			"UiReactWireRunner: MapIntToString rule '%s' should use SELECTION_CHANGED for tree wiring."
			% rule.rule_id
		)
	if n is Tree:
		var tree := n as Tree
		_safe_connect(tree.item_selected, cb)
		_safe_connect(tree.nothing_selected, cb)
	if rule.source_int_state != null:
		_safe_connect(rule.source_int_state.changed, cb)


func _bind_refresh_items(n: Node, rule: UiReactWireRefreshItemsFromCatalog) -> void:
	var cb := _make_rule_cb(rule, n)
	match rule.trigger:
		UiReactWireRule.TriggerKind.TEXT_CHANGED:
			if n is LineEdit:
				_safe_connect((n as LineEdit).text_changed, cb)
		UiReactWireRule.TriggerKind.TEXT_ENTERED:
			if n is LineEdit:
				_safe_connect((n as LineEdit).text_submitted, cb)
		UiReactWireRule.TriggerKind.SELECTION_CHANGED:
			if n is Tree:
				var tree := n as Tree
				_safe_connect(tree.item_selected, cb)
				_safe_connect(tree.nothing_selected, cb)
			elif n is ItemList:
				_safe_connect((n as ItemList).item_selected, cb)
		_:
			push_warning(
				"UiReactWireRunner: RefreshItemsFromCatalog rule '%s' trigger %s not bound on node %s."
				% [rule.rule_id, rule.trigger, n.get_path()]
			)
	if rule.filter_text_state != null:
		_safe_connect(rule.filter_text_state.changed, cb)
	if rule.category_kind_state != null:
		_safe_connect(rule.category_kind_state.changed, cb)


func _bind_copy_detail(n: Node, rule: UiReactWireCopySelectionDetail) -> void:
	var apply_cb := _make_rule_cb(rule, n)
	var sel_cb := func (_nv: Variant = null, _ov: Variant = null) -> void:
		if rule.clear_suffix_on_selection_change and rule.suffix_note_state != null:
			rule.suffix_note_state.set_value("")
		if not is_inside_tree():
			return
		if not is_instance_valid(n):
			return
		_apply_rule({"node": n, "rule": rule})
	if rule.trigger == UiReactWireRule.TriggerKind.SELECTION_CHANGED and n is ItemList:
		_safe_connect((n as ItemList).item_selected, sel_cb)
	if rule.items_state != null:
		_safe_connect(rule.items_state.changed, apply_cb)
	if rule.suffix_note_state != null:
		_safe_connect(rule.suffix_note_state.changed, apply_cb)
	if rule.selected_state != null:
		_safe_connect(rule.selected_state.changed, sel_cb)


func _bind_set_string_on_bool_pulse(n: Node, rule: UiReactWireSetStringOnBoolPulse) -> void:
	if rule.pulse_bool == null:
		return
	var cb := func (new_val: Variant, old_val: Variant) -> void:
		if not is_inside_tree():
			return
		if not is_instance_valid(n):
			return
		rule.apply_from_pulse(n, new_val, old_val)
	_safe_connect(rule.pulse_bool.value_changed, cb)


func _bind_sync_bool_debug_line(n: Node, rule: UiReactWireSyncBoolStateDebugLine) -> void:
	var cb := _make_rule_cb(rule, n)
	if rule.bool_state != null:
		_safe_connect(rule.bool_state.value_changed, cb)

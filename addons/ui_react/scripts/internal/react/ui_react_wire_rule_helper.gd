## Binds [member wire_rules] on a single [UiReact*] host: signals, [Resource.changed], initial [method UiReactWireRule.apply].
## See [code]docs/WIRING_LAYER.md[/code]. Use [method schedule_attach] / [method detach] from the host's [method Node._enter_tree] / [method Node._exit_tree].
class_name UiReactWireRuleHelper
extends RefCounted

const _META_CONNS := &"_ui_react_wire_helper_conns"


static func schedule_attach(host: Node) -> void:
	if not _has_bindable_rules(host):
		return
	var tree := host.get_tree()
	if tree == null:
		return
	tree.process_frame.connect(
		func () -> void:
			if is_instance_valid(host) and host.is_inside_tree():
				attach(host),
		CONNECT_ONE_SHOT
	)


static func detach(host: Node) -> void:
	if not host.has_meta(_META_CONNS):
		return
	var conns: Variant = host.get_meta(_META_CONNS)
	if conns is Array:
		for c in conns as Array:
			var sig: Signal = c.get("signal", null)
			var cb: Callable = c.get("callable", Callable())
			if sig is Signal and cb.is_valid() and sig.is_connected(cb):
				sig.disconnect(cb)
	host.remove_meta(_META_CONNS)


static func attach(host: Node) -> void:
	detach(host)
	if not _has_bindable_rules(host):
		return
	var wr_variant: Variant = host.get(&"wire_rules")
	if wr_variant == null or not (wr_variant is Array):
		return
	var wr: Array = wr_variant
	var conns: Array[Dictionary] = []
	host.set_meta(_META_CONNS, conns)
	for idx in range(wr.size()):
		var r_variant: Variant = wr[idx]
		if r_variant == null or not (r_variant is UiReactWireRule):
			continue
		var rule := r_variant as UiReactWireRule
		if not rule.enabled:
			continue
		_bind_entry(host, rule, conns)
	for idx in range(wr.size()):
		var r_variant2: Variant = wr[idx]
		if r_variant2 == null or not (r_variant2 is UiReactWireRule):
			continue
		var rule2 := r_variant2 as UiReactWireRule
		if not rule2.enabled:
			continue
		_apply_rule(host, rule2)


static func _has_bindable_rules(host: Node) -> bool:
	if not &"wire_rules" in host:
		return false
	var wr_variant: Variant = host.get(&"wire_rules")
	if wr_variant == null or not (wr_variant is Array):
		return false
	for item in wr_variant as Array:
		if item is UiReactWireRule:
			var r := item as UiReactWireRule
			if r.enabled:
				return true
	return false


static func _bind_entry(host: Node, rule: UiReactWireRule, conns: Array[Dictionary]) -> void:
	if rule is UiReactWireMapIntToString:
		_bind_map_int_to_string(host, rule as UiReactWireMapIntToString, conns)
	elif rule is UiReactWireRefreshItemsFromCatalog:
		_bind_refresh_items(host, rule as UiReactWireRefreshItemsFromCatalog, conns)
	elif rule is UiReactWireCopySelectionDetail:
		_bind_copy_detail(host, rule as UiReactWireCopySelectionDetail, conns)
	elif rule is UiReactWireSetStringOnBoolPulse:
		_bind_set_string_on_bool_pulse(host, rule as UiReactWireSetStringOnBoolPulse, conns)
	elif rule is UiReactWireSyncBoolStateDebugLine:
		_bind_sync_bool_debug_line(host, rule as UiReactWireSyncBoolStateDebugLine, conns)


## Godot passes **signal arguments first**, then bound args — so do not use [method Callable.bind] with
## [code](rule, source)[/code] on a method that expects [code](rule, source)[/code] first. Lambdas close over rule/source.
static func _make_rule_cb(host: Node, rule: UiReactWireRule) -> Callable:
	return func (_arg0: Variant = null, _arg1: Variant = null) -> void:
		if not host.is_inside_tree():
			return
		if not is_instance_valid(host):
			return
		_apply_rule(host, rule)


static func _apply_rule(host: Node, rule: UiReactWireRule) -> void:
	if not rule.enabled:
		return
	var rid: String = rule.rule_id if rule.rule_id != "" else rule.resource_path
	if not is_instance_valid(host):
		push_warning("UiReactWireRuleHelper: rule '%s' skipped; source node freed." % rid)
		return
	rule.apply(host)


static func _safe_connect(conns: Array[Dictionary], sig: Signal, cb: Callable) -> void:
	if not cb.is_valid():
		return
	if sig.is_connected(cb):
		return
	sig.connect(cb)
	conns.append({"signal": sig, "callable": cb})


static func _bind_map_int_to_string(
	host: Node, rule: UiReactWireMapIntToString, conns: Array[Dictionary]
) -> void:
	var cb := _make_rule_cb(host, rule)
	if rule.trigger != UiReactWireRule.TriggerKind.SELECTION_CHANGED:
		push_warning(
			"UiReactWireRuleHelper: MapIntToString rule '%s' should use SELECTION_CHANGED for tree wiring."
			% rule.rule_id
		)
	if host is Tree:
		var tree := host as Tree
		_safe_connect(conns, tree.item_selected, cb)
		_safe_connect(conns, tree.nothing_selected, cb)
	if rule.source_int_state != null:
		_safe_connect(conns, rule.source_int_state.changed, cb)


static func _bind_refresh_items(
	host: Node, rule: UiReactWireRefreshItemsFromCatalog, conns: Array[Dictionary]
) -> void:
	var cb := _make_rule_cb(host, rule)
	match rule.trigger:
		UiReactWireRule.TriggerKind.TEXT_CHANGED:
			if host is LineEdit:
				_safe_connect(conns, (host as LineEdit).text_changed, cb)
		UiReactWireRule.TriggerKind.TEXT_ENTERED:
			if host is LineEdit:
				_safe_connect(conns, (host as LineEdit).text_submitted, cb)
		UiReactWireRule.TriggerKind.SELECTION_CHANGED:
			if host is Tree:
				var tree := host as Tree
				_safe_connect(conns, tree.item_selected, cb)
				_safe_connect(conns, tree.nothing_selected, cb)
			elif host is ItemList:
				_safe_connect(conns, (host as ItemList).item_selected, cb)
		_:
			push_warning(
				"UiReactWireRuleHelper: RefreshItemsFromCatalog rule '%s' trigger %s not bound on node %s."
				% [rule.rule_id, rule.trigger, host.get_path()]
			)
	if rule.filter_text_state != null:
		_safe_connect(conns, rule.filter_text_state.changed, cb)
	if rule.category_kind_state != null:
		_safe_connect(conns, rule.category_kind_state.changed, cb)


static func _bind_copy_detail(
	host: Node, rule: UiReactWireCopySelectionDetail, conns: Array[Dictionary]
) -> void:
	var apply_cb := _make_rule_cb(host, rule)
	var sel_cb := func (_nv: Variant = null, _ov: Variant = null) -> void:
		if rule.clear_suffix_on_selection_change and rule.suffix_note_state != null:
			rule.suffix_note_state.set_value("")
		if not host.is_inside_tree():
			return
		if not is_instance_valid(host):
			return
		_apply_rule(host, rule)
	if rule.trigger == UiReactWireRule.TriggerKind.SELECTION_CHANGED and host is ItemList:
		_safe_connect(conns, (host as ItemList).item_selected, sel_cb)
	if rule.items_state != null:
		_safe_connect(conns, rule.items_state.changed, apply_cb)
	if rule.suffix_note_state != null:
		_safe_connect(conns, rule.suffix_note_state.changed, apply_cb)
	if rule.selected_state != null:
		_safe_connect(conns, rule.selected_state.changed, sel_cb)


static func _bind_set_string_on_bool_pulse(
	host: Node, rule: UiReactWireSetStringOnBoolPulse, conns: Array[Dictionary]
) -> void:
	if rule.pulse_bool == null:
		return
	var cb := func (new_val: Variant, old_val: Variant) -> void:
		if not host.is_inside_tree():
			return
		if not is_instance_valid(host):
			return
		rule.apply_from_pulse(host, new_val, old_val)
	_safe_connect(conns, rule.pulse_bool.value_changed, cb)


static func _bind_sync_bool_debug_line(
	host: Node, rule: UiReactWireSyncBoolStateDebugLine, conns: Array[Dictionary]
) -> void:
	var cb := _make_rule_cb(host, rule)
	if rule.bool_state != null:
		_safe_connect(conns, rule.bool_state.value_changed, cb)

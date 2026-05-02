## Binds [member wire_rules] on a single [UiReact*] host: signals, [Resource.changed], and optionally an initial [method UiReactWireRule.apply] when [member UiReactWireRule.run_apply_on_attach] is [code]true[/code].
## See [code]docs/WIRING_LAYER.md[/code].
## Prefer [method schedule_attach] during [method Node._enter_tree] after [UiState] binding is wired in [method Node._ready], and detach during [method Node._exit_tree] **after** unbinding reactive [UiState] connections (typically [method UiReactControlStateWire.unbind_value_changed]), then call [method detach] so wiring rules never run against half-torn controls.
## [method attach] preserves two-phase semantics: bind connections for **all** enabled rules first, then [method UiReactWireRule.apply] for rows with [member UiReactWireRule.run_apply_on_attach] in array index order.
class_name UiReactWireRuleHelper
extends RefCounted

const _META_CONNS := &"_ui_react_wire_helper_conns"


static var _WIRE_BIND_DISPATCH_READY: bool = false
## [member Resource.get_script] key -> [Callable] taking [code](host, rule, conns)[/code].
static var _WIRE_BIND_DISPATCH_TABLE: Dictionary = {}


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
	var staged_apply_on_attach: Array[UiReactWireRule] = []
	for idx in range(wr.size()):
		var r_variant: Variant = wr[idx]
		if r_variant == null or not (r_variant is UiReactWireRule):
			continue
		var rule := r_variant as UiReactWireRule
		if not rule.enabled:
			continue
		_dispatch_bind_registered(host, rule, conns)
		if rule.run_apply_on_attach:
			staged_apply_on_attach.append(rule)
	for r_apply in staged_apply_on_attach:
		_apply_rule(host, r_apply)


static func _has_bindable_rules(host: Node) -> bool:
	if not &"wire_rules" in host:
		return false
	var wr_variant: Variant = host.get(&"wire_rules")
	if wr_variant == null or not (wr_variant is Array):
		return false
	for item in wr_variant as Array:
		if item is UiReactWireRule:
			var rr := item as UiReactWireRule
			if rr.enabled:
				return true
	return false


static func _ensure_wire_dispatch_table() -> void:
	if _WIRE_BIND_DISPATCH_READY:
		return
	_WIRE_BIND_DISPATCH_TABLE = {
		preload(
			"res://addons/ui_react/scripts/api/models/ui_react_wire_map_int_to_string.gd"
		): Callable(UiReactWireRuleHelper, "_binder_entry_map_int_to_string"),
		preload(
			"res://addons/ui_react/scripts/api/models/ui_react_wire_refresh_items_from_catalog.gd"
		): Callable(UiReactWireRuleHelper, "_binder_entry_refresh_items"),
		preload(
			"res://addons/ui_react/scripts/api/models/ui_react_wire_sort_array_by_key.gd"
		): Callable(UiReactWireRuleHelper, "_binder_entry_sort_array_by_key"),
		preload(
			"res://addons/ui_react/scripts/api/models/ui_react_wire_copy_selection_detail.gd"
		): Callable(UiReactWireRuleHelper, "_binder_entry_copy_detail"),
		preload(
			"res://addons/ui_react/scripts/api/models/ui_react_wire_set_string_on_bool_pulse.gd"
		): Callable(UiReactWireRuleHelper, "_binder_entry_set_string_on_bool_pulse"),
		preload(
			"res://addons/ui_react/scripts/api/models/ui_react_wire_sync_bool_state_debug_line.gd"
		): Callable(UiReactWireRuleHelper, "_binder_entry_sync_bool_debug_line"),
	}
	_WIRE_BIND_DISPATCH_READY = true


static func _binder_entry_map_int_to_string(
	host: Node, rule: UiReactWireRule, conns: Array[Dictionary]
) -> void:
	_bind_impl_map_int_to_string(host, rule as UiReactWireMapIntToString, conns)


static func _binder_entry_refresh_items(
	host: Node, rule: UiReactWireRule, conns: Array[Dictionary]
) -> void:
	_bind_impl_refresh_items(host, rule as UiReactWireRefreshItemsFromCatalog, conns)


static func _binder_entry_sort_array_by_key(
	host: Node, rule: UiReactWireRule, conns: Array[Dictionary]
) -> void:
	_bind_impl_sort_array_by_key(host, rule, conns)


static func _binder_entry_copy_detail(
	host: Node, rule: UiReactWireRule, conns: Array[Dictionary]
) -> void:
	_bind_impl_copy_detail(host, rule as UiReactWireCopySelectionDetail, conns)


static func _binder_entry_set_string_on_bool_pulse(
	host: Node, rule: UiReactWireRule, conns: Array[Dictionary]
) -> void:
	_bind_impl_set_string_on_bool_pulse(host, rule as UiReactWireSetStringOnBoolPulse, conns)


static func _binder_entry_sync_bool_debug_line(
	host: Node, rule: UiReactWireRule, conns: Array[Dictionary]
) -> void:
	_bind_impl_sync_bool_debug_line(host, rule as UiReactWireSyncBoolStateDebugLine, conns)


static func _dispatch_bind_registered(host: Node, rule: UiReactWireRule, conns: Array[Dictionary]) -> void:
	_ensure_wire_dispatch_table()
	var scr: Script = rule.get_script()
	if scr == null:
		var host_where := ""
		if is_instance_valid(host) and host.is_inside_tree():
			host_where = str(host.get_path())
		push_warning(
			"UiReactWireRuleHelper: rule '%s' has no script (resource='%s'; host='%s')"
			% [rule.rule_id, rule.resource_path, host_where]
		)
		return
	var cb: Callable = _WIRE_BIND_DISPATCH_TABLE.get(scr, Callable())
	if not cb.is_valid():
		var script_path := scr.resource_path
		push_warning(
			"UiReactWireRuleHelper: no binder registered for rule script '%s' on '%s'"
			% [script_path, host.name]
		)
		return
	cb.call(host, rule, conns)


## Test-only: number of [code]preload[/code] keys in the binder table ([code]_ensure_wire_dispatch_table[/code] populates six shipped rules).
static func debug_wire_bind_dispatch_count_for_tests() -> int:
	_ensure_wire_dispatch_table()
	return _WIRE_BIND_DISPATCH_TABLE.size()


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


static func _bind_impl_map_int_to_string(
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
	elif host is OptionButton:
		_safe_connect(conns, (host as OptionButton).item_selected, cb)
	elif host is TabContainer:
		_safe_connect(conns, (host as TabContainer).tab_selected, cb)
	if rule.source_int_state != null:
		_safe_connect(conns, rule.source_int_state.changed, cb)


static func _bind_impl_refresh_items(
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
			elif host is OptionButton:
				_safe_connect(conns, (host as OptionButton).item_selected, cb)
			elif host is TabContainer:
				_safe_connect(conns, (host as TabContainer).tab_selected, cb)
		_:
			push_warning(
				"UiReactWireRuleHelper: RefreshItemsFromCatalog rule '%s' trigger %s not bound on node %s."
				% [rule.rule_id, rule.trigger, host.get_path()]
			)
	if rule.filter_text_state != null:
		_safe_connect(conns, rule.filter_text_state.changed, cb)
	if rule.category_kind_state != null:
		_safe_connect(conns, rule.category_kind_state.changed, cb)


static func _bind_impl_sort_array_by_key(host: Node, rule: UiReactWireRule, conns: Array[Dictionary]) -> void:
	var cb := _make_rule_cb(host, rule)
	var items_st: Variant = rule.get(&"items_state")
	if items_st is UiState:
		_safe_connect(conns, (items_st as UiState).changed, cb)
	var key_st: Variant = rule.get(&"sort_key_state")
	if key_st is UiState:
		_safe_connect(conns, (key_st as UiState).changed, cb)
	var desc_st: Variant = rule.get(&"descending_state")
	if desc_st is UiState:
		_safe_connect(conns, (desc_st as UiState).changed, cb)


static func _bind_impl_copy_detail(
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
	if rule.trigger == UiReactWireRule.TriggerKind.SELECTION_CHANGED:
		if host is ItemList:
			_safe_connect(conns, (host as ItemList).item_selected, sel_cb)
		elif host is OptionButton:
			_safe_connect(conns, (host as OptionButton).item_selected, sel_cb)
		elif host is TabContainer:
			_safe_connect(conns, (host as TabContainer).tab_selected, sel_cb)
	if rule.items_state != null:
		_safe_connect(conns, rule.items_state.changed, apply_cb)
	if rule.suffix_note_state != null:
		_safe_connect(conns, rule.suffix_note_state.changed, apply_cb)
	if rule.selected_state != null:
		_safe_connect(conns, rule.selected_state.changed, sel_cb)


static func _bind_impl_set_string_on_bool_pulse(
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


static func _bind_impl_sync_bool_debug_line(
	host: Node, rule: UiReactWireSyncBoolStateDebugLine, conns: Array[Dictionary]
) -> void:
	var cb := _make_rule_cb(host, rule)
	if rule.bool_state != null:
		_safe_connect(conns, rule.bool_state.value_changed, cb)

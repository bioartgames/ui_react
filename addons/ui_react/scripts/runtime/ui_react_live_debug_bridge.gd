extends RefCounted
## Thin preloaded wrapper ([code]ui_react_live_debug_bridge.gd[/code]): [`static`] methods delegate to [`ui_react_live_debug_facade.gd`] via [`Variant.call`] on the façade script resource.

## The façade preload is typed as Variant so [method Variant.call] targets the exported script resource.

static var _facade_scr: Variant = preload(
	"res://addons/ui_react/scripts/runtime/ui_react_live_debug_facade.gd"
)


static func is_effective_enabled() -> bool:
	return bool(_facade_scr.call(&"is_effective_enabled"))


static func register_buffer(buffer: Object) -> void:
	_facade_scr.call(&"register_buffer", buffer)


static func unregister_buffer(buffer: Object) -> void:
	_facade_scr.call(&"unregister_buffer", buffer)


static func get_buffer_snapshot_newest_first() -> Array:
	var v: Variant = _facade_scr.call(&"get_buffer_snapshot_newest_first")
	if typeof(v) != TYPE_ARRAY:
		return []
	return v


static func maybe_computed_recompute(computed: UiState) -> void:
	_facade_scr.call(&"maybe_computed_recompute", computed)


static func maybe_wire_apply(host: Node, rule: UiReactWireRule) -> void:
	_facade_scr.call(&"maybe_wire_apply", host, rule)


static func maybe_action_apply(
	owner: Control,
	row: UiReactActionTarget,
	row_index: int,
	component_name: String,
	via_desc: String,
) -> void:
	_facade_scr.call(&"maybe_action_apply", owner, row, row_index, component_name, via_desc)


static func maybe_state_value_changed(
	st: UiState,
	new_val: Variant,
	old_val: Variant,
	host_path_str: String,
	property_hint: String,
) -> void:
	_facade_scr.call(
		&"maybe_state_value_changed",
		st,
		new_val,
		old_val,
		host_path_str,
		property_hint,
	)


static func reset_sequence_for_tests() -> void:
	_facade_scr.call(&"reset_sequence_for_tests")


static func get_force_enabled_for_tests() -> bool:
	return bool(_facade_scr.call(&"get_force_enabled_for_tests"))


static func set_force_enabled_for_tests(v: bool) -> void:
	_facade_scr.call(&"set_force_enabled_for_tests", v)

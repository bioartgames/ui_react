extends RefCounted
## Thin hooks for Ui React internals (wire/computed/actions/harvester). Call sites preload [code]ui_react_live_debug_bridge.gd[/code]; tests use static [method get_force_enabled_for_tests] / [method set_force_enabled_for_tests].


const _Kinds := preload("res://addons/ui_react/scripts/runtime/ui_react_live_debug_event_kinds.gd")
const _RUNTIME_LIVE_DEBUG_ENABLED_KEY := &"ui_react/settings/runtime/live_debug_enabled"


const _GraphIds := preload(
	"res://addons/ui_react/scripts/internal/react/ui_react_graph_node_ids.gd"
)

static var force_enabled_for_tests: bool = false
static var _buffer = null # UiReactLiveDebugBuffer Duck-typed — avoids cyclic class_name ordering
static var _seq: int = 0


static func register_buffer(buffer: Object) -> void:
	if buffer != null and buffer.has_method(&"push"):
		_buffer = buffer


static func unregister_buffer(buffer: Object) -> void:
	if _buffer != null and _buffer == buffer:
		_buffer = null
	_seq = 0


static func get_buffer_snapshot_newest_first() -> Array:
	if _buffer == null:
		return []
	return _buffer.call(&"snapshot_newest_first")


static func reset_sequence_for_tests() -> void:
	_seq = 0


static func get_force_enabled_for_tests() -> bool:
	return force_enabled_for_tests


static func set_force_enabled_for_tests(v: bool) -> void:
	force_enabled_for_tests = v


static func is_effective_enabled() -> bool:
	if force_enabled_for_tests:
		return true
	if not OS.is_debug_build():
		return false
	return bool(ProjectSettings.get_setting(_RUNTIME_LIVE_DEBUG_ENABLED_KEY, false))


static func maybe_state_value_changed(
	st: UiState,
	new_val: Variant,
	old_val: Variant,
	host_path_str: String,
	property_hint: String,
) -> void:
	if not is_effective_enabled() or _buffer == null:
		return
	if st == null or not is_instance_valid(st):
		return
	var hp := NodePath(host_path_str) if not host_path_str.is_empty() and host_path_str != "*" else NodePath()
	var ctx := property_hint if not property_hint.is_empty() else &"value_changed"
	var sid := _GraphIds.state_stable_id(hp, str(ctx), st)
	var meta: Dictionary = {
		_Kinds.META_STATE_ID: sid,
		_Kinds.META_RESOURCE_PATH: str(st.resource_path),
		_Kinds.META_NEW_VALUE_STR: _truncate_payload(var_to_str(new_val)),
		_Kinds.META_OLD_VALUE_STR: _truncate_payload(var_to_str(old_val)),
		_Kinds.META_HOST_PATH_OPTIONAL: host_path_str if host_path_str != "" else "*",
		_Kinds.META_PROPERTY_HINT: property_hint,
	}
	_do_push(_Kinds.Kind.STATE_VALUE_CHANGED, meta)


static func maybe_computed_recompute(computed: UiState) -> void:
	if not is_effective_enabled() or _buffer == null:
		return
	if computed == null or not is_instance_valid(computed):
		return
	var sid := _GraphIds.state_stable_id(NodePath(), "computed", computed)
	var meta: Dictionary = {
		_Kinds.META_STATE_ID: sid,
		_Kinds.META_RESOURCE_PATH: str(computed.resource_path),
		_Kinds.META_INSTANCE_ID: computed.get_instance_id(),
	}
	_do_push(_Kinds.Kind.COMPUTED_RECOMPUTE, meta)


static func maybe_wire_apply(host: Node, rule: UiReactWireRule) -> void:
	if not is_effective_enabled() or _buffer == null:
		return
	if host == null or not is_instance_valid(host) or rule == null:
		return
	var host_path_str := str(host.get_path()) if host.is_inside_tree() else ""
	var scr := rule.get_script() as Script
	var base := ""
	if scr != null:
		base = scr.resource_path.get_file()
	var rid := rule.rule_id if rule.rule_id != "" else rule.resource_path
	var meta: Dictionary = {
		_Kinds.META_RULE_ID: rid,
		_Kinds.META_HOST_PATH: host_path_str,
		_Kinds.META_RULE_SCRIPT_BASENAME: base,
	}
	_do_push(_Kinds.Kind.WIRE_RULE_APPLY, meta)


static func maybe_action_apply(
	owner: Control,
	row: UiReactActionTarget,
	row_index: int,
	component_name: String,
	via_desc: String,
) -> void:
	if not is_effective_enabled() or _buffer == null:
		return
	if owner == null or not is_instance_valid(owner) or row == null:
		return
	var meta: Dictionary = {
		_Kinds.META_HOST_PATH: str(owner.get_path()) if owner.is_inside_tree() else "",
		_Kinds.META_ROW_INDEX: row_index,
		_Kinds.META_ACTION_KIND: int(row.action),
		_Kinds.META_VIA: via_desc,
		&"component_name": component_name,
	}
	_do_push(_Kinds.Kind.ACTION_APPLY, meta)


static func _do_push(kind, meta: Dictionary) -> void:
	if _buffer == null:
		return
	_seq += 1
	var row := _Kinds.make_row(_seq, kind, meta)
	_buffer.call(&"push", row)


static func _truncate_payload(s: String) -> String:
	if s.length() <= 384:
		return s
	return s.substr(0, 381) + "..."

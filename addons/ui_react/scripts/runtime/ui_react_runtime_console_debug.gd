## Runtime (**CB-018C**) — one-line [code]print[/code] trace to editor **Output** for wire/computed/action orchestration (**debug builds**).
## Toggle from **Ui React** dock **Wiring** tab **footer** (below the Dependency Graph) only; persists [code]console_debug_enabled[/code] ([member UiReactDockConfig.KEY_RUNTIME_CONSOLE_DEBUG_ENABLED]). No autoload buffer.
extends RefCounted
class_name UiReactRuntimeConsoleDebug

## Must remain identical to [constant UiReactDockConfig.KEY_RUNTIME_CONSOLE_DEBUG_ENABLED].
const _PS_CONSOLE_DEBUG := "ui_react/settings/runtime/console_debug_enabled"

const MAX_FIELD_CHARS := 200

static var force_enabled_for_tests: bool = false
static var _test_lines: Array[String] = []


static func get_force_enabled_for_tests() -> bool:
	return force_enabled_for_tests


static func set_force_enabled_for_tests(v: bool) -> void:
	force_enabled_for_tests = v


static func clear_test_capture() -> void:
	_test_lines.clear()


static func get_test_capture_snapshot() -> Array[String]:
	var out: Array[String] = []
	out.assign(_test_lines)
	return out


static func effective_enabled() -> bool:
	if force_enabled_for_tests:
		return true
	if Engine.is_editor_hint():
		return false
	if not OS.is_debug_build():
		return false
	return bool(ProjectSettings.get_setting(_PS_CONSOLE_DEBUG, false))


static func _truncate(s: String, max_chars: int) -> String:
	if s.length() <= max_chars:
		return s
	return s.substr(0, max_chars) + "…"


static func _resource_gd_basename(res: Resource) -> String:
	if res == null:
		return "<null>"
	var scr: Variant = res.get_script()
	if scr != null and scr is Script:
		var p := (scr as Script).resource_path
		if p != "":
			return p.get_file()
	return "<embedded>"


static func _action_kind_label(kind: Variant) -> String:
	match kind:
		UiReactActionTarget.UiReactActionKind.GRAB_FOCUS:
			return "GRAB_FOCUS"
		UiReactActionTarget.UiReactActionKind.SET_VISIBLE:
			return "SET_VISIBLE"
		UiReactActionTarget.UiReactActionKind.SET_UI_BOOL_FLAG:
			return "SET_UI_BOOL_FLAG"
		UiReactActionTarget.UiReactActionKind.SET_MOUSE_FILTER:
			return "SET_MOUSE_FILTER"
		UiReactActionTarget.UiReactActionKind.SUBTRACT_PRODUCT_FROM_FLOAT:
			return "SUBTRACT_PRODUCT_FROM_FLOAT"
		UiReactActionTarget.UiReactActionKind.ADD_PRODUCT_TO_FLOAT:
			return "ADD_PRODUCT_TO_FLOAT"
		UiReactActionTarget.UiReactActionKind.TRANSFER_FLOAT_PRODUCT_CLAMPED:
			return "TRANSFER_FLOAT_PRODUCT_CLAMPED"
		UiReactActionTarget.UiReactActionKind.ADD_PRODUCT_TO_INT:
			return "ADD_PRODUCT_TO_INT"
		UiReactActionTarget.UiReactActionKind.TRANSFER_INT_PRODUCT_CLAMPED:
			return "TRANSFER_INT_PRODUCT_CLAMPED"
		UiReactActionTarget.UiReactActionKind.SET_FLOAT_LITERAL:
			return "SET_FLOAT_LITERAL"
		_:
			return "UNKNOWN(%d)" % int(kind)


static func _emit(kind: StringName, fields: Dictionary) -> void:
	if not effective_enabled():
		return
	var parts: PackedStringArray = PackedStringArray()
	parts.append("[UiReact:d]")
	parts.append(str(kind))
	var ks_sorted: Array = fields.keys()
	ks_sorted.sort_custom(func(a, b) -> bool: return String(a).nocasecmp_to(String(b)) < 0)
	for k_var in ks_sorted:
		var vv: Variant = fields[k_var]
		parts.append("%s=%s" % [str(k_var), _truncate(str(vv), MAX_FIELD_CHARS)])
	var line := " ".join(parts)
	print(line)
	if force_enabled_for_tests:
		_test_lines.append(line)


static func maybe_wire_apply(host: Node, rule: UiReactWireRule) -> void:
	var rid := rule.rule_id if rule.rule_id != "" else rule.resource_path
	if rid == "":
		rid = "<anonymous>"
	var host_str := ""
	if host != null and is_instance_valid(host) and host.is_inside_tree():
		host_str = str(host.get_path())
	else:
		host_str = "<freed?>"
	_emit(
		&"WIRE",
		{"host": host_str, "rule": rid, "script": _resource_gd_basename(rule)}
	)


static func maybe_computed_recompute(computed: UiState) -> void:
	if computed == null:
		return
	_emit(
		&"CMP",
		{
			"gd": _resource_gd_basename(computed),
			"id": str(computed.get_instance_id()),
			"path": computed.resource_path,
		}
	)


static func maybe_action_apply(
	owner: Node, component_name: String, row_index: int, action_kind: Variant
) -> void:
	var owner_str := ""
	if owner != null and is_instance_valid(owner) and owner.is_inside_tree():
		owner_str = str(owner.get_path())
	else:
		owner_str = "<invalid>"
	_emit(
		&"ACT",
		{
			"component": component_name,
			"idx": str(row_index),
			"kind": _action_kind_label(action_kind),
			"owner": owner_str,
		}
	)

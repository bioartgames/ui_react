## Runtime (**CB-018C**) — one-line [code]print[/code] trace to editor **Output** for wire/computed/action orchestration (**debug builds**).
## Toggle from **Ui React** dock **Wiring** tab only; persists [code]console_debug_enabled[/code] ([member UiReactDockConfig.KEY_RUNTIME_CONSOLE_DEBUG_ENABLED]). No autoload buffer.
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
		{"host": host_str, "rule": rid, "script": rule.get_class()}
	)


static func maybe_computed_recompute(computed: UiState) -> void:
	if computed == null:
		return
	_emit(&"CMP", {"id": str(computed.get_instance_id()), "path": computed.resource_path})


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
		{"component": component_name, "idx": str(row_index), "kind": str(action_kind), "owner": owner_str}
	)

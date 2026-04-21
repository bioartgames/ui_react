## Graph-adjacent **UiState** `.tres` creation (**Track 3**); DRY with [UiReactStateFactoryService].
class_name UiReactGraphResourceFactory
extends RefCounted


static func factory_state_class_names() -> PackedStringArray:
	return PackedStringArray(
		["UiBoolState", "UiIntState", "UiFloatState", "UiStringState", "UiArrayState"]
	)


static func is_factory_supported_class(class_name_str: String) -> bool:
	for c in factory_state_class_names():
		if c == class_name_str:
			return true
	return false


static func output_dir_from_project_settings() -> String:
	var raw: Variant = ProjectSettings.get_setting(
		UiReactDockConfig.KEY_STATE_OUTPUT_PATH,
		UiReactStateFactoryService.DEFAULT_OUTPUT_DIR
	)
	var p := String(raw).strip_edges()
	if p.is_empty():
		p = UiReactStateFactoryService.DEFAULT_OUTPUT_DIR
	if not p.ends_with("/"):
		p += "/"
	return p


static func _sanitize_path_stub(v: String, fallback: String) -> String:
	var s := v.strip_edges().to_lower()
	if s.is_empty():
		s = fallback
	s = s.replace(" ", "_").replace("-", "_")
	var out := ""
	for i: int in range(s.length()):
		var ch := s.substr(i, 1)
		var ok := (
			(ch >= "a" and ch <= "z")
			or (ch >= "0" and ch <= "9")
			or ch == "_"
		)
		out += ch if ok else "_"
	while out.contains("__"):
		out = out.replace("__", "_")
	out = out.strip_edges()
	if out.is_empty():
		out = fallback
	return out


## Deterministic default save path for Create / Create & assign flows.
static func suggest_state_save_path(
	state_class_name: String,
	output_dir: String,
	host_node_name: String = "",
	binding_prop_name: String = ""
) -> String:
	var node_stub := _sanitize_path_stub(host_node_name, "state")
	var class_stub := _sanitize_path_stub(state_class_name.trim_suffix("State"), "state")
	var prop_stub := _sanitize_path_stub(binding_prop_name, class_stub)
	var base_prop := "%s_%s" % [prop_stub, class_stub]
	return UiReactStateFactoryService.build_unique_file_path(output_dir, node_stub, base_prop)


## Save a new [UiState] instance to [param path] (must be [code]res://[/code]); returns reloaded resource or null.
static func save_new_state_at_path(state_class: StringName, path: String) -> Resource:
	if path.is_empty():
		return null
	var parent := path.get_base_dir()
	var err := UiReactStateFactoryService.ensure_output_dir(parent + "/")
	if err != OK:
		push_error("Ui React: could not create folder: %s" % parent)
		return null
	var res := UiReactStateFactoryService.instantiate_state(state_class)
	if res == null:
		return null
	return UiReactStateFactoryService.save_and_reload(res, path)

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

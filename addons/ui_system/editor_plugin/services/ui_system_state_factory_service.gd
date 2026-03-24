## Creates typed [UiState] subclasses and saves them under the plugin output folder.
class_name UiSystemStateFactoryService
extends RefCounted

const DEFAULT_OUTPUT_DIR := "res://addons/ui_system/ui_resources/plugin_generated/"


static func default_output_dir() -> String:
	var p := ProjectSettings.get_setting("ui_system/plugin_state_output_path", DEFAULT_OUTPUT_DIR) as String
	if p.is_empty():
		return DEFAULT_OUTPUT_DIR
	if not p.ends_with("/"):
		p += "/"
	return p


static func ensure_output_dir(path: String) -> Error:
	var abs_path := ProjectSettings.globalize_path(path)
	if DirAccess.dir_exists_absolute(abs_path):
		return OK
	return DirAccess.make_dir_recursive_absolute(abs_path)


static func instantiate_state(state_class: StringName) -> Resource:
	match String(state_class):
		"UiBoolState":
			return UiBoolState.new(false)
		"UiFloatState":
			return UiFloatState.new(0.0)
		"UiStringState":
			return UiStringState.new("")
		"UiArrayState":
			return UiArrayState.new([])
		"UiState":
			return UiState.new(null)
		_:
			return UiState.new(null)


static func build_file_path(output_dir: String, node_name: String, property_name: String) -> String:
	var base := _sanitize("%s_%s" % [node_name, property_name])
	return "%s%s.tres" % [output_dir, base]


static func _sanitize(s: String) -> String:
	var out := s.replace(" ", "_").replace("/", "_").replace(":", "_").replace("\\", "_")
	if out.is_empty():
		out = "ui_state"
	return out


## Saves [param resource] to [param path] and returns the loaded instance (for stable references in scenes).
static func save_and_reload(resource: Resource, path: String) -> Resource:
	var err := ResourceSaver.save(resource, path)
	if err != OK:
		push_error("UiSystemStateFactoryService: failed to save %s (error %d)" % [path, err])
		return null
	return ResourceLoader.load(path)

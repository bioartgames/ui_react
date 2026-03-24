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


## First free path matching [code]build_file_path[/code], then [code]<base>_2.tres[/code], [code]<base>_3.tres[/code], … if files already exist (no overwrites).
static func build_unique_file_path(output_dir: String, node_name: String, property_name: String) -> String:
	var base := _sanitize("%s_%s" % [node_name, property_name])
	var first := "%s%s.tres" % [output_dir, base]
	if not _resource_file_exists(first):
		return first
	var i := 2
	while i < 10000:
		var candidate := "%s%s_%d.tres" % [output_dir, base, i]
		if not _resource_file_exists(candidate):
			return candidate
		i += 1
	push_error("UiSystemStateFactoryService: could not find free filename for base %s" % base)
	return first


static func _resource_file_exists(path: String) -> bool:
	if path.is_empty():
		return false
	var abs_path := ProjectSettings.globalize_path(path)
	return FileAccess.file_exists(abs_path)


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

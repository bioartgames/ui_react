## Extracts [code]res://[/code] path strings from a saved scene file (text [code].tscn[/code]) for editor diagnostics.
class_name UiReactSceneFileResourcePaths
extends RefCounted

const _RES_PATH_PATTERN := "res://[^\\s\"']+"

static func normalize_res_path(path: String) -> String:
	return path.strip_edges().replace("\\", "/")


## Returns [code]Dictionary[/code] with normalized [code]res://[/code] paths as keys (values [code]true[/code]).
## [param scene_file_path]: [code]res://[/code] or absolute path to [code].tscn[/code] / [code].scn[/code].
static func collect_res_paths_from_scene_file(scene_file_path: String) -> Dictionary:
	var out: Dictionary = {}
	var trimmed := scene_file_path.strip_edges()
	if trimmed.is_empty():
		return out

	if not FileAccess.file_exists(trimmed):
		push_warning(
			"UiReactSceneFileResourcePaths: scene file not found (%s); skipping scene-file unused scan." % trimmed
		)
		return out

	var text := FileAccess.get_file_as_string(trimmed)
	if text.is_empty():
		push_warning(
			"UiReactSceneFileResourcePaths: empty or unreadable scene file (%s); skipping scene-file unused scan." % trimmed
		)
		return out

	var rx := RegEx.new()
	var err := rx.compile(_RES_PATH_PATTERN)
	if err != OK:
		push_warning("UiReactSceneFileResourcePaths: regex compile failed.")
		return out

	var m := rx.search_all(text)
	for r in m:
		var s := normalize_res_path(String(r.get_string()))
		if not s.is_empty():
			out[s] = true
	return out

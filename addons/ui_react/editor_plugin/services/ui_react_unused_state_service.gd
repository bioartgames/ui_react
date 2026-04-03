## Builds dock INFO rows for [UiState] [code].tres[/code] that appear in the **saved** edited scene file but are **not** assigned on any [UiReact*] binding in that scene.
##
## Scope: the active edited scene only (parsed from [member Node.scene_file_path] text). No project-wide scan.
## Unsaved scenes ([code]scene_file_path[/code] empty): no unused-state rows. Code-only assignments (never in [code].tscn[/code]) are not candidates.
class_name UiReactUnusedStateService
extends RefCounted

const _FIX_HINT := (
	"This [UiState] path appears in the saved scene file for the **edited** scene but is not assigned on any Ui React control here. "
	+ "This check does **not** scan other scenes or script-only references. "
	+ "Assign it on a [UiReact*] export, remove it from the scene if unused, or ignore this row; do not assume it is safe to delete without checking Godot's dependency warning."
)

## path_norm -> { mtime: int, is_ui_state: bool }
static var _load_cache: Dictionary = {}


static func clear_load_cache() -> void:
	_load_cache.clear()


static func build_issues(output_dir: String, root: Node) -> Array[UiReactDiagnosticModel.DiagnosticIssue]:
	var issues: Array[UiReactDiagnosticModel.DiagnosticIssue] = []
	if root == null:
		return issues

	var scene_fp: String = root.scene_file_path.strip_edges()
	if scene_fp.is_empty():
		return issues

	var scene_paths: Dictionary = UiReactSceneFileResourcePaths.collect_res_paths_from_scene_file(scene_fp)
	if scene_paths.is_empty():
		return issues

	var dir_norm := _normalize_output_dir(output_dir)
	if dir_norm.is_empty():
		return issues
	var dir_trim := dir_norm.trim_suffix("/")
	var da := DirAccess.open(dir_trim)
	if da == null:
		return issues

	var referenced: Dictionary = UiReactStateReferenceCollector.collect_referenced_state_paths_for_scene(root)
	var referenced_norm: Dictionary = {}
	for k in referenced.keys():
		referenced_norm[UiReactSceneFileResourcePaths.normalize_res_path(str(k))] = true

	var candidates: Array[String] = []
	var list_err := da.list_dir_begin()
	if list_err != OK:
		push_warning("UiReactUnusedStateService: list_dir_begin failed (%s) for %s" % [list_err, dir_trim])
		return issues
	var entry := da.get_next()
	while entry != "":
		if not da.current_is_dir() and entry.ends_with(".tres"):
			candidates.append(dir_norm + entry)
		entry = da.get_next()
	da.list_dir_end()
	candidates.sort()

	for path in candidates:
		var path_norm: String = UiReactSceneFileResourcePaths.normalize_res_path(path)
		if not scene_paths.has(path_norm):
			continue
		if referenced_norm.has(path_norm):
			continue

		var mt: int = FileAccess.get_modified_time(path)
		if mt == 0:
			mt = -1

		var cached: Variant = _load_cache.get(path_norm, null)
		if cached is Dictionary:
			var cd: Dictionary = cached
			if int(cd.get("mtime", -2)) == mt:
				if cd.get("is_ui_state", false):
					issues.append(
						UiReactDiagnosticModel.DiagnosticIssue.make_unused_state_file_issue(
							path,
							"UiState in this scene file, not on Ui React: %s" % path,
							_FIX_HINT,
						)
					)
				continue

		var res := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REUSE) as Resource
		var is_ui := res != null and res is UiState
		_load_cache[path_norm] = {"mtime": mt, "is_ui_state": is_ui}
		if is_ui:
			issues.append(
				UiReactDiagnosticModel.DiagnosticIssue.make_unused_state_file_issue(
					path,
					"UiState in this scene file, not on Ui React: %s" % path,
					_FIX_HINT,
				)
			)
	return issues


static func _normalize_output_dir(path: String) -> String:
	var p := path.strip_edges()
	if p.is_empty():
		p = UiReactStateFactoryService.default_output_dir()
	if not p.ends_with("/"):
		p += "/"
	return p

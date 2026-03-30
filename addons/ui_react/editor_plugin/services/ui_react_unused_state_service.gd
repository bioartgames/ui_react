## Builds dock diagnostics for [UiState] [code].tres[/code] files in the plugin output folder not bound in the edited scene.
class_name UiReactUnusedStateService
extends RefCounted

const _FIX_HINT := (
	"Not referenced by any Ui React binding in this scene. "
	+ "Safe to delete if you do not load or assign this resource from code or other scenes."
)


static func build_issues(output_dir: String, root: Node) -> Array[UiReactDiagnosticModel.DiagnosticIssue]:
	var issues: Array[UiReactDiagnosticModel.DiagnosticIssue] = []
	var dir_norm := _normalize_output_dir(output_dir)
	if dir_norm.is_empty():
		return issues
	var dir_trim := dir_norm.trim_suffix("/")
	var da := DirAccess.open(dir_trim)
	if da == null:
		return issues
	var referenced: Dictionary = UiReactStateReferenceCollector.collect_referenced_state_paths_for_scene(root)
	var candidates: Array[String] = []
	da.list_dir_begin()
	var entry := da.get_next()
	while entry != "":
		if not da.current_is_dir() and entry.ends_with(".tres"):
			candidates.append(dir_norm + entry)
		entry = da.get_next()
	da.list_dir_end()
	candidates.sort()
	for path in candidates:
		if referenced.has(path):
			continue
		var res := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Resource
		if res != null and res is UiState:
			issues.append(
				UiReactDiagnosticModel.DiagnosticIssue.make_structured(
					UiReactDiagnosticModel.Severity.INFO,
					"",
					"",
					"Unused state file: %s" % path,
					_FIX_HINT,
					NodePath(),
					&"",
					&"",
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

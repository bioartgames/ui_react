## Fix, copy, focus, ignore, and scan-collection actions for [UiReactDock].
class_name UiReactDockActions
extends RefCounted

var _dock: UiReactDock


func _init(dock: UiReactDock) -> void:
	_dock = dock


func collect_react_under(n: Node) -> Array[Node]:
	var out: Array[Node] = []
	if UiReactScannerService.is_react_node(n):
		out.append(n)
	for c in n.get_children():
		for r in collect_react_under(c):
			out.append(r)
	return out


func resolve_output_dir() -> String:
	var out_dir := _dock._path_edit.text.strip_edges()
	if out_dir.is_empty():
		out_dir = UiReactStateFactoryService.default_output_dir()
	if not out_dir.ends_with("/"):
		out_dir += "/"
	return out_dir


func resolve_node_for_issue_fix(issue: UiReactDiagnosticModel.DiagnosticIssue) -> Node:
	if issue == null or issue.property_name == &"" or issue.suggested_state_class == &"":
		return null
	var ei := _dock._plugin.get_editor_interface()
	var root := ei.get_edited_scene_root()
	if root == null:
		return null
	var node := root.get_node_or_null(issue.node_path)
	if node == null or not (node is Node):
		push_warning("UiReactDock: node not found for path %s" % issue.node_path)
		return null
	return node


func maybe_confirm_replace_binding(node: Node, issue: UiReactDiagnosticModel.DiagnosticIssue) -> bool:
	var cur: Variant = node.get(issue.property_name)
	if cur == null:
		return true
	_dock._replace_confirm_dialog.title = "Replace binding resource"
	_dock._replace_confirm_dialog.dialog_text = (
		"Property '%s' already has a resource assigned. Replace it with a new %s saved to the output folder? "
		% [str(issue.property_name), str(issue.suggested_state_class)]
		+ "The old reference will be unassigned from this property (the file on disk is not deleted)."
	)
	_dock._replace_confirm_dialog.popup_centered()
	var accepted := false
	var finished := false
	var on_ok := func() -> void:
		accepted = true
		finished = true
	var on_cancel := func() -> void:
		accepted = false
		finished = true
	_dock._replace_confirm_dialog.confirmed.connect(on_ok, CONNECT_ONE_SHOT)
	_dock._replace_confirm_dialog.canceled.connect(on_cancel, CONNECT_ONE_SHOT)
	while not finished:
		await _dock.get_tree().process_frame
	return accepted


func create_and_assign_core(issue: UiReactDiagnosticModel.DiagnosticIssue, node: Node) -> bool:
	if node == null:
		return false
	var out_dir := resolve_output_dir()
	_dock._persist_state_output_path(out_dir)
	var err := UiReactStateFactoryService.ensure_output_dir(out_dir)
	if err != OK:
		push_error("UiReactDock: could not create output folder: %s" % out_dir)
		return false

	var res := UiReactStateFactoryService.instantiate_state(issue.suggested_state_class)
	var path: String = UiReactStateFactoryService.build_unique_file_path(
		out_dir, str(node.name), str(issue.property_name)
	)
	var loaded := UiReactStateFactoryService.save_and_reload(res, path)
	if loaded == null:
		return false
	_dock._actions.assign_resource_property(node, issue.property_name, loaded)
	return true


func create_and_assign_for_issue(issue: UiReactDiagnosticModel.DiagnosticIssue) -> bool:
	var node := resolve_node_for_issue_fix(issue)
	if node == null:
		return false
	return create_and_assign_core(issue, node)


func on_row_fix(flat_index: int) -> void:
	if flat_index < 0 or flat_index >= _dock._issues_shown.size():
		return
	var issue: UiReactDiagnosticModel.DiagnosticIssue = _dock._issues_shown[flat_index]
	if not _dock._can_create_state_for_issue(issue):
		return
	var node := resolve_node_for_issue_fix(issue)
	if node == null:
		return
	if not await maybe_confirm_replace_binding(node, issue):
		return
	if not create_and_assign_core(issue, node):
		return
	_dock._plugin.get_editor_interface().get_resource_filesystem().scan()
	_dock.request_refresh(&"after_row_fix")


func on_row_focus(flat_index: int) -> void:
	if flat_index < 0 or flat_index >= _dock._issues_shown.size():
		return
	var issue: UiReactDiagnosticModel.DiagnosticIssue = _dock._issues_shown[flat_index]
	if issue.node_path.is_empty():
		return
	var ei := _dock._plugin.get_editor_interface()
	var root := ei.get_edited_scene_root()
	if root == null:
		return
	var node := root.get_node_or_null(issue.node_path)
	if node:
		ei.edit_node(node)


func on_row_ignore(flat_index: int) -> void:
	if flat_index < 0 or flat_index >= _dock._issues_shown.size():
		return
	var issue: UiReactDiagnosticModel.DiagnosticIssue = _dock._issues_shown[flat_index]
	_dock._ignored_issue_keys[UiReactDockFilter.fingerprint(issue)] = true
	_dock._apply_filters()


func on_ignore_all() -> void:
	if _dock._issues_shown.is_empty():
		return
	for issue in _dock._issues_shown:
		_dock._ignored_issue_keys[UiReactDockFilter.fingerprint(issue)] = true
	_dock._apply_filters()


func on_copy_report() -> void:
	var lines: Array[String] = []
	for issue in _dock._issues_shown:
		var line := "%s %s" % [
			UiReactDockIssueList.severity_prefix(issue.severity),
			issue.get_summary_line(),
		]
		if not issue.fix_hint.is_empty():
			line += " Fix: %s" % issue.fix_hint
		lines.append(line)
	DisplayServer.clipboard_set("\n".join(lines))


func on_fix_all() -> void:
	var to_fix: Array[UiReactDiagnosticModel.DiagnosticIssue] = []
	for issue in _dock._issues_shown:
		if _dock._can_fix_all_for_issue(issue):
			to_fix.append(issue)
	if to_fix.is_empty():
		return

	var created := 0
	var failed := 0
	for issue in to_fix:
		if create_and_assign_for_issue(issue):
			created += 1
		else:
			failed += 1

	_dock._plugin.get_editor_interface().get_resource_filesystem().scan()
	_dock.request_refresh(&"after_fix_all")
	if failed > 0:
		push_warning("UiReactDock: Fix All — created: %d, failed: %d" % [created, failed])

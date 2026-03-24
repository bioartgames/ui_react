@tool
extends Control

const _SCAN_SELECTION := 0
const _SCAN_SCENE := 1

var _plugin: EditorPlugin
var _actions: UiSystemActionController

var _issues_all: Array = []
var _issues_shown: Array = []

var _mode_option: OptionButton
var _filter_err: CheckBox
var _filter_warn: CheckBox
var _filter_info: CheckBox
var _auto_refresh: CheckBox
var _path_edit: LineEdit
var _item_list: ItemList
var _details_scroll: ScrollContainer
var _details_label: RichTextLabel
var _btn_refresh: Button
var _btn_copy: Button
var _btn_focus: Button
var _btn_create: Button


func setup(plugin: EditorPlugin) -> void:
	_plugin = plugin
	_actions = UiSystemActionController.new(plugin.get_undo_redo())
	_build_ui()
	_connect_editor_signals()
	_register_default_project_settings()
	call_deferred(&"refresh")


func _register_default_project_settings() -> void:
	if not ProjectSettings.has_setting("ui_system/plugin_state_output_path"):
		ProjectSettings.set_setting("ui_system/plugin_state_output_path", UiSystemStateFactoryService.DEFAULT_OUTPUT_DIR)
	if _path_edit:
		_path_edit.text = UiSystemStateFactoryService.default_output_dir()


func _build_ui() -> void:
	# Match built-in bottom tabs: prevent collapsing to an unusably tiny height.
	custom_minimum_size = Vector2(0, 180)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_child(vbox)

	var mode_row := HBoxContainer.new()
	vbox.add_child(mode_row)
	mode_row.add_child(Label.new())
	mode_row.get_child(0).text = "Scan:"
	_mode_option = OptionButton.new()
	_mode_option.add_item("Selection", _SCAN_SELECTION)
	_mode_option.add_item("Entire scene", _SCAN_SCENE)
	_mode_option.item_selected.connect(func(_i): refresh())
	mode_row.add_child(_mode_option)

	_auto_refresh = CheckBox.new()
	_auto_refresh.text = "Auto-refresh on selection"
	_auto_refresh.button_pressed = true
	_auto_refresh.toggled.connect(func(_on): refresh())
	mode_row.add_child(_auto_refresh)

	var filt_row := HBoxContainer.new()
	vbox.add_child(filt_row)
	filt_row.add_child(Label.new())
	filt_row.get_child(0).text = "Show:"
	_filter_err = CheckBox.new()
	_filter_err.text = "Errors"
	_filter_err.button_pressed = true
	_filter_err.toggled.connect(func(_on): _apply_filters())
	filt_row.add_child(_filter_err)
	_filter_warn = CheckBox.new()
	_filter_warn.text = "Warnings"
	_filter_warn.button_pressed = true
	_filter_warn.toggled.connect(func(_on): _apply_filters())
	filt_row.add_child(_filter_warn)
	_filter_info = CheckBox.new()
	_filter_info.text = "Info"
	_filter_info.button_pressed = true
	_filter_info.toggled.connect(func(_on): _apply_filters())
	filt_row.add_child(_filter_info)

	var path_row := HBoxContainer.new()
	vbox.add_child(path_row)
	path_row.add_child(Label.new())
	path_row.get_child(0).text = "State output folder:"
	_path_edit = LineEdit.new()
	_path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_path_edit.text = UiSystemStateFactoryService.default_output_dir()
	_path_edit.text_submitted.connect(func(p): _on_path_changed(p))
	path_row.add_child(_path_edit)

	_item_list = ItemList.new()
	_item_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_item_list.custom_minimum_size = Vector2(0, 140)
	_item_list.item_selected.connect(_on_item_selected)
	vbox.add_child(_item_list)

	_details_scroll = ScrollContainer.new()
	_details_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_details_scroll.custom_minimum_size = Vector2(0, 120)
	vbox.add_child(_details_scroll)

	_details_label = RichTextLabel.new()
	_details_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_details_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_details_label.bbcode_enabled = true
	_details_label.fit_content = true
	_details_label.scroll_active = false
	_details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details_scroll.add_child(_details_label)

	var btn_row := HBoxContainer.new()
	vbox.add_child(btn_row)
	_btn_refresh = Button.new()
	_btn_refresh.text = "Refresh"
	_btn_refresh.pressed.connect(refresh)
	btn_row.add_child(_btn_refresh)
	_btn_copy = Button.new()
	_btn_copy.text = "Copy report"
	_btn_copy.pressed.connect(_on_copy_report)
	btn_row.add_child(_btn_copy)
	_btn_focus = Button.new()
	_btn_focus.text = "Focus node"
	_btn_focus.disabled = true
	_btn_focus.pressed.connect(_on_focus_node)
	btn_row.add_child(_btn_focus)
	_btn_create = Button.new()
	_btn_create.text = "Create & assign typed state"
	_btn_create.disabled = true
	_btn_create.pressed.connect(_on_create_assign)
	btn_row.add_child(_btn_create)

	_update_details_pane(null)
	_update_action_buttons(null)


func _connect_editor_signals() -> void:
	var ei := _plugin.get_editor_interface()
	ei.get_selection().selection_changed.connect(_on_selection_changed)


func _on_selection_changed() -> void:
	if _auto_refresh and _auto_refresh.button_pressed and _mode_option.selected == _SCAN_SELECTION:
		refresh()


func _on_path_changed(new_text: String) -> void:
	var p := new_text.strip_edges()
	if p.is_empty():
		return
	if not p.ends_with("/"):
		p += "/"
	ProjectSettings.set_setting("ui_system/plugin_state_output_path", p)


func _on_item_selected(_idx: int) -> void:
	var issue: Variant = _get_selected_issue()
	_update_details_pane(issue)
	_update_action_buttons(issue)


func _get_selected_issue() -> Variant:
	var sel := _item_list.get_selected_items()
	if sel.is_empty():
		return null
	var i := int(sel[0])
	if i < 0 or i >= _issues_shown.size():
		return null
	return _issues_shown[i]


func _update_details_pane(issue: Variant) -> void:
	if issue == null:
		_details_label.text = "[i]Select an issue in the list above to see the full message, fix, and metadata.[/i]"
		return
	var sev := _severity_display_name(issue.severity)
	var body := ""
	body += "[b]Severity[/b]: %s\n" % sev
	if not issue.component_name.is_empty():
		body += "[b]Component[/b]: %s\n" % issue.component_name
	if not issue.node_name.is_empty():
		body += "[b]Node[/b]: %s\n" % issue.node_name
	if not issue.node_path.is_empty():
		body += "[b]Path[/b]: %s\n" % str(issue.node_path)
	var itxt: String = issue.issue_text if not issue.issue_text.is_empty() else issue.message
	body += "[b]Issue[/b]: %s\n" % itxt
	if not issue.fix_hint.is_empty():
		body += "[b]Fix[/b]: %s\n" % issue.fix_hint
	if issue.property_name != &"":
		body += "[b]Property[/b]: %s\n" % str(issue.property_name)
	if issue.suggested_state_class != &"":
		body += "[b]Suggested type[/b]: %s\n" % str(issue.suggested_state_class)
	_details_label.text = body


func _severity_display_name(sev: int) -> String:
	match sev:
		UiSystemDiagnosticModel.Severity.ERROR:
			return "Error"
		UiSystemDiagnosticModel.Severity.WARNING:
			return "Warning"
		_:
			return "Info"


func _update_action_buttons(issue: Variant) -> void:
	if issue == null:
		_btn_focus.disabled = true
		_btn_create.disabled = true
		return
	_btn_focus.disabled = issue.node_path.is_empty()
	var can_create: bool = (
		issue.severity == UiSystemDiagnosticModel.Severity.INFO
		and issue.property_name != &""
		and issue.suggested_state_class != &""
	)
	_btn_create.disabled = not can_create


func refresh() -> void:
	_issues_all.clear()
	var ei := _plugin.get_editor_interface()
	var root := ei.get_edited_scene_root()
	if root == null:
		_issues_all.append(
			UiSystemDiagnosticModel.DiagnosticIssue.make_structured(
				UiSystemDiagnosticModel.Severity.INFO,
				"",
				"",
				"No edited scene.",
				"Open a scene with UiReact* controls.",
				NodePath(),
				&"",
				&"",
			)
		)
		_apply_filters()
		return

	var nodes: Array[Node] = []
	if _mode_option.selected == _SCAN_SCENE:
		for n in UiSystemScannerService.collect_react_nodes(root):
			nodes.append(n)
	else:
		var seen: Dictionary = {}
		for sel in ei.get_selection().get_selected_nodes():
			for r in _collect_react_under(sel):
				if not seen.has(r):
					seen[r] = true
					nodes.append(r)

	if nodes.is_empty():
		_issues_all.append(
			UiSystemDiagnosticModel.DiagnosticIssue.make_structured(
				UiSystemDiagnosticModel.Severity.INFO,
				"",
				"",
				"No UiReact* nodes in this scan scope.",
				"Attach a UiReact* script or change scan mode to Entire scene.",
				NodePath(),
				&"",
				&"",
			)
		)
	else:
		_issues_all.append_array(UiSystemValidatorService.validate_nodes(nodes, root))

	_apply_filters()


func _apply_filters() -> void:
	_issues_shown.clear()
	_item_list.clear()
	for issue in _issues_all:
		if issue.severity == UiSystemDiagnosticModel.Severity.ERROR and not _filter_err.button_pressed:
			continue
		if issue.severity == UiSystemDiagnosticModel.Severity.WARNING and not _filter_warn.button_pressed:
			continue
		if issue.severity == UiSystemDiagnosticModel.Severity.INFO and not _filter_info.button_pressed:
			continue
		_issues_shown.append(issue)
		var prefix := _severity_prefix(issue.severity)
		var summary: String = issue.summary_text if not String(issue.summary_text).is_empty() else issue.message
		_item_list.add_item("%s %s" % [prefix, summary])

	if _issues_shown.is_empty():
		_item_list.deselect_all()
		_update_details_pane(null)
		_update_action_buttons(null)
	else:
		_item_list.select(0)
		_update_details_pane(_issues_shown[0])
		_update_action_buttons(_issues_shown[0])


func _severity_prefix(sev: int) -> String:
	match sev:
		UiSystemDiagnosticModel.Severity.ERROR:
			return "[E]"
		UiSystemDiagnosticModel.Severity.WARNING:
			return "[W]"
		_:
			return "[I]"


func _on_copy_report() -> void:
	var lines: Array[String] = []
	for issue in _issues_shown:
		var line := "%s %s" % [_severity_prefix(issue.severity), issue.message]
		if not issue.fix_hint.is_empty():
			line += " Fix: %s" % issue.fix_hint
		lines.append(line)
	DisplayServer.clipboard_set("\n".join(lines))


func _on_focus_node() -> void:
	var issue: Variant = _get_selected_issue()
	if issue == null or issue.node_path.is_empty():
		return
	var ei := _plugin.get_editor_interface()
	var root := ei.get_edited_scene_root()
	if root == null:
		return
	var node := root.get_node_or_null(issue.node_path)
	if node:
		ei.edit_node(node)


func _on_create_assign() -> void:
	var issue: Variant = _get_selected_issue()
	if issue == null or issue.property_name == &"" or issue.suggested_state_class == &"":
		return
	var ei := _plugin.get_editor_interface()
	var root := ei.get_edited_scene_root()
	if root == null:
		return
	var node := root.get_node_or_null(issue.node_path)
	if node == null or not (node is Node):
		push_warning("UiSystemDock: node not found for path %s" % issue.node_path)
		return

	var out_dir := _path_edit.text.strip_edges()
	if out_dir.is_empty():
		out_dir = UiSystemStateFactoryService.default_output_dir()
	if not out_dir.ends_with("/"):
		out_dir += "/"
	ProjectSettings.set_setting("ui_system/plugin_state_output_path", out_dir)
	var err := UiSystemStateFactoryService.ensure_output_dir(out_dir)
	if err != OK:
		push_error("UiSystemDock: could not create output folder: %s" % out_dir)
		return

	var res := UiSystemStateFactoryService.instantiate_state(issue.suggested_state_class)
	var path := UiSystemStateFactoryService.build_file_path(out_dir, str(node.name), str(issue.property_name))
	var loaded := UiSystemStateFactoryService.save_and_reload(res, path)
	if loaded == null:
		return
	_actions.assign_resource_property(node, issue.property_name, loaded)
	_plugin.get_editor_interface().get_resource_filesystem().scan()
	refresh()


func _collect_react_under(n: Node) -> Array[Node]:
	var out: Array[Node] = []
	if UiSystemScannerService.is_react_node(n):
		out.append(n)
	for c in n.get_children():
		for r in _collect_react_under(c):
			out.append(r)
	return out

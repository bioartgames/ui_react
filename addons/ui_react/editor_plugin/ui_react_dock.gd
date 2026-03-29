@tool
extends Control

const _SCAN_SELECTION := 0
const _SCAN_SCENE := 1

const _GROUP_FLAT := 0
const _GROUP_BY_NODE := 1
const _GROUP_BY_SEVERITY := 2

const _KEY_SCAN_MODE := "ui_react/plugin_scan_mode"
const _KEY_SHOW_ERRORS := "ui_react/plugin_show_errors"
const _KEY_SHOW_WARNINGS := "ui_react/plugin_show_warnings"
const _KEY_SHOW_INFO := "ui_react/plugin_show_info"
const _KEY_AUTO_REFRESH := "ui_react/plugin_auto_refresh"
const _KEY_STATE_OUTPUT_PATH := "ui_react/plugin_state_output_path"

const _DEF_SHOW_ERRORS := true
const _DEF_SHOW_WARNINGS := true
const _DEF_SHOW_INFO := true
const _DEF_AUTO_REFRESH := true

## Blocks save callbacks while applying persisted values (avoids duplicate writes / refresh loops).
var _suppress_pref_save: bool = false

## Coalesces multiple refresh requests into one deferred [method refresh] call per frame.
var _coalesced_refresh_pending: bool = false
## Set by [method _run_startup_refresh]; cleared after first successful root or one no-scene retry.
var _expect_startup_scene_retry: bool = false

var _plugin: EditorPlugin
var _actions: UiReactActionController

var _issues_all: Array = []
var _issues_shown: Array = []

## Session-only: hidden until next [method refresh] (fingerprint keys).
var _ignored_issue_keys: Dictionary = {}

var _selected_flat_index: int = -1

var _search_timer: Timer

var _mode_option: OptionButton
var _group_option: OptionButton
var _filter_err: CheckBox
var _filter_warn: CheckBox
var _filter_info: CheckBox
var _auto_refresh: CheckBox
var _path_edit: LineEdit
var _search_edit: LineEdit
var _issues_scroll: ScrollContainer
var _issues_container: VBoxContainer
var _details_scroll: ScrollContainer
var _details_label: RichTextLabel
var _btn_refresh: Button
var _btn_copy: Button
var _btn_fix_all: Button
var _replace_confirm_dialog: ConfirmationDialog

## group_key -> expanded (for grouped view)
var _group_expanded: Dictionary = {}


func setup(plugin: EditorPlugin) -> void:
	_plugin = plugin
	_actions = UiReactActionController.new(plugin.get_undo_redo())
	_build_ui()
	_register_default_project_settings()
	_load_persisted_ui_preferences()
	_connect_editor_signals()
	call_deferred(&"_run_startup_refresh")


func request_refresh(_reason: StringName = &"manual") -> void:
	if _coalesced_refresh_pending:
		return
	_coalesced_refresh_pending = true
	call_deferred(&"_execute_pending_refresh")


func _execute_pending_refresh() -> void:
	_coalesced_refresh_pending = false
	refresh()


func _run_startup_refresh() -> void:
	_expect_startup_scene_retry = true
	request_refresh(&"startup")


## Called from [EditorPlugin] when the edited scene tab changes (open/switch/empty).
func notify_edited_scene_changed() -> void:
	request_refresh(&"scene_changed")


func _save_ui_preference(key: String, value: Variant) -> void:
	ProjectSettings.set_setting(key, value)
	var err := ProjectSettings.save()
	if err != OK:
		push_warning("UiReactDock: could not save project settings (%s)" % key)


func _register_default_project_settings() -> void:
	var added_defaults := false
	if not ProjectSettings.has_setting(_KEY_STATE_OUTPUT_PATH):
		ProjectSettings.set_setting(_KEY_STATE_OUTPUT_PATH, UiReactStateFactoryService.DEFAULT_OUTPUT_DIR)
		added_defaults = true
	if not ProjectSettings.has_setting(_KEY_SCAN_MODE):
		ProjectSettings.set_setting(_KEY_SCAN_MODE, _SCAN_SELECTION)
		added_defaults = true
	if not ProjectSettings.has_setting(_KEY_SHOW_ERRORS):
		ProjectSettings.set_setting(_KEY_SHOW_ERRORS, _DEF_SHOW_ERRORS)
		added_defaults = true
	if not ProjectSettings.has_setting(_KEY_SHOW_WARNINGS):
		ProjectSettings.set_setting(_KEY_SHOW_WARNINGS, _DEF_SHOW_WARNINGS)
		added_defaults = true
	if not ProjectSettings.has_setting(_KEY_SHOW_INFO):
		ProjectSettings.set_setting(_KEY_SHOW_INFO, _DEF_SHOW_INFO)
		added_defaults = true
	if not ProjectSettings.has_setting(_KEY_AUTO_REFRESH):
		ProjectSettings.set_setting(_KEY_AUTO_REFRESH, _DEF_AUTO_REFRESH)
		added_defaults = true
	if added_defaults:
		var err := ProjectSettings.save()
		if err != OK:
			push_warning("UiReactDock: could not save default project settings")


func _load_persisted_ui_preferences() -> void:
	_suppress_pref_save = true

	var mode_raw: Variant = ProjectSettings.get_setting(_KEY_SCAN_MODE, _SCAN_SELECTION)
	var mode_id: int = int(mode_raw) if typeof(mode_raw) in [TYPE_INT, TYPE_FLOAT] else _SCAN_SELECTION
	if mode_id != _SCAN_SELECTION and mode_id != _SCAN_SCENE:
		mode_id = _SCAN_SELECTION
	if _mode_option:
		var idx := _mode_option.get_item_index(mode_id)
		if idx >= 0:
			_mode_option.select(idx)
		else:
			_mode_option.select(_mode_option.get_item_index(_SCAN_SELECTION))

	if _filter_err:
		_filter_err.button_pressed = bool(ProjectSettings.get_setting(_KEY_SHOW_ERRORS, _DEF_SHOW_ERRORS))
	if _filter_warn:
		_filter_warn.button_pressed = bool(ProjectSettings.get_setting(_KEY_SHOW_WARNINGS, _DEF_SHOW_WARNINGS))
	if _filter_info:
		_filter_info.button_pressed = bool(ProjectSettings.get_setting(_KEY_SHOW_INFO, _DEF_SHOW_INFO))
	if _auto_refresh:
		_auto_refresh.button_pressed = bool(ProjectSettings.get_setting(_KEY_AUTO_REFRESH, _DEF_AUTO_REFRESH))
	if _path_edit:
		_path_edit.text = UiReactStateFactoryService.default_output_dir()

	_suppress_pref_save = false


func _build_ui() -> void:
	# Tooltip copy: verb-first, one short sentence; scope (Selection vs scene, filtered list) where it matters.
	custom_minimum_size = Vector2(0, 200)
	clip_contents = true

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.clip_contents = true
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.clip_contents = true
	margin.add_child(vbox)

	var mode_row := HBoxContainer.new()
	vbox.add_child(mode_row)
	mode_row.add_child(Label.new())
	mode_row.get_child(0).text = "Scan:"
	_mode_option = OptionButton.new()
	_mode_option.add_item("Selection", _SCAN_SELECTION)
	_mode_option.add_item("Entire scene", _SCAN_SCENE)
	_mode_option.item_selected.connect(_on_scan_mode_selected)
	_mode_option.tooltip_text = "Choose scan scope: Selection scans selected nodes and their subtrees; Entire scene scans all UiReact* nodes in the edited scene."
	mode_row.add_child(_mode_option)

	_auto_refresh = CheckBox.new()
	_auto_refresh.text = "Auto-refresh on selection"
	_auto_refresh.button_pressed = true
	_auto_refresh.toggled.connect(_on_auto_refresh_toggled)
	_auto_refresh.tooltip_text = "When enabled in Selection mode, rescan diagnostics automatically when the editor selection changes."
	mode_row.add_child(_auto_refresh)

	var group_row := HBoxContainer.new()
	vbox.add_child(group_row)
	group_row.add_child(Label.new())
	group_row.get_child(0).text = "Group:"
	_group_option = OptionButton.new()
	_group_option.add_item("Flat list", _GROUP_FLAT)
	_group_option.add_item("By node", _GROUP_BY_NODE)
	_group_option.add_item("By severity", _GROUP_BY_SEVERITY)
	_group_option.item_selected.connect(_on_group_mode_selected)
	_group_option.tooltip_text = "Organize the issue list as a flat list, grouped by node, or grouped by severity."
	group_row.add_child(_group_option)

	var filt_row := HBoxContainer.new()
	vbox.add_child(filt_row)
	filt_row.add_child(Label.new())
	filt_row.get_child(0).text = "Show:"
	_filter_err = CheckBox.new()
	_filter_err.text = "Errors"
	_filter_err.button_pressed = true
	_filter_err.toggled.connect(_on_filter_errors_toggled)
	_filter_err.tooltip_text = "Show or hide error diagnostics."
	filt_row.add_child(_filter_err)
	_filter_warn = CheckBox.new()
	_filter_warn.text = "Warnings"
	_filter_warn.button_pressed = true
	_filter_warn.toggled.connect(_on_filter_warnings_toggled)
	_filter_warn.tooltip_text = "Show or hide warning diagnostics."
	filt_row.add_child(_filter_warn)
	_filter_info = CheckBox.new()
	_filter_info.text = "Info"
	_filter_info.button_pressed = true
	_filter_info.toggled.connect(_on_filter_info_toggled)
	_filter_info.tooltip_text = "Show or hide informational diagnostics."
	filt_row.add_child(_filter_info)

	var search_row := HBoxContainer.new()
	vbox.add_child(search_row)
	search_row.add_child(Label.new())
	search_row.get_child(0).text = "Filter:"
	_search_edit = LineEdit.new()
	_search_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search_edit.placeholder_text = "Node, path, property, message…"
	_search_edit.text_changed.connect(_on_search_text_changed)
	_search_edit.tooltip_text = "Filter issues by node name, path, property, component, message text, or fix hint."
	search_row.add_child(_search_edit)

	_search_timer = Timer.new()
	_search_timer.one_shot = true
	_search_timer.wait_time = 0.12
	_search_timer.timeout.connect(_apply_filters)
	vbox.add_child(_search_timer)

	var path_row := HBoxContainer.new()
	vbox.add_child(path_row)
	path_row.add_child(Label.new())
	path_row.get_child(0).text = "State output folder:"
	_path_edit = LineEdit.new()
	_path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_path_edit.text = UiReactStateFactoryService.default_output_dir()
	_path_edit.text_submitted.connect(func(p): _on_path_changed(p))
	_path_edit.tooltip_text = "Folder where Fix and Fix All save new .tres state files. If a filename already exists, the plugin uses _2, _3, … suffixes instead of overwriting."
	path_row.add_child(_path_edit)

	var split_main := VSplitContainer.new()
	split_main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split_main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split_main.add_theme_constant_override(&"autohide", 0)
	split_main.add_theme_constant_override(&"minimum_grab_thickness", 10)
	vbox.add_child(split_main)

	var issues_section := VBoxContainer.new()
	issues_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	issues_section.size_flags_vertical = Control.SIZE_EXPAND_FILL
	issues_section.add_theme_constant_override(&"separation", 4)
	split_main.add_child(issues_section)

	var issues_title := Label.new()
	issues_title.text = "Issues"
	issues_title.tooltip_text = "Drag the splitter below this section to resize Issues vs Report."
	issues_section.add_child(issues_title)

	var issues_panel := PanelContainer.new()
	issues_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	issues_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	issues_panel.custom_minimum_size = Vector2(0, 56)
	issues_panel.tooltip_text = "Diagnostics list; click an issue summary to open the report below."
	issues_section.add_child(issues_panel)

	var issues_panel_margin := MarginContainer.new()
	issues_panel_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	issues_panel_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	issues_panel_margin.add_theme_constant_override(&"margin_left", 6)
	issues_panel_margin.add_theme_constant_override(&"margin_right", 6)
	issues_panel_margin.add_theme_constant_override(&"margin_top", 6)
	issues_panel_margin.add_theme_constant_override(&"margin_bottom", 6)
	issues_panel.add_child(issues_panel_margin)

	_issues_scroll = ScrollContainer.new()
	_issues_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_issues_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_issues_scroll.tooltip_text = "Scroll the diagnostics list."
	issues_panel_margin.add_child(_issues_scroll)

	_issues_container = VBoxContainer.new()
	_issues_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_issues_scroll.add_child(_issues_container)

	var report_section := VBoxContainer.new()
	report_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	report_section.size_flags_vertical = Control.SIZE_EXPAND_FILL
	report_section.add_theme_constant_override(&"separation", 4)
	split_main.add_child(report_section)

	var report_title := Label.new()
	report_title.text = "Report"
	report_title.tooltip_text = "Drag the splitter above this section to resize Issues vs Report."
	report_section.add_child(report_title)

	var report_panel := PanelContainer.new()
	report_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	report_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	report_panel.custom_minimum_size = Vector2(0, 56)
	report_section.add_child(report_panel)

	var report_panel_margin := MarginContainer.new()
	report_panel_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	report_panel_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	report_panel_margin.add_theme_constant_override(&"margin_left", 6)
	report_panel_margin.add_theme_constant_override(&"margin_right", 6)
	report_panel_margin.add_theme_constant_override(&"margin_top", 6)
	report_panel_margin.add_theme_constant_override(&"margin_bottom", 6)
	report_panel.add_child(report_panel_margin)

	_details_scroll = ScrollContainer.new()
	_details_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_details_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	report_panel_margin.add_child(_details_scroll)

	_details_label = RichTextLabel.new()
	_details_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_details_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_details_label.bbcode_enabled = true
	# Fit content height so ScrollContainer owns vertical overflow (stable inside VSplitContainer).
	_details_label.fit_content = true
	_details_label.scroll_active = false
	_details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details_label.tooltip_text = "Full message, fix hint, metadata, and for binding issues with a UiState assigned a scan-time Value type / Effective value preview."
	_details_scroll.add_child(_details_label)

	# Keep initial split neutral so Issues/Report start balanced by default.
	split_main.split_offset = 0

	var btn_row := HBoxContainer.new()
	vbox.add_child(btn_row)
	_btn_refresh = Button.new()
	_btn_refresh.text = "Rescan"
	_btn_refresh.tooltip_text = "Run diagnostics now using the current Scan mode and filters. Clears Ignore hides."
	_btn_refresh.pressed.connect(func(): request_refresh(&"manual"))
	btn_row.add_child(_btn_refresh)
	_btn_copy = Button.new()
	_btn_copy.text = "Copy report"
	_btn_copy.pressed.connect(_on_copy_report)
	_btn_copy.tooltip_text = "Copy the filtered diagnostics report to the clipboard."
	btn_row.add_child(_btn_copy)
	_btn_fix_all = Button.new()
	_btn_fix_all.text = "Fix All"
	_btn_fix_all.tooltip_text = "Create and assign state resources for all eligible empty-slot issues (INFO/WARNING only). ERROR rows use per-row Fix; replacing an existing resource asks for confirmation."
	_btn_fix_all.disabled = true
	_btn_fix_all.pressed.connect(_on_fix_all)
	btn_row.add_child(_btn_fix_all)

	_replace_confirm_dialog = ConfirmationDialog.new()
	_replace_confirm_dialog.ok_button_text = "Replace"
	_replace_confirm_dialog.cancel_button_text = "Cancel"
	add_child(_replace_confirm_dialog)

	_update_details_pane(null)


func _connect_editor_signals() -> void:
	var ei := _plugin.get_editor_interface()
	ei.get_selection().selection_changed.connect(_on_selection_changed)


func _on_selection_changed() -> void:
	if _auto_refresh and _auto_refresh.button_pressed and _mode_option.get_item_id(_mode_option.selected) == _SCAN_SELECTION:
		request_refresh(&"selection_changed")


func _on_scan_mode_selected(idx: int) -> void:
	if _suppress_pref_save:
		return
	_save_ui_preference(_KEY_SCAN_MODE, _mode_option.get_item_id(idx))
	request_refresh(&"scan_mode_changed")


func _on_group_mode_selected(_idx: int) -> void:
	_rebuild_issue_list_ui()


func _on_auto_refresh_toggled(_pressed: bool) -> void:
	if _suppress_pref_save:
		return
	_save_ui_preference(_KEY_AUTO_REFRESH, _auto_refresh.button_pressed)
	request_refresh(&"auto_refresh_toggled")


func _on_filter_errors_toggled(_pressed: bool) -> void:
	if _suppress_pref_save:
		return
	_save_ui_preference(_KEY_SHOW_ERRORS, _filter_err.button_pressed)
	_apply_filters()


func _on_filter_warnings_toggled(_pressed: bool) -> void:
	if _suppress_pref_save:
		return
	_save_ui_preference(_KEY_SHOW_WARNINGS, _filter_warn.button_pressed)
	_apply_filters()


func _on_filter_info_toggled(_pressed: bool) -> void:
	if _suppress_pref_save:
		return
	_save_ui_preference(_KEY_SHOW_INFO, _filter_info.button_pressed)
	_apply_filters()


func _on_search_text_changed(_new_text: String) -> void:
	if _search_timer:
		_search_timer.start()


func _on_path_changed(new_text: String) -> void:
	var p := new_text.strip_edges()
	if p.is_empty():
		return
	if not p.ends_with("/"):
		p += "/"
	_save_ui_preference(_KEY_STATE_OUTPUT_PATH, p)


func _select_issue_at_index(idx: int) -> void:
	_selected_flat_index = idx
	var issue: Variant = _get_selected_issue()
	_update_details_pane(issue)
	_rebuild_issue_list_ui()


func _get_selected_issue() -> Variant:
	if _selected_flat_index < 0 or _selected_flat_index >= _issues_shown.size():
		return null
	return _issues_shown[_selected_flat_index]


## Prevents user/state text from breaking [RichTextLabel] BBCode (e.g. values containing "[").
func _escape_bbcode_literal(s: String) -> String:
	return s.replace("[", "[lb]")


func _update_details_pane(issue: Variant) -> void:
	if issue == null:
		_details_label.text = "[i]Click an issue summary in the Issues list to see the full message, fix, and metadata.[/i]"
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
	# Value preview: scan-time state value snippet (binding warnings only). Omit from text search (see _issue_matches_search).
	if not String(issue.value_preview).is_empty():
		if not String(issue.value_type).is_empty():
			body += "[b]Value type[/b]: %s\n" % _escape_bbcode_literal(String(issue.value_type))
		body += "[b]Effective value[/b]: %s" % _escape_bbcode_literal(String(issue.value_preview))
		if issue.value_truncated:
			body += " [i](truncated)[/i]"
		body += "\n"
	_details_label.text = body


func _severity_display_name(sev: int) -> String:
	match sev:
		UiReactDiagnosticModel.Severity.ERROR:
			return "Error"
		UiReactDiagnosticModel.Severity.WARNING:
			return "Warning"
		_:
			return "Info"


func _can_create_state_for_issue(issue: Variant) -> bool:
	if issue == null:
		return false
	if issue.property_name == &"" or issue.suggested_state_class == &"":
		return false
	if issue.node_path.is_empty():
		return false
	match issue.severity:
		UiReactDiagnosticModel.Severity.INFO, UiReactDiagnosticModel.Severity.WARNING, UiReactDiagnosticModel.Severity.ERROR:
			return true
		_:
			return false


func _can_fix_all_for_issue(issue: Variant) -> bool:
	if not _can_create_state_for_issue(issue):
		return false
	return (
		issue.severity == UiReactDiagnosticModel.Severity.INFO
		or issue.severity == UiReactDiagnosticModel.Severity.WARNING
	)


func _update_fix_all_button() -> void:
	var any := false
	for issue in _issues_shown:
		if _can_fix_all_for_issue(issue):
			any = true
			break
	_btn_fix_all.disabled = not any


func refresh() -> void:
	_issues_all.clear()
	_ignored_issue_keys.clear()
	var ei := _plugin.get_editor_interface()
	var root := ei.get_edited_scene_root()
	if root == null:
		_issues_all.append(
			UiReactDiagnosticModel.DiagnosticIssue.make_structured(
				UiReactDiagnosticModel.Severity.INFO,
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
		if _expect_startup_scene_retry:
			_expect_startup_scene_retry = false
			request_refresh(&"startup_no_scene")
		return

	_expect_startup_scene_retry = false

	var nodes: Array[Node] = []
	if _mode_option.get_item_id(_mode_option.selected) == _SCAN_SCENE:
		for n in UiReactScannerService.collect_react_nodes(root):
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
			UiReactDiagnosticModel.DiagnosticIssue.make_structured(
				UiReactDiagnosticModel.Severity.INFO,
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
		_issues_all.append_array(UiReactValidatorService.validate_nodes(nodes, root))

	_apply_filters()


func _issue_fingerprint(issue: Variant) -> String:
	return "%s|%s|%s" % [str(issue.node_path), str(issue.property_name), str(issue.issue_text)]


func _issue_matches_search(issue: Variant, q: String) -> bool:
	if q.is_empty():
		return true
	var needle := q.to_lower()
	var parts: Array[String] = []
	parts.append(String(issue.summary_text).to_lower())
	parts.append(String(issue.message).to_lower())
	parts.append(String(issue.issue_text).to_lower())
	parts.append(String(issue.fix_hint).to_lower())
	parts.append(String(issue.node_name).to_lower())
	parts.append(str(issue.node_path).to_lower())
	parts.append(str(issue.property_name).to_lower())
	parts.append(String(issue.component_name).to_lower())
	# Do not index full value_preview (noisy / huge); optional: allow filtering by short value_type label only.
	if not String(issue.value_type).is_empty():
		parts.append(String(issue.value_type).to_lower())
	var blob := " ".join(parts)
	return needle in blob


func _apply_filters() -> void:
	_issues_shown.clear()
	var q := ""
	if _search_edit:
		q = _search_edit.text.strip_edges()

	for issue in _issues_all:
		if issue.severity == UiReactDiagnosticModel.Severity.ERROR and not _filter_err.button_pressed:
			continue
		if issue.severity == UiReactDiagnosticModel.Severity.WARNING and not _filter_warn.button_pressed:
			continue
		if issue.severity == UiReactDiagnosticModel.Severity.INFO and not _filter_info.button_pressed:
			continue
		if not _issue_matches_search(issue, q):
			continue
		if _ignored_issue_keys.has(_issue_fingerprint(issue)):
			continue
		_issues_shown.append(issue)

	_selected_flat_index = -1
	if _issues_shown.is_empty():
		_update_details_pane(null)
	else:
		_selected_flat_index = 0
		_update_details_pane(_issues_shown[0])

	_update_fix_all_button()
	_rebuild_issue_list_ui()


func _severity_prefix(sev: int) -> String:
	match sev:
		UiReactDiagnosticModel.Severity.ERROR:
			return "[E]"
		UiReactDiagnosticModel.Severity.WARNING:
			return "[W]"
		_:
			return "[I]"


func _group_key_for_issue(issue: Variant) -> String:
	var mode := _GROUP_FLAT
	if _group_option:
		mode = _group_option.get_item_id(_group_option.selected)
	match mode:
		_GROUP_BY_NODE:
			if not issue.node_name.is_empty():
				return issue.node_name
			return str(issue.node_path) if not issue.node_path.is_empty() else "(scene)"
		_GROUP_BY_SEVERITY:
			match issue.severity:
				UiReactDiagnosticModel.Severity.ERROR:
					return "Errors"
				UiReactDiagnosticModel.Severity.WARNING:
					return "Warnings"
				_:
					return "Info"
		_:
			return ""


func _sort_group_keys(keys: Array[String]) -> void:
	var mode := _GROUP_FLAT
	if _group_option:
		mode = _group_option.get_item_id(_group_option.selected)
	if mode == _GROUP_BY_SEVERITY:
		# Fixed order: Errors, Warnings, Info
		var order := {"Errors": 0, "Warnings": 1, "Info": 2}
		keys.sort_custom(func(a: String, b: String) -> bool:
			var ia: int = order.get(a, 99)
			var ib: int = order.get(b, 99)
			if ia != ib:
				return ia < ib
			return a < b
		)
	else:
		keys.sort()


func _rebuild_issue_list_ui() -> void:
	for i in range(_issues_container.get_child_count() - 1, -1, -1):
		_issues_container.get_child(i).queue_free()

	var mode := _GROUP_FLAT
	if _group_option:
		mode = _group_option.get_item_id(_group_option.selected)

	if mode == _GROUP_FLAT or _issues_shown.is_empty():
		for i in range(_issues_shown.size()):
			_issues_container.add_child(_make_issue_row(_issues_shown[i], i))
		return

	# Grouped
	var buckets: Dictionary = {}
	for i in range(_issues_shown.size()):
		var issue: Variant = _issues_shown[i]
		var gk := _group_key_for_issue(issue)
		if not buckets.has(gk):
			buckets[gk] = []
		(buckets[gk] as Array).append(i)

	var keys: Array[String] = []
	for k in buckets.keys():
		keys.append(String(k))
	_sort_group_keys(keys)

	for gk in keys:
		var indices: Array = buckets[gk]
		if not _group_expanded.has(gk):
			_group_expanded[gk] = true
		var expanded: bool = bool(_group_expanded[gk])

		var header := HBoxContainer.new()
		var toggle := Button.new()
		toggle.text = ("▼ " if expanded else "▶ ") + "%s (%d)" % [gk, indices.size()]
		toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		toggle.flat = true
		toggle.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var gk_cap: String = gk
		toggle.pressed.connect(func(): _toggle_group(gk_cap))
		toggle.tooltip_text = "Expand or collapse this group."
		header.add_child(toggle)
		_issues_container.add_child(header)

		var inner := VBoxContainer.new()
		inner.visible = expanded
		inner.add_theme_constant_override("separation", 2)
		for idx in indices:
			inner.add_child(_make_issue_row(_issues_shown[idx], int(idx)))
		_issues_container.add_child(inner)


func _toggle_group(group_key: String) -> void:
	var cur: bool = bool(_group_expanded.get(group_key, true))
	_group_expanded[group_key] = not cur
	_rebuild_issue_list_ui()


func _make_issue_row(issue: Variant, flat_index: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 6)
	var summary: String = issue.summary_text if not String(issue.summary_text).is_empty() else issue.message
	var sel_btn := Button.new()
	sel_btn.text = "%s %s" % [_severity_prefix(issue.severity), summary]
	sel_btn.flat = false
	sel_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	sel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sel_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var fi := flat_index
	sel_btn.pressed.connect(func(): _select_issue_at_index(fi))
	sel_btn.tooltip_text = "Click to open this issue in the Report panel below."
	if flat_index == _selected_flat_index:
		var sel_style := StyleBoxFlat.new()
		sel_style.bg_color = Color(0.25, 0.45, 0.75, 0.28)
		sel_style.set_corner_radius_all(3)
		sel_style.set_content_margin_all(4)
		sel_btn.add_theme_stylebox_override(&"normal", sel_style)
		var sel_hover := StyleBoxFlat.new()
		sel_hover.bg_color = Color(0.3, 0.52, 0.82, 0.34)
		sel_hover.set_corner_radius_all(3)
		sel_hover.set_content_margin_all(4)
		sel_btn.add_theme_stylebox_override(&"hover", sel_hover)
		var sel_pressed := StyleBoxFlat.new()
		sel_pressed.bg_color = Color(0.22, 0.38, 0.62, 0.4)
		sel_pressed.set_corner_radius_all(3)
		sel_pressed.set_content_margin_all(4)
		sel_btn.add_theme_stylebox_override(&"pressed", sel_pressed)
	row.add_child(sel_btn)

	var btn_fix := Button.new()
	btn_fix.text = "Fix"
	btn_fix.disabled = not _can_create_state_for_issue(issue)
	btn_fix.pressed.connect(func(): _on_row_fix(fi))
	btn_fix.tooltip_text = "When eligible: create and assign a suggested Ui*State resource. Empty slot: no prompt. ERROR wrong-type rows with an existing resource: confirm before replace."
	row.add_child(btn_fix)

	var btn_focus := Button.new()
	btn_focus.text = "Focus"
	btn_focus.disabled = issue.node_path.is_empty()
	btn_focus.pressed.connect(func(): _on_row_focus(fi))
	btn_focus.tooltip_text = "Focus the scene node referenced by this issue."
	row.add_child(btn_focus)

	var btn_ignore := Button.new()
	btn_ignore.text = "Ignore"
	btn_ignore.pressed.connect(func(): _on_row_ignore(fi))
	btn_ignore.tooltip_text = "Hide this issue until the next Rescan."
	row.add_child(btn_ignore)

	return row


func _on_row_fix(flat_index: int) -> void:
	if flat_index < 0 or flat_index >= _issues_shown.size():
		return
	var issue: Variant = _issues_shown[flat_index]
	if not _can_create_state_for_issue(issue):
		return
	var node := _resolve_node_for_issue_fix(issue)
	if node == null:
		return
	if not await _maybe_confirm_replace_binding(node, issue):
		return
	if not _create_and_assign_core(issue, node):
		return
	_plugin.get_editor_interface().get_resource_filesystem().scan()
	request_refresh(&"after_row_fix")


func _on_row_focus(flat_index: int) -> void:
	if flat_index < 0 or flat_index >= _issues_shown.size():
		return
	var issue: Variant = _issues_shown[flat_index]
	if issue.node_path.is_empty():
		return
	var ei := _plugin.get_editor_interface()
	var root := ei.get_edited_scene_root()
	if root == null:
		return
	var node := root.get_node_or_null(issue.node_path)
	if node:
		ei.edit_node(node)


func _on_row_ignore(flat_index: int) -> void:
	if flat_index < 0 or flat_index >= _issues_shown.size():
		return
	var issue: Variant = _issues_shown[flat_index]
	_ignored_issue_keys[_issue_fingerprint(issue)] = true
	_apply_filters()


func _on_copy_report() -> void:
	var lines: Array[String] = []
	for issue in _issues_shown:
		var line := "%s %s" % [_severity_prefix(issue.severity), issue.message]
		if not issue.fix_hint.is_empty():
			line += " Fix: %s" % issue.fix_hint
		lines.append(line)
	DisplayServer.clipboard_set("\n".join(lines))


func _resolve_output_dir() -> String:
	var out_dir := _path_edit.text.strip_edges()
	if out_dir.is_empty():
		out_dir = UiReactStateFactoryService.default_output_dir()
	if not out_dir.ends_with("/"):
		out_dir += "/"
	return out_dir


func _resolve_node_for_issue_fix(issue: Variant) -> Node:
	if issue == null or issue.property_name == &"" or issue.suggested_state_class == &"":
		return null
	var ei := _plugin.get_editor_interface()
	var root := ei.get_edited_scene_root()
	if root == null:
		return null
	var node := root.get_node_or_null(issue.node_path)
	if node == null or not (node is Node):
		push_warning("UiReactDock: node not found for path %s" % issue.node_path)
		return null
	return node


func _maybe_confirm_replace_binding(node: Node, issue: Variant) -> bool:
	var cur: Variant = node.get(issue.property_name)
	if cur == null:
		return true
	_replace_confirm_dialog.title = "Replace binding resource"
	_replace_confirm_dialog.dialog_text = (
		"Property '%s' already has a resource assigned. Replace it with a new %s saved to the output folder? "
		% [str(issue.property_name), str(issue.suggested_state_class)]
		+ "The old reference will be unassigned from this property (the file on disk is not deleted)."
	)
	_replace_confirm_dialog.popup_centered()
	var accepted := false
	var finished := false
	var on_ok := func() -> void:
		accepted = true
		finished = true
	var on_cancel := func() -> void:
		accepted = false
		finished = true
	_replace_confirm_dialog.confirmed.connect(on_ok, CONNECT_ONE_SHOT)
	_replace_confirm_dialog.canceled.connect(on_cancel, CONNECT_ONE_SHOT)
	while not finished:
		await get_tree().process_frame
	return accepted


func _create_and_assign_core(issue: Variant, node: Node) -> bool:
	if node == null:
		return false
	var out_dir := _resolve_output_dir()
	_save_ui_preference(_KEY_STATE_OUTPUT_PATH, out_dir)
	var err := UiReactStateFactoryService.ensure_output_dir(out_dir)
	if err != OK:
		push_error("UiReactDock: could not create output folder: %s" % out_dir)
		return false

	var res := UiReactStateFactoryService.instantiate_state(issue.suggested_state_class)
	var path: String = UiReactStateFactoryService.build_unique_file_path(out_dir, str(node.name), str(issue.property_name))
	var loaded := UiReactStateFactoryService.save_and_reload(res, path)
	if loaded == null:
		return false
	_actions.assign_resource_property(node, issue.property_name, loaded)
	return true


func _create_and_assign_for_issue(issue: Variant) -> bool:
	var node := _resolve_node_for_issue_fix(issue)
	if node == null:
		return false
	return _create_and_assign_core(issue, node)


func _on_fix_all() -> void:
	var to_fix: Array = []
	for issue in _issues_shown:
		if _can_fix_all_for_issue(issue):
			to_fix.append(issue)
	if to_fix.is_empty():
		return

	var created := 0
	var failed := 0
	for issue in to_fix:
		if _create_and_assign_for_issue(issue):
			created += 1
		else:
			failed += 1

	_plugin.get_editor_interface().get_resource_filesystem().scan()
	request_refresh(&"after_fix_all")
	print("UiReactDock: Fix All — created: %d, failed: %d" % [created, failed])


func _collect_react_under(n: Node) -> Array[Node]:
	var out: Array[Node] = []
	if UiReactScannerService.is_react_node(n):
		out.append(n)
	for c in n.get_children():
		for r in _collect_react_under(c):
			out.append(r)
	return out

@tool
extends Control
class_name UiReactDock

const _WiringPanelScript := preload("res://addons/ui_react/editor_plugin/dock/ui_react_dock_wiring_panel.gd")

const TAB_DIAGNOSTICS := 0
const TAB_WIRING := 1
const _DIAG_TAB_BASE := "Diagnostics"

const _EMPTY_ISSUES_NO_DIAGNOSTICS := (
	"No issues reported for the current scan—either the scene is clean or nothing matched the scan scope."
)
const _EMPTY_ISSUES_FILTERED := (
	"No issues match the current filters or search; try clearing the search box or changing severity filters or group mode."
)

## Blocks save callbacks while applying persisted values (avoids duplicate writes / refresh loops).
var _suppress_pref_save: bool = false

## Coalesces multiple refresh requests into one deferred [method refresh] call per frame.
var _coalesced_refresh_pending: bool = false
## When true, next [method refresh] clears unused-state file cache ([code]UiReactUnusedStateService[/code]).
var _unused_cache_invalidate_pending: bool = false
## Set by [method _run_startup_refresh]; cleared after first successful root or one no-scene retry.
var _expect_startup_scene_retry: bool = false
## Coalesces [EditorUndoRedoManager] undo/redo into one deferred **Wiring** tab refresh per frame.
var _undo_redo_graph_refresh_pending: bool = false

var _plugin: EditorPlugin
var _actions: UiReactActionController
var _dock_actions: UiReactDockActions
var _issue_list: UiReactDockIssueList

var _issues_all: Array[UiReactDiagnosticModel.DiagnosticIssue] = []
var _issues_shown: Array[UiReactDiagnosticModel.DiagnosticIssue] = []

## Session-only: hidden until next [method refresh] (fingerprint keys).
var _ignored_issue_keys: Dictionary = {}
## Project-persisted: [code]res://[/code] paths of ignored unused-state file diagnostics.
var _ignored_unused_state_paths: Dictionary = {}

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
var _btn_ignore_all: Button
var _replace_confirm_dialog: ConfirmationDialog

var _tabs: TabContainer
## [UiReactDockWiringPanel] — graph + wire rules workbench (**CB-058** tab merge).
var _wiring_panel: Variant = null
## Tracks previous tab for persist-on-leave-Wiring; aligned with [member TabContainer.current_tab] after loads.
var _last_tab_for_persist: int = TAB_DIAGNOSTICS
## Last value applied to the Diagnostics tab title; avoids redundant [method TabContainer.set_tab_title] calls.
var _last_diagnostics_title_count: int = -1

## group_key -> expanded (for grouped view)
var _group_expanded: Dictionary = {}


func setup(plugin: EditorPlugin) -> void:
	_plugin = plugin
	_actions = UiReactActionController.new(plugin.get_undo_redo())
	_build_ui()
	_dock_actions = UiReactDockActions.new(self)
	_issue_list = UiReactDockIssueList.new(self)
	UiReactDockConfig.register_default_project_settings()
	UiReactDockConfig.load_into(self)
	_ignored_unused_state_paths = UiReactDockConfig.load_ignored_unused_state_paths_dict()
	_connect_editor_signals()
	call_deferred(&"_run_startup_refresh")
	call_deferred(&"_deferred_wiring_tab_activate")


func set_plugin_owner(plugin: EditorPlugin) -> void:
	_plugin = plugin


func open_and_focus_diagnostics() -> void:
	if _tabs == null:
		return
	_tabs.current_tab = TAB_DIAGNOSTICS
	_last_tab_for_persist = TAB_DIAGNOSTICS


func open_and_focus_wiring() -> void:
	if _tabs == null:
		return
	_tabs.current_tab = TAB_WIRING
	_last_tab_for_persist = TAB_WIRING
	call_deferred(&"_deferred_wiring_tab_activate")


func get_current_editor_tab() -> int:
	if _tabs == null:
		return -1
	return _tabs.current_tab


func capture_session_for_layout_persist() -> void:
	if _tabs:
		UiReactDockConfig.save_last_tab_session(_tabs.current_tab)
	if _wiring_panel != null and _wiring_panel.has_method(&"capture_session_for_persist"):
		_wiring_panel.call(&"capture_session_for_persist")


func request_refresh(_reason: StringName = &"manual") -> void:
	if _reason == &"manual":
		_unused_cache_invalidate_pending = true
	if _coalesced_refresh_pending:
		return
	_coalesced_refresh_pending = true
	call_deferred(&"_execute_pending_refresh")


func _execute_pending_refresh() -> void:
	_coalesced_refresh_pending = false
	refresh()


func _on_undo_redo_version_changed() -> void:
	if _undo_redo_graph_refresh_pending:
		return
	_undo_redo_graph_refresh_pending = true
	call_deferred(&"_flush_undo_redo_graph_refresh")


func _flush_undo_redo_graph_refresh() -> void:
	_undo_redo_graph_refresh_pending = false
	if _tabs == null or _tabs.current_tab != TAB_WIRING:
		return
	if _wiring_panel != null and _wiring_panel.has_method(&"refresh"):
		_wiring_panel.call(&"refresh")


func _run_startup_refresh() -> void:
	_expect_startup_scene_retry = true
	request_refresh(&"startup")


## Called from [EditorPlugin] when the edited scene tab changes (open/switch/empty).
func notify_edited_scene_changed() -> void:
	if _tabs != null and _tabs.current_tab == TAB_WIRING:
		call_deferred(&"_deferred_wiring_tab_activate")
	request_refresh(&"scene_changed")


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

	_tabs = TabContainer.new()
	_tabs.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.clip_contents = true
	margin.add_child(_tabs)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.clip_contents = true
	_tabs.add_child(vbox)
	_update_diagnostics_tab_title()

	var wiring = _WiringPanelScript.new()
	wiring.setup(_plugin, _actions, func(): request_refresh(&"dependency_graph_edit"))
	_wiring_panel = wiring
	_tabs.add_child(wiring)
	_tabs.set_tab_title(1, "Wiring")

	if not _tabs.tab_selected.is_connected(_on_tabs_tab_selected):
		_tabs.tab_selected.connect(_on_tabs_tab_selected)

	var mode_row := HBoxContainer.new()
	vbox.add_child(mode_row)
	mode_row.add_child(Label.new())
	mode_row.get_child(0).text = "Scan mode:"
	_mode_option = OptionButton.new()
	_mode_option.add_item("Selection", UiReactDockConfig.SCAN_MODE_SELECTION)
	_mode_option.add_item("Entire scene", UiReactDockConfig.SCAN_MODE_SCENE)
	_mode_option.item_selected.connect(_on_scan_mode_selected)
	_mode_option.tooltip_text = (
		"Scan mode selector: Selection scans selected subtrees; Entire scene scans all UiReact* nodes."
	)
	mode_row.add_child(_mode_option)

	_auto_refresh = CheckBox.new()
	_auto_refresh.text = "Auto-refresh on selection"
	_auto_refresh.button_pressed = true
	_auto_refresh.toggled.connect(_on_auto_refresh_toggled)
	_auto_refresh.tooltip_text = "In Selection mode, rescan when the editor selection changes."
	mode_row.add_child(_auto_refresh)

	var group_row := HBoxContainer.new()
	vbox.add_child(group_row)
	group_row.add_child(Label.new())
	group_row.get_child(0).text = "Group by:"
	_group_option = OptionButton.new()
	_group_option.add_item("Flat list", UiReactDockConfig.GROUP_FLAT)
	_group_option.add_item("By node", UiReactDockConfig.GROUP_BY_NODE)
	_group_option.add_item("By severity", UiReactDockConfig.GROUP_BY_SEVERITY)
	_group_option.item_selected.connect(_on_group_mode_selected)
	_group_option.tooltip_text = "Grouping selector: Flat list, by node, or by severity."
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
	_path_edit.tooltip_text = "Folder for new .tres from Fix / Fix All (adds _2, _3… if the name exists)."
	path_row.add_child(_path_edit)

	var split_main := VSplitContainer.new()
	split_main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split_main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split_main.add_theme_constant_override(&"autohide", 0)
	split_main.add_theme_constant_override(&"minimum_grab_thickness", 10)
	UiReactDockTheme.apply_split_bar(split_main, _plugin)
	split_main.tooltip_text = "Drag to resize the issue list and the report below."
	vbox.add_child(split_main)

	var issues_section := VBoxContainer.new()
	issues_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	issues_section.size_flags_vertical = Control.SIZE_EXPAND_FILL
	issues_section.add_theme_constant_override(&"separation", 4)
	split_main.add_child(issues_section)

	var issues_panel := PanelContainer.new()
	issues_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	issues_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	issues_panel.custom_minimum_size = Vector2(0, 56)
	issues_panel.tooltip_text = "Click a row to show its report below."
	issues_section.add_child(issues_panel)
	UiReactDockTheme.apply_panelcontainer(issues_panel, _plugin)

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
	issues_panel_margin.add_child(_issues_scroll)

	_issues_container = VBoxContainer.new()
	_issues_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_issues_scroll.add_child(_issues_container)

	var report_section := VBoxContainer.new()
	report_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	report_section.size_flags_vertical = Control.SIZE_EXPAND_FILL
	report_section.add_theme_constant_override(&"separation", 4)
	split_main.add_child(report_section)

	var report_panel := PanelContainer.new()
	report_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	report_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	report_panel.custom_minimum_size = Vector2(0, 56)
	report_panel.tooltip_text = "Report: full text, fix hints, and metadata for the selected issue."
	report_section.add_child(report_panel)
	UiReactDockTheme.apply_panelcontainer(report_panel, _plugin)

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
	_details_scroll.tooltip_text = "Report details for the selected issue."
	report_panel_margin.add_child(_details_scroll)

	_details_label = RichTextLabel.new()
	_details_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_details_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_details_label.bbcode_enabled = true
	# Fit content height so ScrollContainer owns vertical overflow (stable inside VSplitContainer).
	_details_label.fit_content = true
	_details_label.scroll_active = false
	_details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details_label.tooltip_text = "Full message, fix hint, metadata, and binding previews."
	_details_scroll.add_child(_details_label)
	UiReactDockTheme.apply_richtext_content(_details_label, _plugin)

	# Keep initial split neutral (issue list vs report) by default.
	split_main.split_offset = 0

	var btn_row := HBoxContainer.new()
	vbox.add_child(btn_row)
	_btn_refresh = Button.new()
	_btn_refresh.text = "Rescan"
	_btn_refresh.tooltip_text = "Rescan now. Clears temporary ignores until next run."
	_btn_refresh.pressed.connect(func(): request_refresh(&"manual"))
	btn_row.add_child(_btn_refresh)
	_btn_copy = Button.new()
	_btn_copy.text = "Copy report"
	_btn_copy.pressed.connect(_on_copy_report_pressed)
	_btn_copy.tooltip_text = "Copy the filtered diagnostics report to the clipboard."
	btn_row.add_child(_btn_copy)
	_btn_fix_all = Button.new()
	_btn_fix_all.text = "Fix All"
	_btn_fix_all.tooltip_text = "Batch empty-slot fixes for INFO/WARNING. Use row Fix for errors and replaces."
	_btn_fix_all.disabled = true
	_btn_fix_all.pressed.connect(_on_fix_all_pressed)
	btn_row.add_child(_btn_fix_all)
	_btn_ignore_all = Button.new()
	_btn_ignore_all.text = "Ignore All"
	_btn_ignore_all.tooltip_text = "Hide all visible issues until the next Rescan."
	_btn_ignore_all.disabled = true
	_btn_ignore_all.pressed.connect(_on_ignore_all_pressed)
	btn_row.add_child(_btn_ignore_all)

	_replace_confirm_dialog = ConfirmationDialog.new()
	_replace_confirm_dialog.ok_button_text = "Replace"
	_replace_confirm_dialog.cancel_button_text = "Cancel"
	add_child(_replace_confirm_dialog)

	_set_details_idle()


func _connect_editor_signals() -> void:
	var ei := _plugin.get_editor_interface()
	var selection := ei.get_selection()
	if not selection.selection_changed.is_connected(_on_selection_changed):
		selection.selection_changed.connect(_on_selection_changed)
	var ur := _plugin.get_undo_redo()
	if ur != null and not ur.version_changed.is_connected(_on_undo_redo_version_changed):
		ur.version_changed.connect(_on_undo_redo_version_changed)
	var fs := ei.get_resource_filesystem()
	if fs != null and not fs.filesystem_changed.is_connected(_on_editor_filesystem_changed):
		fs.filesystem_changed.connect(_on_editor_filesystem_changed)


func _disconnect_editor_signals() -> void:
	if _plugin == null:
		return
	var ei := _plugin.get_editor_interface()
	var selection := ei.get_selection()
	if selection.selection_changed.is_connected(_on_selection_changed):
		selection.selection_changed.disconnect(_on_selection_changed)
	var ur := _plugin.get_undo_redo()
	if ur != null and ur.version_changed.is_connected(_on_undo_redo_version_changed):
		ur.version_changed.disconnect(_on_undo_redo_version_changed)
	var fs := ei.get_resource_filesystem()
	if fs != null and fs.filesystem_changed.is_connected(_on_editor_filesystem_changed):
		fs.filesystem_changed.disconnect(_on_editor_filesystem_changed)


func _exit_tree() -> void:
	_disconnect_editor_signals()


func _on_selection_changed() -> void:
	if _wiring_panel != null and _wiring_panel.has_method(&"refresh"):
		_wiring_panel.call(&"refresh")
	if _auto_refresh and _auto_refresh.button_pressed and _mode_option.get_item_id(_mode_option.selected) == UiReactDockConfig.SCAN_MODE_SELECTION:
		request_refresh(&"selection_changed")


func _on_tabs_tab_selected(tab_idx: int) -> void:
	var prev := _last_tab_for_persist
	if not _suppress_pref_save:
		if prev == TAB_WIRING and tab_idx != TAB_WIRING:
			if _wiring_panel != null and _wiring_panel.has_method(&"capture_session_for_persist"):
				_wiring_panel.call(&"capture_session_for_persist")
		UiReactDockConfig.save_last_tab_session(tab_idx)
	_last_tab_for_persist = tab_idx
	if tab_idx == TAB_WIRING and not _suppress_pref_save:
		call_deferred(&"_deferred_wiring_tab_activate")


func _deferred_wiring_tab_activate() -> void:
	if _tabs == null or _tabs.current_tab != TAB_WIRING:
		return
	if _wiring_panel != null and _wiring_panel.has_method(&"restore_session_from_settings"):
		var restored: Variant = _wiring_panel.call(&"restore_session_from_settings")
		if restored is bool and (restored as bool):
			return
	if _wiring_panel != null and _wiring_panel.has_method(&"refresh"):
		_wiring_panel.call(&"refresh")


func _update_diagnostics_tab_title() -> void:
	if _tabs == null:
		return
	var n := _issues_shown.size()
	if n == _last_diagnostics_title_count:
		return
	_last_diagnostics_title_count = n
	_tabs.set_tab_title(TAB_DIAGNOSTICS, "%s (%d)" % [_DIAG_TAB_BASE, n])


func _on_editor_filesystem_changed() -> void:
	request_refresh(&"filesystem_changed")


func _on_scan_mode_selected(idx: int) -> void:
	if _suppress_pref_save:
		return
	UiReactDockConfig.save_ui_preference(UiReactDockConfig.KEY_SCAN_MODE, _mode_option.get_item_id(idx))
	request_refresh(&"scan_mode_changed")


func _on_group_mode_selected(idx: int) -> void:
	if _suppress_pref_save:
		return
	UiReactDockConfig.save_ui_preference(UiReactDockConfig.KEY_GROUP_MODE, _group_option.get_item_id(idx))
	_issue_list.rebuild()


func _on_auto_refresh_toggled(_pressed: bool) -> void:
	if _suppress_pref_save:
		return
	UiReactDockConfig.save_ui_preference(UiReactDockConfig.KEY_AUTO_REFRESH, _auto_refresh.button_pressed)
	request_refresh(&"auto_refresh_toggled")


func _on_filter_errors_toggled(_pressed: bool) -> void:
	if _suppress_pref_save:
		return
	UiReactDockConfig.save_ui_preference(UiReactDockConfig.KEY_SHOW_ERRORS, _filter_err.button_pressed)
	_apply_filters()


func _on_filter_warnings_toggled(_pressed: bool) -> void:
	if _suppress_pref_save:
		return
	UiReactDockConfig.save_ui_preference(UiReactDockConfig.KEY_SHOW_WARNINGS, _filter_warn.button_pressed)
	_apply_filters()


func _on_filter_info_toggled(_pressed: bool) -> void:
	if _suppress_pref_save:
		return
	UiReactDockConfig.save_ui_preference(UiReactDockConfig.KEY_SHOW_INFO, _filter_info.button_pressed)
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
	UiReactDockConfig.save_ui_preference(UiReactDockConfig.KEY_STATE_OUTPUT_PATH, p)


func _select_issue_at_index(idx: int) -> void:
	_selected_flat_index = idx
	var issue := _get_selected_issue()
	if issue == null:
		_set_details_idle()
	else:
		_update_details_pane(issue)
		if not issue.node_path.is_empty():
			_on_row_focus(idx)
	_issue_list.rebuild()


func _get_selected_issue() -> UiReactDiagnosticModel.DiagnosticIssue:
	if _selected_flat_index < 0 or _selected_flat_index >= _issues_shown.size():
		return null
	return _issues_shown[_selected_flat_index]


func _set_details_idle() -> void:
	_details_label.text = UiReactDockDetails.idle_placeholder_text()


func _update_details_pane(issue: UiReactDiagnosticModel.DiagnosticIssue) -> void:
	_details_label.text = UiReactDockDetails.build_details_bbcode(issue)


func _can_create_state_for_issue(issue: UiReactDiagnosticModel.DiagnosticIssue) -> bool:
	if issue == null:
		return false
	if issue.issue_kind == UiReactDiagnosticModel.IssueKind.UNUSED_STATE_FILE:
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


func _can_fix_all_for_issue(issue: UiReactDiagnosticModel.DiagnosticIssue) -> bool:
	if not _can_create_state_for_issue(issue):
		return false
	return (
		issue.severity == UiReactDiagnosticModel.Severity.INFO
		or issue.severity == UiReactDiagnosticModel.Severity.WARNING
	)


func _update_bottom_action_buttons() -> void:
	var any_fix := false
	for issue in _issues_shown:
		if _can_fix_all_for_issue(issue):
			any_fix = true
			break
	if _btn_fix_all:
		_btn_fix_all.disabled = not any_fix
	if _btn_ignore_all:
		_btn_ignore_all.disabled = _issues_shown.is_empty()


func refresh() -> void:
	_issues_all.clear()
	_ignored_issue_keys.clear()
	var clear_unused_cache := _unused_cache_invalidate_pending
	_unused_cache_invalidate_pending = false
	if clear_unused_cache:
		UiReactUnusedStateService.clear_load_cache()
	var ei := _plugin.get_editor_interface()
	var root := ei.get_edited_scene_root()
	if root == null:
		_issues_all.append(
			UiReactDiagnosticModel.DiagnosticIssue.make_structured(
				UiReactDiagnosticModel.Severity.INFO,
				"",
				"",
				"No edited scene is open, so Diagnostics has nothing to scan.",
				"Open a scene from the Scene or FileSystem dock (or click its tab), then click Rescan in this dock.",
				NodePath(),
				&"",
				&"",
				UiReactDiagnosticModel.IssueKind.GENERIC,
				"",
			)
		)
		_apply_filters()
		if _expect_startup_scene_retry:
			_expect_startup_scene_retry = false
			request_refresh(&"startup_no_scene")
		return

	_expect_startup_scene_retry = false

	var nodes: Array[Node] = []
	if _mode_option.get_item_id(_mode_option.selected) == UiReactDockConfig.SCAN_MODE_SCENE:
		for n in UiReactScannerService.collect_react_nodes(root):
			nodes.append(n)
	else:
		var seen: Dictionary = {}
		for sel in ei.get_selection().get_selected_nodes():
			for r in _dock_actions.collect_react_under(sel):
				if not seen.has(r):
					seen[r] = true
					nodes.append(r)

	if nodes.is_empty():
		_issues_all.append(
			UiReactDiagnosticModel.DiagnosticIssue.make_structured(
				UiReactDiagnosticModel.Severity.INFO,
				"",
				"",
				"This scan found no Ui React controls in the current scope.",
				"Switch Scan to Entire scene or widen your selection, add Ui React nodes to the scene, then click Rescan.",
				NodePath(),
				&"",
				&"",
				UiReactDiagnosticModel.IssueKind.GENERIC,
				"",
			)
		)
	else:
		_issues_all.append_array(UiReactValidatorService.validate_nodes(nodes, root))

	if root:
		_issues_all.append_array(UiReactValidatorService.validate_wiring_under_root(root))
		_issues_all.append_array(UiReactValidatorService.validate_transactional_under_root(root))
		_issues_all.append_array(UiReactValidatorService.validate_computed_under_root(root))

	_issues_all.append_array(UiReactUnusedStateService.build_issues(_dock_actions.resolve_output_dir(), root))

	_apply_filters()


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
		if (
			issue.issue_kind == UiReactDiagnosticModel.IssueKind.UNUSED_STATE_FILE
			and _ignored_unused_state_paths.has(issue.resource_path)
		):
			continue
		if not UiReactDockFilter.matches_search(issue, q):
			continue
		if _ignored_issue_keys.has(UiReactDockFilter.fingerprint(issue)):
			continue
		_issues_shown.append(issue)

	_selected_flat_index = -1
	if _issues_shown.is_empty():
		_set_details_idle()
	else:
		_selected_flat_index = 0
		_update_details_pane(_issues_shown[0])

	_update_bottom_action_buttons()
	_issue_list.rebuild()
	_update_diagnostics_tab_title()


func _on_row_fix(flat_index: int) -> void:
	await _dock_actions.on_row_fix(flat_index)


func _on_row_focus(flat_index: int) -> void:
	_dock_actions.on_row_focus(flat_index)


func _on_row_reveal(flat_index: int) -> void:
	_dock_actions.on_row_reveal(flat_index)


func _on_row_ignore(flat_index: int) -> void:
	_dock_actions.on_row_ignore(flat_index)


func _on_ignore_all_pressed() -> void:
	_dock_actions.on_ignore_all()


func _on_copy_report_pressed() -> void:
	_dock_actions.on_copy_report()


func _on_fix_all_pressed() -> void:
	_dock_actions.on_fix_all()

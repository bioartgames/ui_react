@tool
extends Control

const _SCAN_SELECTION := 0
const _SCAN_SCENE := 1

const _GROUP_FLAT := 0
const _GROUP_BY_NODE := 1
const _GROUP_BY_SEVERITY := 2

const _KEY_SCAN_MODE := "ui_system/plugin_scan_mode"
const _KEY_SHOW_ERRORS := "ui_system/plugin_show_errors"
const _KEY_SHOW_WARNINGS := "ui_system/plugin_show_warnings"
const _KEY_SHOW_INFO := "ui_system/plugin_show_info"
const _KEY_AUTO_REFRESH := "ui_system/plugin_auto_refresh"
const _KEY_STATE_OUTPUT_PATH := "ui_system/plugin_state_output_path"

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
var _actions: UiSystemActionController

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
var _btn_focus: Button
var _btn_create: Button
var _btn_create_all: Button

## group_key -> expanded (for grouped view)
var _group_expanded: Dictionary = {}


func setup(plugin: EditorPlugin) -> void:
	_plugin = plugin
	_actions = UiSystemActionController.new(plugin.get_undo_redo())
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
		push_warning("UiSystemDock: could not save project settings (%s)" % key)


func _register_default_project_settings() -> void:
	var added_defaults := false
	if not ProjectSettings.has_setting(_KEY_STATE_OUTPUT_PATH):
		ProjectSettings.set_setting(_KEY_STATE_OUTPUT_PATH, UiSystemStateFactoryService.DEFAULT_OUTPUT_DIR)
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
			push_warning("UiSystemDock: could not save default project settings")


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
		_path_edit.text = UiSystemStateFactoryService.default_output_dir()

	_suppress_pref_save = false


func _build_ui() -> void:
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
	_mode_option.item_selected.connect(_on_scan_mode_selected)
	mode_row.add_child(_mode_option)

	_auto_refresh = CheckBox.new()
	_auto_refresh.text = "Auto-refresh on selection"
	_auto_refresh.button_pressed = true
	_auto_refresh.toggled.connect(_on_auto_refresh_toggled)
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
	group_row.add_child(_group_option)

	var filt_row := HBoxContainer.new()
	vbox.add_child(filt_row)
	filt_row.add_child(Label.new())
	filt_row.get_child(0).text = "Show:"
	_filter_err = CheckBox.new()
	_filter_err.text = "Errors"
	_filter_err.button_pressed = true
	_filter_err.toggled.connect(_on_filter_errors_toggled)
	filt_row.add_child(_filter_err)
	_filter_warn = CheckBox.new()
	_filter_warn.text = "Warnings"
	_filter_warn.button_pressed = true
	_filter_warn.toggled.connect(_on_filter_warnings_toggled)
	filt_row.add_child(_filter_warn)
	_filter_info = CheckBox.new()
	_filter_info.text = "Info"
	_filter_info.button_pressed = true
	_filter_info.toggled.connect(_on_filter_info_toggled)
	filt_row.add_child(_filter_info)

	var search_row := HBoxContainer.new()
	vbox.add_child(search_row)
	search_row.add_child(Label.new())
	search_row.get_child(0).text = "Filter:"
	_search_edit = LineEdit.new()
	_search_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search_edit.placeholder_text = "Node, path, property, message…"
	_search_edit.text_changed.connect(_on_search_text_changed)
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
	_path_edit.text = UiSystemStateFactoryService.default_output_dir()
	_path_edit.text_submitted.connect(func(p): _on_path_changed(p))
	path_row.add_child(_path_edit)

	_issues_scroll = ScrollContainer.new()
	_issues_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_issues_scroll.custom_minimum_size = Vector2(0, 140)
	vbox.add_child(_issues_scroll)

	_issues_container = VBoxContainer.new()
	_issues_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_issues_scroll.add_child(_issues_container)

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
	_btn_refresh.pressed.connect(func(): request_refresh(&"manual"))
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
	_btn_create_all = Button.new()
	_btn_create_all.text = "Create all missing"
	_btn_create_all.disabled = true
	_btn_create_all.pressed.connect(_on_create_assign_all)
	btn_row.add_child(_btn_create_all)

	_update_details_pane(null)
	_update_action_buttons(null)


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
	_update_action_buttons(issue)


func _get_selected_issue() -> Variant:
	if _selected_flat_index < 0 or _selected_flat_index >= _issues_shown.size():
		return null
	return _issues_shown[_selected_flat_index]


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


func _can_create_state_for_issue(issue: Variant) -> bool:
	if issue == null:
		return false
	if issue.property_name == &"" or issue.suggested_state_class == &"":
		return false
	# Unassigned binding rows (optional INFO or required WARNING) carry a suggested class.
	return issue.severity == UiSystemDiagnosticModel.Severity.INFO or issue.severity == UiSystemDiagnosticModel.Severity.WARNING


func _update_action_buttons(issue: Variant) -> void:
	if issue == null:
		_btn_focus.disabled = true
		_btn_create.disabled = true
		return
	_btn_focus.disabled = issue.node_path.is_empty()
	_btn_create.disabled = not _can_create_state_for_issue(issue)


func _update_create_all_button() -> void:
	var any := false
	for issue in _issues_shown:
		if _can_create_state_for_issue(issue):
			any = true
			break
	_btn_create_all.disabled = not any


func refresh() -> void:
	_issues_all.clear()
	_ignored_issue_keys.clear()
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
		if _expect_startup_scene_retry:
			_expect_startup_scene_retry = false
			request_refresh(&"startup_no_scene")
		return

	_expect_startup_scene_retry = false

	var nodes: Array[Node] = []
	if _mode_option.get_item_id(_mode_option.selected) == _SCAN_SCENE:
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
	var blob := " ".join(parts)
	return needle in blob


func _apply_filters() -> void:
	_issues_shown.clear()
	var q := ""
	if _search_edit:
		q = _search_edit.text.strip_edges()

	for issue in _issues_all:
		if issue.severity == UiSystemDiagnosticModel.Severity.ERROR and not _filter_err.button_pressed:
			continue
		if issue.severity == UiSystemDiagnosticModel.Severity.WARNING and not _filter_warn.button_pressed:
			continue
		if issue.severity == UiSystemDiagnosticModel.Severity.INFO and not _filter_info.button_pressed:
			continue
		if not _issue_matches_search(issue, q):
			continue
		if _ignored_issue_keys.has(_issue_fingerprint(issue)):
			continue
		_issues_shown.append(issue)

	_selected_flat_index = -1
	if _issues_shown.is_empty():
		_update_details_pane(null)
		_update_action_buttons(null)
	else:
		_selected_flat_index = 0
		_update_details_pane(_issues_shown[0])
		_update_action_buttons(_issues_shown[0])

	_update_create_all_button()
	_rebuild_issue_list_ui()


func _severity_prefix(sev: int) -> String:
	match sev:
		UiSystemDiagnosticModel.Severity.ERROR:
			return "[E]"
		UiSystemDiagnosticModel.Severity.WARNING:
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
				UiSystemDiagnosticModel.Severity.ERROR:
					return "Errors"
				UiSystemDiagnosticModel.Severity.WARNING:
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
	var summary: String = issue.summary_text if not String(issue.summary_text).is_empty() else issue.message
	var sel_btn := Button.new()
	sel_btn.text = "%s %s" % [_severity_prefix(issue.severity), summary]
	sel_btn.flat = true
	sel_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	sel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fi := flat_index
	sel_btn.pressed.connect(func(): _select_issue_at_index(fi))
	row.add_child(sel_btn)

	var btn_fix := Button.new()
	btn_fix.text = "Fix"
	btn_fix.disabled = not _can_create_state_for_issue(issue)
	btn_fix.pressed.connect(func(): _on_row_fix(fi))
	row.add_child(btn_fix)

	var btn_focus := Button.new()
	btn_focus.text = "Focus"
	btn_focus.disabled = issue.node_path.is_empty()
	btn_focus.pressed.connect(func(): _on_row_focus(fi))
	row.add_child(btn_focus)

	var btn_ignore := Button.new()
	btn_ignore.text = "Ignore"
	btn_ignore.pressed.connect(func(): _on_row_ignore(fi))
	row.add_child(btn_ignore)

	return row


func _on_row_fix(flat_index: int) -> void:
	if flat_index < 0 or flat_index >= _issues_shown.size():
		return
	var issue: Variant = _issues_shown[flat_index]
	if not _can_create_state_for_issue(issue):
		return
	_create_and_assign_for_issue(issue)


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


func _resolve_output_dir() -> String:
	var out_dir := _path_edit.text.strip_edges()
	if out_dir.is_empty():
		out_dir = UiSystemStateFactoryService.default_output_dir()
	if not out_dir.ends_with("/"):
		out_dir += "/"
	return out_dir


func _create_and_assign_for_issue(issue: Variant) -> bool:
	if issue == null or issue.property_name == &"" or issue.suggested_state_class == &"":
		return false
	var ei := _plugin.get_editor_interface()
	var root := ei.get_edited_scene_root()
	if root == null:
		return false
	var node := root.get_node_or_null(issue.node_path)
	if node == null or not (node is Node):
		push_warning("UiSystemDock: node not found for path %s" % issue.node_path)
		return false

	var out_dir := _resolve_output_dir()
	_save_ui_preference(_KEY_STATE_OUTPUT_PATH, out_dir)
	var err := UiSystemStateFactoryService.ensure_output_dir(out_dir)
	if err != OK:
		push_error("UiSystemDock: could not create output folder: %s" % out_dir)
		return false

	var res := UiSystemStateFactoryService.instantiate_state(issue.suggested_state_class)
	var path: String = UiSystemStateFactoryService.build_unique_file_path(out_dir, str(node.name), str(issue.property_name))
	var loaded := UiSystemStateFactoryService.save_and_reload(res, path)
	if loaded == null:
		return false
	_actions.assign_resource_property(node, issue.property_name, loaded)
	return true


func _on_create_assign() -> void:
	var issue: Variant = _get_selected_issue()
	if issue == null:
		return
	if not _create_and_assign_for_issue(issue):
		return
	_plugin.get_editor_interface().get_resource_filesystem().scan()
	request_refresh(&"after_create_assign")


func _on_create_assign_all() -> void:
	var to_fix: Array = []
	for issue in _issues_shown:
		if _can_create_state_for_issue(issue):
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
	request_refresh(&"after_create_assign_all")
	print("UiSystemDock: Create all missing — created: %d, failed: %d" % [created, failed])


func _collect_react_under(n: Node) -> Array[Node]:
	var out: Array[Node] = []
	if UiSystemScannerService.is_react_node(n):
		out.append(n)
	for c in n.get_children():
		for r in _collect_react_under(c):
			out.append(r)
	return out

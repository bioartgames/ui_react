## Issue list UI: flat / grouped rows, expand/collapse, selection styling.
class_name UiReactDockIssueList
extends RefCounted

const _GROUP_KEY_UNUSED_STATE_FILES := "Unused state files"
var _scope := UiReactSubscriptionScope.new()

var _dock: UiReactDock


func _init(dock: UiReactDock) -> void:
	_dock = dock


static func severity_prefix(sev: int) -> String:
	match sev:
		UiReactDiagnosticModel.Severity.ERROR:
			return "[E]"
		UiReactDiagnosticModel.Severity.WARNING:
			return "[W]"
		_:
			return "[I]"


static func group_key_for_issue(issue: UiReactDiagnosticModel.DiagnosticIssue, mode: int) -> String:
	match mode:
		UiReactDockConfig.GROUP_BY_NODE:
			if issue.issue_kind == UiReactDiagnosticModel.IssueKind.UNUSED_STATE_FILE:
				return _GROUP_KEY_UNUSED_STATE_FILES
			if not issue.node_name.is_empty():
				return issue.node_name
			return str(issue.node_path) if not issue.node_path.is_empty() else "(scene)"
		UiReactDockConfig.GROUP_BY_SEVERITY:
			match issue.severity:
				UiReactDiagnosticModel.Severity.ERROR:
					return "Errors"
				UiReactDiagnosticModel.Severity.WARNING:
					return "Warnings"
				_:
					return "Info"
		_:
			return ""


static func sort_group_keys(keys: Array[String], mode: int) -> void:
	if mode == UiReactDockConfig.GROUP_BY_SEVERITY:
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


static func empty_state_text(
	issues_all_empty: bool, empty_no_diagnostics: String, empty_filtered: String
) -> String:
	if issues_all_empty:
		return empty_no_diagnostics
	return empty_filtered


func toggle_group(group_key: String) -> void:
	var cur: bool = bool(_dock._group_expanded.get(group_key, true))
	_dock._group_expanded[group_key] = not cur
	rebuild()


func rebuild() -> void:
	for i in range(_dock._issues_container.get_child_count() - 1, -1, -1):
		_dock._issues_container.get_child(i).queue_free()

	var mode := UiReactDockConfig.GROUP_FLAT
	if _dock._group_option:
		mode = _dock._group_option.get_item_id(_dock._group_option.selected)

	if _dock._issues_shown.is_empty():
		var empty_lbl := RichTextLabel.new()
		empty_lbl.bbcode_enabled = false
		empty_lbl.text = empty_state_text(
			_dock._issues_all.is_empty(),
			_dock._EMPTY_ISSUES_NO_DIAGNOSTICS,
			_dock._EMPTY_ISSUES_FILTERED
		)
		empty_lbl.fit_content = true
		empty_lbl.scroll_active = false
		empty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UiReactDockTheme.apply_richtext_content(empty_lbl, _dock._plugin)
		_dock._issues_container.add_child(empty_lbl)
		return

	if mode == UiReactDockConfig.GROUP_FLAT:
		for i in range(_dock._issues_shown.size()):
			_dock._issues_container.add_child(_make_issue_row(_dock._issues_shown[i], i))
		return

	var buckets: Dictionary = {}
	for i in range(_dock._issues_shown.size()):
		var issue: UiReactDiagnosticModel.DiagnosticIssue = _dock._issues_shown[i]
		var gk := group_key_for_issue(issue, mode)
		if not buckets.has(gk):
			buckets[gk] = []
		(buckets[gk] as Array).append(i)

	var keys: Array[String] = []
	for k in buckets.keys():
		keys.append(String(k))
	sort_group_keys(keys, mode)

	for gk in keys:
		var indices: Array = buckets[gk]
		if not _dock._group_expanded.has(gk):
			_dock._group_expanded[gk] = true
		var expanded: bool = bool(_dock._group_expanded[gk])

		var header := HBoxContainer.new()
		var toggle := Button.new()
		toggle.text = ("▼ " if expanded else "▶ ") + "%s (%d)" % [gk, indices.size()]
		toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		toggle.flat = true
		toggle.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var gk_cap: String = gk
		_scope.connect_signal(toggle.pressed, func(): toggle_group(gk_cap))
		toggle.tooltip_text = "Expand or collapse this group."
		header.add_child(toggle)
		_dock._issues_container.add_child(header)

		var inner := VBoxContainer.new()
		inner.visible = expanded
		inner.add_theme_constant_override("separation", 2)
		for idx in indices:
			inner.add_child(_make_issue_row(_dock._issues_shown[idx], int(idx)))
		_dock._issues_container.add_child(inner)


func _make_issue_row(issue: UiReactDiagnosticModel.DiagnosticIssue, flat_index: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 6)
	var summary: String = issue.get_summary_line()
	var sel_btn := Button.new()
	sel_btn.text = "%s %s" % [severity_prefix(issue.severity), summary]
	sel_btn.flat = false
	sel_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	sel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sel_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var fi := flat_index
	_scope.connect_signal(sel_btn.pressed, func(): _dock._select_issue_at_index(fi))
	sel_btn.tooltip_text = (
		"Show details below. If this issue references a scene node, also focus that node in the editor (Inspector)."
	)
	if flat_index == _dock._selected_flat_index:
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

	if issue.issue_kind == UiReactDiagnosticModel.IssueKind.UNUSED_STATE_FILE:
		var btn_reveal := Button.new()
		btn_reveal.text = "Reveal"
		_scope.connect_signal(btn_reveal.pressed, func(): _dock._on_row_reveal(fi))
		btn_reveal.tooltip_text = "Open this file in the FileSystem dock (unused-state scope: current scene)."
		row.add_child(btn_reveal)

		var btn_ignore_u := Button.new()
		btn_ignore_u.text = "Ignore"
		_scope.connect_signal(btn_ignore_u.pressed, func(): _dock._on_row_ignore(fi))
		btn_ignore_u.tooltip_text = "Hide this hint for the project (Project Settings)."
		row.add_child(btn_ignore_u)
	else:
		var btn_fix := Button.new()
		btn_fix.text = "Fix"
		btn_fix.disabled = not _dock._can_create_state_for_issue(issue)
		_scope.connect_signal(btn_fix.pressed, func(): _dock._on_row_fix(fi))
		btn_fix.tooltip_text = "Create or assign suggested state; may confirm when replacing on errors."
		row.add_child(btn_fix)

		var btn_ignore := Button.new()
		btn_ignore.text = "Ignore"
		_scope.connect_signal(btn_ignore.pressed, func(): _dock._on_row_ignore(fi))
		btn_ignore.tooltip_text = "Hide this issue until the next Rescan."
		row.add_child(btn_ignore)

	return row


func dispose() -> void:
	if _scope != null:
		_scope.dispose()
		_scope = null


func _exit_tree() -> void:
	dispose()

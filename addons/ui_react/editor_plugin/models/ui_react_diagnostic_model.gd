## Structured diagnostics for the Ui React editor plugin (inspector-only).
class_name UiReactDiagnosticModel
extends RefCounted

enum Severity {
	INFO,
	WARNING,
	ERROR,
}

enum IssueKind {
	## Binding / validator rows; not tied to a standalone `.tres` path row.
	GENERIC,
	## [UiState] `.tres` listed when its [code]res://[/code] appears in the **saved** edited scene file but is not assigned on any [UiReact*] export. **Not** a project-wide “globally unused” check.
	UNUSED_STATE_FILE,
}

## One actionable row in the dock list.
class DiagnosticIssue:
	extends RefCounted
	var severity: int = UiReactDiagnosticModel.Severity.INFO
	var issue_kind: UiReactDiagnosticModel.IssueKind = UiReactDiagnosticModel.IssueKind.GENERIC
	## [code]res://[/code] path for [enum IssueKind.UNUSED_STATE_FILE] rows (scene-file-scoped unused [UiState] files only).
	var resource_path: String = ""
	## Legacy full line (export / copy report). Prefer [member issue_text] + structured fields for UI.
	var message: String = ""
	## Optional explicit fix hint (details pane and copy report).
	var fix_hint: String = ""
	## Path to scene node (for focus / navigation).
	var node_path: NodePath = NodePath()
	## Property name on the node (e.g. [code]pressed_state[/code]) for quick-fix actions.
	var property_name: StringName = &""
	## Suggested typed resource class for [method UiReactStateFactoryService.create_and_save], if any.
	var suggested_state_class: StringName = &""

	## [code]UiReactButton[/code]-style class name when known.
	var component_name: String = ""
	## Scene node [member Node.name] when known.
	var node_name: String = ""
	## Problem statement only (no "Fix:" text).
	var issue_text: String = ""
	## Short single-line summary for [ItemList] rows (no fix text).
	var summary_text: String = ""
	## Truncated scan-time preview of bound state [code]get_value()[/code] (details pane only; optional).
	var value_preview: String = ""
	## Human-readable type label for [member value_preview] (e.g. [code]bool[/code], [code]String[/code]).
	var value_type: String = ""
	## True when [member value_preview] was shortened for display.
	var value_truncated: bool = false

	## Row text for [ItemList]: uses [member summary_text] when set, else [member message].
	func get_summary_line() -> String:
		if not summary_text.is_empty():
			return summary_text
		return message

	static func make_unused_state_file_issue(res_path: String, issue_text: String, fix_hint: String) -> DiagnosticIssue:
		var i := DiagnosticIssue.new()
		i.severity = UiReactDiagnosticModel.Severity.INFO
		i.issue_kind = UiReactDiagnosticModel.IssueKind.UNUSED_STATE_FILE
		i.resource_path = res_path
		i.issue_text = issue_text
		i.summary_text = issue_text
		i.message = issue_text
		i.fix_hint = fix_hint
		i.node_path = NodePath()
		i.property_name = &""
		i.suggested_state_class = &""
		i.component_name = ""
		i.node_name = ""
		return i

	## Structured constructor for validator and dock output; [param p_issue_kind] [param p_resource_path] required at call sites.
	static func make_structured(
		p_severity: int,
		p_component: String,
		p_node_name: String,
		p_issue_text: String,
		p_fix: String,
		p_node_path: NodePath,
		p_property: StringName,
		p_suggested: StringName,
		p_issue_kind: UiReactDiagnosticModel.IssueKind,
		p_resource_path: String,
	) -> DiagnosticIssue:
		var i := DiagnosticIssue.new()
		i.severity = p_severity
		i.component_name = p_component
		i.node_name = p_node_name
		i.issue_text = p_issue_text
		if p_component.is_empty():
			i.summary_text = p_issue_text
			i.message = p_issue_text
		else:
			i.summary_text = "%s / %s — %s" % [p_component, p_node_name, p_issue_text]
			i.message = "%s '%s': %s" % [p_component, p_node_name, p_issue_text]
		i.fix_hint = p_fix
		i.node_path = p_node_path
		i.property_name = p_property
		i.suggested_state_class = p_suggested
		i.issue_kind = p_issue_kind
		i.resource_path = p_resource_path
		return i


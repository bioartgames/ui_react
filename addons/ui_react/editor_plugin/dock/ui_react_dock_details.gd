## Report panel BBCode formatting (static).
class_name UiReactDockDetails
extends Object


static func escape_bbcode_literal(s: String) -> String:
	return s.replace("[", "[lb]")


static func severity_display_name(sev: int) -> String:
	match sev:
		UiReactDiagnosticModel.Severity.ERROR:
			return "Error"
		UiReactDiagnosticModel.Severity.WARNING:
			return "Warning"
		_:
			return "Info"


static func idle_placeholder_text() -> String:
	return "Pick a row in the list above to see the full message, what to try next, and Inspector fields."


static func build_details_bbcode(issue: UiReactDiagnosticModel.DiagnosticIssue) -> String:
	var sev := severity_display_name(issue.severity)
	var body := ""
	body += "[b]Severity[/b]: %s\n" % sev
	if not issue.component_name.is_empty():
		body += "[b]Component[/b]: %s\n" % issue.component_name
	if not issue.node_name.is_empty():
		body += "[b]Node[/b]: %s\n" % issue.node_name
	if not issue.node_path.is_empty():
		body += "[b]Path[/b]: %s\n" % str(issue.node_path)
	if not issue.resource_path.is_empty():
		body += "[b]Resource[/b]: %s\n" % escape_bbcode_literal(issue.resource_path)
	var itxt: String = issue.issue_text if not issue.issue_text.is_empty() else issue.message
	body += "[b]Issue[/b]: %s\n" % itxt
	if not issue.fix_hint.is_empty():
		body += "[b]Fix[/b]: %s\n" % issue.fix_hint
	if issue.property_name != &"":
		body += "[b]Inspector property[/b]: %s\n" % str(issue.property_name)
	if issue.suggested_state_class != &"":
		body += "[b]Suggested resource type[/b]: %s\n" % str(issue.suggested_state_class)
	if not String(issue.value_preview).is_empty():
		if not String(issue.value_type).is_empty():
			body += "[b]Value type[/b]: %s\n" % escape_bbcode_literal(String(issue.value_type))
		body += "[b]Effective value[/b]: %s" % escape_bbcode_literal(String(issue.value_preview))
		if issue.value_truncated:
			body += " [i](truncated)[/i]"
		body += "\n"
	return body

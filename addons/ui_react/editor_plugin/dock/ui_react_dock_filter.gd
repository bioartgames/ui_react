## Pure filter and search helpers for dock diagnostics (no UI).
class_name UiReactDockFilter
extends Object


static func visible_issues(
	all_issues: Array[UiReactDiagnosticModel.DiagnosticIssue],
	search_query: String,
	show_error: bool,
	show_warning: bool,
	show_info: bool,
	ignored_issue_keys: Dictionary,
	ignored_unused_state_paths: Dictionary,
) -> Array[UiReactDiagnosticModel.DiagnosticIssue]:
	var out: Array[UiReactDiagnosticModel.DiagnosticIssue] = []
	for issue in all_issues:
		if issue.severity == UiReactDiagnosticModel.Severity.ERROR and not show_error:
			continue
		if issue.severity == UiReactDiagnosticModel.Severity.WARNING and not show_warning:
			continue
		if issue.severity == UiReactDiagnosticModel.Severity.INFO and not show_info:
			continue
		if (
			issue.issue_kind == UiReactDiagnosticModel.IssueKind.UNUSED_STATE_FILE
			and ignored_unused_state_paths.has(issue.resource_path)
		):
			continue
		if not matches_search(issue, search_query):
			continue
		if ignored_issue_keys.has(fingerprint(issue)):
			continue
		out.append(issue)
	return out


static func fingerprint(issue: UiReactDiagnosticModel.DiagnosticIssue) -> String:
	return "%s|%s|%s|%s" % [
		str(issue.node_path),
		str(issue.property_name),
		str(issue.issue_text),
		String(issue.resource_path),
	]


static func matches_search(issue: UiReactDiagnosticModel.DiagnosticIssue, q: String) -> bool:
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
	if not String(issue.value_type).is_empty():
		parts.append(String(issue.value_type).to_lower())
	if not String(issue.resource_path).is_empty():
		parts.append(String(issue.resource_path).to_lower())
	var blob := " ".join(parts)
	return needle in blob

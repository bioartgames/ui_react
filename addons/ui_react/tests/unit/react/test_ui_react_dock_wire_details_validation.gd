extends GutTest


func test_filter_wire_rule_issues_by_index_uses_issue_text_prefix() -> void:
	var issues: Array = []
	issues.append(
		UiReactDiagnosticModel.DiagnosticIssue.make_structured(
			UiReactDiagnosticModel.Severity.WARNING,
			"UiReactItemList",
			"Host",
			"wire_rules[2]: the detail text state is missing.",
			"In the Inspector, assign Detail state to a UiStringState resource.",
			NodePath("ItemList"),
			&"wire_rules",
			&"",
			UiReactDiagnosticModel.IssueKind.GENERIC,
			"",
		)
	)
	issues.append(
		UiReactDiagnosticModel.DiagnosticIssue.make_structured(
			UiReactDiagnosticModel.Severity.WARNING,
			"UiReactItemList",
			"Host",
			"wire_rules: same UiReactWireRule instance is also on /root/A; use one rule instance per host (docs/WIRING_LAYER.md).",
			"Duplicate the subresource.",
			NodePath("ItemList"),
			&"wire_rules",
			&"",
			UiReactDiagnosticModel.IssueKind.GENERIC,
			"",
		)
	)
	var filtered := UiReactDockWireDetails.filter_wire_rule_issues_by_index(issues, 2)
	assert_eq(filtered.size(), 1)
	assert_eq(filtered[0].issue_text, "wire_rules[2]: the detail text state is missing.")


func test_format_wire_rule_diagnostic_issues_empty_returns_em_dash() -> void:
	var empty: Array = []
	assert_eq(UiReactDockWireDetails.format_wire_rule_diagnostic_issues(empty), "—")


func test_format_wire_rule_diagnostic_issues_includes_fix_hint_line() -> void:
	var issues: Array = []
	var i := UiReactDiagnosticModel.DiagnosticIssue.make_structured(
		UiReactDiagnosticModel.Severity.WARNING,
		"X",
		"Y",
		"wire_rules[0]: the pulse bool state is missing.",
		"In the Inspector, assign Pulse bool to a UiBoolState resource.",
		NodePath("."),
		&"wire_rules",
		&"",
		UiReactDiagnosticModel.IssueKind.GENERIC,
		"",
	)
	issues.append(i)
	var s := UiReactDockWireDetails.format_wire_rule_diagnostic_issues(issues)
	assert_true(s.contains("wire_rules[0]:"))
	assert_true(s.contains("Fix: In the Inspector, assign Pulse bool to a UiBoolState resource."))


func test_null_wire_rules_slot_validation_row_matches_validator() -> void:
	var root := Control.new()
	var host := UiReactItemList.new()
	add_child_autofree(root)
	root.add_child(host)
	host.name = "ItemList"
	host.wire_rules = [null]
	var plain := UiReactDockWireDetails.build_details_plain_text(null, 0, host, root)
	assert_true(plain.contains("wire_rules[0]"))
	assert_true(plain.contains("null") or plain.contains("empty") or plain.contains("empty slot"))


func test_copy_detail_missing_detail_state_in_validation_row() -> void:
	var root := Control.new()
	var host := UiReactItemList.new()
	add_child_autofree(root)
	root.add_child(host)
	host.name = "ItemList"
	var rule := UiReactWireCopySelectionDetail.new()
	rule.selected_state = UiIntState.new(0)
	rule.detail_state = null
	host.wire_rules = [rule]
	var plain := UiReactDockWireDetails.build_details_plain_text(rule, 0, host, root)
	assert_true(plain.contains("wire_rules[0]:"))
	assert_true(plain.contains("the detail text state is missing"))


func test_disabled_rule_emits_validator_copy_in_details() -> void:
	var root := Control.new()
	var host := UiReactItemList.new()
	add_child_autofree(root)
	root.add_child(host)
	host.name = "ItemList"
	var rule := UiReactWireCopySelectionDetail.new()
	rule.enabled = false
	rule.detail_state = UiStringState.new("")
	rule.selected_state = UiIntState.new(0)
	host.wire_rules = [rule]
	var plain := UiReactDockWireDetails.build_details_plain_text(rule, 0, host, root)
	assert_true(plain.contains("turned off") or plain.contains("disabled"))
	assert_true(plain.contains("wire_rules[0]:"))


func test_refresh_rule_warns_on_non_res_icon_path() -> void:
	var root := Control.new()
	var host := UiReactItemList.new()
	add_child_autofree(root)
	root.add_child(host)
	host.name = "ItemList"
	var rule := UiReactWireRefreshItemsFromCatalog.new()
	rule.items_state = UiArrayState.new([])
	rule.catalog = UiReactWireCatalogData.new()
	rule.first_row_icon_path = "user://icon.png"
	host.wire_rules = [rule]
	var issues := UiReactWiringValidator.validate_wire_rules("UiReactItemList", host, NodePath("ItemList"))
	var found := false
	for it in issues:
		if String(it.issue_text).contains("First row icon path"):
			found = true
			break
	assert_true(found)


func test_sync_bool_debug_line_warns_when_line_prefix_too_long() -> void:
	var root := Control.new()
	var host := UiReactItemList.new()
	add_child_autofree(root)
	root.add_child(host)
	host.name = "ItemList"
	var rule := UiReactWireSyncBoolStateDebugLine.new()
	rule.bool_state = UiBoolState.new(false)
	rule.target_string_state = UiStringState.new("")
	var long_prefix := ""
	for i: int in range(2100):
		long_prefix += "x"
	rule.line_prefix = long_prefix
	host.wire_rules = [rule]
	var issues := UiReactWiringValidator.validate_wire_rules("UiReactItemList", host, NodePath("ItemList"))
	var found := false
	for it in issues:
		if String(it.issue_text).contains("line_prefix is longer than the quick-edit limit"):
			found = true
			break
	assert_true(found)

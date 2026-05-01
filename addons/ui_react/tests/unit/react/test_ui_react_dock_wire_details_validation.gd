extends GutTest


func test_wire_details_plain_text_omits_checks_row() -> void:
	var root := Control.new()
	var host := UiReactItemList.new()
	add_child_autofree(root)
	root.add_child(host)
	host.name = "ItemList"
	var rule := UiReactWireCopySelectionDetail.new()
	rule.enabled = true
	rule.detail_state = UiStringState.new("")
	rule.selected_state = UiIntState.new(0)
	host.wire_rules = [rule]
	var plain := UiReactDockWireDetails.build_details_plain_text(rule, 0, host, root)
	assert_false(plain.contains("Checks:"))


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


func test_duplicate_wire_outputs_warns_when_two_rules_write_same_state() -> void:
	var root := Control.new()
	var host := UiReactItemList.new()
	add_child_autofree(root)
	root.add_child(host)
	host.name = "ItemList"
	var shared_out := UiStringState.new("")
	var r0 := UiReactWireMapIntToString.new()
	r0.enabled = true
	r0.source_int_state = UiIntState.new(0)
	r0.target_string_state = shared_out
	var r1 := UiReactWireMapIntToString.new()
	r1.enabled = true
	r1.source_int_state = UiIntState.new(1)
	r1.target_string_state = shared_out
	host.wire_rules = [r0, r1]
	var issues := UiReactWiringValidator.validate_wire_rules("UiReactItemList", host, NodePath("ItemList"))
	var found_dup := false
	for it in issues:
		if String(it.issue_text).contains("both write the same UiState output"):
			found_dup = true
			break
	assert_true(found_dup)

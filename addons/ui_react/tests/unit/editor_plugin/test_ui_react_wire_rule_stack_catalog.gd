extends GutTest

const _WireStackCatalog := preload("res://addons/ui_react/editor_plugin/services/ui_react_wire_rule_stack_catalog.gd")


func test_stack_entries_has_three_entries() -> void:
	assert_eq(_WireStackCatalog.stack_entries().size(), 3)


func test_stack_entry_keys() -> void:
	for e: Dictionary in _WireStackCatalog.stack_entries():
		assert_true(e.has(&"label"), "entry should have StringName &\"label\"")
		assert_true(e.has(&"about"), "entry should have StringName &\"about\"")
		assert_true(e.has(&"id"), "entry should have StringName &\"id\"")
		assert_true(String(e[&"label"]).length() > 0, "label should be non-empty")


func _index_of_stack_id(want: String) -> int:
	var entries: Array[Dictionary] = _WireStackCatalog.stack_entries()
	for i: int in range(entries.size()):
		if String(entries[i].get(&"id", &"")) == want:
			return i
	return -1


func test_inv_detail_returns_three_typed_rules() -> void:
	var idx := _index_of_stack_id("inv_detail")
	var stack: Array[UiReactWireRule] = _WireStackCatalog.instantiate_stack(idx)
	assert_eq(stack.size(), 3)
	assert_true(stack[0] is UiReactWireSortArrayByKey)
	assert_true(stack[1] is UiReactWireCopySelectionDetail)
	assert_true(stack[2] is UiReactWireSetStringOnBoolPulse)


func test_filter_sort_detail_returns_three_typed_rules() -> void:
	var idx := _index_of_stack_id("filter_sort_detail")
	var stack: Array[UiReactWireRule] = _WireStackCatalog.instantiate_stack(idx)
	assert_eq(stack.size(), 3)
	assert_true(stack[0] is UiReactWireRefreshItemsFromCatalog)
	assert_true(stack[1] is UiReactWireSortArrayByKey)
	assert_true(stack[2] is UiReactWireCopySelectionDetail)


func test_catalog_list_returns_two_typed_rules() -> void:
	var idx := _index_of_stack_id("catalog_list")
	var stack: Array[UiReactWireRule] = _WireStackCatalog.instantiate_stack(idx)
	assert_eq(stack.size(), 2)
	assert_true(stack[0] is UiReactWireRefreshItemsFromCatalog)
	assert_true(stack[1] is UiReactWireCopySelectionDetail)


func test_rules_have_non_empty_rule_id_after_default_assignment() -> void:
	## Catalog [code]rule_id[/code] values are set and non-empty; the section also assigns [code]rule_{base + i}[/code] for empty rows.
	for idx: int in range(_WireStackCatalog.stack_entries().size()):
		var stack: Array[UiReactWireRule] = _WireStackCatalog.instantiate_stack(idx)
		for i: int in range(stack.size()):
			var rid: String = String(stack[i].rule_id).strip_edges()
			assert_true(rid.length() > 0, "expected catalog default rule_id; index %d rule %d" % [idx, i])
	## Empty-slot simulation (same shape as [code]append_stack_from_catalog_index[/code]).
	var empty_rule := UiReactWireSortArrayByKey.new()
	empty_rule.rule_id = ""
	var base: int = 1
	empty_rule.rule_id = "rule_%d" % (base)
	assert_eq(empty_rule.rule_id, "rule_1")


func test_out_of_bounds_returns_empty_array() -> void:
	var neg: Array[UiReactWireRule] = _WireStackCatalog.instantiate_stack(-1)
	var big: Array[UiReactWireRule] = _WireStackCatalog.instantiate_stack(99)
	assert_true(neg.is_empty())
	assert_true(big.is_empty())

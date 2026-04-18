extends GutTest

const NO_PICK := "No pick."


# --- selection_detail_base ---


func test_selection_detail_base_negative_index_returns_no_selection() -> void:
	var items: Array = [{"name": "a", "kind": "b"}]
	assert_eq(UiReactWireTemplate.selection_detail_base(-1, items, NO_PICK), NO_PICK)


func test_selection_detail_base_index_equal_size_returns_no_selection() -> void:
	var items: Array = [{"name": "only"}]
	assert_eq(UiReactWireTemplate.selection_detail_base(1, items, NO_PICK), NO_PICK)


func test_selection_detail_base_empty_items_returns_no_selection() -> void:
	assert_eq(UiReactWireTemplate.selection_detail_base(0, [], NO_PICK), NO_PICK)


func test_selection_detail_base_dict_with_name_formats_three_part() -> void:
	var items: Array = [{"name": "Sword", "kind": "weapon", "qty": 2}]
	var r := UiReactWireTemplate.selection_detail_base(0, items, "x")
	assert_true(r.begins_with("Selected: "))
	assert_true(r.contains("Sword"))
	assert_true(r.contains("weapon"))
	assert_true(r.contains("(qty 2)"))


func test_selection_detail_base_dict_with_kind_only_still_uses_three_part() -> void:
	var items: Array = [{"kind": "armor"}]
	var r := UiReactWireTemplate.selection_detail_base(0, items, "x")
	assert_true(r.begins_with("Selected: "))
	assert_true(r.contains("armor"))
	assert_true(r.contains("(qty 1)"))


func test_selection_detail_base_dict_with_name_only() -> void:
	var items: Array = [{"name": "Only"}]
	var r := UiReactWireTemplate.selection_detail_base(0, items, "x")
	assert_true(r.begins_with("Selected: "))
	assert_true(r.contains("Only"))
	assert_true(r.contains("(qty 1)"))


func test_selection_detail_base_dict_without_name_or_kind_uses_label() -> void:
	var items: Array = [{"label": "Row A"}]
	var r := UiReactWireTemplate.selection_detail_base(0, items, "x")
	assert_true(r.begins_with("Selected: "))
	assert_true(r.contains("Row A"))


func test_selection_detail_base_dict_without_name_or_kind_prefers_text_over_str_entry() -> void:
	var items: Array = [{"text": "Row B"}]
	var r := UiReactWireTemplate.selection_detail_base(0, items, "x")
	assert_true(r.begins_with("Selected: "))
	assert_true(r.contains("Row B"))


func test_selection_detail_base_dict_label_over_text() -> void:
	var items: Array = [{"label": "L", "text": "T"}]
	var r := UiReactWireTemplate.selection_detail_base(0, items, "x")
	assert_true(r.begins_with("Selected: "))
	assert_true(r.contains("L"))
	assert_false(r.contains("T"))


func test_selection_detail_base_non_dict_entry() -> void:
	var items: Array = ["hello"]
	var r := UiReactWireTemplate.selection_detail_base(0, items, "x")
	assert_true(r.begins_with("Selected: "))
	assert_true(r.contains("hello"))


func test_selection_detail_base_non_dict_number() -> void:
	var items: Array = [42]
	var r := UiReactWireTemplate.selection_detail_base(0, items, "x")
	assert_true(r.begins_with("Selected: "))
	assert_true(r.contains("42"))


func test_selection_detail_base_empty_dict_without_keys_matches_inner_expression() -> void:
	var d: Dictionary = {}
	var r := UiReactWireTemplate.selection_detail_base(0, [d], "x")
	assert_true(r.begins_with("Selected: "))
	assert_eq(r, "Selected: %s" % str(d))


# --- substitute_row_placeholders ---


func test_substitute_all_placeholders() -> void:
	var row := {"name": "a", "kind": "b", "qty": 3}
	assert_eq(
		UiReactWireTemplate.substitute_row_placeholders("{name}|{kind}|{qty}", row),
		"a|b|3"
	)


func test_substitute_empty_row_uses_defaults() -> void:
	assert_eq(UiReactWireTemplate.substitute_row_placeholders("{name}{kind}{qty}", {}), "1")


func test_substitute_qty_default_int() -> void:
	assert_eq(UiReactWireTemplate.substitute_row_placeholders("{qty}", {}), "1")


func test_substitute_replaces_multiple_same_placeholder() -> void:
	assert_eq(
		UiReactWireTemplate.substitute_row_placeholders("{name}-{name}", {"name": "x"}),
		"x-x"
	)


func test_substitute_empty_template() -> void:
	assert_eq(UiReactWireTemplate.substitute_row_placeholders("", {"name": "a"}), "")


# --- selected_row_dict ---


func test_selected_row_dict_negative_index() -> void:
	var items: Array = [{"a": 1}]
	assert_eq(UiReactWireTemplate.selected_row_dict(-1, items), {})


func test_selected_row_dict_index_too_large() -> void:
	var items: Array = [{}]
	assert_eq(UiReactWireTemplate.selected_row_dict(5, items), {})


func test_selected_row_dict_empty_items() -> void:
	assert_eq(UiReactWireTemplate.selected_row_dict(0, []), {})


func test_selected_row_dict_returns_dictionary_entry() -> void:
	var items: Array = [{"k": 1}]
	var result := UiReactWireTemplate.selected_row_dict(0, items)
	assert_eq(result.get("k", null), 1)


func test_selected_row_dict_non_dict_returns_empty() -> void:
	var items: Array = ["x"]
	assert_eq(UiReactWireTemplate.selected_row_dict(0, items), {})


# --- row_display_name ---


func test_row_display_name_strips_whitespace() -> void:
	assert_eq(UiReactWireTemplate.row_display_name({"name": "  axe  "}), "axe")


func test_row_display_name_missing_name() -> void:
	assert_eq(UiReactWireTemplate.row_display_name({}), "")


func test_row_display_name_empty_string() -> void:
	assert_eq(UiReactWireTemplate.row_display_name({"name": ""}), "")

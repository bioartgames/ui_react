extends GutTest


func _apply(rule: UiReactWireRule) -> void:
	rule.apply(null)


func _row(name: String, kind: String, qty: Variant) -> Dictionary:
	return {"name": name, "kind": kind, "qty": qty}


func _catalog_with_rows(rows: Array) -> UiReactWireCatalogData:
	var c := UiReactWireCatalogData.new()
	c.rows.clear()
	for item in rows:
		c.rows.append(item as Dictionary)
	return c


# --- UiReactWireMapIntToString ---


func test_map_int_disabled_noop() -> void:
	var rule := UiReactWireMapIntToString.new()
	rule.enabled = false
	var src := UiIntState.new(1)
	var tgt := UiStringState.new("before")
	rule.source_int_state = src
	rule.target_string_state = tgt
	rule.index_to_string = {1: "weapon"}
	_apply(rule)
	assert_eq(tgt.get_string_value(), "before")


func test_map_int_missing_source_noop() -> void:
	var rule := UiReactWireMapIntToString.new()
	var tgt := UiStringState.new("x")
	rule.source_int_state = null
	rule.target_string_state = tgt
	rule.index_to_string = {0: "a"}
	_apply(rule)
	assert_eq(tgt.get_string_value(), "x")


func test_map_int_missing_target_noop() -> void:
	var rule := UiReactWireMapIntToString.new()
	var src := UiIntState.new(1)
	rule.source_int_state = src
	rule.target_string_state = null
	rule.index_to_string = {1: "weapon"}
	_apply(rule)
	assert_eq(src.get_int_value(), 1)


func test_map_int_matches_int_key() -> void:
	var rule := UiReactWireMapIntToString.new()
	var src := UiIntState.new(1)
	var tgt := UiStringState.new()
	rule.source_int_state = src
	rule.target_string_state = tgt
	rule.index_to_string = {1: "weapon"}
	_apply(rule)
	assert_eq(tgt.get_string_value(), "weapon")


func test_map_int_matches_stringified_key() -> void:
	var rule := UiReactWireMapIntToString.new()
	var src := UiIntState.new(2)
	var tgt := UiStringState.new()
	rule.source_int_state = src
	rule.target_string_state = tgt
	rule.index_to_string = {"2": "consumable"}
	_apply(rule)
	assert_eq(tgt.get_string_value(), "consumable")


func test_map_int_unmatched_index_empty() -> void:
	var rule := UiReactWireMapIntToString.new()
	var src := UiIntState.new(5)
	var tgt := UiStringState.new("x")
	rule.source_int_state = src
	rule.target_string_state = tgt
	rule.index_to_string = {0: "a"}
	_apply(rule)
	assert_eq(tgt.get_string_value(), "")


func test_map_int_hint_skipped_when_null() -> void:
	var rule := UiReactWireMapIntToString.new()
	var src := UiIntState.new(1)
	var tgt := UiStringState.new()
	rule.source_int_state = src
	rule.target_string_state = tgt
	rule.hint_state = null
	rule.index_to_string = {1: "weapon"}
	_apply(rule)
	assert_eq(tgt.get_string_value(), "weapon")


func test_map_int_hint_sets_category_line() -> void:
	var rule := UiReactWireMapIntToString.new()
	var src := UiIntState.new(1)
	var tgt := UiStringState.new()
	var hint := UiStringState.new()
	rule.source_int_state = src
	rule.target_string_state = tgt
	rule.hint_state = hint
	rule.index_to_string = {1: "weapon"}
	rule.hint_labels_by_index = {1: "Weapons"}
	_apply(rule)
	assert_eq(hint.get_string_value(), "Category: Weapons (tree index 1).")


func test_map_int_hint_default_label() -> void:
	var rule := UiReactWireMapIntToString.new()
	var src := UiIntState.new(3)
	var tgt := UiStringState.new()
	var hint := UiStringState.new()
	rule.source_int_state = src
	rule.target_string_state = tgt
	rule.hint_state = hint
	rule.index_to_string = {3: "x"}
	rule.hint_labels_by_index = {}
	_apply(rule)
	assert_eq(hint.get_string_value(), "Category: (pick a row) (tree index 3).")


# --- UiReactWireRefreshItemsFromCatalog ---


func test_refresh_disabled_noop() -> void:
	var rule := UiReactWireRefreshItemsFromCatalog.new()
	rule.enabled = false
	var items := UiArrayState.new([{"label": "old"}])
	var cat := _catalog_with_rows([_row("A", "weapon", 1)])
	rule.items_state = items
	rule.catalog = cat
	_apply(rule)
	assert_eq(items.get_array_value().size(), 1)
	assert_eq(items.get_array_value()[0].get("label", ""), "old")


func test_refresh_missing_items_noop() -> void:
	var rule := UiReactWireRefreshItemsFromCatalog.new()
	var cat := _catalog_with_rows([_row("A", "weapon", 1)])
	rule.items_state = null
	rule.catalog = cat
	_apply(rule)
	assert_eq(cat.rows.size(), 1)


func test_refresh_missing_catalog_noop() -> void:
	var rule := UiReactWireRefreshItemsFromCatalog.new()
	var items := UiArrayState.new()
	rule.items_state = items
	rule.catalog = null
	_apply(rule)
	assert_eq(items.get_array_value().size(), 0)


func test_refresh_builds_lines_no_filters() -> void:
	var rule := UiReactWireRefreshItemsFromCatalog.new()
	var items := UiArrayState.new()
	var cat := _catalog_with_rows([_row("Alpha", "weapon", 1), _row("Beta", "food", 2)])
	rule.items_state = items
	rule.catalog = cat
	rule.filter_text_state = null
	rule.category_kind_state = null
	_apply(rule)
	var lines: Array = items.get_array_value()
	assert_eq(lines.size(), 2)
	var label0: String = str(lines[0].get("label", ""))
	assert_eq(label0, "Alpha (weapon) × 1")


func test_refresh_kind_filter_excludes() -> void:
	var rule := UiReactWireRefreshItemsFromCatalog.new()
	var items := UiArrayState.new()
	var cat := _catalog_with_rows([_row("Sword", "weapon", 1), _row("Bread", "food", 2)])
	var kind_st := UiStringState.new("weapon")
	rule.items_state = items
	rule.catalog = cat
	rule.category_kind_state = kind_st
	_apply(rule)
	var lines: Array = items.get_array_value()
	assert_eq(lines.size(), 1)
	assert_eq(str(lines[0].get("kind", "")), "weapon")


func test_refresh_needle_filters_name() -> void:
	var rule := UiReactWireRefreshItemsFromCatalog.new()
	var items := UiArrayState.new()
	var cat := _catalog_with_rows([
		_row("FooBar", "junk", 1),
		_row("Other", "junk", 1),
	])
	var needle := UiStringState.new("foo")
	rule.items_state = items
	rule.catalog = cat
	rule.filter_text_state = needle
	_apply(rule)
	var lines: Array = items.get_array_value()
	assert_eq(lines.size(), 1)
	assert_eq(str(lines[0].get("name", "")), "FooBar")


func test_refresh_needle_filters_kind_substring() -> void:
	var rule := UiReactWireRefreshItemsFromCatalog.new()
	var items := UiArrayState.new()
	var cat := _catalog_with_rows([
		_row("Zed", "alpha", 1),
		_row("Q", "elixir", 2),
	])
	var needle := UiStringState.new("eli")
	rule.items_state = items
	rule.catalog = cat
	rule.filter_text_state = needle
	_apply(rule)
	var lines: Array = items.get_array_value()
	assert_eq(lines.size(), 1)
	assert_eq(str(lines[0].get("kind", "")), "elixir")


func test_refresh_selected_clamped_to_minus_one_when_oob() -> void:
	var rule := UiReactWireRefreshItemsFromCatalog.new()
	var items := UiArrayState.new()
	var sel := UiIntState.new(5)
	var cat := _catalog_with_rows([_row("Only", "weapon", 1)])
	rule.items_state = items
	rule.catalog = cat
	rule.selected_state = sel
	_apply(rule)
	assert_eq(sel.get_int_value(), -1)


func test_refresh_first_row_gets_icon_when_path_set() -> void:
	var rule := UiReactWireRefreshItemsFromCatalog.new()
	var items := UiArrayState.new()
	var cat := _catalog_with_rows([_row("A", "weapon", 1)])
	rule.items_state = items
	rule.catalog = cat
	rule.first_row_icon_path = "res://icon.png"
	_apply(rule)
	var lines: Array = items.get_array_value()
	assert_eq(lines[0].get("icon", ""), "res://icon.png")


func test_refresh_no_icon_when_path_empty() -> void:
	var rule := UiReactWireRefreshItemsFromCatalog.new()
	var items := UiArrayState.new()
	var cat := _catalog_with_rows([_row("A", "weapon", 1)])
	rule.items_state = items
	rule.catalog = cat
	rule.first_row_icon_path = ""
	_apply(rule)
	var d: Dictionary = items.get_array_value()[0]
	assert_false(d.has("icon"))


func test_refresh_selected_null_skips_clamp() -> void:
	var rule := UiReactWireRefreshItemsFromCatalog.new()
	var items := UiArrayState.new()
	var cat := _catalog_with_rows([_row("A", "weapon", 1), _row("B", "food", 2)])
	rule.items_state = items
	rule.catalog = cat
	rule.selected_state = null
	_apply(rule)
	assert_eq(items.get_array_value().size(), 2)


# --- UiReactWireCopySelectionDetail ---


func test_copy_detail_disabled_noop() -> void:
	var rule := UiReactWireCopySelectionDetail.new()
	rule.enabled = false
	var detail := UiStringState.new("keep")
	var sel := UiIntState.new(0)
	var items := UiArrayState.new([{"name": "X", "kind": "y", "qty": 1}])
	rule.detail_state = detail
	rule.selected_state = sel
	rule.items_state = items
	_apply(rule)
	assert_eq(detail.get_string_value(), "keep")


func test_copy_detail_missing_detail_noop() -> void:
	var rule := UiReactWireCopySelectionDetail.new()
	rule.detail_state = null
	var sel := UiIntState.new(0)
	rule.selected_state = sel
	_apply(rule)
	assert_eq(sel.get_int_value(), 0)


func test_copy_detail_missing_selected_noop() -> void:
	var rule := UiReactWireCopySelectionDetail.new()
	var detail := UiStringState.new()
	rule.detail_state = detail
	rule.selected_state = null
	_apply(rule)
	assert_eq(detail.get_string_value(), "")


func test_copy_detail_null_items_uses_empty_list() -> void:
	var rule := UiReactWireCopySelectionDetail.new()
	var detail := UiStringState.new()
	var sel := UiIntState.new(0)
	rule.detail_state = detail
	rule.selected_state = sel
	rule.items_state = null
	rule.text_no_selection = "No."
	_apply(rule)
	assert_eq(
		detail.get_string_value(),
		UiReactWireTemplate.selection_detail_base(0, [], "No.")
	)


func test_copy_detail_with_suffix_second_line() -> void:
	var rule := UiReactWireCopySelectionDetail.new()
	var detail := UiStringState.new()
	var sel := UiIntState.new(0)
	var items := UiArrayState.new([{"name": "N", "kind": "k", "qty": 1}])
	var note := UiStringState.new("Note")
	rule.detail_state = detail
	rule.selected_state = sel
	rule.items_state = items
	rule.suffix_note_state = note
	_apply(rule)
	var base := UiReactWireTemplate.selection_detail_base(0, items.get_array_value(), "No selection.")
	assert_eq(detail.get_string_value(), "%s\n%s" % [base, "Note"])


func test_copy_detail_matches_template_for_selection() -> void:
	var rule := UiReactWireCopySelectionDetail.new()
	var detail := UiStringState.new()
	var sel := UiIntState.new(0)
	var arr: Array = [{"name": "Sword", "kind": "weapon", "qty": 2}]
	var items := UiArrayState.new(arr)
	rule.detail_state = detail
	rule.selected_state = sel
	rule.items_state = items
	rule.text_no_selection = "x"
	_apply(rule)
	assert_eq(
		detail.get_string_value(),
		UiReactWireTemplate.selection_detail_base(0, arr, "x")
	)


# --- UiReactWireSetStringOnBoolPulse ---


func test_pulse_disabled_noop() -> void:
	var rule := UiReactWireSetStringOnBoolPulse.new()
	rule.enabled = false
	var tgt := UiStringState.new("before")
	var pulse := UiBoolState.new(false)
	rule.target_string_state = tgt
	rule.pulse_bool = pulse
	rule.template_rising = "{name}"
	rule.require_rising_edge = true
	rule.apply_from_pulse(null, true, false)
	assert_eq(tgt.get_string_value(), "before")


func test_pulse_missing_target_noop() -> void:
	var rule := UiReactWireSetStringOnBoolPulse.new()
	rule.target_string_state = null
	var pulse := UiBoolState.new(false)
	rule.pulse_bool = pulse
	rule.apply_from_pulse(null, true, false)
	assert_eq(pulse.get_bool_value(), false)


func test_pulse_missing_pulse_noop() -> void:
	var rule := UiReactWireSetStringOnBoolPulse.new()
	var tgt := UiStringState.new()
	rule.target_string_state = tgt
	rule.pulse_bool = null
	rule.apply_from_pulse(null, true, false)
	assert_eq(tgt.get_string_value(), "")


func test_pulse_rising_edge_false_to_true_writes_template() -> void:
	var rule := UiReactWireSetStringOnBoolPulse.new()
	var tgt := UiStringState.new()
	var sel := UiIntState.new(0)
	var items := UiArrayState.new([{"name": "a", "kind": "b", "qty": 3}])
	rule.target_string_state = tgt
	rule.pulse_bool = UiBoolState.new(false)
	rule.selected_state = sel
	rule.items_state = items
	rule.template_rising = "{name}|{kind}|{qty}"
	rule.require_rising_edge = true
	rule.apply_from_pulse(null, true, false)
	assert_eq(tgt.get_string_value(), "a|b|3")


func test_pulse_rising_edge_noop_when_not_rising() -> void:
	var rule := UiReactWireSetStringOnBoolPulse.new()
	var tgt := UiStringState.new("unchanged")
	var sel := UiIntState.new(0)
	var items := UiArrayState.new([{"name": "a", "kind": "b", "qty": 1}])
	rule.target_string_state = tgt
	rule.pulse_bool = UiBoolState.new(true)
	rule.selected_state = sel
	rule.items_state = items
	rule.template_rising = "{name}"
	rule.require_rising_edge = true
	rule.apply_from_pulse(null, true, true)
	assert_eq(tgt.get_string_value(), "unchanged")


func test_pulse_non_rising_mode_requires_new_true() -> void:
	var rule := UiReactWireSetStringOnBoolPulse.new()
	var tgt := UiStringState.new("keep")
	rule.target_string_state = tgt
	rule.pulse_bool = UiBoolState.new(false)
	rule.require_rising_edge = false
	rule.template_rising = "{name}"
	rule.apply_from_pulse(null, false, false)
	assert_eq(tgt.get_string_value(), "keep")


func test_pulse_non_rising_mode_new_true_without_old_constraint() -> void:
	var rule := UiReactWireSetStringOnBoolPulse.new()
	var tgt := UiStringState.new("BEFORE")
	var sel := UiIntState.new(0)
	var items := UiArrayState.new([{"name": "z", "kind": "y", "qty": 2}])
	rule.target_string_state = tgt
	rule.pulse_bool = UiBoolState.new(true)
	rule.selected_state = sel
	rule.items_state = items
	rule.template_rising = "{name}-{qty}"
	rule.require_rising_edge = false
	rule.apply_from_pulse(null, true, true)
	assert_eq(tgt.get_string_value(), "z-2")


func test_pulse_template_no_selection_when_name_empty() -> void:
	var rule := UiReactWireSetStringOnBoolPulse.new()
	var tgt := UiStringState.new()
	var sel := UiIntState.new(0)
	var items := UiArrayState.new([{"kind": "only"}])
	rule.target_string_state = tgt
	rule.pulse_bool = UiBoolState.new(false)
	rule.selected_state = sel
	rule.items_state = items
	rule.template_no_selection = "Pick"
	rule.template_rising = "SHOULD_NOT_USE"
	rule.require_rising_edge = true
	rule.apply_from_pulse(null, true, false)
	assert_eq(tgt.get_string_value(), "Pick")


func test_pulse_template_no_selection_negative_index() -> void:
	var rule := UiReactWireSetStringOnBoolPulse.new()
	var tgt := UiStringState.new()
	var sel := UiIntState.new(-1)
	var items := UiArrayState.new([{"name": "a", "kind": "b", "qty": 1}])
	rule.target_string_state = tgt
	rule.pulse_bool = UiBoolState.new(false)
	rule.selected_state = sel
	rule.items_state = items
	rule.template_no_selection = "Pick"
	rule.template_rising = "X"
	rule.require_rising_edge = true
	rule.apply_from_pulse(null, true, false)
	assert_eq(tgt.get_string_value(), "Pick")


func test_pulse_items_null_uses_empty_row() -> void:
	var rule := UiReactWireSetStringOnBoolPulse.new()
	var tgt := UiStringState.new()
	var sel := UiIntState.new(0)
	rule.target_string_state = tgt
	rule.pulse_bool = UiBoolState.new(false)
	rule.selected_state = sel
	rule.items_state = null
	rule.template_rising = "{name}{kind}{qty}"
	rule.require_rising_edge = true
	rule.apply_from_pulse(null, true, false)
	assert_eq(tgt.get_string_value(), "1")


# --- UiReactWireSyncBoolStateDebugLine ---


func test_debug_disabled_noop() -> void:
	var rule := UiReactWireSyncBoolStateDebugLine.new()
	rule.enabled = false
	var tgt := UiStringState.new("old")
	rule.target_string_state = tgt
	rule.bool_state = UiBoolState.new(true)
	_apply(rule)
	assert_eq(tgt.get_string_value(), "old")


func test_debug_missing_target_noop() -> void:
	var rule := UiReactWireSyncBoolStateDebugLine.new()
	rule.target_string_state = null
	var b := UiBoolState.new(false)
	rule.bool_state = b
	_apply(rule)
	assert_eq(b.get_bool_value(), false)


func test_debug_null_bool_uses_em_dash() -> void:
	var rule := UiReactWireSyncBoolStateDebugLine.new()
	var tgt := UiStringState.new()
	rule.target_string_state = tgt
	rule.bool_state = null
	rule.line_prefix = "DBG:"
	_apply(rule)
	assert_eq(tgt.get_string_value(), "DBG:—")


func test_debug_bool_false() -> void:
	var rule := UiReactWireSyncBoolStateDebugLine.new()
	var tgt := UiStringState.new()
	rule.target_string_state = tgt
	rule.bool_state = UiBoolState.new(false)
	rule.line_prefix = ""
	_apply(rule)
	assert_eq(tgt.get_string_value(), "false")


func test_debug_prefix_concat() -> void:
	var rule := UiReactWireSyncBoolStateDebugLine.new()
	var tgt := UiStringState.new()
	rule.target_string_state = tgt
	rule.bool_state = UiBoolState.new(true)
	rule.line_prefix = "x:"
	_apply(rule)
	assert_eq(tgt.get_string_value(), "x:true")


# --- UiReactWireSortArrayByKey ---


func test_sort_disabled_noop() -> void:
	var rule := UiReactWireSortArrayByKey.new()
	rule.enabled = false
	var items := UiArrayState.new([{"k": 2}, {"k": 1}])
	var key_st := UiStringState.new("k")
	rule.items_state = items
	rule.sort_key_state = key_st
	_apply(rule)
	assert_eq(items.get_array_value()[0].get("k", -1), 2)


func test_sort_missing_items_noop() -> void:
	var rule := UiReactWireSortArrayByKey.new()
	rule.items_state = null
	var key_st := UiStringState.new("k")
	rule.sort_key_state = key_st
	_apply(rule)
	assert_eq(key_st.get_string_value(), "k")


func test_sort_missing_sort_key_noop() -> void:
	var rule := UiReactWireSortArrayByKey.new()
	var items := UiArrayState.new([1, 2])
	rule.items_state = items
	rule.sort_key_state = null
	_apply(rule)
	assert_eq(items.get_array_value()[0], 1)


func test_sort_empty_key_noop() -> void:
	var rule := UiReactWireSortArrayByKey.new()
	var items := UiArrayState.new([{"a": 1}, {"a": 2}])
	var key_st := UiStringState.new("   ")
	rule.items_state = items
	rule.sort_key_state = key_st
	_apply(rule)
	var after: Array = items.get_array_value()
	assert_eq(after.size(), 2)
	assert_eq(after[0].get("a", null), 1)
	assert_eq(after[1].get("a", null), 2)


func test_sort_empty_array_noop() -> void:
	var rule := UiReactWireSortArrayByKey.new()
	var items := UiArrayState.new([])
	var key_st := UiStringState.new("name")
	rule.items_state = items
	rule.sort_key_state = key_st
	_apply(rule)
	assert_eq(items.get_array_value().size(), 0)


func test_sort_dicts_by_key_ascending() -> void:
	var rule := UiReactWireSortArrayByKey.new()
	var items := UiArrayState.new([{"sort": 2, "id": "b"}, {"sort": 1, "id": "a"}])
	var key_st := UiStringState.new("sort")
	rule.items_state = items
	rule.sort_key_state = key_st
	_apply(rule)
	var a: Array = items.get_array_value()
	assert_eq(a[0].get("id", ""), "a")
	assert_eq(a[1].get("id", ""), "b")


func test_sort_non_dict_compares_str() -> void:
	var rule := UiReactWireSortArrayByKey.new()
	var items := UiArrayState.new([2, 10])
	var key_st := UiStringState.new("k")
	rule.items_state = items
	rule.sort_key_state = key_st
	_apply(rule)
	var a: Array = items.get_array_value()
	assert_eq(a[0], 10)
	assert_eq(a[1], 2)


func test_sort_descending_reverses() -> void:
	var rule := UiReactWireSortArrayByKey.new()
	var items := UiArrayState.new([{"v": 1}, {"v": 2}])
	var key_st := UiStringState.new("v")
	var desc := UiBoolState.new(true)
	rule.items_state = items
	rule.sort_key_state = key_st
	rule.descending_state = desc
	_apply(rule)
	var a: Array = items.get_array_value()
	assert_eq(int(a[0].get("v", 0)), 2)
	assert_eq(int(a[1].get("v", 0)), 1)


func test_sort_null_sort_key_sorts_first() -> void:
	var rule := UiReactWireSortArrayByKey.new()
	var items := UiArrayState.new([{"k": 1}, {"k": null}])
	var key_st := UiStringState.new("k")
	rule.items_state = items
	rule.sort_key_state = key_st
	_apply(rule)
	var a: Array = items.get_array_value()
	assert_eq(a[0].get("k", "missing"), null)
	assert_eq(a[1].get("k", -1), 1)


func test_sort_descending_null_when_present() -> void:
	var rule := UiReactWireSortArrayByKey.new()
	var items := UiArrayState.new([{"k": 1}, {"k": null}])
	var key_st := UiStringState.new("k")
	var desc := UiBoolState.new(true)
	rule.items_state = items
	rule.sort_key_state = key_st
	rule.descending_state = desc
	_apply(rule)
	var a: Array = items.get_array_value()
	assert_eq(int(a[0].get("k", -1)), 1)
	assert_eq(a[1].get("k", "missing"), null)

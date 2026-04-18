extends GutTest


func _tabs_with_titles(titles: PackedStringArray) -> TabContainer:
	var tab_container := TabContainer.new()
	for i in titles.size():
		tab_container.add_child(Control.new())
		tab_container.set_tab_title(i, titles[i])
	add_child_autofree(tab_container)
	return tab_container


func _empty_tab_container() -> TabContainer:
	var tab_container := TabContainer.new()
	add_child_autofree(tab_container)
	return tab_container


# --- UiTabSelectionBinding ---


func test_resolve_int_passthrough_in_range() -> void:
	var tabs := _tabs_with_titles(PackedStringArray(["A", "B"]))
	assert_eq(UiTabSelectionBinding.resolve_tab_index(tabs, 0), 0)


func test_resolve_int_passthrough_out_of_range_no_clamp() -> void:
	var tabs := _tabs_with_titles(PackedStringArray(["A", "B"]))
	assert_eq(UiTabSelectionBinding.resolve_tab_index(tabs, 99), 99)


func test_resolve_int_negative_passthrough() -> void:
	var tabs := _tabs_with_titles(PackedStringArray(["A", "B"]))
	assert_eq(UiTabSelectionBinding.resolve_tab_index(tabs, -3), -3)


func test_resolve_string_matches_title() -> void:
	var tabs := _tabs_with_titles(PackedStringArray(["Alpha", "Beta"]))
	assert_eq(UiTabSelectionBinding.resolve_tab_index(tabs, "Beta"), 1)


func test_resolve_string_no_match_returns_minus_one() -> void:
	var tabs := _tabs_with_titles(PackedStringArray(["Alpha", "Beta"]))
	assert_eq(UiTabSelectionBinding.resolve_tab_index(tabs, "Gamma"), -1)


func test_resolve_string_empty_container_returns_minus_one() -> void:
	var tabs := _empty_tab_container()
	assert_eq(UiTabSelectionBinding.resolve_tab_index(tabs, "X"), -1)


func test_resolve_float_returns_minus_one() -> void:
	var tabs := _tabs_with_titles(PackedStringArray(["A"]))
	assert_eq(UiTabSelectionBinding.resolve_tab_index(tabs, 1.0), -1)


# --- UiTabCollectionSync ---


func test_apply_shrink_removes_extra_tabs() -> void:
	var tabs := _tabs_with_titles(PackedStringArray(["T0", "T1", "T2"]))
	var tabs_array: Array = ["Only"]
	var ret := UiTabCollectionSync.apply_tabs_from_array(tabs, tabs_array, null)
	assert_same(ret, null)
	assert_eq(tabs.get_tab_count(), 1)
	assert_eq(tabs.get_tab_title(0), "Only")
	await wait_idle_frames(2)


func test_apply_grow_adds_tabs_with_string_titles() -> void:
	var tabs := _tabs_with_titles(PackedStringArray(["Was"]))
	var tabs_array: Array = ["a", "b", "c"]
	var ret := UiTabCollectionSync.apply_tabs_from_array(tabs, tabs_array, null)
	assert_same(ret, null)
	assert_eq(tabs.get_tab_count(), 3)
	assert_eq(tabs.get_tab_title(0), "a")
	assert_eq(tabs.get_tab_title(1), "b")
	assert_eq(tabs.get_tab_title(2), "c")


func test_apply_dict_titles_and_missing_icon() -> void:
	var tabs := _empty_tab_container()
	var row0 := {
		UiTabCollectionSync.TAB_DATA_KEY_TITLE: "D0",
		UiTabCollectionSync.TAB_DATA_KEY_ICON: null,
	}
	var row1 := {UiTabCollectionSync.TAB_DATA_KEY_TITLE: "D1"}
	var tabs_array: Array = [row0, row1]
	var ret := UiTabCollectionSync.apply_tabs_from_array(tabs, tabs_array, null)
	assert_same(ret, null)
	assert_eq(tabs.get_tab_count(), 2)
	assert_eq(tabs.get_tab_title(0), "D0")
	assert_eq(tabs.get_tab_title(1), "D1")


func test_apply_non_string_non_dict_uses_str() -> void:
	var tabs := _empty_tab_container()
	var tabs_array: Array = ["S", 9]
	var ret := UiTabCollectionSync.apply_tabs_from_array(tabs, tabs_array, null)
	assert_same(ret, null)
	assert_eq(tabs.get_tab_count(), 2)
	assert_eq(tabs.get_tab_title(0), "S")
	assert_eq(tabs.get_tab_title(1), "9")


func test_apply_same_count_updates_titles() -> void:
	var tabs := _tabs_with_titles(PackedStringArray(["Old0", "Old1"]))
	var tabs_array: Array = ["N0", "N1"]
	var ret := UiTabCollectionSync.apply_tabs_from_array(tabs, tabs_array, null)
	assert_same(ret, null)
	assert_eq(tabs.get_tab_count(), 2)
	assert_eq(tabs.get_tab_title(0), "N0")
	assert_eq(tabs.get_tab_title(1), "N1")


func test_apply_shrink_clamps_current_tab_high() -> void:
	var tabs := _tabs_with_titles(PackedStringArray(["T0", "T1", "T2"]))
	tabs.current_tab = 2
	var tabs_array: Array = ["Single"]
	var ret := UiTabCollectionSync.apply_tabs_from_array(tabs, tabs_array, null)
	assert_eq(tabs.get_tab_count(), 1)
	assert_eq(tabs.get_tab_title(0), "Single")
	assert_eq(tabs.current_tab, 0)
	# TabContainer may clamp current_tab when tabs are removed before apply's branch runs; then ret stays null.
	assert_true(ret == null or ret == 0)
	await wait_idle_frames(2)


func test_apply_empty_array_removes_all_tabs() -> void:
	var tabs := _tabs_with_titles(PackedStringArray(["A", "B"]))
	var tabs_array: Array = []
	var ret := UiTabCollectionSync.apply_tabs_from_array(tabs, tabs_array, null)
	assert_same(ret, null)
	assert_eq(tabs.get_tab_count(), 0)
	await wait_idle_frames(2)


func test_apply_tab_config_resizes_tab_content_states() -> void:
	var tabs := _empty_tab_container()
	var cfg := UiTabContainerCfg.new()
	var tabs_array: Array = ["a", "b", "c", "d"]
	var ret := UiTabCollectionSync.apply_tabs_from_array(tabs, tabs_array, cfg)
	assert_same(ret, null)
	assert_eq(cfg.tab_content_states.size(), 4)


func test_apply_null_tab_config_skips_resize() -> void:
	var tabs := _empty_tab_container()
	var cfg := UiTabContainerCfg.new()
	var tabs_array: Array = ["x"]
	var ret := UiTabCollectionSync.apply_tabs_from_array(tabs, tabs_array, null)
	assert_same(ret, null)
	assert_eq(tabs.get_tab_count(), 1)
	assert_eq(cfg.tab_content_states.size(), 0)


func test_apply_placeholder_icon_on_dict_row() -> void:
	var tabs := _empty_tab_container()
	var icon := PlaceholderTexture2D.new()
	var row := {
		UiTabCollectionSync.TAB_DATA_KEY_TITLE: "I0",
		UiTabCollectionSync.TAB_DATA_KEY_ICON: icon,
	}
	var tabs_array: Array = [row]
	var ret := UiTabCollectionSync.apply_tabs_from_array(tabs, tabs_array, null)
	assert_same(ret, null)
	assert_eq(tabs.get_tab_count(), 1)
	assert_eq(tabs.get_tab_title(0), "I0")
	assert_true(tabs.get_tab_icon(0) != null)

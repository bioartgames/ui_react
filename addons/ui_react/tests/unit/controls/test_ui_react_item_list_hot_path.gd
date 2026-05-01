extends GutTest

const _ICON_PNG := "res://addons/gut/icon.png"


func test_icon_string_path_cache_same_path_two_rows_then_rebuild() -> void:
	if Engine.is_editor_hint():
		return
	var root := Node.new()
	add_child_autofree(root)

	var arr := UiArrayState.new([])
	var list := UiReactItemList.new()
	list.items_state = arr
	root.add_child(list)
	await wait_process_frames(2)

	arr.set_value([
		{"label": "A", "icon": _ICON_PNG},
		{"label": "B", "icon": _ICON_PNG},
	])
	await wait_process_frames(1)
	assert_eq(list.item_count, 2)
	var n_after_first: int = list.debug_icon_path_cache_entry_count_for_tests()

	arr.set_value([
		{"label": "A2", "icon": _ICON_PNG},
		{"label": "B2", "icon": _ICON_PNG},
	])
	await wait_process_frames(1)
	assert_eq(list.item_count, 2)
	assert_eq(list.debug_icon_path_cache_entry_count_for_tests(), n_after_first)
	assert_gte(n_after_first, 1)


func test_signature_short_circuit_preserves_rows_when_label_vs_text_equivalent_dicts() -> void:
	if Engine.is_editor_hint():
		return
	var root := Node.new()
	add_child_autofree(root)

	var arr := UiArrayState.new([])
	var list := UiReactItemList.new()
	list.items_state = arr
	root.add_child(list)
	await wait_process_frames(2)

	arr.set_value([{"label": "a"}])
	await wait_process_frames(1)
	assert_eq(list.item_count, 1)
	assert_eq(list.get_item_text(0), "a")

	arr.set_value([{"text": "a"}])
	await wait_process_frames(1)
	assert_eq(list.item_count, 1)
	assert_eq(list.get_item_text(0), "a")


func test_signature_change_rebuilds_label_text() -> void:
	if Engine.is_editor_hint():
		return
	var root := Node.new()
	add_child_autofree(root)

	var arr := UiArrayState.new([])
	var list := UiReactItemList.new()
	list.items_state = arr
	root.add_child(list)
	await wait_process_frames(2)

	arr.set_value([{"label": "before"}])
	await wait_process_frames(1)
	arr.set_value([{"label": "after"}])
	await wait_process_frames(1)
	assert_eq(list.get_item_text(0), "after")

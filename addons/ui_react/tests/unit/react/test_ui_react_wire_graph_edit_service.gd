extends GutTest


func test_shallow_descriptor_matrix_includes_new_milestone2_fields() -> void:
	var copy_desc := UiReactWireGraphEditService.shallow_field_descriptors_for_class(
		&"UiReactWireCopySelectionDetail"
	)
	var has_copy_text := false
	var has_copy_clear := false
	for d: Dictionary in copy_desc:
		var prop := String(d.get(&"prop", ""))
		if prop == "text_no_selection":
			has_copy_text = true
		if prop == "clear_suffix_on_selection_change":
			has_copy_clear = true
	assert_true(has_copy_text)
	assert_true(has_copy_clear)

	var debug_desc := UiReactWireGraphEditService.shallow_field_descriptors_for_class(
		&"UiReactWireSyncBoolStateDebugLine"
	)
	assert_eq(debug_desc.size(), 1)
	assert_eq(String((debug_desc[0] as Dictionary).get(&"prop", "")), "line_prefix")


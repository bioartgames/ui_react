extends GutTest


func after_each() -> void:
	UiReactComputedService.reset_internal_state_for_tests()


func test_checkbox_exit_tree_releases_computed_site() -> void:
	if Engine.is_editor_hint():
		return
	var root := Node.new()
	add_child_autofree(root)
	var src := UiBoolState.new(false)
	var comp := UiComputedBoolInvert.new()
	comp.sources = [src]

	var cb := UiReactCheckBox.new()
	cb.checked_state = comp
	root.add_child(cb)
	await wait_process_frames(2)

	root.remove_child(cb)
	cb.queue_free()
	await wait_process_frames(2)

	var cb2 := UiReactCheckBox.new()
	cb2.checked_state = comp
	root.add_child(cb2)
	await wait_process_frames(2)

	src.set_value(true)
	await wait_process_frames(2)

	var desired := bool(comp.get_value())
	assert_eq(cb2.button_pressed, desired)

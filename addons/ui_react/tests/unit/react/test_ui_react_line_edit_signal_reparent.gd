extends GutTest


func test_line_edit_reparent_does_not_accumulate_text_changed_connections() -> void:
	if Engine.is_editor_hint():
		return
	var root := Node.new()
	add_child_autofree(root)
	var le := UiReactLineEdit.new()
	root.add_child(le)
	await wait_process_frames(1)
	var baseline: int = le.text_changed.get_connections().size()
	for _i in range(10):
		root.remove_child(le)
		root.add_child(le)
		await wait_process_frames(1)
	var after: int = le.text_changed.get_connections().size()
	assert_true(
		after <= baseline,
		"text_changed connections should not grow across reparent loops (baseline=%d after=%d)"
		% [baseline, after]
	)


func test_button_reparent_does_not_accumulate_pressed_connections() -> void:
	if Engine.is_editor_hint():
		return
	var root := Node.new()
	add_child_autofree(root)
	var btn := UiReactButton.new()
	root.add_child(btn)
	await wait_process_frames(1)
	var baseline: int = btn.pressed.get_connections().size()
	for _i in range(10):
		root.remove_child(btn)
		root.add_child(btn)
		await wait_process_frames(1)
	var after: int = btn.pressed.get_connections().size()
	assert_true(
		after <= baseline,
		"pressed connections should not grow across reparent loops (baseline=%d after=%d)"
		% [baseline, after]
	)

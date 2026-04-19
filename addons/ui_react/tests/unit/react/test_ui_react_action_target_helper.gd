extends GutTest

const CMP := "TestComponent"


func _owner_control() -> Control:
	return autoqfree(Control.new())


func _owner_button() -> UiReactButton:
	return autoqfree(UiReactButton.new())


func _allow_empty_pressed() -> Array[int]:
	var allow: Array[int] = []
	allow.append(int(UiAnimTarget.Trigger.PRESSED))
	return allow


func _row_grab(target_path: String = "Child") -> UiReactActionTarget:
	var r := UiReactActionTarget.new()
	r.action = UiReactActionTarget.UiReactActionKind.GRAB_FOCUS
	r.target = NodePath(target_path)
	return r


func _row_set_visible(target_path: String = "Child") -> UiReactActionTarget:
	var r := UiReactActionTarget.new()
	r.action = UiReactActionTarget.UiReactActionKind.SET_VISIBLE
	r.target = NodePath(target_path)
	return r


func _row_set_mouse_filter(target_path: String = "Child") -> UiReactActionTarget:
	var r := UiReactActionTarget.new()
	r.action = UiReactActionTarget.UiReactActionKind.SET_MOUSE_FILTER
	r.target = NodePath(target_path)
	return r


func _row_bool_flag(bool_flag_state: UiBoolState, state_watch: UiBoolState = null) -> UiReactActionTarget:
	var r := UiReactActionTarget.new()
	r.action = UiReactActionTarget.UiReactActionKind.SET_UI_BOOL_FLAG
	r.bool_flag_state = bool_flag_state
	r.state_watch = state_watch
	return r


# --- validate_action_targets ---


func test_validate_preserves_disabled_row() -> void:
	var owner := _owner_control()
	var row := _row_grab("")
	row.enabled = false
	var action_targets: Array[UiReactActionTarget] = [row]
	var out := UiReactActionTargetHelper.validate_action_targets(owner, CMP, action_targets, [])
	assert_eq(out.size(), 1)
	assert_same(out[0], row)


func test_validate_skips_null_entry() -> void:
	var owner := _owner_control()
	var only_null: Array[UiReactActionTarget] = []
	only_null.resize(1)
	var out_empty := UiReactActionTargetHelper.validate_action_targets(owner, CMP, only_null, [])
	assert_true(out_empty.is_empty())

	var r := _row_grab("X")
	var null_then_row: Array[UiReactActionTarget] = []
	null_then_row.resize(2)
	null_then_row[1] = r
	var out_one := UiReactActionTargetHelper.validate_action_targets(owner, CMP, null_then_row, [])
	assert_eq(out_one.size(), 1)
	assert_same(out_one[0], r)


func test_validate_button_keeps_control_triggered_row() -> void:
	var owner := _owner_button()
	var row := _row_grab("Child")
	row.trigger = UiAnimTarget.Trigger.PRESSED
	var action_targets: Array[UiReactActionTarget] = [row]
	var out := UiReactActionTargetHelper.validate_action_targets(owner, CMP, action_targets, [])
	assert_eq(out.size(), 1)
	assert_same(out[0], row)


func test_validate_button_keeps_state_watch_row() -> void:
	var owner := _owner_button()
	var row := _row_grab("Child")
	row.state_watch = UiBoolState.new()
	row.trigger = UiAnimTarget.Trigger.PRESSED
	var action_targets: Array[UiReactActionTarget] = [row]
	var out := UiReactActionTargetHelper.validate_action_targets(owner, CMP, action_targets, [])
	assert_eq(out.size(), 1)
	assert_same(out[0], row)


## Warns only (no continue); row is still appended if otherwise valid — see ui_react_action_target_helper.gd lines 84–90.
func test_validate_state_watch_non_pressed_still_outputs_when_otherwise_valid() -> void:
	var owner := _owner_control()
	var row := _row_grab("Target")
	row.state_watch = UiBoolState.new()
	row.trigger = UiAnimTarget.Trigger.TEXT_CHANGED
	var action_targets: Array[UiReactActionTarget] = [row]
	var out := UiReactActionTargetHelper.validate_action_targets(owner, CMP, action_targets, [])
	assert_engine_error(1)
	assert_eq(out.size(), 1)
	assert_same(out[0], row)


func test_validate_bool_flag_missing_dropped() -> void:
	var owner := _owner_control()
	var row := _row_bool_flag(null, null)
	var action_targets: Array[UiReactActionTarget] = [row]
	var out := UiReactActionTargetHelper.validate_action_targets(owner, CMP, action_targets, [])
	assert_engine_error(1)
	assert_true(out.is_empty())


func test_validate_bool_flag_same_as_state_watch_dropped() -> void:
	var owner := _owner_control()
	var sw := UiBoolState.new()
	var row := _row_bool_flag(sw, sw)
	var action_targets: Array[UiReactActionTarget] = [row]
	var out := UiReactActionTargetHelper.validate_action_targets(owner, CMP, action_targets, [])
	assert_push_error(1)
	assert_true(out.is_empty())


func test_validate_grab_focus_empty_target_dropped() -> void:
	var owner := _owner_control()
	var row := _row_grab("")
	row.trigger = UiAnimTarget.Trigger.PRESSED
	var action_targets: Array[UiReactActionTarget] = [row]
	var out := UiReactActionTargetHelper.validate_action_targets(owner, CMP, action_targets, [])
	assert_engine_error(1)
	assert_true(out.is_empty())


func test_validate_grab_focus_empty_target_allowed() -> void:
	var owner := _owner_control()
	var row := _row_grab("")
	row.trigger = UiAnimTarget.Trigger.PRESSED
	var action_targets: Array[UiReactActionTarget] = [row]
	var out := UiReactActionTargetHelper.validate_action_targets(owner, CMP, action_targets, _allow_empty_pressed())
	assert_eq(out.size(), 1)
	assert_same(out[0], row)


func test_validate_set_visible_empty_target_dropped() -> void:
	var owner := _owner_control()
	var row := _row_set_visible("")
	row.trigger = UiAnimTarget.Trigger.PRESSED
	var action_targets: Array[UiReactActionTarget] = [row]
	var out := UiReactActionTargetHelper.validate_action_targets(owner, CMP, action_targets, [])
	assert_engine_error(1)
	assert_true(out.is_empty())


func test_validate_set_mouse_filter_empty_target_allowed_with_allowlist() -> void:
	var owner := _owner_control()
	var row := _row_set_mouse_filter("")
	row.trigger = UiAnimTarget.Trigger.PRESSED
	var action_targets: Array[UiReactActionTarget] = [row]
	var out := UiReactActionTargetHelper.validate_action_targets(owner, CMP, action_targets, _allow_empty_pressed())
	assert_eq(out.size(), 1)
	assert_same(out[0], row)


func test_validate_minimal_grab_focus_passes() -> void:
	var owner := _owner_control()
	var row := _row_grab("X")
	row.state_watch = null
	row.trigger = UiAnimTarget.Trigger.PRESSED
	var action_targets: Array[UiReactActionTarget] = [row]
	var out := UiReactActionTargetHelper.validate_action_targets(owner, CMP, action_targets, [])
	assert_eq(out.size(), 1)
	assert_same(out[0], row)


# --- collect_control_trigger_map ---


func test_collect_skips_null_and_disabled() -> void:
	var action_targets: Array[UiReactActionTarget] = []
	action_targets.resize(3)
	var disabled := _row_grab("A")
	disabled.enabled = false
	disabled.trigger = UiAnimTarget.Trigger.HOVER_ENTER
	var enabled := _row_grab("B")
	enabled.trigger = UiAnimTarget.Trigger.PRESSED
	action_targets[1] = disabled
	action_targets[2] = enabled
	var trigger_map := UiReactActionTargetHelper.collect_control_trigger_map(action_targets)
	assert_eq(trigger_map.size(), 1)
	assert_true(trigger_map.has(UiAnimTarget.Trigger.PRESSED))


func test_collect_skips_state_watch_rows() -> void:
	var row_a := _row_grab("A")
	row_a.state_watch = UiBoolState.new()
	row_a.trigger = UiAnimTarget.Trigger.PRESSED
	var row_b := _row_grab("B")
	row_b.trigger = UiAnimTarget.Trigger.HOVER_ENTER
	var action_targets: Array[UiReactActionTarget] = [row_a, row_b]
	var trigger_map := UiReactActionTargetHelper.collect_control_trigger_map(action_targets)
	assert_eq(trigger_map.size(), 1)
	assert_true(trigger_map.has(UiAnimTarget.Trigger.HOVER_ENTER))


func test_collect_merges_multiple_triggers() -> void:
	var row_p := _row_grab("A")
	row_p.trigger = UiAnimTarget.Trigger.PRESSED
	var row_t := _row_grab("B")
	row_t.trigger = UiAnimTarget.Trigger.TEXT_CHANGED
	var action_targets: Array[UiReactActionTarget] = [row_p, row_t]
	var trigger_map := UiReactActionTargetHelper.collect_control_trigger_map(action_targets)
	assert_true(trigger_map.has(UiAnimTarget.Trigger.PRESSED))
	assert_true(trigger_map.has(UiAnimTarget.Trigger.TEXT_CHANGED))


func test_collect_duplicate_trigger_single_key() -> void:
	var row_a := _row_grab("A")
	row_a.trigger = UiAnimTarget.Trigger.SELECTION_CHANGED
	var row_b := _row_grab("B")
	row_b.trigger = UiAnimTarget.Trigger.SELECTION_CHANGED
	var action_targets: Array[UiReactActionTarget] = [row_a, row_b]
	var trigger_map := UiReactActionTargetHelper.collect_control_trigger_map(action_targets)
	assert_eq(trigger_map.size(), 1)
	assert_eq(trigger_map[UiAnimTarget.Trigger.SELECTION_CHANGED], true)

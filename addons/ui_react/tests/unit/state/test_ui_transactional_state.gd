extends GutTest


# --- Init ---


func test_init_defaults_scalar_zero() -> void:
	var t := UiTransactionalState.new()
	assert_eq(t.get_committed_value(), 0.0)
	assert_eq(t.get_draft_value(), 0.0)
	assert_eq(typeof(t.get_draft_value()), TYPE_FLOAT)
	assert_false(t.has_pending_changes())


func test_init_clones_initial_array() -> void:
	var a: Array = [1, 2]
	var t := UiTransactionalState.new(a)
	a.append(3)
	var d: Array = t.get_draft_value()
	assert_eq(d.size(), 2)
	assert_eq(d[0], 1)
	assert_eq(d[1], 2)


# --- Cloning ---


func test_set_value_clones_array() -> void:
	var t := UiTransactionalState.new()
	var outer: Array = [1]
	t.set_value(outer)
	outer.append(2)
	var v: Array = t.get_value()
	assert_eq(v.size(), 1)
	assert_eq(v[0], 1)


func test_set_value_clones_dictionary() -> void:
	var t := UiTransactionalState.new()
	var outer: Dictionary = {"k": 1}
	t.set_value(outer)
	outer["k"] = 99
	var v: Dictionary = t.get_value()
	assert_eq(v["k"], 1)


func test_apply_draft_clones_into_committed_array() -> void:
	var t := UiTransactionalState.new([1])
	t.set_value([2, 3])
	t.apply_draft()
	var c: Array = t.get_committed_value()
	var d: Array = t.get_draft_value()
	c.append(99)
	assert_eq(d.size(), 2)
	assert_eq(d[0], 2)
	assert_eq(d[1], 3)


func test_begin_edit_clones_committed_to_draft() -> void:
	var t := UiTransactionalState.new([1])
	t.set_value([9])
	t.begin_edit()
	var d: Array = t.get_draft_value()
	assert_eq(d.size(), 1)
	assert_eq(d[0], 1)


# --- Variants / pending ---


func test_pending_false_when_int_and_float_equal() -> void:
	var t := UiTransactionalState.new(1.0)
	t.set_value(1)
	assert_false(t.has_pending_changes())


func test_pending_true_when_values_differ() -> void:
	var t := UiTransactionalState.new(0.0)
	t.set_value(1.0)
	assert_true(t.has_pending_changes())


func test_float_approx_equal_no_pending() -> void:
	var t := UiTransactionalState.new(1.0)
	t.set_value(1.0 + 1e-7)
	assert_false(t.has_pending_changes())


func test_pending_true_mismatched_non_numeric_types() -> void:
	var t := UiTransactionalState.new("a")
	t.set_value("b")
	assert_true(t.has_pending_changes())


# --- set_value / set_silent / signals ---


func test_set_value_noop_when_equal_no_value_changed() -> void:
	var t := UiTransactionalState.new()
	t.set_value(1.0)
	watch_signals(t)
	t.set_value(1.0)
	assert_signal_not_emitted(t, "value_changed")


func test_set_silent_emits_changed_not_value_changed() -> void:
	var t := UiTransactionalState.new()
	watch_signals(t)
	t.set_silent(5.0)
	assert_signal_not_emitted(t, "value_changed")
	assert_signal_emitted(t, "changed")


func test_set_value_emits_value_changed_when_draft_changes() -> void:
	var t := UiTransactionalState.new()
	watch_signals(t)
	t.set_value(1.0)
	assert_signal_emitted_with_parameters(t, "value_changed", [1.0, 0.0])
	assert_signal_emitted(t, "changed")


# --- begin_edit ---


func test_begin_edit_resets_draft_from_committed() -> void:
	var t := UiTransactionalState.new(5.0)
	t.set_value(10.0)
	t.begin_edit()
	assert_eq(t.get_value(), 5.0)


func test_begin_edit_when_draft_already_equals_committed_no_value_changed() -> void:
	var t := UiTransactionalState.new(5.0)
	watch_signals(t)
	t.begin_edit()
	assert_signal_not_emitted(t, "value_changed")


func test_begin_edit_when_draft_changes_emits_value_changed() -> void:
	var t := UiTransactionalState.new(5.0)
	t.set_value(10.0)
	watch_signals(t)
	t.begin_edit()
	assert_signal_emitted_with_parameters(t, "value_changed", [5.0, 10.0])


# --- apply_draft ---


func test_apply_draft_copies_draft_to_committed() -> void:
	var t := UiTransactionalState.new(0.0)
	t.set_value(7.0)
	t.apply_draft()
	assert_eq(t.get_committed_value(), 7.0)
	assert_false(t.has_pending_changes())


func test_apply_draft_noop_when_already_in_sync() -> void:
	var t := UiTransactionalState.new(3.0)
	watch_signals(t)
	t.apply_draft()
	assert_signal_not_emitted(t, "value_changed")
	assert_signal_not_emitted(t, "changed")


func test_apply_draft_does_not_emit_value_changed() -> void:
	var t := UiTransactionalState.new(0.0)
	t.set_value(7.0)
	watch_signals(t)
	t.apply_draft()
	assert_signal_not_emitted(t, "value_changed")
	assert_signal_emitted(t, "changed")


# --- cancel_draft / reset_to_committed ---


func test_cancel_draft_restores_draft_from_committed() -> void:
	var t := UiTransactionalState.new(3.0)
	t.set_value(9.0)
	t.cancel_draft()
	assert_eq(t.get_value(), 3.0)
	assert_false(t.has_pending_changes())


func test_reset_to_committed_matches_cancel_draft() -> void:
	var t1 := UiTransactionalState.new(3.0)
	t1.set_value(9.0)
	var t2 := UiTransactionalState.new(3.0)
	t2.set_value(9.0)
	t1.cancel_draft()
	t2.reset_to_committed()
	assert_eq(t1.get_draft_value(), t2.get_draft_value())
	assert_eq(t1.has_pending_changes(), t2.has_pending_changes())


func test_cancel_draft_emits_value_changed_when_draft_changes() -> void:
	var t := UiTransactionalState.new(3.0)
	t.set_value(9.0)
	watch_signals(t)
	t.cancel_draft()
	assert_signal_emitted(t, "value_changed")


# --- matches_expected_binding_class ---


func test_matches_bool_true() -> void:
	var t := UiTransactionalState.new()
	t.committed_value = true
	assert_true(t.matches_expected_binding_class(&"UiBoolState"))


func test_matches_bool_false_for_int() -> void:
	var t := UiTransactionalState.new()
	t.committed_value = 1
	assert_false(t.matches_expected_binding_class(&"UiBoolState"))


func test_matches_int_true() -> void:
	var t := UiTransactionalState.new()
	t.committed_value = 42
	assert_true(t.matches_expected_binding_class(&"UiIntState"))


func test_matches_int_false_for_float() -> void:
	var t := UiTransactionalState.new()
	t.committed_value = 1.0
	assert_false(t.matches_expected_binding_class(&"UiIntState"))


func test_matches_float_true_float() -> void:
	var t := UiTransactionalState.new()
	t.committed_value = 1.5
	assert_true(t.matches_expected_binding_class(&"UiFloatState"))


func test_matches_float_true_int() -> void:
	var t := UiTransactionalState.new()
	t.committed_value = 7
	assert_true(t.matches_expected_binding_class(&"UiFloatState"))


func test_matches_float_false_bool() -> void:
	var t := UiTransactionalState.new()
	t.committed_value = true
	assert_false(t.matches_expected_binding_class(&"UiFloatState"))


func test_matches_string_true_string() -> void:
	var t := UiTransactionalState.new()
	t.committed_value = "x"
	assert_true(t.matches_expected_binding_class(&"UiStringState"))


func test_matches_string_true_stringname() -> void:
	var t := UiTransactionalState.new()
	t.committed_value = &"x"
	assert_true(t.matches_expected_binding_class(&"UiStringState"))


func test_matches_array_true() -> void:
	var t := UiTransactionalState.new()
	t.committed_value = [1]
	assert_true(t.matches_expected_binding_class(&"UiArrayState"))


func test_matches_array_false_dict() -> void:
	var t := UiTransactionalState.new()
	t.committed_value = {}
	assert_false(t.matches_expected_binding_class(&"UiArrayState"))


func test_matches_unknown_expected_false() -> void:
	var t := UiTransactionalState.new()
	t.committed_value = true
	assert_false(t.matches_expected_binding_class(&"UiNonexistent"))

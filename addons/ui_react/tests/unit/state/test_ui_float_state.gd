extends GutTest


func test_set_value_null_maps_to_zero() -> void:
	var s := UiFloatState.new()
	s.set_value(null)
	assert_eq(s.get_float_value(), 0.0)
	assert_eq(s.get_value(), 0.0)


func test_set_value_noop_when_equal_approx() -> void:
	var s := UiFloatState.new()
	s.set_value(1.0)
	watch_signals(s)
	s.set_value(1.0)
	assert_signal_not_emitted(s, "value_changed")


func test_set_value_emits_value_changed_and_changed() -> void:
	var s := UiFloatState.new()
	watch_signals(s)
	s.set_value(2.0)
	assert_signal_emitted_with_parameters(s, "value_changed", [2.0, 0.0])
	assert_signal_emitted(s, "changed")


func test_set_silent_updates_without_value_changed() -> void:
	var s := UiFloatState.new()
	watch_signals(s)
	s.set_silent(5.0)
	assert_eq(s.get_float_value(), 5.0)
	assert_signal_not_emitted(s, "value_changed")
	assert_signal_emitted(s, "changed")

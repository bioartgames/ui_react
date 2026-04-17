extends GutTest


func test_set_value_null_maps_to_zero() -> void:
	var s := UiIntState.new()
	s.set_value(null)
	assert_eq(s.get_int_value(), 0)


func test_set_value_int_updates_and_emits() -> void:
	var s := UiIntState.new(0)
	watch_signals(s)
	s.set_value(7)
	assert_eq(s.get_int_value(), 7)
	assert_signal_emitted_with_parameters(s, "value_changed", [7, 0])
	assert_signal_emitted(s, "changed")


func test_set_value_float_rejected_no_mutation() -> void:
	var s := UiIntState.new(3)
	watch_signals(s)
	s.set_value(4.0)
	assert_engine_error("UiIntState.set_value: float")
	assert_eq(s.get_int_value(), 3)
	assert_signal_not_emitted(s, "value_changed")


func test_set_value_invalid_type_rejected() -> void:
	var s := UiIntState.new(2)
	watch_signals(s)
	s.set_value("nope")
	assert_engine_error("UiIntState.set_value: expected int")
	assert_eq(s.get_int_value(), 2)
	assert_signal_not_emitted(s, "value_changed")


func test_set_silent_null_and_int_emit_changed() -> void:
	var s := UiIntState.new(5)
	watch_signals(s)
	s.set_silent(null)
	assert_eq(s.get_int_value(), 0)
	assert_signal_emitted(s, "changed")


func test_set_silent_int_updates() -> void:
	var s := UiIntState.new(0)
	watch_signals(s)
	s.set_silent(42)
	assert_eq(s.get_int_value(), 42)
	assert_signal_emitted(s, "changed")


func test_set_silent_float_rejected() -> void:
	var s := UiIntState.new(1)
	watch_signals(s)
	s.set_silent(2.0)
	assert_engine_error("UiIntState.set_silent: float")
	assert_eq(s.get_int_value(), 1)
	assert_signal_not_emitted(s, "changed")


func test_set_silent_invalid_type_no_emit_changed() -> void:
	var s := UiIntState.new(9)
	watch_signals(s)
	s.set_silent("bad")
	assert_engine_error("UiIntState.set_silent: expected int")
	assert_eq(s.get_int_value(), 9)
	assert_signal_not_emitted(s, "changed")

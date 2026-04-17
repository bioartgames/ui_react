extends GutTest


func test_set_value_noop_when_same() -> void:
	var s := UiBoolState.new(false)
	watch_signals(s)
	s.set_value(false)
	assert_signal_not_emitted(s, "value_changed")


func test_set_value_emits_when_changed() -> void:
	var s := UiBoolState.new(false)
	watch_signals(s)
	s.set_value(true)
	assert_signal_emitted_with_parameters(s, "value_changed", [true, false])
	assert_signal_emitted(s, "changed")


func test_set_silent_emits_changed_only() -> void:
	var s := UiBoolState.new(false)
	watch_signals(s)
	s.set_silent(true)
	assert_true(s.get_bool_value())
	assert_signal_not_emitted(s, "value_changed")
	assert_signal_emitted(s, "changed")


func test_set_value_coerces_non_bool_variant() -> void:
	var s := UiBoolState.new(false)
	s.set_value(1)
	assert_true(s.get_bool_value())

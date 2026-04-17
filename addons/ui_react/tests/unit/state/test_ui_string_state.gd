extends GutTest


func test_set_value_null_maps_to_empty_string() -> void:
	var s := UiStringState.new()
	s.set_value(null)
	assert_eq(s.get_string_value(), "")
	assert_eq(s.get_value(), "")


func test_set_value_noop_when_same_string() -> void:
	var s := UiStringState.new("hi")
	watch_signals(s)
	s.set_value("hi")
	assert_signal_not_emitted(s, "value_changed")


func test_set_value_emits_when_changed() -> void:
	var s := UiStringState.new("a")
	watch_signals(s)
	s.set_value("b")
	assert_signal_emitted_with_parameters(s, "value_changed", ["b", "a"])
	assert_signal_emitted(s, "changed")


func test_set_silent_updates_without_value_changed() -> void:
	var s := UiStringState.new("x")
	watch_signals(s)
	s.set_silent("y")
	assert_eq(s.get_string_value(), "y")
	assert_signal_not_emitted(s, "value_changed")
	assert_signal_emitted(s, "changed")

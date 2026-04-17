extends GutTest


func test_set_value_null_maps_to_empty_array() -> void:
	var s := UiArrayState.new()
	s.set_value(null)
	assert_eq(s.get_array_value(), [])
	assert_eq(s.get_value(), [])


func test_set_value_duplicates_input_array() -> void:
	var s := UiArrayState.new()
	var src: Array = [1, 2]
	s.set_value(src)
	src.append(3)
	assert_eq(s.get_array_value(), [1, 2])


func test_set_value_accepts_packed_arrays() -> void:
	var s := UiArrayState.new()
	var p32 := PackedInt32Array([10, 20])
	s.set_value(p32)
	assert_eq(s.get_array_value(), [10, 20])
	var pf := PackedFloat32Array([1.5, 2.5])
	s.set_value(pf)
	assert_eq(s.get_array_value(), [1.5, 2.5])


func test_set_value_rejects_non_array() -> void:
	var s := UiArrayState.new([1])
	watch_signals(s)
	s.set_value(99)
	assert_engine_error("UiArrayState.set_value() expects an Array")
	assert_eq(s.get_array_value(), [1])
	assert_signal_not_emitted(s, "value_changed")


func test_set_value_noop_when_deep_equal() -> void:
	var s := UiArrayState.new()
	s.set_value([1, 2])
	watch_signals(s)
	s.set_value([1, 2])
	assert_signal_not_emitted(s, "value_changed")


func test_set_value_emits_when_changed() -> void:
	var s := UiArrayState.new()
	watch_signals(s)
	s.set_value(["a"])
	assert_signal_emitted(s, "value_changed")
	assert_signal_emitted(s, "changed")


func test_set_silent_null_clears() -> void:
	var s := UiArrayState.new([1, 2])
	watch_signals(s)
	s.set_silent(null)
	assert_eq(s.get_array_value(), [])
	assert_signal_emitted(s, "changed")


func test_set_silent_invalid_type_coerces_to_empty() -> void:
	var s := UiArrayState.new([7])
	watch_signals(s)
	s.set_silent("nope")
	assert_eq(s.get_array_value(), [])
	assert_signal_emitted(s, "changed")

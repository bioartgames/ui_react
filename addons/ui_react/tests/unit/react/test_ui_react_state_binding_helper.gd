extends GutTest

const CMP := "TestComponent"
const OWNER := "OwnerNode"
const FIELD := "items_state"


func _string_state(text: String) -> UiStringState:
	var s := UiStringState.new()
	s.set_value(text)
	return s


# --- warn_setup ---


func test_warn_setup_emits_engine_warning() -> void:
	var owner: Control = autoqfree(Control.new())
	owner.name = "Probe"
	UiReactStateBindingHelper.warn_setup(CMP, owner, "something wrong", "fix it")
	assert_engine_error("something wrong")


# --- initial_sync ---


func test_initial_sync_skips_when_state_null() -> void:
	var captured: Array = [false]
	var cb := func(_a: Variant, _b: Variant) -> void:
		captured[0] = true
	UiReactStateBindingHelper.initial_sync(null, cb)
	assert_false(captured[0])


func test_initial_sync_calls_with_duplicate_float_value() -> void:
	var state := UiFloatState.new()
	state.set_value(2.5)
	var pair: Array = []
	var cb := func(a: Variant, b: Variant) -> void:
		pair.clear()
		pair.append(a)
		pair.append(b)
	UiReactStateBindingHelper.initial_sync(state, cb)
	assert_eq(pair.size(), 2)
	assert_eq(pair[0], 2.5)
	assert_eq(pair[1], 2.5)
	assert_eq(pair[0], pair[1])


# --- deferred_finish_initialization ---


func test_deferred_finish_invokes_default_method() -> void:
	var probe := _DeferredInitProbe.new()
	add_child_autofree(probe)
	UiReactStateBindingHelper.deferred_finish_initialization(probe)
	await wait_idle_frames(1)
	assert_eq(probe.hits, 1)


# --- coerce_bool ---


func test_coerce_bool_true() -> void:
	assert_true(UiReactStateBindingHelper.coerce_bool(true))


func test_coerce_bool_false() -> void:
	assert_false(UiReactStateBindingHelper.coerce_bool(false))


func test_coerce_bool_null() -> void:
	assert_false(UiReactStateBindingHelper.coerce_bool(null))


func test_coerce_bool_zero_int() -> void:
	assert_false(UiReactStateBindingHelper.coerce_bool(0))


func test_coerce_bool_nonempty_string() -> void:
	assert_true(UiReactStateBindingHelper.coerce_bool("x"))


# --- coerce_float ---


func test_coerce_float_null_default_zero() -> void:
	assert_eq(UiReactStateBindingHelper.coerce_float(null), 0.0)


func test_coerce_float_null_custom_default() -> void:
	assert_eq(UiReactStateBindingHelper.coerce_float(null, 7.25), 7.25)


func test_coerce_float_from_int() -> void:
	assert_eq(UiReactStateBindingHelper.coerce_float(42, 0.0), 42.0)


func test_coerce_float_from_float() -> void:
	assert_eq(UiReactStateBindingHelper.coerce_float(3.5, 0.0), 3.5)


func test_coerce_float_from_numeric_string() -> void:
	assert_eq(UiReactStateBindingHelper.coerce_float("2.25", 0.0), 2.25)


# --- approx_equal_float ---


func test_approx_equal_negative_epsilon_identical() -> void:
	assert_true(UiReactStateBindingHelper.approx_equal_float(1.0, 1.0, -1.0))


func test_approx_equal_negative_epsilon_close() -> void:
	assert_true(UiReactStateBindingHelper.approx_equal_float(1.0, 1.0 + 1e-7, -1.0))


func test_approx_equal_negative_epsilon_far() -> void:
	assert_false(UiReactStateBindingHelper.approx_equal_float(1.0, 2.0, -1.0))


func test_approx_equal_positive_window_inside() -> void:
	assert_true(UiReactStateBindingHelper.approx_equal_float(1.0, 1.05, 0.1))


func test_approx_equal_positive_window_outside() -> void:
	assert_false(UiReactStateBindingHelper.approx_equal_float(1.0, 1.2, 0.1))


func test_approx_equal_zero_epsilon_exact() -> void:
	assert_true(UiReactStateBindingHelper.approx_equal_float(3.0, 3.0, 0.0))


func test_approx_equal_zero_epsilon_rejects_tiny_diff() -> void:
	assert_false(UiReactStateBindingHelper.approx_equal_float(3.0, 3.0001, 0.0))


# --- expect_array_state ---


func test_expect_array_state_returns_same_reference() -> void:
	var a: Array = ["x"]
	var out := UiReactStateBindingHelper.expect_array_state(CMP, OWNER, FIELD, a)
	assert_same(out, a)


func test_expect_array_state_empty_array() -> void:
	var a: Array = []
	var out := UiReactStateBindingHelper.expect_array_state(CMP, OWNER, FIELD, a)
	assert_true(out is Array)
	assert_eq((out as Array).size(), 0)


func test_expect_array_state_dictionary_returns_null() -> void:
	var out := UiReactStateBindingHelper.expect_array_state(CMP, OWNER, FIELD, {})
	assert_engine_error("must be an Array")
	assert_same(out, null)


func test_expect_array_state_int_returns_null() -> void:
	var out := UiReactStateBindingHelper.expect_array_state(CMP, OWNER, FIELD, 7)
	assert_engine_error("must be an Array")
	assert_same(out, null)


func test_expect_array_state_packed_string_array_returns_null() -> void:
	var packed := PackedStringArray()
	packed.append("p")
	var out := UiReactStateBindingHelper.expect_array_state(CMP, OWNER, FIELD, packed)
	assert_engine_error("must be an Array")
	assert_same(out, null)


# --- as_text_flat ---


func test_as_text_flat_scalar_int() -> void:
	assert_eq(UiReactStateBindingHelper.as_text_flat(5), "5")


func test_as_text_flat_empty_array() -> void:
	assert_eq(UiReactStateBindingHelper.as_text_flat([]), "")


func test_as_text_flat_joins_elements() -> void:
	assert_eq(UiReactStateBindingHelper.as_text_flat([1, 2]), "12")


func test_as_text_flat_bool_elements() -> void:
	assert_eq(UiReactStateBindingHelper.as_text_flat([true, false]), "truefalse")


# --- as_text_recursive ---


func test_as_text_recursive_scalar() -> void:
	assert_eq(UiReactStateBindingHelper.as_text_recursive(42), "42")


func test_as_text_recursive_unwraps_bool_state() -> void:
	var s := UiBoolState.new()
	s.set_value(true)
	assert_eq(UiReactStateBindingHelper.as_text_recursive(s), "true")


func test_as_text_recursive_unwraps_string_state() -> void:
	assert_eq(UiReactStateBindingHelper.as_text_recursive(_string_state("hi")), "hi")


func test_as_text_recursive_array_of_string_states() -> void:
	var a: Array = [_string_state("a"), _string_state("b")]
	assert_eq(UiReactStateBindingHelper.as_text_recursive(a), "ab")


func test_as_text_recursive_nested_arrays_of_int_states() -> void:
	var i1 := UiIntState.new()
	i1.set_value(1)
	var i2 := UiIntState.new()
	i2.set_value(2)
	var inner0: Array = [i1]
	var inner1: Array = [i2]
	var outer: Array = [inner0, inner1]
	assert_eq(UiReactStateBindingHelper.as_text_recursive(outer), "12")


class _DeferredInitProbe extends Node:
	var hits: int = 0

	func _finish_initialization() -> void:
		hits += 1

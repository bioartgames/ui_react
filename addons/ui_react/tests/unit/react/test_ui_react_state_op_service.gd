extends GutTest

## Matches Godot 64-bit signed int range (used for overflow edge cases).
const I64_MAX := 9223372036854775807


func _float(v: float) -> UiFloatState:
	var s := UiFloatState.new()
	s.set_value(v)
	return s


func _int(v: int) -> UiIntState:
	var s := UiIntState.new()
	s.set_value(v)
	return s


# --- float_from_state ---


func test_float_from_state_null_returns_zero() -> void:
	assert_eq(UiReactStateOpService.float_from_state(null), 0.0)


func test_float_from_state_reads_value() -> void:
	var s := _float(3.5)
	assert_eq(UiReactStateOpService.float_from_state(s), 3.5)


# --- int_from_state ---


func test_int_from_state_null_returns_zero() -> void:
	assert_eq(UiReactStateOpService.int_from_state(null), 0)


func test_int_from_state_reads_value() -> void:
	var s := _int(42)
	assert_eq(UiReactStateOpService.int_from_state(s), 42)


# --- set_float_literal ---


func test_set_float_literal_null_accum_noop() -> void:
	var s := _float(5.0)
	UiReactStateOpService.set_float_literal(null, 9.0)
	assert_eq(s.get_float_value(), 5.0)


func test_set_float_literal_sets_value() -> void:
	var s := _float(1.0)
	UiReactStateOpService.set_float_literal(s, 8.25)
	assert_eq(s.get_float_value(), 8.25)


# --- afford_floats ---


func test_afford_floats_true_when_gold_covers_total() -> void:
	var gold := _float(10.0)
	var price := _float(2.0)
	var qty := _float(3.0)
	assert_true(UiReactStateOpService.afford_floats(gold, price, qty))


func test_afford_floats_false_when_gold_below_total() -> void:
	var gold := _float(5.0)
	var price := _float(2.0)
	var qty := _float(4.0)
	assert_false(UiReactStateOpService.afford_floats(gold, price, qty))


func test_afford_floats_equal_is_affordable() -> void:
	var gold := _float(6.0)
	var price := _float(2.0)
	var qty := _float(3.0)
	assert_true(UiReactStateOpService.afford_floats(gold, price, qty))


func test_afford_null_accum_treats_gold_as_zero() -> void:
	var price := _float(2.0)
	var qty := _float(3.0)
	assert_false(UiReactStateOpService.afford_floats(null, price, qty))


func test_afford_null_price_makes_total_zero() -> void:
	var gold := _float(10.0)
	var qty := _float(5.0)
	assert_true(UiReactStateOpService.afford_floats(gold, null, qty))


func test_afford_all_null_is_affordable() -> void:
	assert_true(UiReactStateOpService.afford_floats(null, null, null))


# --- subtract_product_from_accumulator ---


func test_subtract_noop_if_any_null() -> void:
	var accum := _float(10.0)
	var price := _float(2.0)
	UiReactStateOpService.subtract_product_from_accumulator(accum, price, null)
	assert_eq(accum.get_float_value(), 10.0)


func test_subtract_noop_if_unaffordable() -> void:
	var accum := _float(5.0)
	var price := _float(2.0)
	var qty := _float(4.0)
	UiReactStateOpService.subtract_product_from_accumulator(accum, price, qty)
	assert_eq(accum.get_float_value(), 5.0)


func test_subtract_reduces_when_affordable() -> void:
	var accum := _float(10.0)
	var price := _float(2.0)
	var qty := _float(3.0)
	UiReactStateOpService.subtract_product_from_accumulator(accum, price, qty)
	assert_eq(accum.get_float_value(), 4.0)


func test_subtract_exactly_affordable() -> void:
	var accum := _float(6.0)
	var price := _float(2.0)
	var qty := _float(3.0)
	UiReactStateOpService.subtract_product_from_accumulator(accum, price, qty)
	assert_eq(accum.get_float_value(), 0.0)


# --- add_product_to_accumulator ---


func test_add_product_noop_if_any_null() -> void:
	var accum := _float(1.0)
	var fa := _float(2.0)
	UiReactStateOpService.add_product_to_accumulator(accum, null, fa)
	assert_eq(accum.get_float_value(), 1.0)


func test_add_product_adds_unbounded() -> void:
	var accum := _float(1.0)
	var fa := _float(2.0)
	var fb := _float(3.0)
	UiReactStateOpService.add_product_to_accumulator(accum, fa, fb)
	assert_eq(accum.get_float_value(), 7.0)


# --- transfer_float_product_clamped ---


func test_transfer_float_noop_if_any_null() -> void:
	var from_s := _float(5.0)
	var to_s := _float(0.0)
	var fa := _float(10.0)
	UiReactStateOpService.transfer_float_product_clamped(from_s, to_s, fa, null)
	assert_eq(from_s.get_float_value(), 5.0)
	assert_eq(to_s.get_float_value(), 0.0)


func test_transfer_float_noop_if_p_non_positive() -> void:
	var from_s := _float(5.0)
	var to_s := _float(0.0)
	var fa := _float(0.0)
	var fb := _float(10.0)
	UiReactStateOpService.transfer_float_product_clamped(from_s, to_s, fa, fb)
	assert_eq(from_s.get_float_value(), 5.0)
	assert_eq(to_s.get_float_value(), 0.0)


func test_transfer_float_noop_if_negative_product() -> void:
	var from_s := _float(5.0)
	var to_s := _float(0.0)
	var fa := _float(-1.0)
	var fb := _float(5.0)
	UiReactStateOpService.transfer_float_product_clamped(from_s, to_s, fa, fb)
	assert_eq(from_s.get_float_value(), 5.0)
	assert_eq(to_s.get_float_value(), 0.0)


func test_transfer_float_noop_if_actual_non_positive() -> void:
	var from_s := _float(0.0)
	var to_s := _float(0.0)
	var fa := _float(2.0)
	var fb := _float(3.0)
	UiReactStateOpService.transfer_float_product_clamped(from_s, to_s, fa, fb)
	assert_eq(from_s.get_float_value(), 0.0)
	assert_eq(to_s.get_float_value(), 0.0)


func test_transfer_float_clamps_to_from_balance() -> void:
	var from_s := _float(5.0)
	var to_s := _float(0.0)
	var fa := _float(10.0)
	var fb := _float(1.0)
	UiReactStateOpService.transfer_float_product_clamped(from_s, to_s, fa, fb)
	assert_eq(from_s.get_float_value(), 0.0)
	assert_eq(to_s.get_float_value(), 5.0)


func test_transfer_float_moves_partial() -> void:
	var from_s := _float(10.0)
	var to_s := _float(3.0)
	var fa := _float(2.0)
	var fb := _float(3.0)
	UiReactStateOpService.transfer_float_product_clamped(from_s, to_s, fa, fb)
	assert_eq(from_s.get_float_value(), 4.0)
	assert_eq(to_s.get_float_value(), 9.0)


# --- add_product_to_int_clamped ---


func test_add_int_clamped_noop_if_any_null() -> void:
	var accum := _int(10)
	var fa := _int(2)
	UiReactStateOpService.add_product_to_int_clamped(accum, null, fa)
	assert_eq(accum.get_int_value(), 10)


func test_add_int_clamped_noop_if_mul_overflow() -> void:
	var accum := _int(0)
	var fa := _int(I64_MAX)
	var fb := _int(2)
	UiReactStateOpService.add_product_to_int_clamped(accum, fa, fb)
	assert_eq(accum.get_int_value(), 0)


func test_add_int_clamped_noop_if_product_negative() -> void:
	var accum := _int(10)
	var fa := _int(-2)
	var fb := _int(3)
	UiReactStateOpService.add_product_to_int_clamped(accum, fa, fb)
	assert_eq(accum.get_int_value(), 10)


func test_add_int_clamped_noop_if_sum_overflow() -> void:
	var accum := _int(I64_MAX)
	var fa := _int(1)
	var fb := _int(1)
	UiReactStateOpService.add_product_to_int_clamped(accum, fa, fb)
	assert_eq(accum.get_int_value(), I64_MAX)


func test_add_int_clamped_adds_when_safe() -> void:
	var accum := _int(10)
	var fa := _int(2)
	var fb := _int(3)
	UiReactStateOpService.add_product_to_int_clamped(accum, fa, fb)
	assert_eq(accum.get_int_value(), 16)


# --- transfer_int_product_clamped ---


func test_transfer_int_noop_if_any_null() -> void:
	var from_s := _int(10)
	var to_s := _int(0)
	var fa := _int(2)
	UiReactStateOpService.transfer_int_product_clamped(from_s, to_s, fa, null)
	assert_eq(from_s.get_int_value(), 10)
	assert_eq(to_s.get_int_value(), 0)


func test_transfer_int_noop_if_mul_overflow() -> void:
	var from_s := _int(10)
	var to_s := _int(0)
	var fa := _int(I64_MAX)
	var fb := _int(2)
	UiReactStateOpService.transfer_int_product_clamped(from_s, to_s, fa, fb)
	assert_eq(from_s.get_int_value(), 10)
	assert_eq(to_s.get_int_value(), 0)


func test_transfer_int_noop_if_p_non_positive() -> void:
	var from_s := _int(10)
	var to_s := _int(0)
	var fa := _int(0)
	var fb := _int(5)
	UiReactStateOpService.transfer_int_product_clamped(from_s, to_s, fa, fb)
	assert_eq(from_s.get_int_value(), 10)
	assert_eq(to_s.get_int_value(), 0)


func test_transfer_int_noop_if_negative_product() -> void:
	var from_s := _int(10)
	var to_s := _int(0)
	var fa := _int(-1)
	var fb := _int(5)
	UiReactStateOpService.transfer_int_product_clamped(from_s, to_s, fa, fb)
	assert_eq(from_s.get_int_value(), 10)
	assert_eq(to_s.get_int_value(), 0)


func test_transfer_int_noop_if_actual_non_positive() -> void:
	var from_s := _int(0)
	var to_s := _int(5)
	var fa := _int(2)
	var fb := _int(3)
	UiReactStateOpService.transfer_int_product_clamped(from_s, to_s, fa, fb)
	assert_eq(from_s.get_int_value(), 0)
	assert_eq(to_s.get_int_value(), 5)


func test_transfer_int_clamped_happy_path() -> void:
	var from_s := _int(10)
	var to_s := _int(3)
	var fa := _int(2)
	var fb := _int(3)
	UiReactStateOpService.transfer_int_product_clamped(from_s, to_s, fa, fb)
	assert_eq(from_s.get_int_value(), 4)
	assert_eq(to_s.get_int_value(), 9)


## to + actual overflows i64; _safe_add_i64 returns null — no mutation.
func test_transfer_int_noop_if_add_overflow() -> void:
	var from_s := _int(100)
	var to_s := _int(I64_MAX)
	var fa := _int(1)
	var fb := _int(1)
	UiReactStateOpService.transfer_int_product_clamped(from_s, to_s, fa, fb)
	assert_eq(from_s.get_int_value(), 100)
	assert_eq(to_s.get_int_value(), I64_MAX)

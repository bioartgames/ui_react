extends GutTest


func _three_floats(g: float, p: float, q: float) -> Array[UiState]:
	return [UiFloatState.new(g), UiFloatState.new(p), UiFloatState.new(q)]


# --- UiComputedBoolInvert ---


func test_bool_invert_empty_sources_returns_true() -> void:
	var invert := UiComputedBoolInvert.new()
	invert.sources = []
	invert.recompute()
	assert_eq(invert.compute_bool(), true)
	assert_eq(invert.get_bool_value(), invert.compute_bool())


func test_bool_invert_null_first_source_returns_true() -> void:
	var invert := UiComputedBoolInvert.new()
	var slots: Array[UiState] = []
	slots.resize(1)
	invert.sources = slots
	assert_eq(invert.sources[0], null)
	assert_eq(invert.compute_bool(), true)
	invert.recompute()
	assert_eq(invert.get_bool_value(), invert.compute_bool())


func test_bool_invert_false_when_source_bool_true() -> void:
	var invert := UiComputedBoolInvert.new()
	invert.sources = [UiBoolState.new(true)]
	invert.recompute()
	assert_eq(invert.compute_bool(), false)
	assert_eq(invert.get_bool_value(), invert.compute_bool())


func test_bool_invert_true_when_source_bool_false() -> void:
	var invert := UiComputedBoolInvert.new()
	invert.sources = [UiBoolState.new(false)]
	invert.recompute()
	assert_eq(invert.compute_bool(), true)
	assert_eq(invert.get_bool_value(), invert.compute_bool())


# --- UiComputedFloatGeProductBool ---


func test_float_ge_afford_true() -> void:
	var ge := UiComputedFloatGeProductBool.new()
	ge.sources = _three_floats(100.0, 10.0, 5.0)
	assert_eq(ge.compute_bool(), true)
	ge.recompute()
	assert_eq(ge.get_bool_value(), ge.compute_bool())


func test_float_ge_afford_false() -> void:
	var ge := UiComputedFloatGeProductBool.new()
	ge.sources = _three_floats(40.0, 10.0, 5.0)
	assert_eq(ge.compute_bool(), false)


func test_float_ge_non_float_at_accum_behaves_as_null_float() -> void:
	var ge := UiComputedFloatGeProductBool.new()
	ge.sources = [UiBoolState.new(false), UiFloatState.new(10.0), UiFloatState.new(5.0)]
	assert_eq(ge.compute_bool(), false)


func test_float_ge_non_float_at_price_zeroes_product() -> void:
	var ge := UiComputedFloatGeProductBool.new()
	ge.sources = [UiFloatState.new(10.0), UiBoolState.new(true), UiFloatState.new(5.0)]
	assert_eq(ge.compute_bool(), true)


func test_float_ge_short_sources_only_gold_float() -> void:
	var ge := UiComputedFloatGeProductBool.new()
	ge.sources = [UiFloatState.new(7.0)]
	assert_eq(ge.compute_bool(), true)


# --- UiComputedOrderSummaryThreeFloatString ---


func test_order_summary_can_afford_string() -> void:
	var o := UiComputedOrderSummaryThreeFloatString.new()
	o.sources = _three_floats(100.0, 10.0, 5.0)
	var got := o.compute_string()
	assert_true(
		UiReactStateOpService.afford_floats(
			o.sources[0] as UiFloatState,
			o.sources[1] as UiFloatState,
			o.sources[2] as UiFloatState
		)
	)
	assert_true(got.contains("Order summary"))
	assert_true(got.contains("Total:"))
	assert_true(got.contains("Gold:"))
	assert_true(got.contains("Can afford"))
	assert_true(got.contains("50.00"))
	assert_true(got.contains("100.00"))


func test_order_summary_cannot_afford_string() -> void:
	var o := UiComputedOrderSummaryThreeFloatString.new()
	o.sources = _three_floats(40.0, 10.0, 5.0)
	var got := o.compute_string()
	assert_false(
		UiReactStateOpService.afford_floats(
			o.sources[0] as UiFloatState,
			o.sources[1] as UiFloatState,
			o.sources[2] as UiFloatState
		)
	)
	assert_true(got.contains("Order summary"))
	assert_true(got.contains("Total:"))
	assert_true(got.contains("Gold:"))
	assert_true(got.contains("Cannot afford"))
	assert_true(got.contains("50.00"))
	assert_true(got.contains("40.00"))


func test_order_summary_zero_total_affords() -> void:
	var o := UiComputedOrderSummaryThreeFloatString.new()
	o.sources = _three_floats(0.0, 0.0, 100.0)
	var got := o.compute_string()
	assert_true(
		UiReactStateOpService.afford_floats(
			o.sources[0] as UiFloatState,
			o.sources[1] as UiFloatState,
			o.sources[2] as UiFloatState
		)
	)
	assert_true(got.contains("Order summary"))
	assert_true(got.contains("Total:"))
	assert_true(got.contains("Gold:"))
	assert_true(got.contains("Can afford"))
	assert_true(got.contains("0.00"))


# --- UiComputedTransactionalStatusString ---


func test_txn_status_empty_sources_matches_format() -> void:
	var t := UiComputedTransactionalStatusString.new()
	t.sources = []
	var got := t.compute_string()
	assert_true(got.contains("Draft:") and got.contains("Committed:"))
	assert_false(got.contains("*unsaved*"))
	assert_eq(got.count("0.0"), 0)


func test_txn_status_two_defaults_no_pending() -> void:
	var t := UiComputedTransactionalStatusString.new()
	var vol := UiTransactionalState.new()
	var mute := UiTransactionalState.new()
	t.sources = [vol, mute]
	var got := t.compute_string()
	assert_true(got.contains("Draft:") and got.contains("Committed:"))
	assert_false(got.contains("*unsaved*"))
	assert_eq(got.count("0.0"), 4)


func test_txn_status_first_pending_only() -> void:
	var t := UiComputedTransactionalStatusString.new()
	var vol := UiTransactionalState.new()
	var mute := UiTransactionalState.new()
	vol.set_value(1.0)
	t.sources = [vol, mute]
	var got := t.compute_string()
	assert_true(got.contains("*unsaved*"))
	assert_true(got.contains("1.0"))


func test_txn_status_both_pending() -> void:
	var t := UiComputedTransactionalStatusString.new()
	var vol := UiTransactionalState.new()
	var mute := UiTransactionalState.new()
	vol.set_value(1.0)
	mute.set_value(2.0)
	t.sources = [vol, mute]
	var got := t.compute_string()
	assert_true(got.contains("*unsaved*"))
	assert_true(got.contains("1.0") and got.contains("2.0"))


func test_txn_status_only_first_slot() -> void:
	var t := UiComputedTransactionalStatusString.new()
	var vol := UiTransactionalState.new()
	t.sources = [vol]
	var got := t.compute_string()
	assert_false(got.contains("*unsaved*"))
	assert_eq(got.count("0.0"), 2)


# --- Smoke recompute ---


func test_recompute_bool_invert_updates_value() -> void:
	var invert := UiComputedBoolInvert.new()
	invert.sources = [UiBoolState.new(true)]
	invert.recompute()
	assert_eq(invert.get_bool_value(), invert.compute_bool())


func test_recompute_order_summary_updates_string() -> void:
	var o := UiComputedOrderSummaryThreeFloatString.new()
	o.sources = _three_floats(100.0, 10.0, 5.0)
	o.recompute()
	assert_eq(o.get_string_value(), o.compute_string())


func test_recompute_transactional_status_updates_string() -> void:
	var t := UiComputedTransactionalStatusString.new()
	var vol := UiTransactionalState.new()
	var mute := UiTransactionalState.new()
	t.sources = [vol, mute]
	t.recompute()
	assert_eq(t.get_string_value(), t.compute_string())

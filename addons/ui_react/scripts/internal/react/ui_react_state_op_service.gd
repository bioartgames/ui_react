extends RefCounted
## Whitelisted float math for [UiReactActionTarget] presets and computeds ([code]docs/ACTION_LAYER.md[/code]).
class_name UiReactStateOpService


static func float_from_state(s: UiFloatState) -> float:
	if s == null:
		return 0.0
	return float(s.get_value())


## [code]accum >= price * qty[/code] with null-safe reads (afford / order-summary computeds).
static func afford_floats(accum: UiFloatState, price: UiFloatState, qty: UiFloatState) -> bool:
	var g := float_from_state(accum)
	var total := float_from_state(price) * float_from_state(qty)
	return g >= total


## Shop-style purchase: [code]accumulator -= price * qty[/code] when affordable; no-op otherwise (matches former [code]shop_computed_demo.gd[/code]).
static func subtract_product_from_accumulator(
	accum: UiFloatState, price: UiFloatState, qty: UiFloatState
) -> void:
	if accum == null or price == null or qty == null:
		return
	var gold := float_from_state(accum)
	var total := float_from_state(price) * float_from_state(qty)
	if gold < total:
		return
	accum.set_value(gold - total)


static func int_from_state(s: UiIntState) -> int:
	if s == null:
		return 0
	return int(s.get_int_value())


## [code]accumulator += factor_a * factor_b[/code] (unbounded add). Any null ref → no-op.
static func add_product_to_accumulator(
	accum: UiFloatState, factor_a: UiFloatState, factor_b: UiFloatState
) -> void:
	if accum == null or factor_a == null or factor_b == null:
		return
	var cur := float_from_state(accum)
	var p := float_from_state(factor_a) * float_from_state(factor_b)
	accum.set_value(cur + p)


## Moves [code]min(from, factor_a * factor_b)[/code] from [param from_s] to [param to_s] when [code]p > 0[/code]. Any null ref → no-op.
static func transfer_float_product_clamped(
	from_s: UiFloatState, to_s: UiFloatState, factor_a: UiFloatState, factor_b: UiFloatState
) -> void:
	if from_s == null or to_s == null or factor_a == null or factor_b == null:
		return
	var p := float_from_state(factor_a) * float_from_state(factor_b)
	if p <= 0.0:
		return
	var from_v := float_from_state(from_s)
	var actual: float = from_v if from_v < p else p
	if actual <= 0.0:
		return
	from_s.set_value(from_v - actual)
	to_s.set_value(float_from_state(to_s) + actual)


static func _safe_mul_i64(a: int, b: int) -> Variant:
	if a == 0 or b == 0:
		return 0
	var c: int = a * b
	if a != 0 and (c / a) != b:
		return null
	return c


static func _safe_add_i64(a: int, b: int) -> Variant:
	var c: int = a + b
	if b > 0 and c < a:
		return null
	if b < 0 and c > a:
		return null
	return c


## [code]accumulator += factor_a * factor_b[/code] when product and sum stay in signed 64-bit range and [code]product >= 0[/code]. Any null ref or unsafe math → no-op.
static func add_product_to_int_clamped(
	accum: UiIntState, factor_a: UiIntState, factor_b: UiIntState
) -> void:
	if accum == null or factor_a == null or factor_b == null:
		return
	var ia := int_from_state(factor_a)
	var ib := int_from_state(factor_b)
	var p_var: Variant = _safe_mul_i64(ia, ib)
	if p_var == null:
		return
	var p: int = p_var as int
	if p < 0:
		return
	var cur := int_from_state(accum)
	var sum_var: Variant = _safe_add_i64(cur, p)
	if sum_var == null:
		return
	accum.set_value(sum_var as int)


## Same clamped transfer as [method transfer_float_product_clamped] for [UiIntState] with safe multiply.
static func transfer_int_product_clamped(
	from_s: UiIntState, to_s: UiIntState, factor_a: UiIntState, factor_b: UiIntState
) -> void:
	if from_s == null or to_s == null or factor_a == null or factor_b == null:
		return
	var ia := int_from_state(factor_a)
	var ib := int_from_state(factor_b)
	var p_var: Variant = _safe_mul_i64(ia, ib)
	if p_var == null:
		return
	var p: int = p_var as int
	if p <= 0:
		return
	var from_v := int_from_state(from_s)
	var actual: int = from_v if from_v < p else p
	if actual <= 0:
		return
	var from_sub_var: Variant = _safe_add_i64(from_v, -actual)
	var to_add_var: Variant = _safe_add_i64(int_from_state(to_s), actual)
	if from_sub_var == null or to_add_var == null:
		return
	from_s.set_value(from_sub_var as int)
	to_s.set_value(to_add_var as int)

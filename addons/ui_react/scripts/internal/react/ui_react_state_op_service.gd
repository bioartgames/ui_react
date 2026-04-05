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

@tool
## [UiComputedStringState]: multi-line **BBCode** order summary from [code][gold, price, qty][/code] ([UiFloatState]).
class_name UiComputedOrderSummaryThreeFloatString
extends UiComputedStringState

const _StateOps = preload("res://addons/ui_react/scripts/internal/react/ui_react_state_op_service.gd")


func compute_string() -> String:
	var accum := _as_float_state(0)
	var price := _as_float_state(1)
	var qty := _as_float_state(2)
	var gold: float = _StateOps.float_from_state(accum)
	var p: float = _StateOps.float_from_state(price)
	var q: float = _StateOps.float_from_state(qty)
	var total: float = p * q
	var can: bool = _StateOps.afford_floats(accum, price, qty)
	var verdict: String = (
		"[color=green][b]Can afford[/b][/color]" if can
		else "[color=red][b]Cannot afford[/b][/color]"
	)
	return (
		"[font_size=18][b]Order summary[/b][/font_size]\n"
		+ "[i]Live totals[/i] — Total: [code]%.2f[/code]  ·  Gold: [code]%.2f[/code]\n" % [total, gold]
		+ verdict
	)


func _as_float_state(index: int) -> UiFloatState:
	if index < 0 or index >= sources.size():
		return null
	var s: UiState = sources[index]
	return s as UiFloatState if s is UiFloatState else null

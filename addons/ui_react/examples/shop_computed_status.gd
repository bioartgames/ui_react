@tool
## Example [UiComputedStringState]: multi-line shop summary as **BBCode** for [UiReactRichTextLabel], from [code][gold, price, quantity][/code] ([UiFloatState]).
class_name ShopComputedStatus
extends "res://addons/ui_react/scripts/api/models/ui_computed_string_state.gd"


func compute_string() -> String:
	var gold: float = _float_at(0)
	var price: float = _float_at(1)
	var qty: float = _float_at(2)
	var total: float = price * qty
	var can: bool = gold >= total
	var verdict: String = (
		"[color=green][b]Can afford[/b][/color]" if can
		else "[color=red][b]Cannot afford[/b][/color]"
	)
	return (
		"[font_size=18][b]Order summary[/b][/font_size]\n"
		+ "[i]Live totals[/i] — Total: [code]%.2f[/code]  ·  Gold: [code]%.2f[/code]\n" % [total, gold]
		+ verdict
	)


func _float_at(index: int) -> float:
	if index < 0 or index >= sources.size():
		return 0.0
	var s: UiState = sources[index]
	if s == null:
		return 0.0
	return float(s.get_value())

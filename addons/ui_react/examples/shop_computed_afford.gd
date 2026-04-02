@tool
## Example [UiComputedBoolState]: [code]gold >= price * quantity[/code]. [member sources]: [code][gold, price, quantity][/code] ([UiFloatState]).
class_name ShopComputedAfford
extends "res://addons/ui_react/scripts/api/models/ui_computed_bool_state.gd"


func compute_bool() -> bool:
	var gold: float = _float_at(0)
	var price: float = _float_at(1)
	var qty: float = _float_at(2)
	return gold >= price * qty


func _float_at(index: int) -> float:
	if index < 0 or index >= sources.size():
		return 0.0
	var s: UiState = sources[index]
	if s == null:
		return 0.0
	return float(s.get_value())

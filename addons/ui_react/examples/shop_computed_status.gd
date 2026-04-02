@tool
## Example [UiComputedStringState]: one-line shop summary from [code][gold, price, quantity][/code] ([UiFloatState]).
class_name ShopComputedStatus
extends "res://addons/ui_react/scripts/api/models/ui_computed_string_state.gd"


func compute_string() -> String:
	var gold: float = _float_at(0)
	var price: float = _float_at(1)
	var qty: float = _float_at(2)
	var total: float = price * qty
	var can: bool = gold >= total
	return (
		"Total: %.2f | Gold: %.2f | %s" % [total, gold, ("Can afford" if can else "Cannot afford")]
	)


func _float_at(index: int) -> float:
	if index < 0 or index >= sources.size():
		return 0.0
	var s: UiState = sources[index]
	if s == null:
		return 0.0
	return float(s.get_value())

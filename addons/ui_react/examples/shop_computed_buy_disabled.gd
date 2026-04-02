@tool
## Example [UiComputedBoolState]: disables Buy when [member sources][0] (typically [ShopComputedAfford]) is [code]false[/code].
class_name ShopComputedBuyDisabled
extends "res://addons/ui_react/scripts/api/models/ui_computed_bool_state.gd"


func compute_bool() -> bool:
	if sources.is_empty() or sources[0] == null:
		return true
	return not bool(sources[0].get_value())

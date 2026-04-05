@tool
## [UiComputedBoolState]: [code]sources[0] >= sources[1] * sources[2][/code] ([UiFloatState] indices: accum, factor_a, factor_b).
class_name UiComputedFloatGeProductBool
extends UiComputedBoolState

const _StateOps = preload("res://addons/ui_react/scripts/internal/react/ui_react_state_op_service.gd")


func compute_bool() -> bool:
	return _StateOps.afford_floats(_as_float_state(0), _as_float_state(1), _as_float_state(2))


func _as_float_state(index: int) -> UiFloatState:
	if index < 0 or index >= sources.size():
		return null
	var s: UiState = sources[index]
	return s as UiFloatState if s is UiFloatState else null

## Optional typed [UiState] for numeric [member value] payloads (sliders, spin boxes, progress).
class_name UiFloatState
extends UiState

func _init(initial_value: Variant = 0.0) -> void:
	super._init(initial_value)

func get_float_value() -> float:
	if value == null:
		return 0.0
	return float(value)

func set_float_value(v: float) -> void:
	set_value(v)

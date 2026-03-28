## Typed [UiState] for numeric payloads (sliders, spin boxes, progress bars).
class_name UiFloatState
extends UiState

@export var value: float = 0.0


func _init(initial_value: Variant = 0.0) -> void:
	if typeof(initial_value) != TYPE_NIL:
		value = float(initial_value)


func get_value() -> Variant:
	return value


func set_value(new_value: Variant) -> void:
	var v: float = 0.0 if new_value == null else float(new_value)
	if is_equal_approx(value, v):
		return
	var old: float = value
	value = v
	value_changed.emit(v, old)
	emit_changed()


func set_silent(new_value: Variant) -> void:
	value = 0.0 if new_value == null else float(new_value)
	emit_changed()


func get_float_value() -> float:
	return value


func set_float_value(v: float) -> void:
	set_value(v)

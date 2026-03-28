## Typed [UiState] for integer payloads (tab index, item list selection, discrete indices).
class_name UiIntState
extends UiState

@export var value: int = 0


func _init(initial_value: Variant = 0) -> void:
	if typeof(initial_value) != TYPE_NIL:
		value = int(initial_value)


func get_value() -> Variant:
	return value


func set_value(new_value: Variant) -> void:
	var v: int
	if new_value == null:
		v = 0
	elif typeof(new_value) == TYPE_FLOAT:
		v = int(new_value)
	else:
		v = int(new_value)
	if value == v:
		return
	var old: int = value
	value = v
	value_changed.emit(v, old)
	emit_changed()


func set_silent(new_value: Variant) -> void:
	if new_value == null:
		value = 0
	elif typeof(new_value) == TYPE_FLOAT:
		value = int(new_value)
	else:
		value = int(new_value)
	emit_changed()


func get_int_value() -> int:
	return value


func set_int_value(v: int) -> void:
	set_value(v)

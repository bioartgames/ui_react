## Typed [UiState] for [Array] payloads (tab lists, composite label text, multi-select indices).
class_name UiArrayState
extends UiState

@export var value: Array = []


func _init(initial_value: Variant = null) -> void:
	if initial_value != null and initial_value is Array:
		value = (initial_value as Array).duplicate()


func get_value() -> Variant:
	return value


func set_value(new_value: Variant) -> void:
	var next: Array = []
	if new_value == null:
		pass
	elif new_value is Array:
		next = (new_value as Array).duplicate()
	elif new_value is PackedInt32Array or new_value is PackedFloat32Array:
		next = Array(new_value)
	else:
		push_warning("UiArrayState.set_value() expects an Array")
		return
	if value == next:
		return
	var old: Array = value
	value = next
	value_changed.emit(next, old)
	emit_changed()


func set_silent(new_value: Variant) -> void:
	if new_value == null:
		value = []
	elif new_value is Array:
		value = (new_value as Array).duplicate()
	elif new_value is PackedInt32Array or new_value is PackedFloat32Array:
		value = Array(new_value)
	else:
		value = []
	emit_changed()


func get_array_value() -> Array:
	return value


func set_array_value(v: Array) -> void:
	set_value(v)

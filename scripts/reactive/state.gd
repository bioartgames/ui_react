extends Resource
class_name State

signal value_changed(new_value, old_value)

@export var value: Variant

func _init(initial_value: Variant = null) -> void:
	value = initial_value

func set_value(new_value: Variant) -> void:
	if value == new_value:
		return
	var old_value: Variant = value
	value = new_value
	emit_signal("value_changed", new_value, old_value)
	emit_changed()

func set_silent(new_value: Variant) -> void:
	value = new_value
	emit_changed()


@tool
## Typed [UiState] for boolean payloads (toggles, pressed/disabled flags).
class_name UiBoolState
extends UiState

@export var value: bool = false


func _init(initial_value: Variant = false) -> void:
	if typeof(initial_value) != TYPE_NIL:
		value = bool(initial_value)


func get_value() -> Variant:
	return value


func set_value(new_value: Variant) -> void:
	var v := bool(new_value)
	if value == v:
		return
	var old: bool = value
	value = v
	if not Engine.is_editor_hint():
		value_changed.emit(v, old)
	emit_changed()


func set_silent(new_value: Variant) -> void:
	value = bool(new_value)
	emit_changed()


func get_bool_value() -> bool:
	return value


func set_bool_value(v: bool) -> void:
	set_value(v)

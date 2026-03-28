## Typed [UiState] for string payloads (labels, line edits, option item text).
class_name UiStringState
extends UiState

@export var value: String = ""


func _init(initial_value: Variant = "") -> void:
	if typeof(initial_value) != TYPE_NIL:
		value = str(initial_value)


func get_value() -> Variant:
	return value


func set_value(new_value: Variant) -> void:
	var v: String = "" if new_value == null else str(new_value)
	if value == v:
		return
	var old: String = value
	value = v
	value_changed.emit(v, old)
	emit_changed()


func set_silent(new_value: Variant) -> void:
	value = "" if new_value == null else str(new_value)
	emit_changed()


func get_string_value() -> String:
	return value


func set_string_value(v: String) -> void:
	set_value(v)

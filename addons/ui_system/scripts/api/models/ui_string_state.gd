## Optional typed [UiState] for string [member value] payloads (labels, line edits, option text).
class_name UiStringState
extends UiState

func _init(initial_value: Variant = "") -> void:
	super._init(initial_value)

func get_string_value() -> String:
	if value == null:
		return ""
	return str(value)

func set_string_value(v: String) -> void:
	set_value(v)

## Optional typed [UiState] for boolean [member value] payloads (toggles, pressed/disabled flags).
## Generic [UiState] remains fully supported; use this when you want clearer intent in the Inspector.
class_name UiBoolState
extends UiState

func _init(initial_value: Variant = false) -> void:
	super._init(initial_value)

func get_bool_value() -> bool:
	return bool(value)

func set_bool_value(v: bool) -> void:
	set_value(v)

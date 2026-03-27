## Optional typed [UiState] for [Array] [member value] payloads (tab lists, composite label text).
class_name UiArrayState
extends UiState

func _init(initial_value: Variant = null) -> void:
	if initial_value == null:
		super._init([])
	else:
		super._init(initial_value)

func get_array_value() -> Array:
	if value is Array:
		return value as Array
	return []

func set_array_value(v: Array) -> void:
	set_value(v)

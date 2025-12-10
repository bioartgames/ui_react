## Reactive value for String type.
@icon("res://icon.svg")
class_name ReactiveString
extends ReactiveValue

## Override to ensure type safety.
func _get_value() -> Variant:
	return _current_value as String

## Override to ensure type safety.
func _set_value(new_value: Variant) -> void:
	var string_value: String = ""
	if new_value != null:
		string_value = str(new_value)
	super._set_value(string_value)


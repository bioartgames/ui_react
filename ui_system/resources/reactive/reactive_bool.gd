## Reactive value for bool type.
@icon("res://icon.svg")
class_name ReactiveBool
extends ReactiveValue

## Override to ensure type safety.
func _get_value() -> Variant:
	if _current_value == null:
		return false
	return _current_value as bool

## Override to ensure type safety.
func _set_value(new_value: Variant) -> void:
	var bool_value: bool = false
	if new_value != null:
		if new_value is bool:
			bool_value = new_value as bool
		elif new_value is int:
			bool_value = (new_value as int) != 0
		elif new_value is float:
			bool_value = (new_value as float) != 0.0
		else:
			# Try to convert string to bool
			var str_value = str(new_value).to_lower()
			bool_value = str_value == "true" or str_value == "1" or str_value == "yes"
	super._set_value(bool_value)


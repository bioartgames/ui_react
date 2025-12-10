## Reactive value for int type.
@icon("res://icon.svg")
class_name ReactiveInt
extends ReactiveValue

## Override to ensure type safety.
func _get_value() -> Variant:
	return _current_value as int

## Override to ensure type safety.
func _set_value(new_value: Variant) -> void:
	var int_value: int = 0
	if new_value != null:
		if new_value is int:
			int_value = new_value as int
		elif new_value is float:
			int_value = int(new_value as float)
		else:
			# Try to convert string to int
			var str_value = str(new_value)
			if str_value.is_valid_int():
				int_value = str_value.to_int()
	super._set_value(int_value)


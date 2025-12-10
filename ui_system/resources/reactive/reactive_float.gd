## Reactive value for float type.
@icon("res://icon.svg")
class_name ReactiveFloat
extends ReactiveValue

## Override to ensure type safety.
func _get_value() -> Variant:
	return _current_value as float

## Override to ensure type safety.
func _set_value(new_value: Variant) -> void:
	var float_value: float = 0.0
	if new_value != null:
		if new_value is float:
			float_value = new_value as float
		elif new_value is int:
			float_value = float(new_value as int)
		else:
			# Try to convert string to float
			var str_value = str(new_value)
			if str_value.is_valid_float():
				float_value = str_value.to_float()
	super._set_value(float_value)


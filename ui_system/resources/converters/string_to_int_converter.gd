## Converts String to int.
@icon("res://icon.svg")
class_name StringToIntConverter
extends ValueConverter

## Converts a string value to an integer.
func convert(value: Variant) -> Variant:
	if value == null:
		return 0
	
	var str_value = str(value)
	if str_value.is_valid_int():
		return str_value.to_int()
	
	return 0


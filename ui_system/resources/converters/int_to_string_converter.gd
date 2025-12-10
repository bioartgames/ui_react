## Converts int to String.
@icon("res://icon.svg")
class_name IntToStringConverter
extends ValueConverter

## Converts an integer value to a string.
func convert(value: Variant) -> Variant:
	if value == null:
		return ""
	
	return str(value)


## Converts bool to text (String) with customizable true/false text.
@icon("res://icon.svg")
class_name BoolToTextConverter
extends ValueConverter

## Text to display when value is true.
@export var true_text: String = "Yes"

## Text to display when value is false.
@export var false_text: String = "No"

## Converts a boolean value to text.
func convert(value: Variant) -> Variant:
	if value == null:
		return false_text
	
	var bool_value = false
	if value is bool:
		bool_value = value as bool
	elif value is int:
		bool_value = (value as int) != 0
	elif value is float:
		bool_value = (value as float) != 0.0
	
	return true_text if bool_value else false_text


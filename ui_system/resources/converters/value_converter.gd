## Base abstract class for value converters.
## Converters transform values between ReactiveValue and Control property types.
@icon("res://icon.svg")
class_name ValueConverter
extends Resource

## Converts a value from one type to another.
## Must be implemented by subclasses.
func convert(value: Variant) -> Variant:
	return value


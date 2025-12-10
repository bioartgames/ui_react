## Base abstract class for text formatters.
## Formatters are specialized converters that always return String.
## Extends ValueConverter for unified system (can be used in bindings or text segments).
@icon("res://icon.svg")
class_name TextFormatter
extends ValueConverter

## Formats a value as a string.
## Must be implemented by subclasses.
func format(value: Variant) -> String:
	return str(value)

## Converts a value (always returns String for formatters).
## Calls format() internally to maintain unified system.
func convert(value: Variant) -> Variant:
	return format(value)


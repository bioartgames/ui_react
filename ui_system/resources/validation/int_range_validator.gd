## Validator for integer range constraints (min/max).
@icon("res://icon.svg")
class_name IntRangeValidator
extends Validator

## Minimum allowed value (inclusive).
@export var min_value: int = 0

## Maximum allowed value (inclusive).
@export var max_value: int = 100

## Validates that the value is an integer within the specified range.
func validate(value: Variant) -> ValidationResult:
	if value == null:
		return ValidationResult.invalid("Value cannot be null", "NULL_VALUE")
	
	var int_value: int = 0
	if value is int:
		int_value = value as int
	elif value is float:
		int_value = int(value as float)
	else:
		return ValidationResult.invalid("Value must be an integer", "INVALID_TYPE")
	
	if int_value < min_value:
		return ValidationResult.invalid("Value %d is less than minimum %d" % [int_value, min_value], "BELOW_MIN")
	
	if int_value > max_value:
		return ValidationResult.invalid("Value %d is greater than maximum %d" % [int_value, max_value], "ABOVE_MAX")
	
	return ValidationResult.valid()


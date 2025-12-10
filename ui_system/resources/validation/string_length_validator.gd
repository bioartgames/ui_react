## Validator for string length constraints.
@icon("res://icon.svg")
class_name StringLengthValidator
extends Validator

## Minimum allowed length (inclusive).
@export var min_length: int = 0

## Maximum allowed length (inclusive).
@export var max_length: int = 100

## Validates that the string length is within the specified range.
func validate(value: Variant) -> ValidationResult:
	if value == null:
		return ValidationResult.invalid("Value cannot be null", "NULL_VALUE")
	
	var str_value: String = str(value)
	var length: int = str_value.length()
	
	if length < min_length:
		return ValidationResult.invalid("String length %d is less than minimum %d" % [length, min_length], "BELOW_MIN_LENGTH")
	
	if length > max_length:
		return ValidationResult.invalid("String length %d is greater than maximum %d" % [length, max_length], "ABOVE_MAX_LENGTH")
	
	return ValidationResult.valid()


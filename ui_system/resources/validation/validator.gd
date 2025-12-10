## Base abstract class for validators.
## Validators enforce value constraints (min/max, length, format).
@icon("res://icon.svg")
class_name Validator
extends Resource

## Validates a value and returns a ValidationResult.
## Must be implemented by subclasses.
func validate(_value: Variant) -> ValidationResult:
	return ValidationResult.valid()


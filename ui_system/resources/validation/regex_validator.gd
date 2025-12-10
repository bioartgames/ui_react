## Validator for regex pattern matching.
@icon("res://icon.svg")
class_name RegexValidator
extends Validator

## Regex pattern to match against.
@export var pattern: String = ""

## Whether the pattern must match (true) or must not match (false).
@export var must_match: bool = true

## Validates that the string matches (or doesn't match) the regex pattern.
func validate(value: Variant) -> ValidationResult:
	if value == null:
		return ValidationResult.invalid("Value cannot be null", "NULL_VALUE")
	
	if pattern.is_empty():
		return ValidationResult.invalid("Pattern cannot be empty", "EMPTY_PATTERN")
	
	var str_value: String = str(value)
	var regex = RegEx.new()
	var error = regex.compile(pattern)
	
	if error != OK:
		return ValidationResult.invalid("Invalid regex pattern: %s" % pattern, "INVALID_PATTERN")
	
	var match_result = regex.search(str_value)
	var matches: bool = match_result != null
	
	if must_match and not matches:
		return ValidationResult.invalid("Value '%s' does not match pattern '%s'" % [str_value, pattern], "PATTERN_MISMATCH")
	
	if not must_match and matches:
		return ValidationResult.invalid("Value '%s' matches forbidden pattern '%s'" % [str_value, pattern], "FORBIDDEN_MATCH")
	
	return ValidationResult.valid()


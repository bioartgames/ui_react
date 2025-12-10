## Resource containing validation result information.
@icon("res://icon.svg")
class_name ValidationResult
extends Resource

## Whether validation passed.
@export var is_valid: bool = true

## Error message if validation failed.
@export var error_message: String = ""

## Error code for programmatic handling.
@export var error_code: String = ""

## Creates a valid result.
static func valid() -> ValidationResult:
	var result = ValidationResult.new()
	result.is_valid = true
	return result

## Creates an invalid result with error message and code.
static func invalid(message: String, code: String = "") -> ValidationResult:
	var result = ValidationResult.new()
	result.is_valid = false
	result.error_message = message
	result.error_code = code
	return result


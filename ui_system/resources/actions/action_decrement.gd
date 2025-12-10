## Action that decrements a numeric ReactiveValue.
@icon("res://icon.svg")
class_name ActionDecrement
extends ReactiveAction

## Validates that the target is a numeric type (ReactiveInt or ReactiveFloat).
func validate_before_execute(target: ReactiveValue, params: ActionParams) -> bool:
	if not super.validate_before_execute(target, params):
		return false
	
	if not (params is IncrementParams):  # Reuse IncrementParams for decrement (amount can be negative)
		return false
	
	# Check if target is numeric
	if not (target is ReactiveInt or target is ReactiveFloat):
		return false
	
	return true

## Decrements the target value by the amount specified in params.
func execute(target: ReactiveValue, params: ActionParams) -> bool:
	if not validate_before_execute(target, params):
		return false
	
	var increment_params = params as IncrementParams
	if increment_params == null:
		return false
	
	# Get current value and decrement (subtract amount)
	var current_value = target.value
	if current_value is int:
		var new_value = current_value as int - increment_params.amount
		target.set_value(new_value)
		return true
	elif current_value is float:
		var new_value = current_value as float - increment_params.amount
		target.set_value(new_value)
		return true
	
	return false


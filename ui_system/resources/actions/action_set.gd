## Action that sets a ReactiveValue to a specific value.
@icon("res://icon.svg")
class_name ActionSet
extends ReactiveAction

## Validates that params is SetParams.
func validate_before_execute(target: ReactiveValue, params: ActionParams) -> bool:
	if not super.validate_before_execute(target, params):
		return false
	
	if not (params is SetParams):
		return false
	
	return true

## Sets the target value to the value specified in params.
func execute(target: ReactiveValue, params: ActionParams) -> bool:
	if not validate_before_execute(target, params):
		return false
	
	var set_params = params as SetParams
	if set_params == null:
		return false
	
	target.set_value(set_params.value)
	return true


## Action that appends text to a ReactiveString.
@icon("res://icon.svg")
class_name ActionAppend
extends ReactiveAction

## Validates that the target is a ReactiveString.
func validate_before_execute(target: ReactiveValue, params: ActionParams) -> bool:
	if not super.validate_before_execute(target, params):
		return false
	
	if not (params is AppendParams):
		return false
	
	if not (target is ReactiveString):
		return false
	
	return true

## Appends text to the target ReactiveString.
func execute(target: ReactiveValue, params: ActionParams) -> bool:
	if not validate_before_execute(target, params):
		return false
	
	var append_params = params as AppendParams
	if append_params == null:
		return false
	
	var current_value = target.value as String
	var new_value = current_value + append_params.text
	target.set_value(new_value)
	return true


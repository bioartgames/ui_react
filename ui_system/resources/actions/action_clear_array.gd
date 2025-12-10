## Action that clears all items from a ReactiveArray.
@icon("res://icon.svg")
class_name ActionClearArray
extends ReactiveAction

## Validates that the target is a ReactiveArray.
func validate_before_execute(target: ReactiveValue, params: ActionParams) -> bool:
	if not super.validate_before_execute(target, params):
		return false
	
	if not (target is ReactiveArray):
		return false
	
	return true

## Clears all items from the target ReactiveArray.
func execute(target: ReactiveValue, params: ActionParams) -> bool:
	if not validate_before_execute(target, params):
		return false
	
	var reactive_array = target as ReactiveArray
	if reactive_array == null:
		return false
	
	reactive_array.clear()
	return true


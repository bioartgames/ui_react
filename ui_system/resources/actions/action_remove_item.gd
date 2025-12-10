## Action that removes an item from a ReactiveArray.
@icon("res://icon.svg")
class_name ActionRemoveItem
extends ReactiveAction

## Validates that the target is a ReactiveArray.
func validate_before_execute(target: ReactiveValue, params: ActionParams) -> bool:
	if not super.validate_before_execute(target, params):
		return false
	
	if not (params is RemoveItemParams):
		return false
	
	if not (target is ReactiveArray):
		return false
	
	var remove_params = params as RemoveItemParams
	if remove_params == null:
		return false
	
	var reactive_array = target as ReactiveArray
	if reactive_array == null:
		return false
	
	# Validate index is within bounds
	var arr = reactive_array.value as Array
	if remove_params.index < 0 or remove_params.index >= arr.size():
		return false
	
	return true

## Removes an item from the target ReactiveArray.
func execute(target: ReactiveValue, params: ActionParams) -> bool:
	if not validate_before_execute(target, params):
		return false
	
	var remove_params = params as RemoveItemParams
	if remove_params == null:
		return false
	
	var reactive_array = target as ReactiveArray
	if reactive_array == null:
		return false
	
	reactive_array.remove_item(remove_params.index)
	return true


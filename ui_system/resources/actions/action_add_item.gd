## Action that adds an item to a ReactiveArray.
@icon("res://icon.svg")
class_name ActionAddItem
extends ReactiveAction

## Validates that the target is a ReactiveArray.
func validate_before_execute(target: ReactiveValue, params: ActionParams) -> bool:
	if not super.validate_before_execute(target, params):
		return false
	
	if not (params is AddItemParams):
		return false
	
	if not (target is ReactiveArray):
		return false
	
	return true

## Adds an item to the target ReactiveArray.
func execute(target: ReactiveValue, params: ActionParams) -> bool:
	if not validate_before_execute(target, params):
		return false
	
	var add_params = params as AddItemParams
	if add_params == null:
		return false
	
	var reactive_array = target as ReactiveArray
	if reactive_array == null:
		return false
	
	# If index is -1 or equals array size, append to end
	var arr = reactive_array.value as Array
	if add_params.index == -1 or add_params.index >= arr.size():
		reactive_array.add_item(add_params.item)
	else:
		# Insert at specific index
		if add_params.index < 0:
			return false
		
		arr.insert(add_params.index, add_params.item)
		# Trigger array signals manually since we're modifying directly
		reactive_array.item_added.emit(add_params.index, add_params.item)
		reactive_array.array_changed.emit()
		reactive_array._batch_update()
	
	return true


## Action that moves/reorders an item in a ReactiveArray.
@icon("res://icon.svg")
class_name ActionMoveItem
extends ReactiveAction

## Validates that the target is a ReactiveArray and indices are valid.
func validate_before_execute(target: ReactiveValue, params: ActionParams) -> bool:
	if not super.validate_before_execute(target, params):
		return false
	
	if not (params is MoveItemParams):
		return false
	
	if not (target is ReactiveArray):
		return false
	
	var move_params = params as MoveItemParams
	if move_params == null:
		return false
	
	var reactive_array = target as ReactiveArray
	if reactive_array == null:
		return false
	
	var arr = reactive_array.value as Array
	
	# Validate indices are within bounds
	if move_params.from_index < 0 or move_params.from_index >= arr.size():
		return false
	if move_params.to_index < 0 or move_params.to_index >= arr.size():
		return false
	
	return true

## Moves an item from one index to another in the target ReactiveArray.
func execute(target: ReactiveValue, params: ActionParams) -> bool:
	if not validate_before_execute(target, params):
		return false
	
	var move_params = params as MoveItemParams
	if move_params == null:
		return false
	
	var reactive_array = target as ReactiveArray
	if reactive_array == null:
		return false
	
	var arr = reactive_array.value as Array
	
	# If indices are the same, nothing to do
	if move_params.from_index == move_params.to_index:
		return true
	
	# Get the item to move
	var item = arr[move_params.from_index]
	
	# Remove from source index
	arr.remove_at(move_params.from_index)
	
	# Calculate new destination index (may have shifted due to removal)
	var new_to_index = move_params.to_index
	if move_params.to_index > move_params.from_index:
		new_to_index = move_params.to_index - 1
	
	# Insert at destination index
	arr.insert(new_to_index, item)
	
	# Trigger array signals manually
	reactive_array.item_removed.emit(move_params.from_index)
	reactive_array.item_added.emit(new_to_index, item)
	reactive_array.array_changed.emit()
	reactive_array._batch_update()
	
	return true


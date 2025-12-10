## Action that swaps two items in a ReactiveArray.
@icon("res://icon.svg")
class_name ActionSwapItems
extends ReactiveAction

## Validates that the target is a ReactiveArray and indices are valid.
func validate_before_execute(target: ReactiveValue, params: ActionParams) -> bool:
	if not super.validate_before_execute(target, params):
		return false
	
	if not (params is SwapItemsParams):
		return false
	
	if not (target is ReactiveArray):
		return false
	
	var swap_params = params as SwapItemsParams
	if swap_params == null:
		return false
	
	var reactive_array = target as ReactiveArray
	if reactive_array == null:
		return false
	
	var arr = reactive_array.value as Array
	
	# Validate indices are within bounds
	if swap_params.index1 < 0 or swap_params.index1 >= arr.size():
		return false
	if swap_params.index2 < 0 or swap_params.index2 >= arr.size():
		return false
	
	return true

## Swaps two items in the target ReactiveArray.
func execute(target: ReactiveValue, params: ActionParams) -> bool:
	if not validate_before_execute(target, params):
		return false
	
	var swap_params = params as SwapItemsParams
	if swap_params == null:
		return false
	
	var reactive_array = target as ReactiveArray
	if reactive_array == null:
		return false
	
	var arr = reactive_array.value as Array
	
	# If indices are the same, nothing to do
	if swap_params.index1 == swap_params.index2:
		return true
	
	# Swap the items
	var temp = arr[swap_params.index1]
	arr[swap_params.index1] = arr[swap_params.index2]
	arr[swap_params.index2] = temp
	
	# Trigger array signals manually
	var old_value1 = arr[swap_params.index2]
	var old_value2 = arr[swap_params.index1]
	reactive_array.item_changed.emit(swap_params.index1, arr[swap_params.index1], old_value1)
	reactive_array.item_changed.emit(swap_params.index2, arr[swap_params.index2], old_value2)
	reactive_array.array_changed.emit()
	reactive_array._batch_update()
	
	return true


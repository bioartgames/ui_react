## Reactive value for Array type.
## Supports both primitive arrays and arrays of ReactiveObjects.
@icon("res://icon.svg")
class_name ReactiveArray
extends ReactiveValue

## Signal emitted when an item is added to the array.
signal item_added(index: int, item: Variant)

## Signal emitted when an item is removed from the array.
signal item_removed(index: int)

## Signal emitted when an item in the array changes.
signal item_changed(index: int, new_value: Variant, old_value: Variant)

## Signal emitted when the array structure changes (add/remove/clear).
signal array_changed()

## Override to return the array value.
func _get_value() -> Variant:
	if _current_value == null:
		_current_value = []
	return _current_value as Array

## Override to set the array value.
func _set_value(new_value: Variant) -> void:
	var array_value: Array = []
	if new_value != null:
		if new_value is Array:
			array_value = new_value.duplicate()  # Make a copy to avoid external modifications
		else:
			# Try to convert to array
			array_value = [new_value]
	super._set_value(array_value)

## Adds an item to the end of the array.
func add_item(item: Variant) -> void:
	var arr = _get_value()
	var index = arr.size()
	arr.append(item)
	item_added.emit(index, item)
	array_changed.emit()
	# Trigger value_changed signal
	_batch_update()

## Removes an item at the specified index.
func remove_item(index: int) -> void:
	var arr = _get_value()
	if index < 0 or index >= arr.size():
		return
	
	arr.remove_at(index)
	item_removed.emit(index)
	array_changed.emit()
	# Trigger value_changed signal
	_batch_update()

## Gets an item at the specified index.
func get_item(index: int) -> Variant:
	var arr = _get_value()
	if index < 0 or index >= arr.size():
		return null
	return arr[index]

## Sets an item at the specified index.
func set_item(index: int, value: Variant) -> void:
	var arr = _get_value()
	if index < 0 or index >= arr.size():
		return
	
	var old_value = arr[index]
	arr[index] = value
	item_changed.emit(index, value, old_value)
	array_changed.emit()
	# Trigger value_changed signal
	_batch_update()

## Clears all items from the array.
func clear() -> void:
	var arr = _get_value()
	var old_size = arr.size()
	arr.clear()
	if old_size > 0:
		array_changed.emit()
		# Trigger value_changed signal
		_batch_update()

## Returns the size of the array.
func size() -> int:
	return _get_value().size()

## Gets a reactive value for an item property.
## For ReactiveObject items, returns the reactive property.
## For primitive items, returns null (primitives cannot provide reactive access).
func get_item_reactive_value(index: int, property_path: String) -> ReactiveValue:
	var item = get_item(index)
	if item == null:
		return null
	
	# If item is a ReactiveObject, get its reactive property
	if item is ReactiveObject:
		return (item as ReactiveObject).get_property_reactive(property_path)
	
	# Primitives cannot provide reactive access
	return null


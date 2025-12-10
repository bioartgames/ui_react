## Reactive value for complex object type (Dictionary-based).
## Properties can be ReactiveValues for nested reactivity.
@icon("res://icon.svg")
class_name ReactiveObject
extends ReactiveValue

## Signal emitted when a property changes.
signal property_changed(property_name: String, new_value: Variant, old_value: Variant)

## Signal emitted when the object structure changes.
signal object_changed()

## Override to return the dictionary value.
func _get_value() -> Variant:
	if _current_value == null:
		_current_value = {}
	return _current_value as Dictionary

## Override to set the dictionary value.
func _set_value(new_value: Variant) -> void:
	var dict_value: Dictionary = {}
	if new_value != null:
		if new_value is Dictionary:
			dict_value = new_value.duplicate()  # Make a copy to avoid external modifications
		else:
			# Try to convert to dictionary
			dict_value = {"value": new_value}
	super._set_value(dict_value)

## Gets a property value by name.
func get_property(name: String) -> Variant:
	var dict = _get_value()
	if not dict.has(name):
		return null
	return dict[name]

## Sets a property value by name.
func set_property(name: String, new_value: Variant) -> void:
	var dict = _get_value()
	var old_value = null
	if dict.has(name):
		old_value = dict[name]
	
	dict[name] = value
	property_changed.emit(name, value, old_value)
	object_changed.emit()
	# Trigger value_changed signal
	_batch_update()

## Gets a reactive value for a property.
## Returns the ReactiveValue if the property is a ReactiveValue, null otherwise.
func get_property_reactive(name: String) -> ReactiveValue:
	var property = get_property(name)
	if property is ReactiveValue:
		return property as ReactiveValue
	return null


## Reactive value for holding references to ReactiveValue or ReactiveObject.
## Used for sharing selection state between components.
@icon("res://icon.svg")
class_name ReactiveReference
extends ReactiveValue

## Signal emitted when the reference changes.
signal reference_changed(new_reference: ReactiveValue, old_reference: ReactiveValue)

## Override to return the referenced ReactiveValue.
func _get_value() -> Variant:
	return _current_value

## Override to set the reference.
func _set_value(new_value: Variant) -> void:
	var old_reference = _current_value
	
	# Validate that new_value is a ReactiveValue or ReactiveObject (or null)
	if new_value != null and not (new_value is ReactiveValue or new_value is ReactiveObject):
		# Invalid type - don't set
		return
	
	# Store old value if tracking is enabled
	if track_old_value:
		_previous_value = _current_value
	
	# Store the new reference
	_current_value = new_value
	
	# Emit reference_changed signal
	if old_reference != new_value:
		reference_changed.emit(new_value as ReactiveValue, old_reference as ReactiveValue)
	
	# Batch the update (will emit value_changed signal)
	_batch_update()

## Sets the reference programmatically.
func set_reference(ref: ReactiveValue) -> void:
	value = ref

## Gets the current reference.
func get_reference() -> ReactiveValue:
	return _current_value as ReactiveValue


## Base abstract class for reactive value resources.
## Provides signal emission, validation, versioning, and update batching.
## This class should not be instantiated directly - use subclasses like ReactiveString, ReactiveInt, etc.
@icon("res://icon.svg")
class_name ReactiveValue
extends Resource

## Expected version for this resource type. Subclasses can override.
const EXPECTED_VERSION: int = 1

## Signal emitted when value changes. Includes both new and old values.
signal value_changed(new_value: Variant, old_value: Variant)

## Signal emitted when validation fails.
signal validation_failed(result: ValidationResult)

## Current version of this resource. Used for migration support.
@export var version: int = 1

## Default value for this reactive value.
@export var default_value: Variant = null

## Whether to track old values. Can be disabled for large values to save memory.
@export var track_old_value: bool = true

## Array of validators to apply when setting values.
@export var validators: Array[Validator] = []

## Current value. Must be overridden by subclasses.
var value: Variant:
	get:
		return _get_value()
	set(v):
		_set_value(v)

## Internal storage for the current value.
var _current_value: Variant = null

## Previous value (tracked if track_old_value is true).
var _previous_value: Variant = null

## Flag to track if we have a pending batched update.
var _has_pending_update: bool = false

## The value to emit in the batched update.
var _batched_value: Variant = null

## The old value to emit in the batched update.
var _batched_old_value: Variant = null

## Abstract method to get the value. Must be implemented by subclasses.
func _get_value() -> Variant:
	return _current_value

## Abstract method to set the value. Must be implemented by subclasses.
func _set_value(new_value: Variant) -> void:
	# Store old value if tracking is enabled
	if track_old_value:
		_previous_value = _current_value
	
	# Validate before setting
	if not _validate_value(new_value):
		return
	
	# Store the new value
	_current_value = new_value
	
	# Batch the update
	_batch_update()

## Validates a value using all registered validators.
func _validate_value(value_to_validate: Variant) -> bool:
	if validators.is_empty():
		return true
	
	for validator in validators:
		if validator == null:
			continue
		
		var result: ValidationResult = validator.validate(value_to_validate)
		if not result.is_valid:
			validation_failed.emit(result)
			return false
	
	return true

## Batches rapid consecutive updates within the same frame.
func _batch_update() -> void:
	# Store the value for batched emission
	_batched_value = _current_value
	_batched_old_value = _previous_value
	
	# If we already have a pending update, just update the batched value
	if _has_pending_update:
		return
	
	# Schedule deferred emission
	_has_pending_update = true
	call_deferred("_emit_batched_signal")

## Emits the batched signal with the final value.
func _emit_batched_signal() -> void:
	if not _has_pending_update:
		return
	
	_has_pending_update = false
	
	# Emit with the final batched value
	value_changed.emit(_batched_value, _batched_old_value)
	
	# Clear batched values
	_batched_value = null
	_batched_old_value = null

## Resets the value to the default value.
func reset_to_default() -> void:
	value = default_value

## Gets the previous value (if tracking is enabled).
func get_old_value() -> Variant:
	return _previous_value

## Called when resource is loaded. Handles version migration.
func _init() -> void:
	# Initialize with default value if not already set
	if _current_value == null:
		_current_value = default_value
	
	# Check for version migration (only if version differs from expected)
	if version != EXPECTED_VERSION and version < EXPECTED_VERSION:
		_migrate_from_version(version)

## Override this method in subclasses to handle version migrations.
## Called automatically when a resource with a different version is loaded.
func _migrate_from_version(_old_version: int) -> void:
	# Base implementation does nothing
	# Subclasses should override to handle version-specific migrations
	pass

## Sets the value programmatically (public API).
func set_value(new_value: Variant) -> void:
	value = new_value


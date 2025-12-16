## Helper object for managing reactive control state and state change handlers.
## Uses composition pattern to avoid inheritance conflicts with Godot control inheritance.
## Provides centralized state management for reactive controls to prevent infinite update loops
## and ensure proper initialization sequencing.
##
## This class is specifically designed for the reactive control system and handles:
## - Property update synchronization to prevent infinite loops
## - Initialization state tracking
## - Type-safe property updates with conversion functions
class_name ReactiveControlHelper

## Reference to the control this helper manages.
var _owner: Control
## Flag indicating if a property update is currently in progress (prevents infinite loops).
var _updating: bool = false
## Flag indicating if the control is still in its initialization phase.
var _is_initializing: bool = true

## Creates a new ReactiveControlHelper for the specified control.
## [param owner]: The Control node this helper will manage.
func _init(owner: Control) -> void:
	_owner = owner

## Updates a control property if the new value differs from the current value.
## This method handles the _updating flag to prevent infinite update loops between
## control changes and state changes. It uses a converter function to ensure type safety.
##
## [param property]: String name of the property to update (e.g., "button_pressed", "text", "value").
## [param new_value]: The new value from the State (typically a Variant).
## [param converter]: Callable that converts the Variant to the appropriate property type
##                   (e.g., func(x): return bool(x) for boolean properties).
## [return]: true if the property was updated, false if no change was needed or an update was already in progress.
func update_property_if_changed(
	property: String,
	new_value: Variant,
	converter: Callable
) -> bool:
	if _updating:
		return false

	var desired = converter.call(new_value)
	var current = _owner.get(property)

	if current == desired:
		return false

	_updating = true
	_owner.set(property, desired)
	_updating = false
	return true

## Checks if a property update is currently in progress.
## This is useful for state change handlers to avoid triggering updates during ongoing updates.
## [return]: true if an update is in progress, false otherwise.
func is_updating() -> bool:
	return _updating

## Manually sets the updating flag.
## This should generally not be needed as update_property_if_changed() manages this automatically,
## but can be useful for complex multi-step updates.
## [param value]: The new value for the updating flag.
func set_updating(value: bool) -> void:
	_updating = value

## Marks the initialization phase as complete.
## This should be called after all initial state synchronization is done to allow
## normal state change handling to begin. State changes that occur during initialization
## are ignored to prevent unwanted animations or side effects.
func finish_initialization() -> void:
	_is_initializing = false

## Checks if the control is still in its initialization phase.
## During initialization, state change handlers should ignore updates to prevent
## unwanted animations or side effects from the initial setup.
## [return]: true if still initializing, false if initialization is complete.
func is_initializing() -> bool:
	return _is_initializing

## Helper object for managing reactive control state and state change handlers.
## Uses composition pattern to avoid inheritance conflicts with Godot control inheritance.
## Provides centralized state management for reactive controls to prevent infinite update loops
## and ensure proper initialization sequencing.
##
## This class is specifically designed for the reactive control system and handles:
## - Property update synchronization to prevent infinite loops
## - Initialization state tracking
## - Type-safe property updates with conversion functions
## - Syncing focus_mode so disabled controls are not focusable
class_name ReactiveControlHelper

## Storage for focus_mode when using static sync (instance_id -> focus_mode).
static var _stored_focus_modes: Dictionary = {}

## Reference to the control this helper manages.
var _owner: Control
## Flag indicating if a property update is currently in progress (prevents infinite loops).
var _updating: bool = false
## Flag indicating if the control is still in its initialization phase.
var _is_initializing: bool = true
## Stored focus_mode when the control was last enabled (-1 means not stored).
var _focus_mode_when_enabled: int = -1

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

## Syncs the owner's focus_mode to its disabled state: when disabled, sets focus_mode to
## FOCUS_NONE so the control cannot be focused; when enabled, restores the previous focus_mode.
## Call this after updating the owner's disabled property (e.g. from disabled_state).
func sync_focus_mode_to_disabled() -> void:
	if _owner.disabled:
		if _focus_mode_when_enabled == -1:
			_focus_mode_when_enabled = _owner.focus_mode
		_owner.focus_mode = Control.FOCUS_NONE
	else:
		if _focus_mode_when_enabled != -1:
			_owner.focus_mode = _focus_mode_when_enabled as Control.FocusMode
			_focus_mode_when_enabled = -1
		else:
			_owner.focus_mode = Control.FOCUS_ALL

## Static variant: syncs [param control]'s focus_mode to its disabled state.
## Use for controls that do not have a ReactiveControlHelper instance (e.g. ReactiveCheckBox, ReactiveOptionButton).
## Call after setting the control's disabled property.
static func sync_focus_mode_to_disabled_static(control: Control) -> void:
	var id = control.get_instance_id()
	if control.disabled:
		if not _stored_focus_modes.has(id):
			_stored_focus_modes[id] = control.focus_mode
		control.focus_mode = Control.FOCUS_NONE
	else:
		if _stored_focus_modes.has(id):
			control.focus_mode = _stored_focus_modes[id] as Control.FocusMode
			_stored_focus_modes.erase(id)
		else:
			control.focus_mode = Control.FOCUS_ALL

## Removes stored focus_mode for [param control] from the static cache.
## Call from _exit_tree for controls that use sync_focus_mode_to_disabled_static, so freed nodes do not leak entries.
static func release_stored_focus_mode(control: Control) -> void:
	_stored_focus_modes.erase(control.get_instance_id())

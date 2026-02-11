## Static utility for handling focus-driven hover animations.
##
## Provides centralized logic for triggering hover animations when focus changes
## via keyboard/gamepad navigation (not mouse). Uses static state tracking to avoid
## requiring meta flags on controls or a navigator node in the scene tree.
##
## Usage:
##   - Components call handle_focus_entered/exited from their focus signal handlers
##   - External code (e.g. input handlers) calls mark_focus_driven() before moving focus
extends RefCounted
class_name FocusDrivenHover

## Static dictionary tracking which controls have focus-driven hover active.
## Key: control instance_id, Value: bool (true if active)
static var _active_hover_controls: Dictionary = {}

## Static dictionary tracking which controls should trigger hover on next focus enter.
## Key: control instance_id, Value: bool (true if marked)
static var _marked_for_focus_driven: Dictionary = {}

## Marks a control as having focus moved to it via keyboard/gamepad navigation.
## Call this BEFORE moving focus (e.g. in _unhandled_input or before grab_focus()).
## [param control]: The control that will receive focus via navigation.
static func mark_focus_driven(control: Control) -> void:
	if not control:
		return
	_marked_for_focus_driven[control.get_instance_id()] = true

## Handles focus enter event, triggering hover animations if focus was driven.
## [param control]: The control that received focus.
## [param animations]: Array of AnimationReel to check for HOVER_ENTER triggers.
## [param skip_animations]: Callable that returns true if animations should be skipped (e.g. during init).
static func handle_focus_entered(
	control: Control,
	animations: Array[AnimationReel],
	skip_animations: Callable
) -> void:
	if not control or skip_animations.call():
		return
	
	var instance_id: int = control.get_instance_id()
	
	# Check if this focus change was caused by navigation
	if _marked_for_focus_driven.has(instance_id):
		# Remove the mark immediately
		_marked_for_focus_driven.erase(instance_id)
		# Mark that navigation hover is active
		_active_hover_controls[instance_id] = true
		# Trigger hover enter animation
		AnimationReel.trigger_matching(control, animations, AnimationReel.Trigger.HOVER_ENTER)

## Handles focus exit event, triggering hover animations if navigation hover was active.
## [param control]: The control that lost focus.
## [param animations]: Array of AnimationReel to check for HOVER_EXIT triggers.
## [param skip_animations]: Callable that returns true if animations should be skipped (e.g. during init).
static func handle_focus_exited(
	control: Control,
	animations: Array[AnimationReel],
	skip_animations: Callable
) -> void:
	if not control or skip_animations.call():
		return
	
	var instance_id: int = control.get_instance_id()
	
	# Check if navigation hover was active
	if _active_hover_controls.has(instance_id):
		# Clear the active flag
		_active_hover_controls.erase(instance_id)
		# Trigger hover exit animation
		AnimationReel.trigger_matching(control, animations, AnimationReel.Trigger.HOVER_EXIT)

## Cleans up state for a control when it's freed (prevents memory leaks).
## Call from _exit_tree in reactive components that use focus-driven hover.
## [param control]: The control being freed.
static func cleanup(control: Control) -> void:
	if not control:
		return
	var instance_id: int = control.get_instance_id()
	_marked_for_focus_driven.erase(instance_id)
	_active_hover_controls.erase(instance_id)

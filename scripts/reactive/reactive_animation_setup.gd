## Static utility for setting up animation reels and signal connections in reactive controls.
##
## Provides centralized logic for validating animation reels, setting control type context,
## and connecting trigger signals to reduce code duplication across reactive controls.
## Uses composition pattern - controls call into this utility rather than inheriting from it.
extends RefCounted
class_name ReactiveAnimationSetup

## Sets up animation reels for a control: validates, filters invalid ones, and sets control type context.
## [param control]: The reactive control instance.
## [param animations]: Array of AnimationReel (will be modified in place with valid reels).
## [param control_type_hint]: The control type hint for filtering triggers in Inspector.
## [return]: Dictionary with "trigger_map" key mapping trigger types to boolean (which triggers are used).
static func setup_reels(
	control: Control,
	animations: Array,
	control_type_hint: AnimationReel.ControlTypeHint
) -> Dictionary:
	var result = AnimationReel.validate_for_control(control, animations)
	
	# Assign valid reels back to the animations array (arrays are by reference in GDScript)
	animations.clear()
	animations.append_array(result.valid_reels)
	
	# Set control context on each reel for Inspector filtering
	for reel in animations:
		if reel:
			reel.control_type_context = control_type_hint
	
	return result.trigger_map

## Connects trigger signals to callbacks based on which triggers are used.
## [param _control]: The reactive control instance (unused, kept for API consistency).
## [param trigger_map]: Dictionary mapping trigger types to boolean (from setup_reels).
## [param bindings]: Array of 3-element arrays: [AnimationReel.Trigger trigger, Signal signal, Callable callback].
##   Example: [[AnimationReel.Trigger.PRESSED, control.pressed, callable(self, "_on_trigger_pressed")]]
static func connect_trigger_bindings(
	_control: Control,
	trigger_map: Dictionary,
	bindings: Array
) -> void:
	for binding in bindings:
		if binding.size() < 3:
			continue
		
		var trigger: AnimationReel.Trigger = binding[0]
		var signal_obj: Signal = binding[1]
		var callback: Callable = binding[2]
		
		# Only connect if this trigger is used in any reel
		if trigger_map.get(trigger, false):
			if not signal_obj.is_connected(callback):
				signal_obj.connect(callback)

## Connects focus-driven hover animations (keyboard/gamepad navigation hover).
## [param control]: The reactive control instance.
## [param animations]: Array of AnimationReel to check for hover triggers.
## [param skip_animations]: Callable that returns true if animations should be skipped (e.g. during init).
static func connect_focus_driven_hover(
	control: Control,
	animations: Array,
	skip_animations: Callable
) -> void:
	# Check if any animations use hover triggers
	var has_hover_triggers = false
	for reel in animations:
		if reel and (reel.trigger == AnimationReel.Trigger.HOVER_ENTER or reel.trigger == AnimationReel.Trigger.HOVER_EXIT):
			has_hover_triggers = true
			break
	
	if not has_hover_triggers:
		return
	
	# Create handlers once and reuse them
	var focus_entered_handler = func():
		FocusDrivenHover.handle_focus_entered(control, animations, skip_animations)
	
	var focus_exited_handler = func():
		FocusDrivenHover.handle_focus_exited(control, animations, skip_animations)
	
	# Connect focus signals for navigation-driven hover animations
	if not control.focus_entered.is_connected(focus_entered_handler):
		control.focus_entered.connect(focus_entered_handler)
	
	if not control.focus_exited.is_connected(focus_exited_handler):
		control.focus_exited.connect(focus_exited_handler)

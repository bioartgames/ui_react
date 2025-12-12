## Action configuration for executing animations in parallel on controls.
##
## Users create this resource and assign it to ControlTargetConfig.action
## when they want to trigger multiple animations simultaneously from buttons or other triggers.
##
## Example:
## [codeblock]
## var config = AnimationParallelActionConfig.new()
## config.target = NodePath("../AnimationTarget")
## config.animations = [slide_config, fade_config, scale_config]
## [/codeblock]
class_name AnimationParallelActionConfig
extends ActionConfig

## Array of AnimationActionConfig resources that define the parallel animations.
## All animations will be executed simultaneously.
@export var animations: Array[AnimationActionConfig] = []

## Path to the control to animate (relative to owner).
## Drag and drop a node here in the Inspector (NodePath supports drag-and-drop), or set manually.
@export var target: NodePath = NodePath()

## Initial state setup before animations start (Dictionary of property: value pairs).
## Common properties: "scale", "modulate", "visible", "position", etc.
## Example: {"scale": Vector2.ZERO, "modulate": Color(1, 1, 1, 0), "visible": true}
@export var initial_setup: Dictionary = {}

## Applies this action by executing all animations in parallel.
## [param owner]: The node that owns the target config (used to resolve target paths and execute animations).
## [param _target]: The control component (unused, we use target instead).
## [param is_on]: Optional boolean state (unused for parallel animations).
## Returns true if the animations were started successfully, false otherwise.
func apply(owner: Node, _target: Control, _is_on: bool = true) -> bool:
	var control = _resolve_target(owner)
	if not control:
		push_warning("AnimationParallelActionConfig: Target control not found. Check target (NodePath) in the Inspector. Tip: Drag a node to target.")
		return false
	
	# Apply initial setup if provided
	for property in initial_setup:
		# Check if the control has this property by checking the property list
		var has_property = false
		for prop_info in control.get_property_list():
			if prop_info.name == property:
				has_property = true
				break
		
		if has_property:
			control.set(property, initial_setup[property])
		else:
			# Property doesn't exist, skip it (or could push_warning if needed)
			push_warning("AnimationParallelActionConfig: Control '%s' does not have property '%s'" % [control.name, property])
	
	# Execute animations in parallel asynchronously
	_execute_parallel_async(owner, control)
	return true

## Executes the animations in parallel asynchronously.
## Creates a helper node to handle the async execution since Resources can't use await.
## [param owner]: The node that owns the animations (for creating tweens).
## [param control]: The control to animate.
func _execute_parallel_async(owner: Node, control: Control) -> void:
	if animations.size() == 0:
		return
	
	# Start all animations simultaneously
	var signals: Array[Signal] = []
	for anim_config in animations:
		if anim_config != null:
			var signal_result = _create_animation_callable(owner, control, anim_config)
			if signal_result is Signal:
				signals.append(signal_result)
	
	# Wait for all animations to complete
	if signals.size() > 0:
		var helper = _ParallelAnimationHelper.new()
		owner.add_child(helper)
		helper.wait_for_all(signals)

## Helper node class for executing parallel animations asynchronously.
## This is needed because Resources can't use await directly.
class _ParallelAnimationHelper extends Node:
	func wait_for_all(signals: Array[Signal]) -> void:
		for signal_item in signals:
			await signal_item
		queue_free()

## Creates a callable that executes a single animation action config.
## [param owner]: The node that owns the animations.
## [param control]: The control to animate.
## [param anim_config]: The AnimationActionConfig to execute.
## Returns a Signal that can be awaited.
func _create_animation_callable(owner: Node, control: Control, anim_config: AnimationActionConfig) -> Signal:
	# Get the animation parameters from the config
	var action = anim_config.action
	var duration = anim_config.duration
	var repeat_count = anim_config.repeat_count
	var flash_color = anim_config.flash_color
	var reverse = anim_config.reverse if anim_config is AnimationActionConfig else false
	
	# Call the appropriate animation based on action type
	# This matches the logic in AnimationActionConfig.apply()
	match action:
		AnimationActionConfig.AnimationAction.EXPAND:
			if reverse:
				return UIAnimationUtils.animate_shrink(owner, control, duration, Vector2(-1, -1), true, true, true, repeat_count)
			else:
				return UIAnimationUtils.animate_expand(owner, control, duration, Vector2(-1, -1), true, false, false, repeat_count)
		AnimationActionConfig.AnimationAction.EXPAND_X:
			if reverse:
				return UIAnimationUtils.animate_shrink_x(owner, control, duration, Vector2(-1, -1), true, true, true, repeat_count)
			else:
				return UIAnimationUtils.animate_expand_x(owner, control, duration, Vector2(-1, -1), true, repeat_count)
		AnimationActionConfig.AnimationAction.EXPAND_Y:
			if reverse:
				return UIAnimationUtils.animate_shrink_y(owner, control, duration, Vector2(-1, -1), true, true, true, repeat_count)
			else:
				return UIAnimationUtils.animate_expand_y(owner, control, duration, Vector2(-1, -1), true, repeat_count)
		AnimationActionConfig.AnimationAction.FADE_IN:
			if reverse:
				return UIAnimationUtils.animate_fade_out(owner, control, duration, true, true, repeat_count)
			else:
				return UIAnimationUtils.animate_fade_in(owner, control, duration, true, repeat_count)
		AnimationActionConfig.AnimationAction.SLIDE_FROM_LEFT:
			if reverse:
				return UIAnimationUtils.animate_slide_to_left(owner, control, 8.0, duration, true, repeat_count)
			else:
				return UIAnimationUtils.animate_slide_from_left(owner, control, 8.0, duration, true, repeat_count)
		AnimationActionConfig.AnimationAction.SLIDE_FROM_RIGHT:
			if reverse:
				return UIAnimationUtils.animate_slide_to_right(owner, control, 8.0, duration, true, repeat_count)
			else:
				return UIAnimationUtils.animate_slide_from_right(owner, control, 8.0, duration, true, repeat_count)
		AnimationActionConfig.AnimationAction.SLIDE_FROM_TOP:
			if reverse:
				return UIAnimationUtils.animate_slide_to_top(owner, control, duration, true, repeat_count)
			else:
				return UIAnimationUtils.animate_slide_from_top(owner, control, 8.0, duration, true, repeat_count)
		AnimationActionConfig.AnimationAction.SLIDE_FROM_BOTTOM:
			if reverse:
				return UIAnimationUtils.animate_slide_to_bottom(owner, control, duration, true, repeat_count)
			else:
				return UIAnimationUtils.animate_slide_from_bottom(owner, control, 8.0, duration, true, repeat_count)
		AnimationActionConfig.AnimationAction.FROM_LEFT_TO_CENTER:
			if reverse:
				return UIAnimationUtils.animate_from_center_to_left(owner, control, duration, true, repeat_count)
			else:
				return UIAnimationUtils.animate_from_left_to_center(owner, control, duration, true, repeat_count)
		AnimationActionConfig.AnimationAction.FROM_RIGHT_TO_CENTER:
			if reverse:
				return UIAnimationUtils.animate_from_center_to_right(owner, control, duration, true, repeat_count)
			else:
				return UIAnimationUtils.animate_from_right_to_center(owner, control, duration, true, repeat_count)
		AnimationActionConfig.AnimationAction.FROM_TOP_TO_CENTER:
			if reverse:
				return UIAnimationUtils.animate_from_center_to_top(owner, control, duration, true, repeat_count)
			else:
				return UIAnimationUtils.animate_from_top_to_center(owner, control, duration, true, repeat_count)
		AnimationActionConfig.AnimationAction.FROM_BOTTOM_TO_CENTER:
			if reverse:
				return UIAnimationUtils.animate_from_center_to_bottom(owner, control, duration, true, repeat_count)
			else:
				return UIAnimationUtils.animate_from_bottom_to_center(owner, control, duration, true, repeat_count)
		AnimationActionConfig.AnimationAction.BOUNCE_IN:
			if reverse:
				return UIAnimationUtils.animate_bounce_out(owner, control, duration, Vector2(-1, -1), true, true, true, repeat_count)
			else:
				return UIAnimationUtils.animate_bounce_in(owner, control, duration, Vector2(-1, -1), true, repeat_count)
		AnimationActionConfig.AnimationAction.ELASTIC_IN:
			if reverse:
				return UIAnimationUtils.animate_elastic_out(owner, control, duration, Vector2(-1, -1), true, true, true, repeat_count)
			else:
				return UIAnimationUtils.animate_elastic_in(owner, control, duration, Vector2(-1, -1), true, repeat_count)
		AnimationActionConfig.AnimationAction.ROTATE_IN:
			var rotate_start_angle = anim_config.rotate_start_angle if anim_config is AnimationActionConfig else -360.0
			if reverse:
				return UIAnimationUtils.animate_rotate_out(owner, control, duration, 360.0, true, true, true, repeat_count)
			else:
				return UIAnimationUtils.animate_rotate_in(owner, control, duration, rotate_start_angle, Vector2(-1, -1), true, repeat_count)
		AnimationActionConfig.AnimationAction.POP:
			var pop_overshoot = anim_config.pop_overshoot if anim_config is AnimationActionConfig else 1.2
			return UIAnimationUtils.animate_pop(owner, control, duration, pop_overshoot, Vector2(-1, -1), true, repeat_count)
		AnimationActionConfig.AnimationAction.PULSE:
			var pulse_amount = anim_config.pulse_amount if anim_config is AnimationActionConfig else 1.1
			var pulse_count = anim_config.pulse_count if anim_config is AnimationActionConfig else 2
			return UIAnimationUtils.animate_pulse(owner, control, duration, pulse_amount, pulse_count, Vector2(-1, -1), true, repeat_count)
		AnimationActionConfig.AnimationAction.SHAKE:
			var shake_intensity = anim_config.shake_intensity if anim_config is AnimationActionConfig else 10.0
			var shake_count = anim_config.shake_count if anim_config is AnimationActionConfig else 5
			return UIAnimationUtils.animate_shake(owner, control, duration, shake_intensity, shake_count, true, repeat_count)
		AnimationActionConfig.AnimationAction.BREATHING:
			return UIAnimationUtils.animate_breathing(owner, control, duration, repeat_count)
		AnimationActionConfig.AnimationAction.WOBBLE:
			return UIAnimationUtils.animate_wobble(owner, control, duration, repeat_count)
		AnimationActionConfig.AnimationAction.FLOAT:
			return UIAnimationUtils.animate_float(owner, control, duration, repeat_count)
		AnimationActionConfig.AnimationAction.GLOW_PULSE:
			return UIAnimationUtils.animate_glow_pulse(owner, control, duration, repeat_count)
		AnimationActionConfig.AnimationAction.COLOR_FLASH:
			var flash_intensity = anim_config.flash_intensity if anim_config is AnimationActionConfig else 1.5
			return UIAnimationUtils.animate_color_flash(owner, control, flash_color, duration, flash_intensity, true)
		_:
			# Default: return a completed signal (no-op)
			var dummy_signal = Signal()
			return dummy_signal

## Resolves the target control node.
## [param owner]: The node that owns this config (used to resolve paths).
## Returns the resolved Control node, or null if not found.
func _resolve_target(owner: Node) -> Control:
	if not target.is_empty():
		var node = owner.get_node_or_null(target)
		if node is Control:
			return node as Control
	return null

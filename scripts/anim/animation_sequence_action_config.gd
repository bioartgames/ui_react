## Action configuration for executing animation sequences on controls.
##
## Users create this resource and assign it to ControlTargetConfig.action
## when they want to trigger a sequence of animations from buttons or other triggers.
##
## Example:
## [codeblock]
## var config = AnimationSequenceActionConfig.new()
## config.target = NodePath("../AnimationTarget")
## config.animations = [expand_config, fade_config, slide_config]
## config.delays = [0.0, 0.3, 0.2]
## config.initial_setup = {"scale": Vector2.ZERO, "modulate": Color(1, 1, 1, 0), "visible": true}
## [/codeblock]
class_name AnimationSequenceActionConfig
extends ActionConfig

## Array of AnimationActionConfig or AnimationParallelActionConfig resources that define the sequence steps.
## Each animation will be executed in order. Parallel configs will execute all their animations simultaneously.
@export var animations: Array[ActionConfig] = []

## Array of delays in seconds between animations (parallel to animations array).
## If delays array is shorter than animations, missing delays default to 0.0.
## First delay is before the first animation, subsequent delays are between animations.
@export var delays: Array[float] = []

## Path to the control to animate (relative to owner).
## Drag and drop a node here in the Inspector (NodePath supports drag-and-drop), or set manually.
@export var target: NodePath = NodePath()

## Initial state setup before sequence starts (Dictionary of property: value pairs).
## Common properties: "scale", "modulate", "visible", "position", etc.
## Example: {"scale": Vector2.ZERO, "modulate": Color(1, 1, 1, 0), "visible": true}
@export var initial_setup: Dictionary = {}

## Applies this action by executing the animation sequence.
## [param owner]: The node that owns the target config (used to resolve target paths and execute sequence).
## [param _target]: The control component (unused, we use target instead).
## [param is_on]: Optional boolean state (unused for sequences).
## Returns true if the sequence was started successfully, false otherwise.
func apply(owner: Node, _target: Control, _is_on: bool = true) -> bool:
	var control = _resolve_target(owner)
	if not control:
		push_warning("AnimationSequenceActionConfig: Target control not found. Check target (NodePath) in the Inspector. Tip: Drag a node to target.")
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
			push_warning("AnimationSequenceActionConfig: Control '%s' does not have property '%s'" % [control.name, property])
	
	# Execute sequence asynchronously using a helper node
	# Since Resources can't use await, we create a temporary helper node
	# that can execute the sequence asynchronously
	_execute_sequence_async(owner, control)
	return true

## Executes the animation sequence asynchronously.
## Creates a helper node to handle the async execution since Resources can't use await.
## [param owner]: The node that owns the sequence (for creating tweens).
## [param control]: The control to animate.
func _execute_sequence_async(owner: Node, control: Control) -> void:
	if animations.size() == 0:
		return
	
	var sequence = AnimationSequence.create()
	
	# Add each animation step with optional delays between them
	for i in range(animations.size()):
		# Add the animation step
		var anim_config = animations[i]
		if anim_config != null:
			# Create a callable that applies this animation config
			sequence.add(func(): return _create_animation_callable(owner, control, anim_config))
		
		# Add delay after this animation (before the next one, if specified)
		# delays[i] is the delay after animation[i], before animation[i+1]
		if i < delays.size() and delays[i] > 0.0:
			sequence.add(func(): return UIAnimationUtils.delay(owner, delays[i]))
	
	# Create a helper node to execute the sequence asynchronously
	# This is needed because Resources can't use await directly
	var helper = AnimationSequenceHelper.new()
	owner.add_child(helper)
	helper.execute_sequence(sequence)
	# Helper will remove itself when done

## Helper node class for executing animation sequences asynchronously.
## This is needed because Resources can't use await directly.
class AnimationSequenceHelper extends Node:
	func execute_sequence(sequence: AnimationSequence) -> void:
		await sequence.play()
		queue_free()

## Creates a callable that executes a single animation action config.
## [param owner]: The node that owns the sequence.
## [param control]: The control to animate.
## [param anim_config]: The AnimationActionConfig (or AnimationParallelActionConfig) to execute.
## Returns a Signal that can be awaited.
func _create_animation_callable(owner: Node, control: Control, anim_config: ActionConfig) -> Signal:
	# Check if this is a parallel config
	if anim_config is AnimationParallelActionConfig:
		var parallel_config = anim_config as AnimationParallelActionConfig
		# Execute parallel animations and wait for all to complete
		var signals: Array[Signal] = []
		for sub_config in parallel_config.animations:
			if sub_config != null:
				var signal_result = _create_animation_callable(owner, control, sub_config)
				if signal_result is Signal:
					signals.append(signal_result)
		
		# Return a signal that completes when all parallel animations finish
		if signals.size() > 0:
			var helper = _ParallelWaitHelper.new()
			owner.add_child(helper)
			helper.wait_for_all(signals)
			return helper.all_finished
		else:
			var dummy_signal = Signal()
			return dummy_signal
	
	# Handle regular AnimationActionConfig
	if not (anim_config is AnimationActionConfig):
		var dummy_signal = Signal()
		return dummy_signal
	
	var action_config = anim_config as AnimationActionConfig
	var action = action_config.action
	var duration = action_config.duration
	var repeat_count = action_config.repeat_count
	var reverse = action_config.reverse
	
	# Call the appropriate animation based on action type
	# This matches the logic in AnimationActionConfig.apply()
	match action:
		AnimationActionConfig.AnimationAction.EXPAND:
			if reverse:
				return UIAnimationUtils.animate_shrink(owner, control, duration, Vector2(-1, -1), false, true, true, repeat_count)
			else:
				return UIAnimationUtils.animate_expand(owner, control, duration, Vector2(-1, -1), false, false, false, repeat_count)
		AnimationActionConfig.AnimationAction.EXPAND_X:
			if reverse:
				return UIAnimationUtils.animate_shrink_x(owner, control, duration, Vector2(-1, -1), false, true, true, repeat_count)
			else:
				return UIAnimationUtils.animate_expand_x(owner, control, duration, Vector2(-1, -1), false, repeat_count)
		AnimationActionConfig.AnimationAction.EXPAND_Y:
			if reverse:
				return UIAnimationUtils.animate_shrink_y(owner, control, duration, Vector2(-1, -1), false, true, true, repeat_count)
			else:
				return UIAnimationUtils.animate_expand_y(owner, control, duration, Vector2(-1, -1), false, repeat_count)
		AnimationActionConfig.AnimationAction.FADE_IN:
			if reverse:
				return UIAnimationUtils.animate_fade_out(owner, control, duration, false, true, repeat_count)
			else:
				return UIAnimationUtils.animate_fade_in(owner, control, duration, false, repeat_count)
		AnimationActionConfig.AnimationAction.SLIDE_FROM_LEFT:
			if reverse:
				return UIAnimationUtils.animate_slide_to_left(owner, control, 8.0, duration, false, repeat_count)
			else:
				return UIAnimationUtils.animate_slide_from_left(owner, control, 8.0, duration, false, repeat_count)
		AnimationActionConfig.AnimationAction.SLIDE_FROM_RIGHT:
			if reverse:
				return UIAnimationUtils.animate_slide_to_right(owner, control, 8.0, duration, false, repeat_count)
			else:
				return UIAnimationUtils.animate_slide_from_right(owner, control, 8.0, duration, false, repeat_count)
		AnimationActionConfig.AnimationAction.SLIDE_FROM_TOP:
			if reverse:
				return UIAnimationUtils.animate_slide_to_top(owner, control, duration, false, repeat_count)
			else:
				return UIAnimationUtils.animate_slide_from_top(owner, control, 8.0, duration, false, repeat_count)
		AnimationActionConfig.AnimationAction.SLIDE_FROM_BOTTOM:
			if reverse:
				return UIAnimationUtils.animate_slide_to_bottom(owner, control, duration, false, repeat_count)
			else:
				return UIAnimationUtils.animate_slide_from_bottom(owner, control, 8.0, duration, false, repeat_count)
		AnimationActionConfig.AnimationAction.FROM_LEFT_TO_CENTER:
			if reverse:
				return UIAnimationUtils.animate_from_center_to_left(owner, control, duration, false, repeat_count)
			else:
				return UIAnimationUtils.animate_from_left_to_center(owner, control, duration, false, repeat_count)
		AnimationActionConfig.AnimationAction.FROM_RIGHT_TO_CENTER:
			if reverse:
				return UIAnimationUtils.animate_from_center_to_right(owner, control, duration, false, repeat_count)
			else:
				return UIAnimationUtils.animate_from_right_to_center(owner, control, duration, false, repeat_count)
		AnimationActionConfig.AnimationAction.FROM_TOP_TO_CENTER:
			if reverse:
				return UIAnimationUtils.animate_from_center_to_top(owner, control, duration, false, repeat_count)
			else:
				return UIAnimationUtils.animate_from_top_to_center(owner, control, duration, false, repeat_count)
		AnimationActionConfig.AnimationAction.FROM_BOTTOM_TO_CENTER:
			if reverse:
				return UIAnimationUtils.animate_from_center_to_bottom(owner, control, duration, false, repeat_count)
			else:
				return UIAnimationUtils.animate_from_bottom_to_center(owner, control, duration, false, repeat_count)
		AnimationActionConfig.AnimationAction.BOUNCE_IN:
			if reverse:
				return UIAnimationUtils.animate_bounce_out(owner, control, duration, Vector2(-1, -1), false, true, true, repeat_count)
			else:
				return UIAnimationUtils.animate_bounce_in(owner, control, duration, Vector2(-1, -1), false, repeat_count)
		AnimationActionConfig.AnimationAction.ELASTIC_IN:
			if reverse:
				return UIAnimationUtils.animate_elastic_out(owner, control, duration, Vector2(-1, -1), false, true, true, repeat_count)
			else:
				return UIAnimationUtils.animate_elastic_in(owner, control, duration, Vector2(-1, -1), false, repeat_count)
		AnimationActionConfig.AnimationAction.ROTATE_IN:
			var rotate_start_angle = action_config.rotate_start_angle if action_config is AnimationActionConfig else -360.0
			if reverse:
				return UIAnimationUtils.animate_rotate_out(owner, control, duration, 360.0, false, true, true, repeat_count)
			else:
				return UIAnimationUtils.animate_rotate_in(owner, control, duration, rotate_start_angle, Vector2(-1, -1), false, repeat_count)
		AnimationActionConfig.AnimationAction.POP:
			var pop_overshoot = action_config.pop_overshoot if action_config is AnimationActionConfig else 1.2
			return UIAnimationUtils.animate_pop(owner, control, duration, pop_overshoot, Vector2(-1, -1), false, repeat_count)
		AnimationActionConfig.AnimationAction.PULSE:
			var pulse_amount = action_config.pulse_amount if action_config is AnimationActionConfig else 1.1
			var pulse_count = action_config.pulse_count if action_config is AnimationActionConfig else 2
			return UIAnimationUtils.animate_pulse(owner, control, duration, pulse_amount, pulse_count, Vector2(-1, -1), false, repeat_count)
		AnimationActionConfig.AnimationAction.SHAKE:
			var shake_intensity = action_config.shake_intensity if action_config is AnimationActionConfig else 10.0
			var shake_count = action_config.shake_count if action_config is AnimationActionConfig else 5
			return UIAnimationUtils.animate_shake(owner, control, duration, shake_intensity, shake_count, false, repeat_count)
		AnimationActionConfig.AnimationAction.BREATHING:
			return UIAnimationUtils.animate_breathing(owner, control, duration, repeat_count)
		AnimationActionConfig.AnimationAction.WOBBLE:
			return UIAnimationUtils.animate_wobble(owner, control, duration, repeat_count)
		AnimationActionConfig.AnimationAction.FLOAT:
			return UIAnimationUtils.animate_float(owner, control, duration, repeat_count)
		AnimationActionConfig.AnimationAction.GLOW_PULSE:
			return UIAnimationUtils.animate_glow_pulse(owner, control, duration, repeat_count)
		AnimationActionConfig.AnimationAction.COLOR_FLASH:
			var flash_color = action_config.flash_color
			var flash_intensity = action_config.flash_intensity if action_config is AnimationActionConfig else 1.5
			return UIAnimationUtils.animate_color_flash(owner, control, flash_color, duration, flash_intensity, false)
		_:
			# Default: return a completed signal (no-op)
			var dummy_signal = Signal()
			return dummy_signal

## Helper node for waiting for multiple parallel animations to complete.
class _ParallelWaitHelper extends Node:
	var all_finished = Signal()
	
	func wait_for_all(signals: Array[Signal]) -> void:
		for signal_item in signals:
			await signal_item
		all_finished.emit()
		queue_free()

## Resolves the target control node.
## [param owner]: The node that owns this config (used to resolve paths).
## Returns the resolved Control node, or null if not found.
func _resolve_target(owner: Node) -> Control:
	if not target.is_empty():
		var node = owner.get_node_or_null(target)
		if node is Control:
			return node as Control
	return null

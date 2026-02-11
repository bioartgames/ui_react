## Core animation utilities shared across animation functions.
## Contains common patterns and helper functions to reduce code duplication.
class_name AnimationCoreUtils

## Minimum scale value for shrink animations.
const SCALE_MIN := Vector2.ZERO
## Maximum scale value for expand animations.
const SCALE_MAX := Vector2.ONE
## Minimum alpha value for fade animations.
const ALPHA_MIN := 0.0
## Maximum alpha value for fade animations.
const ALPHA_MAX := 1.0
## Default offset for slide animations in pixels.
const DEFAULT_OFFSET := 8.0
## Default animation duration in seconds.
const DEFAULT_DURATION := 0.3
## Default duration for shrink animations in seconds.
const SHRINK_ANIMATION_DURATION := 0.15
## Pivot offset value indicating center pivot (use center calculation).
const PIVOT_OFFSET_CENTER := Vector2(-1, -1)
## Multiplier for calculating center pivot offset (0.5 = center).
const PIVOT_CENTER_MULTIPLIER := 0.5
## Duration for instant tween operations (0.0 = immediate).
const INSTANT_TWEEN_DURATION := 0.0
## Repeat count value indicating no repeats.
const REPEAT_NONE := 0
## Repeat count value indicating infinite repeats.
const REPEAT_INFINITE := -1

## Wraps an animation callable with loop handling.
## [param source_node]: Node to create tween on
## [param target]: Control being animated
## [param animation_callable]: Callable that returns Signal
## [param repeat_count]: Number of times to repeat (0 = no repeat)
## [return]: Signal that fires when animation completes
static func wrap_with_loop(
	source_node: Node,
	target: Control,
	animation_callable: Callable,
	repeat_count: int
) -> Signal:
	if repeat_count != REPEAT_NONE:
		return _loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Validates animation parameters (source_node and target).
## Uses consistent error reporting with context for better debugging.
## [param source_node]: Node to validate
## [param target]: Control to validate
## [param function_name]: Name of calling function (for error messages)
## [return]: true if valid, false otherwise
static func validate_animation_params(source_node: Node, target: Control, function_name: String) -> bool:
	if not source_node:
		push_error("AnimationCoreUtils.%s(): source_node is null. Tip: Ensure the node is valid and in the scene tree before calling this function." % function_name)
		return false
	if not target:
		push_error("AnimationCoreUtils.%s(): target is null. Tip: Ensure the target Control is valid and in the scene tree before calling this function." % function_name)
		return false
	return true

## Validates that a node has a viewport and returns it.
## Uses consistent error reporting with context.
## [param node]: Node to get viewport from
## [param function_name]: Name of calling function (for error messages)
## [return]: Viewport if valid, null otherwise
static func validate_viewport(node: Node, function_name: String) -> Viewport:
	if not node:
		push_error("AnimationCoreUtils.%s(): node is null. Tip: Ensure the node is valid and in the scene tree before calling this function." % function_name)
		return null
	
	var viewport: Viewport = node.get_viewport()
	if not viewport:
		push_error("AnimationCoreUtils.%s(): node '%s' has no viewport. Tip: Ensure the node is added to the scene tree and has a viewport (usually happens after _ready())." % [function_name, node.name])
		return null
	
	return viewport

## Validates that a tween was created successfully.
## Uses consistent error reporting with context.
## [param tween]: Tween to validate
## [param node_name]: Name of the node that created the tween (for error messages)
## [param function_name]: Name of calling function (for error messages)
## [return]: true if valid, false otherwise
static func validate_tween(tween: Tween, node_name: String, function_name: String) -> bool:
	if not tween:
		push_error("AnimationCoreUtils.%s(): Failed to create tween on node '%s'. Tip: Check if the node is in the scene tree and not already processing (e.g., during _ready())." % [function_name, node_name])
		return false
	return true

## Sets up pivot offset for scale animations.
## [param target]: Control to set pivot on
## [param pivot_offset]: Desired pivot offset (PIVOT_OFFSET_CENTER = center)
static func setup_pivot_offset(target: Control, pivot_offset: Vector2) -> void:
	if pivot_offset == PIVOT_OFFSET_CENTER:
		target.pivot_offset = get_center_pivot_offset(target)  # Calls static method in same class
	else:
		target.pivot_offset = pivot_offset

## Gets the center pivot offset for a control.
## [param target]: Control to get pivot for
## [return]: Vector2 representing center pivot offset
static func get_center_pivot_offset(target: Control) -> Vector2:
	if not target:
		return Vector2.ZERO
	return Vector2(target.size.x * PIVOT_CENTER_MULTIPLIER, target.size.y * PIVOT_CENTER_MULTIPLIER)

## Validates that a Signal object has a valid underlying object.
## Signals from freed objects (like Tweens) can exist but have null objects.
## This prevents connecting to invalid signals that would cause null object errors.
## [param signal_item]: The Signal to validate
## [return]: true if the signal is valid and can be connected to, false otherwise
static func is_valid_signal(signal_item: Signal) -> bool:
	if signal_item == null:
		return false

	var signal_object: Object = signal_item.get_object()
	if signal_object == null or not is_instance_valid(signal_object):
		return false

	return true

## Handles auto-visible logic for animations.
## [param target]: Control to show/hide
## [param auto_visible]: Whether to automatically show target
static func handle_auto_visible(target: Control, auto_visible: bool) -> void:
	if auto_visible:
		target.visible = true

## Handles loop animation logic (moved from animation_utilities.gd).
## [param source_node]: Node to create tween on
## [param target]: Control being animated
## [param animation_callable]: Callable that returns Signal
## [param repeat_count]: Number of repeats (0 = no repeat, -1 = infinite, 1+ = finite repeats)
## [return]: Signal that fires when animation completes
static func _loop_animation(source_node: Node, target: Control, animation_callable: Callable, repeat_count: int) -> Signal:
	if repeat_count == REPEAT_NONE:
		# No repeats, just execute once
		return animation_callable.call()

	if repeat_count == REPEAT_INFINITE:
		# Infinite loop - attach helper to target control
		var infinite_helper: _AnimationLoopHelper = _AnimationLoopHelper.new()
		infinite_helper._target_control = target  # Store target reference to interrupt animations
		target.add_child(infinite_helper)
		# Wrap the callable to capture tween references and pass helper directly
		var wrapped_callable: Callable = infinite_helper._wrap_animation_callable(animation_callable, source_node)
		infinite_helper.start_infinite_loop(wrapped_callable)

		# Always return the signal to maintain type contract
		# The helper node is accessible as a child of target if manual control is needed
		return infinite_helper.loop_finished

	# Finite repeats - use AnimationSequence, attach helper to target control
	var sequence: AnimationSequence = AnimationSequence.create()
	# repeat_count represents number of repeats, so total plays = repeat_count + 1
	var total_plays: int = repeat_count + 1
	for i in range(total_plays):
		sequence.add(animation_callable)

	# Execute sequence asynchronously using helper node
	var finite_helper: _FiniteLoopHelper = _FiniteLoopHelper.new()
	target.add_child(finite_helper)
	finite_helper.execute_sequence(sequence)
	return finite_helper.sequence_finished

## Helper node for executing finite animation loops.
class _FiniteLoopHelper extends Node:
	signal sequence_finished

	func execute_sequence(sequence: AnimationSequence) -> void:
		await sequence.play()
		sequence_finished.emit()
		queue_free()

## Helper node for managing infinite animation loops.
class _AnimationLoopHelper extends Node:
	const HELPER_TYPE = "_AnimationLoopHelper"  # Identifier for helper detection
	signal loop_finished
	var _is_running: bool = false
	var _target_control: Control = null  # Store target to interrupt animations
	var _active_tweens: Array[Tween] = []  # Track all active tweens

	func _init():
		# Set a metadata flag to identify this as a loop helper
		set_meta("_is_animation_loop_helper", true)

	## Static helper function to create a tween and store it in the helper if available
	## This should be called from animation callables instead of source_node.create_tween()
	## [param source_node]: The node to create the tween from
	## [param helper]: Optional helper to track the tween in
	static func create_tracked_tween(source_node: Node, helper: _AnimationLoopHelper = null) -> Tween:
		var tween: Tween = source_node.create_tween()
		if tween and helper:
			helper._active_tweens.append(tween)
		return tween

	## Wraps an animation callable to capture tween references
	## [param original_callable]: The original animation callable
	## [param callable_source_node]: The source_node that the callable uses (from its closure)
	func _wrap_animation_callable(original_callable: Callable, callable_source_node: Node) -> Callable:
		var helper_ref = weakref(self)
		return func() -> Signal:
			# Store helper reference in the source_node's metadata so create_tracked_tween can find it
			callable_source_node.set_meta("_animation_helper_ref", helper_ref)

			# Call the original callable - it will store tweens via metadata if it uses create_tracked_tween
			var signal_result = original_callable.call()

			# Keep metadata until tween completes (don't remove immediately)
			# The tween will be cleaned up when stop() is called
			return signal_result

	func start_infinite_loop(animation_callable: Callable) -> void:
		_is_running = true
		_continue_loop(animation_callable)

	func _continue_loop(animation_callable: Callable) -> void:
		if not _is_running:
			return

		# Before calling the callable, clear old completed tweens
		_active_tweens = _active_tweens.filter(func(t: Tween) -> bool:
			return is_instance_valid(t) and t.is_valid() and t.is_running()
		)

		var signal_result: Signal = animation_callable.call()
		if signal_result is Signal:
			await signal_result
			if _is_running:
				_continue_loop(animation_callable)

	func stop() -> void:
		_is_running = false

		# Kill all tracked active tweens
		for tween in _active_tweens:
			if is_instance_valid(tween) and tween.is_valid():
				tween.kill()
		_active_tweens.clear()

		# Also interrupt by directly setting properties to stop any untracked tweens
		if _target_control:
			var current_pos: Vector2 = _target_control.position
			var current_scale: Vector2 = _target_control.scale
			var current_modulate: Color = _target_control.modulate
			var current_rotation: float = _target_control.rotation_degrees

			# Directly set properties - this interrupts tweens in Godot 4
			_target_control.position = current_pos
			_target_control.scale = current_scale
			_target_control.modulate = current_modulate
			_target_control.rotation_degrees = current_rotation

		loop_finished.emit()
		queue_free()

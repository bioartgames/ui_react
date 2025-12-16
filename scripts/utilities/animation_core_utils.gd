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
	if repeat_count != 0:
		return _loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Validates animation parameters (source_node and target).
## [param source_node]: Node to validate
## [param target]: Control to validate
## [param function_name]: Name of calling function (for error messages)
## [return]: true if valid, false otherwise
static func validate_animation_params(source_node: Node, target: Control, function_name: String) -> bool:
	if not source_node or not target:
		push_warning("UIAnimationUtils: Invalid source_node or target for %s" % function_name)
		return false
	return true

## Sets up pivot offset for scale animations.
## [param target]: Control to set pivot on
## [param pivot_offset]: Desired pivot offset (Vector2(-1, -1) = center)
static func setup_pivot_offset(target: Control, pivot_offset: Vector2) -> void:
	if pivot_offset == Vector2(-1, -1):
		target.pivot_offset = get_center_pivot_offset(target)  # Calls static method in same class
	else:
		target.pivot_offset = pivot_offset

## Gets the center pivot offset for a control.
## [param target]: Control to get pivot for
## [return]: Vector2 representing center pivot offset
static func get_center_pivot_offset(target: Control) -> Vector2:
	if not target:
		return Vector2.ZERO
	return Vector2(target.size.x * 0.5, target.size.y * 0.5)

## Gets the horizontal center position for a control within its viewport.
## [param source_node]: The node to get viewport from.
## [param target]: The control to center.
## [return]: X position that centers the control horizontally.
static func get_node_center(source_node: Node, target: Control) -> float:
	if not source_node or not target:
		var source_name: String = "null"
		var target_name: String = "null"
		if source_node != null:
			source_name = source_node.name
		if target != null:
			target_name = target.name
		push_warning("AnimationCoreUtils.get_node_center(): Invalid source_node (%s) or target (%s). Tip: Ensure both nodes are valid and in the scene tree before calling this function." % [source_name, target_name])
		return 0.0

	var viewport = source_node.get_viewport()
	if not viewport:
		push_warning("AnimationCoreUtils.get_node_center(): source_node '%s' has no viewport. Tip: Ensure the node is added to the scene tree and has a viewport (usually happens after _ready())." % source_node.name)
		return 0.0

	return (viewport.get_visible_rect().size.x * 0.5) - (target.size.x * 0.5)

## Gets the vertical center position for a control within its viewport.
## [param source_node]: The node to get viewport from.
## [param target]: The control to center.
## [return]: Y position that centers the control vertically.
static func get_node_center_y(source_node: Node, target: Control) -> float:
	if not source_node or not target:
		push_warning("AnimationCoreUtils: Invalid source_node or target for get_node_center_y")
		return 0.0

	var viewport = source_node.get_viewport()
	if not viewport:
		push_warning("AnimationCoreUtils: source_node has no viewport")
		return 0.0

	return (viewport.get_visible_rect().size.y * 0.5) - (target.size.y * 0.5)

## Validates that a Signal object has a valid underlying object.
## Signals from freed objects (like Tweens) can exist but have null objects.
## This prevents connecting to invalid signals that would cause null object errors.
## [param signal_item]: The Signal to validate
## [return]: true if the signal is valid and can be connected to, false otherwise
static func is_valid_signal(signal_item: Signal) -> bool:
	if signal_item == null:
		return false

	var signal_object = signal_item.get_object()
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
	if repeat_count == 0:
		# No repeats, just execute once
		return animation_callable.call()

	if repeat_count == -1:
		# Infinite loop - attach helper to target control
		var infinite_helper = _AnimationLoopHelper.new()
		infinite_helper._target_control = target  # Store target reference to interrupt animations
		target.add_child(infinite_helper)
		# Wrap the callable to capture tween references and pass helper directly
		var wrapped_callable = infinite_helper._wrap_animation_callable(animation_callable, source_node)
		infinite_helper.start_infinite_loop(wrapped_callable)

		# Always return the signal to maintain type contract
		# The helper node is accessible as a child of target if manual control is needed
		return infinite_helper.loop_finished

	# Finite repeats - use AnimationSequence, attach helper to target control
	var sequence = AnimationSequence.create()
	# repeat_count represents number of repeats, so total plays = repeat_count + 1
	var total_plays = repeat_count + 1
	for i in range(total_plays):
		sequence.add(animation_callable)

	# Execute sequence asynchronously using helper node
	var finite_helper = _FiniteLoopHelper.new()
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
	var _is_running = false
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
		var tween = source_node.create_tween()
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

		var signal_result = animation_callable.call()
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
			var current_pos = _target_control.position
			var current_scale = _target_control.scale
			var current_modulate = _target_control.modulate
			var current_rotation = _target_control.rotation_degrees

			# Directly set properties - this interrupts tweens in Godot 4
			_target_control.position = current_pos
			_target_control.scale = current_scale
			_target_control.modulate = current_modulate
			_target_control.rotation_degrees = current_rotation

		loop_finished.emit()
		queue_free()

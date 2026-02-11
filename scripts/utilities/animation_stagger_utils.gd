## Animation stagger utilities for sequenced animations.
##
## Provides functions for animating multiple targets with delays between each animation.
## Includes the _StaggerHelper class for managing staggered execution.
class_name AnimationStaggerUtils

## Animates multiple targets with staggered timing using an AnimationClip.
## [param source_node]: The node to create the tween from (usually self).
## [param targets]: Array of controls to animate in sequence.
## [param delay_between]: Delay in seconds between starting each animation.
## [param clip]: The animation clip to execute on each target.
## [return]: Signal that emits when all staggered animations complete.
static func animate_stagger_from_clip(source_node: Node, targets: Array[Control], delay_between: float, clip: AnimationClip) -> Signal:
	if targets.size() == 0 or not clip:
		push_warning("AnimationStaggerUtils: Invalid source_node or empty targets for animate_stagger_from_clip")
		return Signal()

	if not source_node:
		push_warning("AnimationStaggerUtils: Invalid source_node for animate_stagger_from_clip")
		return Signal()

	# Create and configure stagger helper
	var helper: _StaggerHelper = _StaggerHelper.new()
	helper._source_node = source_node
	helper._targets = targets
	helper._delay_between = delay_between
	helper._clip = clip
	source_node.add_child(helper)
	helper.start_stagger()

	return helper.stagger_finished

## Stops all active stagger animations on the given targets.
## [param source_node]: The node that owns the stagger animations.
## [param targets]: Array of controls to stop stagger animations on.
static func stop_stagger_animations(source_node: Node, targets: Array[Control]) -> void:
	if not source_node:
		return

	for target in targets:
		if not target:
			continue

		# Find and stop any active stagger helpers on this target
		for child in target.get_children():
			if child is _StaggerHelper and child._is_running:
				child.stop()

## Helper class for managing staggered animation execution.
class _StaggerHelper extends Node:
	signal stagger_finished

	var _source_node: Node = null
	var _targets: Array[Control] = []
	var _delay_between: float = 0.0
	var _clip: AnimationClip = null
	var _is_running: bool = false

	func start_stagger() -> void:
		if _targets.size() == 0 or not _clip:
			stagger_finished.emit()
			queue_free()
			return

		# Get animation parameters from AnimationClip
		var tween_easing: int = AnimationClip.to_tween_easing(_clip.easing)

		# Calculate total delay
		var total_delay: float = _delay_between * (_targets.size() - 1)

		# Start animations with stagger
		for i in range(_targets.size()):
			var target: Control = _targets[i]
			if not is_instance_valid(target):
				continue

			var delay_time: float = _delay_between * i

			# Create a timer for this target's delay
			var timer: SceneTreeTimer = get_tree().create_timer(delay_time)
			timer.timeout.connect(func():
				if _is_running and is_instance_valid(target):
					_clip.execute(_source_node, target, tween_easing)
			)

		# Wait for all animations to complete
		var max_time: float = total_delay + _clip.duration
		await get_tree().create_timer(max_time).timeout

		if _is_running:
			stagger_finished.emit()
		queue_free()

	func stop() -> void:
		_is_running = false
		stagger_finished.emit()
		queue_free()

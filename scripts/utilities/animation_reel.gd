## Animation reel configuration that contains multiple clips and handles execution.
##
## AnimationReel groups multiple AnimationClip instances together with target controls
## and provides manual execution mode selection. It can execute animations in two modes:
## - PARALLEL: All animation clips run simultaneously on all targets
## - SEQUENCE: Animation clips run sequentially on each target (all targets run their sequences simultaneously)
class_name AnimationReel
extends Resource

## When to trigger this animation reel.
enum Trigger {
	PRESSED,           # When button is pressed (default)
	HOVER_ENTER,       # When mouse enters control
	HOVER_EXIT,        # When mouse exits control
	TOGGLED_ON,        # When toggle is turned on
	TOGGLED_OFF,       # When toggle is turned off
	TEXT_CHANGED,      # When text value changes
	SELECTION_CHANGED, # When selection changes
	VALUE_CHANGED,     # When value changes
	VALUE_INCREASED,   # When value increases
	VALUE_DECREASED,   # When value decreases
	DRAG_STARTED,      # When user starts dragging
	DRAG_ENDED,        # When user stops dragging
	COMPLETED,         # When progress reaches completion
	TEXT_ENTERED,      # When user presses Enter in text input
	FOCUS_ENTERED,     # When input gains focus
	FOCUS_EXITED,      # When input loses focus
}

## Execution mode for this animation reel.
enum ExecutionMode {
	PARALLEL,    # All animation clips run simultaneously
	SEQUENCE     # Animation clips run one after another
}

## ============================================
## CORE SETTINGS
## ============================================

## Execution mode for this animation reel.
## PARALLEL: All clips run simultaneously
## SEQUENCE: Clips run one after another
@export var execution_mode: ExecutionMode = ExecutionMode.SEQUENCE

## When to trigger this animation reel (dropdown selection in Inspector).
@export var trigger: Trigger = Trigger.PRESSED

## Multiple targets for this reel (drag and drop nodes from scene tree).
## If empty, animations will not execute. At least one target is required.
@export var targets: Array[NodePath] = []

## Animation clips to execute in this reel.
## Supports single clip (applied to all targets), or multiple clips (executed as sequence).
@export var animations: Array[AnimationClip] = []

## Applies this animation reel to the specified owner node.
## Uses the selected execution_mode to determine how to run the animations.
## [param owner]: The node that owns the animation (for creating tweens and resolving targets).
## [return]: Signal that emits when animation completes (or empty Signal if no animations).
func apply(owner: Node) -> Signal:
	# Early validation
	if animations.size() == 0:
		return Signal()  # No-op if no clips

	if targets.size() == 0:
		push_warning("AnimationReel: No targets specified")
		return Signal()

	# Resolve all targets upfront
	var resolved_targets: Array[Control] = []
	for path in targets:
		var node = owner.get_node_or_null(path)
		if node is Control:
			resolved_targets.append(node as Control)

	if resolved_targets.size() == 0:
		push_warning("AnimationReel: No valid targets found")
		return Signal()

	# Use manual execution mode selection
	match execution_mode:
		ExecutionMode.PARALLEL:
			return _apply_parallel(owner, resolved_targets, animations)
		ExecutionMode.SEQUENCE:
			return _apply_sequence(owner, resolved_targets, animations)
		_:
			push_warning("AnimationReel: Invalid execution mode %d" % execution_mode)
			return Signal()

## Applies single animation clip to single target.
## [param owner]: The node that owns the animation.
## [param target]: The control to animate.
## [param clip]: The animation clip to execute.
## [return]: Signal that emits when animation completes.
func _apply_single(owner: Node, target: Control, clip: AnimationClip) -> Signal:
	# Check respect_disabled
	if clip.respect_disabled and owner.has_method("is_disabled") and owner.is_disabled():
		return Signal()  # Skip if disabled

	# Get tween easing from clip
	var tween_easing: int = _get_tween_easing_from_clip(clip)

	# Execute clip animation
	return clip.execute(owner, target, tween_easing)

## Applies single animation clip to multiple targets.
## Uses stagger if clip.stagger > 0, otherwise applies simultaneously.
## [param owner]: The node that owns the animation.
## [param targets]: Array of controls to animate.
## [param clip]: The animation clip to execute.
## [return]: Signal that emits when all animations complete.
func _apply_multi(owner: Node, targets: Array[Control], clip: AnimationClip) -> Signal:
	if targets.size() == 1:
		return _apply_single(owner, targets[0], clip)

	# Check respect_disabled
	if clip.respect_disabled and owner.has_method("is_disabled") and owner.is_disabled():
		return Signal()

	# Use stagger if clip.stagger > 0
	if clip.stagger > 0.0:
		return _apply_multi_stagger(owner, targets, clip)
	else:
		# Apply to all targets simultaneously
		return _apply_multi_parallel(owner, targets, clip)

## Applies animation clip to multiple targets simultaneously (no stagger).
## [param owner]: The node that owns the animation.
## [param targets]: Array of controls to animate.
## [param clip]: The animation clip to execute.
## [return]: Signal that emits when all animations complete.
func _apply_multi_parallel(owner: Node, targets: Array[Control], clip: AnimationClip) -> Signal:
	var signals: Array[Signal] = []
	var tween_easing: int = _get_tween_easing_from_clip(clip)

	for target in targets:
		var signal_result = clip.execute(owner, target, tween_easing)
		if signal_result is Signal:
			signals.append(signal_result)

	if signals.size() > 0:
		return _wait_for_all_signals(owner, signals)
	else:
		return Signal()

## Applies animation clip to multiple targets with stagger timing.
## [param owner]: The node that owns the animation.
## [param targets]: Array of controls to animate.
## [param clip]: The animation clip to execute.
## [return]: Signal that emits when stagger animation completes.
func _apply_multi_stagger(owner: Node, targets: Array[Control], clip: AnimationClip) -> Signal:
	# Use existing stagger utility from UIAnimationUtils
	return UIAnimationUtils.animate_stagger_from_clip(owner, targets, clip.stagger, clip)

## Applies multiple animation clips in parallel to all targets simultaneously.
## Each clip runs on each target at the same time.
## [param owner]: The node that owns the animation.
## [param targets]: Array of controls to animate.
## [param clips]: Array of animation clips to execute in parallel.
## [return]: Signal that emits when all parallel animations complete.
func _apply_parallel(owner: Node, targets: Array[Control], clips: Array[AnimationClip]) -> Signal:
	if clips.size() == 0:
		return Signal()

	var all_signals: Array[Signal] = []

	# For each target, run all clips in parallel
	for target in targets:
		for clip in clips:
			# Check respect_disabled per clip
			if clip.respect_disabled and owner.has_method("is_disabled") and owner.is_disabled():
				continue  # Skip this clip

			var tween_easing = _get_tween_easing_from_clip(clip)
			var signal_result = clip.execute(owner, target, tween_easing)
			if signal_result is Signal:
				all_signals.append(signal_result)

	# Wait for all parallel animations to complete
	if all_signals.size() > 0:
		return _wait_for_all_signals(owner, all_signals)
	else:
		return Signal()

## Applies multiple animation clips as a sequence to all targets simultaneously.
## Each target gets the same sequence of clips executed on it.
## [param owner]: The node that owns the animation.
## [param targets]: Array of controls to animate.
## [param clips]: Array of animation clips to execute sequentially.
## [return]: Signal that emits when all sequences complete.
func _apply_sequence(owner: Node, targets: Array[Control], clips: Array[AnimationClip]) -> Signal:
	# Create sequence for each target (all run simultaneously)
	var all_signals: Array[Signal] = []

	for target in targets:
		var anim_sequence = AnimationSequence.create()

		for clip in clips:
			# Check respect_disabled per clip
			if clip.respect_disabled and owner.has_method("is_disabled") and owner.is_disabled():
				continue  # Skip this clip

			# Add delay if specified
			if clip.delay > 0.0:
				anim_sequence.add(func(): return UIAnimationUtils.delay(owner, clip.delay))

			# Add animation
			var tween_easing = _get_tween_easing_from_clip(clip)
			anim_sequence.add(func(): return clip.execute(owner, target, tween_easing))

		# Execute sequence for this target
		var helper = _SequenceHelper.new()
		owner.add_child(helper)
		helper.execute_sequence(anim_sequence)
		all_signals.append(helper.sequence_finished)

	# Wait for all sequences to complete
	if all_signals.size() > 0:
		return _wait_for_all_signals(owner, all_signals)
	else:
		return Signal()

## Converts AnimationClip.Easing enum to Tween.EASE_* constant.
## [param clip]: The animation clip to get easing from.
## [return]: Tween easing constant.
func _get_tween_easing_from_clip(clip: AnimationClip) -> int:
	match clip.easing:
		AnimationClip.Easing.EASE_IN:
			return Tween.EASE_IN
		AnimationClip.Easing.EASE_OUT:
			return Tween.EASE_OUT
		AnimationClip.Easing.EASE_IN_OUT:
			return Tween.EASE_IN_OUT
		AnimationClip.Easing.EASE_OUT_IN:
			return Tween.EASE_OUT_IN
		_:
			return Tween.EASE_OUT

## Waits for all signals to complete (for parallel execution).
## [param owner]: The node to attach helper to.
## [param signals]: Array of signals to wait for.
## [return]: Signal that emits when all signals complete.
func _wait_for_all_signals(owner: Node, signals: Array[Signal]) -> Signal:
	var helper = _ParallelWaitHelper.new()
	owner.add_child(helper)
	helper.wait_for_all(signals)
	return helper.all_finished

## Helper node for executing animation sequences asynchronously.
class _SequenceHelper extends Node:
	signal sequence_finished

	func execute_sequence(sequence: AnimationSequence) -> void:
		await sequence.play()
		sequence_finished.emit()
		queue_free()

## Helper node for waiting for multiple parallel animations to complete.
class _ParallelWaitHelper extends Node:
	signal all_finished

	func wait_for_all(signals: Array[Signal]) -> void:
		for signal_item in signals:
			await signal_item
		all_finished.emit()
		queue_free()

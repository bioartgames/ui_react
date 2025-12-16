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
	if animations.is_empty():
		return Signal()  # No-op if no clips

	if targets.is_empty():
		push_warning("AnimationReel: No targets specified")
		return Signal()

	# Resolve all targets upfront
	var resolved_targets: Array[Control] = []
	for path in targets:
		var node = owner.get_node_or_null(path)
		if node is Control:
			resolved_targets.append(node as Control)

	if resolved_targets.is_empty():
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
	var tween_easing: int = AnimationClip.to_tween_easing(clip.easing)

	# Execute clip animation
	return clip.execute(owner, target, tween_easing)

## Applies single animation clip to multiple targets.
## Uses stagger if clip.stagger > 0, otherwise applies simultaneously.
## [param owner]: The node that owns the animation.
## [param resolved_targets]: Array of controls to animate.
## [param clip]: The animation clip to execute.
## [return]: Signal that emits when all animations complete.
func _apply_multi(owner: Node, resolved_targets: Array[Control], clip: AnimationClip) -> Signal:
	if resolved_targets.size() == 1:
		return _apply_single(owner, resolved_targets[0], clip)

	# Check respect_disabled
	if clip.respect_disabled and owner.has_method("is_disabled") and owner.is_disabled():
		return Signal()

	# Use stagger if clip.stagger > 0
	if clip.stagger > 0.0:
		return _apply_multi_stagger(owner, resolved_targets, clip)
	else:
		# Apply to all targets simultaneously
		return _apply_multi_parallel(owner, resolved_targets, clip)

## Applies animation clip to multiple targets simultaneously (no stagger).
## [param owner]: The node that owns the animation.
## [param resolved_targets]: Array of controls to animate.
## [param clip]: The animation clip to execute.
## [return]: Signal that emits when all animations complete.
func _apply_multi_parallel(owner: Node, resolved_targets: Array[Control], clip: AnimationClip) -> Signal:
	var signals: Array[Signal] = []
	var tween_easing: int = AnimationClip.to_tween_easing(clip.easing)

	for target in resolved_targets:
		var signal_result = clip.execute(owner, target, tween_easing)
		if signal_result is Signal:
			signals.append(signal_result)

	if signals.size() > 0:
		return _wait_for_all_signals(owner, signals)
	else:
		return Signal()

## Applies animation clip to multiple targets with stagger timing.
## [param owner]: The node that owns the animation.
## [param resolved_targets]: Array of controls to animate.
## [param clip]: The animation clip to execute.
## [return]: Signal that emits when stagger animation completes.
func _apply_multi_stagger(owner: Node, resolved_targets: Array[Control], clip: AnimationClip) -> Signal:
	# Use existing stagger utility from UIAnimationUtils
	return UIAnimationUtils.animate_stagger_from_clip(owner, resolved_targets, clip.stagger, clip)

## Applies multiple animation clips in parallel to all targets simultaneously.
## Each clip runs on each target at the same time.
## Special case: If there's a single clip with multiple targets and stagger > 0, uses stagger timing.
## [param owner]: The node that owns the animation.
## [param resolved_targets]: Array of controls to animate.
## [param clips]: Array of animation clips to execute in parallel.
## [return]: Signal that emits when all parallel animations complete.
func _apply_parallel(owner: Node, resolved_targets: Array[Control], clips: Array[AnimationClip]) -> Signal:
	if clips.is_empty():
		return Signal()

	# Special case: Single clip with multiple targets and stagger enabled
	if clips.size() == 1:
		var clip = clips[0]
		# Check respect_disabled
		if clip.respect_disabled and owner.has_method("is_disabled") and owner.is_disabled():
			return Signal()
		
		# Single target: just apply normally
		if resolved_targets.size() == 1:
			return _apply_single(owner, resolved_targets[0], clip)
		
		# Multiple targets: use stagger if enabled, otherwise parallel
		if clip.stagger > 0.0:
			return _apply_multi_stagger(owner, resolved_targets, clip)
		# Otherwise fall through to normal parallel execution

	var all_signals: Array[Signal] = []

	# For each target, run all clips in parallel
	for target in resolved_targets:
		for clip in clips:
			# Check respect_disabled per clip
			if clip.respect_disabled and owner.has_method("is_disabled") and owner.is_disabled():
				continue  # Skip this clip

			var tween_easing = AnimationClip.to_tween_easing(clip.easing)
			var signal_result = clip.execute(owner, target, tween_easing)
			if signal_result is Signal:
				all_signals.append(signal_result)

	# Wait for all parallel animations to complete
	if all_signals.size() > 0:
		return _wait_for_all_signals(owner, all_signals)
	else:
		return Signal()

## Applies multiple animation clips as a sequence to all targets simultaneously.
## Each clip runs on all targets, then waits for all targets to finish before moving to the next clip.
## Each clip can have its own stagger value that applies when that clip runs.
## [param owner]: The node that owns the animation.
## [param resolved_targets]: Array of controls to animate.
## [param clips]: Array of animation clips to execute sequentially.
## [return]: Signal that emits when all sequences complete.
func _apply_sequence(owner: Node, resolved_targets: Array[Control], clips: Array[AnimationClip]) -> Signal:
	# Use a helper to coordinate per-clip stagger execution
	var helper = _SequenceStaggerHelper.new()
	owner.add_child(helper)
	helper.execute_sequence_with_stagger(owner, resolved_targets, clips)
	return helper.sequence_finished


## Waits for all signals to complete (for parallel execution).
## [param owner]: The node to attach helper to.
## [param signals]: Array of signals to wait for.
## [return]: Signal that emits when all signals complete.
func _wait_for_all_signals(owner: Node, signals: Array[Signal]) -> Signal:
	var helper = _ParallelWaitHelper.new()
	owner.add_child(helper)
	helper.wait_for_all(signals)
	return helper.all_finished

## Helper node for waiting for multiple parallel animations to complete.
class _ParallelWaitHelper extends Node:
	signal all_finished

	func wait_for_all(signals: Array[Signal]) -> void:
		if signals.size() == 0:
			all_finished.emit()
			queue_free()
			return
		
		# Use arrays to hold mutable state (lambdas capture by value, not reference)
		var completed_count: Array[int] = [0]
		var total_count = signals.size()
		var has_emitted: Array[bool] = [false]
		
		# Connect to each signal to track completion
		# This avoids the null object error when awaiting signals from freed Tweens
		for signal_item in signals:
			# Use centralized validation utility
			if not AnimationCoreUtils.is_valid_signal(signal_item):
				completed_count[0] += 1
				continue

			# Connect callback to track when this signal fires
			var callback = func():
				completed_count[0] += 1
				if completed_count[0] >= total_count and not has_emitted[0]:
					has_emitted[0] = true
					all_finished.emit()
					queue_free()
			
			# Try to connect - if the signal's object is already freed, this may fail silently
			# but we have a timeout fallback
			signal_item.connect(callback, CONNECT_ONE_SHOT)
		
		# Check if all were null/invalid
		if completed_count[0] >= total_count and not has_emitted[0]:
			has_emitted[0] = true
			all_finished.emit()
			queue_free()
			return
		
		# Safety timeout: emit after max expected duration
		# This handles cases where signals can't connect (objects freed)
		var timeout = get_tree().create_timer(5.0)
		timeout.timeout.connect(func():
			if not has_emitted[0]:
				has_emitted[0] = true
				all_finished.emit()
				queue_free()
		)

## Helper node for executing sequences with per-clip stagger.
## Each clip runs on all targets with its own stagger value, then waits for completion before next clip.
class _SequenceStaggerHelper extends Node:
	signal sequence_finished

	func execute_sequence_with_stagger(owner_node: Node, resolved_targets: Array[Control], clips: Array[AnimationClip]) -> void:
		for clip in clips:
			# Check respect_disabled per clip
			if clip.respect_disabled and owner_node.has_method("is_disabled") and owner_node.is_disabled():
				continue  # Skip this clip

			# Add delay if specified (before this clip starts)
			if clip.delay > 0.0:
				await UIAnimationUtils.delay(owner_node, clip.delay)

			# Execute this clip on all targets with per-clip stagger
			var clip_signal: Signal
			
			if resolved_targets.size() == 1:
				# Single target: just execute normally
				var tween_easing = AnimationClip.to_tween_easing(clip.easing)
				clip_signal = clip.execute(owner_node, resolved_targets[0], tween_easing)
			elif clip.stagger > 0.0:
				# Multiple targets with stagger: use stagger utility
				clip_signal = UIAnimationUtils.animate_stagger_from_clip(owner_node, resolved_targets, clip.stagger, clip)
			else:
				# Multiple targets without stagger: apply simultaneously
				var signals: Array[Signal] = []
				var tween_easing = AnimationClip.to_tween_easing(clip.easing)
				for target in resolved_targets:
					var signal_result = clip.execute(owner_node, target, tween_easing)
					if signal_result is Signal:
						signals.append(signal_result)
				
				# Wait for all parallel animations to complete
				if signals.size() > 0:
					var wait_helper = _ParallelWaitHelper.new()
					owner_node.add_child(wait_helper)
					wait_helper.wait_for_all(signals)
					clip_signal = wait_helper.all_finished
				else:
					clip_signal = Signal()

			# Wait for this clip to finish on all targets before moving to next clip
			if clip_signal is Signal:
				await clip_signal

		sequence_finished.emit()
		queue_free()

## Validates an array of animation reels for a control and returns valid ones.
## Does NOT handle signal connections (those are control-specific).
## [param owner]: The control instance (for get_node_or_null and name)
## [param animations]: Array of AnimationReel to validate
## [return]: Dictionary with:
##   - "valid_reels": Array[AnimationReel] - filtered valid reels
##   - "trigger_map": Dictionary - maps trigger types to boolean (which triggers are used)
static func validate_for_control(
	owner: Control,
	animations: Array[AnimationReel]
) -> Dictionary:
	var valid_reels: Array[AnimationReel] = []
	var trigger_map: Dictionary = {}

	for reel in animations:
		if reel == null:
			continue

		# Validate targets array
		if reel.targets.is_empty():
			push_warning("%s '%s': AnimationReel has no targets." % [owner.get_class(), owner.name])
			continue

		# Validate targets resolve to Controls
		var has_valid_target = false
		for path in reel.targets:
			var node = owner.get_node_or_null(path)
			if node is Control:
				has_valid_target = true
				break

		if not has_valid_target:
			push_warning("%s '%s': AnimationReel has no valid targets." % [owner.get_class(), owner.name])
			continue

		valid_reels.append(reel)
		trigger_map[reel.trigger] = true

	return {
		"valid_reels": valid_reels,
		"trigger_map": trigger_map
	}

## Triggers animations for reels matching the specified trigger type.
## Pure function - no state needed, can be static.
## [param owner]: The control instance (passed to reel.apply())
## [param animations]: Array of AnimationReel to check
## [param trigger_type]: The AnimationReel.Trigger enum value to match
static func trigger_matching(
	owner: Control,
	animations: Array[AnimationReel],
	trigger_type: Trigger
) -> void:
	if animations.is_empty():
		return

	for reel in animations:
		if reel == null:
			continue
		if reel.trigger != trigger_type:
			continue
		reel.apply(owner)

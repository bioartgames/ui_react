## Static animation functions for UI element transitions.
##
## UiAnimUtils provides a comprehensive set of common UI animations for animating UI elements
## with transitions like slides, fades, pops, and shrinks. All animation functions return a Signal
## that can be awaited for sequencing multiple animations. This makes it ideal for animating panel
## show and hide transitions, creating smooth UI transitions, sequencing multiple animations together,
## and custom animation needs beyond what reactive components provide. Unlike writing custom animation
## code, UiAnimUtils provides a comprehensive set of common UI animations, consistent animation
## timing and easing, awaitable signals for sequencing, safe handling of edge cases like null nodes
## and viewport issues, and utility functions for animation setup like pivot calculation and tween
## creation. Reactive controls such as [UiReactButton] use these functions internally,
## but you can also call them directly for custom animations.
##
## Example:
## [codeblock]
## # Animate panel expansion
## await UiAnimUtils.animate_expand(self, panel).finished
##
## # Fade in a label
## await UiAnimUtils.animate_fade_in(self, label).finished
##
## # Sequence multiple animations
## var sequence = UiAnimSequence.create()
## sequence.add(func(): return UiAnimUtils.animate_expand(self, panel))
## sequence.add(func(): return UiAnimUtils.animate_fade_in(self, label))
## await sequence.play()
## [/codeblock]
class_name UiAnimUtils
extends RefCounted

## Default offset for slide animations in pixels.
const DEFAULT_OFFSET := 8.0
## Default animation speed in seconds.
const DEFAULT_SPEED := 0.3
## Default speed for shrink animations in seconds.
const SHRINK_ANIMATION_SPEED := 0.15
## Minimum alpha value for fade animations.
const ALPHA_MIN := 0.0
## Maximum alpha value for fade animations.
const ALPHA_MAX := 1.0
## Minimum scale value for pop/shrink animations.
const SCALE_MIN := Vector2.ZERO
## Maximum scale value for pop/shrink animations.
const SCALE_MAX := Vector2.ONE
## Subtle scale pulse for breathing animation (5% increase).
const BREATHING_SCALE_MULTIPLIER := 1.05
## Subtle rotation amplitude for wobble animation (degrees).
const WOBBLE_ROTATION_DEGREES := 3.0
## Default vertical float distance for [method animate_float] (pixels).
const DEFAULT_FLOAT_DISTANCE_PX := 10.0

## Delegates snapshot storage to [UiAnimSnapshotStore].
static func _acquire_unified_snapshot(source_node: Node, target: Control) -> UiAnimSnapshotStore.ControlStateSnapshot:
	return UiAnimSnapshotStore.acquire_unified_snapshot(source_node, target)

static func _release_unified_snapshot(target: Control, restore_immediately: bool = true) -> bool:
	return UiAnimSnapshotStore.release_unified_snapshot(target, restore_immediately)

static func _get_unified_snapshot(target: Control) -> UiAnimSnapshotStore.ControlStateSnapshot:
	return UiAnimSnapshotStore.get_unified_snapshot(target)

static func _clear_unified_snapshot(target: Control) -> void:
	UiAnimSnapshotStore.clear_unified_snapshot(target)

## Calculates the center X position of a node relative to the viewport.
## [param source_node]: The node to get viewport from.
## [param target]: The control to calculate center for.
## [return]: The center X position, or 0.0 if calculation fails.
static func get_node_center(source_node: Node, target: Control) -> float:
	return UiAnimTweenFactory.get_node_center(source_node, target)

## Calculates the pivot offset to center a control for scale animations.
## [param target]: The control to calculate pivot for.
## [return]: The pivot offset Vector2, or Vector2.ZERO if target is null.
static func get_center_pivot_offset(target: Control) -> Vector2:
	return UiAnimTweenFactory.get_center_pivot_offset(target)

## Creates a tween with null checking and error handling.
## [param node]: The node to create tween for.
## [return]: The created Tween, or null if creation failed.
static func create_safe_tween(node: Node) -> Tween:
	return UiAnimTweenFactory.create_safe_tween(node)

## Creates a snapshot of a control's current state (delegates to [UiAnimSnapshotStore]).
static func snapshot_control_state(target: Control) -> UiAnimSnapshotStore.ControlStateSnapshot:
	return UiAnimSnapshotStore.snapshot_control_state(target)

## Restores a control from a snapshot (delegates to [UiAnimSnapshotStore]).
static func restore_control_state(target: Control, snapshot: UiAnimSnapshotStore.ControlStateSnapshot) -> void:
	UiAnimSnapshotStore.restore_control_state(target, snapshot)

## Resets a control to "normal" state (scale=1, modulate.a=1, rotation=0).
## Does not reset position as that is usually intentional.
## [param target]: The control to reset.
static func reset_control_to_normal(target: Control) -> void:
	if not target:
		return
	target.scale = SCALE_MAX
	target.modulate.a = ALPHA_MAX
	target.rotation_degrees = 0.0

## Disables focus on all child Control nodes recursively.
## This prevents child nodes from interfering with keyboard/controller navigation.
## Only the parent Control should be focusable for proper navigation.
## [param parent]: The parent Control node whose children should have focus disabled.
## [param _exclude_self]: Reserved for future use - currently always processes children only.
static func disable_focus_on_children(parent: Control, _exclude_self: bool = true) -> void:
	if not parent:
		return
	
	# Recursively disable focus on all child Control nodes
	for child in parent.get_children():
		if child is Control:
			var child_control = child as Control
			child_control.focus_mode = Control.FOCUS_NONE
			# Recursively process grandchildren
			disable_focus_on_children(child_control, false)

## Stops all active animations (looping animations and tweens) for a target control.
## [param source_node]: The node that owns animations (used for tween cleanup).
## [param target]: The control to stop animations for (where loop helpers are attached).
static func stop_all_animations(source_node: Node, target: Control) -> void:
	if not source_node or not target:
		return
	
	# Find and stop all _AnimationLoopHelper and _FiniteLoopHelper nodes attached to the target
	var nodes_to_check: Array[Node] = [target]
	var checked_nodes: Dictionary = {}
	
	# Search the target control and all its children recursively
	while nodes_to_check.size() > 0:
		var current_node = nodes_to_check.pop_front()
		if current_node == null or checked_nodes.has(current_node):
			continue
		checked_nodes[current_node] = true
		
		# Check all children for loop helpers
		for child in current_node.get_children():
			# Check if this is a loop helper by checking metadata
			if child.has_meta("_is_animation_loop_helper"):
				# This is an _AnimationLoopHelper - call stop to properly clean it up
				if child.has_method("stop"):
					child.call("stop")
			# Also check for _FiniteLoopHelper (check for sequence_finished signal)
			elif child.has_method("execute_sequence"):
				# This is a _FiniteLoopHelper - queue_free will stop it
				child.queue_free()
			
			# Recursively check children of children
			nodes_to_check.append(child)
	
	# Kill all active tweens on the target control
	# Get all tweens from the scene tree and kill those affecting the target
	var scene_tree = source_node.get_tree()
	if scene_tree:
		# Create a temporary tween to kill any existing tweens
		var temp_tween = source_node.create_tween()
		if temp_tween:
			# Kill the temp tween immediately
			temp_tween.kill()

## Animates a control sliding in from the left side of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param offset]: Final position offset from left edge (default: 8.0).
## [param speed]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_slide_from_left(source_node: Node, target: Control, offset := DEFAULT_OFFSET, speed := DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		target.position.x = -target.size.x
		
		var tween = source_node.create_tween()
		tween.tween_property(target, 'position:x', offset, speed).set_trans(Tween.TRANS_BACK).set_ease(easing)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control sliding out to the left side of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param _offset]: Unused parameter (kept for API consistency).
## [param speed]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation and visible=false after completion (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_slide_to_left(source_node: Node, target: Control, _offset := DEFAULT_OFFSET, speed := DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		var tween = source_node.create_tween()
		tween.tween_property(target, 'position:x', -target.size.x, speed).set_trans(Tween.TRANS_BACK).set_ease(easing)
		
		if auto_visible:
			tween.finished.connect(func(): target.visible = false)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control sliding in from the right side of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param offset]: Final position offset from right edge (default: 8.0).
## [param speed]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_slide_from_right(source_node: Node, target: Control, offset := DEFAULT_OFFSET, speed := DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	var animation_callable = func() -> Signal:
		if not source_node or not target:
			push_warning("UiAnimUtils: Invalid source_node or target for animate_slide_from_right")
			return Signal()
		
		if auto_visible:
			target.visible = true
		
		var viewport = source_node.get_viewport()
		if not viewport:
			push_warning("UiAnimUtils: source_node has no viewport")
			return Signal()
		
		var viewport_size = viewport.get_visible_rect().size.x
		target.position.x = viewport_size
		
		var tween = source_node.create_tween()
		if not tween:
			push_warning("UiAnimUtils: Failed to create tween")
			return Signal()
		
		tween.tween_property(target, "position:x", (viewport_size - target.size.x) - offset, speed).set_trans(Tween.TRANS_BACK).set_ease(easing)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control sliding out to the right side of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param _offset]: Unused parameter (kept for API consistency).
## [param speed]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation and visible=false after completion (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_slide_to_right(source_node: Node, target: Control, _offset := DEFAULT_OFFSET, speed := DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		var tween = source_node.create_tween()
		tween.tween_property(target, 'position:x', source_node.get_viewport().size.x, speed).set_trans(Tween.TRANS_BACK).set_ease(easing)
		
		if auto_visible:
			tween.finished.connect(func(): target.visible = false)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control sliding in from the top of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param offset]: Final position offset from top edge (default: 8.0).
## [param speed]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_slide_from_top(source_node: Node, target: Control, offset: float = DEFAULT_OFFSET, speed := DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		target.position.y = -target.size.y
		
		var tween = source_node.create_tween()
		tween.tween_property(target, 'position:y', offset, speed).set_trans(Tween.TRANS_BACK).set_ease(easing)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control sliding out to the top of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation and visible=false after completion (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_slide_to_top(source_node: Node, target: Control, speed := DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		var tween = source_node.create_tween()
		tween.tween_property(target, 'position:y', -target.size.y, speed).set_trans(Tween.TRANS_BACK).set_ease(easing)
		
		if auto_visible:
			tween.finished.connect(func(): target.visible = false)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control expanding with a scale animation from zero to full size (both x and y).
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.3).
## [param pivot_offset]: Custom pivot offset for scaling (default: Vector2(-1, -1) uses center).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param auto_setup]: If true, automatically sets scale=Vector2.ZERO before animation (default: false). Note: Scale is always set internally, so this parameter is optional.
## [param auto_reset]: If true, automatically resets scale=Vector2.ONE after animation completes (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_expand(source_node: Node, target: Control, speed := DEFAULT_SPEED, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false, auto_setup: bool = false, auto_reset: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not source_node or not target:
		push_warning("UiAnimUtils: Invalid source_node or target for animate_expand")
		return Signal()

	# Acquire baseline snapshot for universal reset support
	_acquire_unified_snapshot(source_node, target)

	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		if pivot_offset == Vector2(-1, -1):
			target.pivot_offset = get_center_pivot_offset(target)
		else:
			target.pivot_offset = pivot_offset
		
		if auto_setup:
			target.scale = SCALE_MIN
		else:
			target.scale = SCALE_MIN  # Always set internally for consistency
		
		var tween = source_node.create_tween()
		if not tween:
			push_warning("UiAnimUtils: Failed to create tween")
			return Signal()
		
		tween.tween_property(target, 'scale', SCALE_MAX, speed).set_trans(Tween.TRANS_BACK).set_ease(easing)
		
		if auto_reset:
			tween.finished.connect(func(): target.scale = SCALE_MAX)
		
		return tween.finished
	
	var result_signal: Signal
	if repeat_count != 0:
		result_signal = UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		result_signal = animation_callable.call()

	# Connect to completion to release unified snapshot
	result_signal.connect(func():
		_release_unified_snapshot(target, true)
	, CONNECT_ONE_SHOT)

	return result_signal

## Animates a control expanding horizontally (scale.x from 0.0 to 1.0).
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.15).
## [param pivot_offset]: Custom pivot offset for scaling (default: Vector2(-1, -1) uses center).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_expand_x(source_node: Node, target: Control, speed := SHRINK_ANIMATION_SPEED, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not source_node or not target:
		push_warning("UiAnimUtils: Invalid source_node or target for animate_expand_x")
		return Signal()

	# Acquire baseline snapshot for universal reset support
	_acquire_unified_snapshot(source_node, target)

	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		if pivot_offset == Vector2(-1, -1):
			target.pivot_offset = get_center_pivot_offset(target)
		else:
			target.pivot_offset = pivot_offset
		
		# Always start from 0 on x-axis, preserve y-axis
		target.scale.x = ALPHA_MIN
		
		var tween = source_node.create_tween()
		if not tween:
			push_warning("UiAnimUtils: Failed to create tween")
			return Signal()
		
		tween.tween_property(target, 'scale:x', SCALE_MAX.x, speed).set_trans(Tween.TRANS_CUBIC).set_ease(easing)
		
		return tween.finished
	
	var result_signal: Signal
	if repeat_count != 0:
		result_signal = UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		result_signal = animation_callable.call()

	# Connect to completion to release unified snapshot
	result_signal.connect(func():
		_release_unified_snapshot(target, true)
	, CONNECT_ONE_SHOT)

	return result_signal

## Animates a control expanding vertically (scale.y from 0.0 to 1.0).
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.15).
## [param pivot_offset]: Custom pivot offset for scaling (default: Vector2(-1, -1) uses center).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_expand_y(source_node: Node, target: Control, speed := SHRINK_ANIMATION_SPEED, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not source_node or not target:
		push_warning("UiAnimUtils: Invalid source_node or target for animate_expand_y")
		return Signal()

	# Acquire baseline snapshot for universal reset support
	_acquire_unified_snapshot(source_node, target)

	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		if pivot_offset == Vector2(-1, -1):
			target.pivot_offset = get_center_pivot_offset(target)
		else:
			target.pivot_offset = pivot_offset
		
		# Always start from 0 on y-axis, preserve x-axis
		target.scale.y = ALPHA_MIN
		
		var tween = source_node.create_tween()
		if not tween:
			push_warning("UiAnimUtils: Failed to create tween")
			return Signal()
		
		tween.tween_property(target, 'scale:y', SCALE_MAX.y, speed).set_trans(Tween.TRANS_CUBIC).set_ease(easing)
		
		return tween.finished
	
	var result_signal: Signal
	if repeat_count != 0:
		result_signal = UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		result_signal = animation_callable.call()

	# Connect to completion to release unified snapshot
	result_signal.connect(func():
		_release_unified_snapshot(target, true)
	, CONNECT_ONE_SHOT)

	return result_signal

## Animates a control shrinking out with a scale animation from full size to zero.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.3).
## [param pivot_offset]: Custom pivot offset for scaling (default: Vector2(-1, -1) uses center).
## [param auto_visible]: If true, automatically sets visible=true before animation and visible=false after completion (default: false).
## [param auto_setup]: If true, automatically sets scale=Vector2.ONE before animation (default: false).
## [param auto_reset]: If true, automatically resets scale=Vector2.ONE after animation completes (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_shrink(source_node: Node, target: Control, speed := DEFAULT_SPEED, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false, auto_setup: bool = false, auto_reset: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not source_node or not target:
		push_warning("UiAnimUtils: Invalid source_node or target for animate_shrink")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		if pivot_offset == Vector2(-1, -1):
			target.pivot_offset = get_center_pivot_offset(target)
		else:
			target.pivot_offset = pivot_offset
		
		if auto_setup:
			target.scale = SCALE_MAX

		var tween = source_node.create_tween()
		if not tween:
			push_warning("UiAnimUtils: Failed to create tween")
			return Signal()
		
		tween.tween_property(target, 'scale', SCALE_MIN, speed).set_trans(Tween.TRANS_BACK).set_ease(easing)
		
		if auto_visible:
			tween.finished.connect(func(): target.visible = false)
		
		if auto_reset:
			tween.finished.connect(func(): target.scale = SCALE_MAX)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control shrinking horizontally (scale.x from 1.0 to 0.0).
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.15).
## [param pivot_offset]: Custom pivot offset for scaling (default: Vector2(-1, -1) uses center).
## [param auto_visible]: If true, automatically sets visible=true before animation and visible=false after completion (default: false).
## [param auto_setup]: If true, automatically sets scale.x=1.0 before animation (default: false).
## [param auto_reset]: If true, automatically resets scale.x=1.0 after animation completes (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_shrink_x(source_node: Node, target: Control, speed := SHRINK_ANIMATION_SPEED, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false, auto_setup: bool = false, auto_reset: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not source_node or not target:
		push_warning("UiAnimUtils: Invalid source_node or target for animate_shrink_x")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		if pivot_offset == Vector2(-1, -1):
			target.pivot_offset = get_center_pivot_offset(target)
		else:
			target.pivot_offset = pivot_offset
		
		if auto_setup:
			target.scale.x = SCALE_MAX.x

		var tween = source_node.create_tween()
		if not tween:
			push_warning("UiAnimUtils: Failed to create tween")
			return Signal()
		
		tween.tween_property(target, 'scale:x', ALPHA_MIN, speed).set_trans(Tween.TRANS_BACK).set_ease(easing)
		
		if auto_visible:
			tween.finished.connect(func(): target.visible = false)
		
		if auto_reset:
			tween.finished.connect(func(): target.scale.x = SCALE_MAX.x)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control shrinking vertically (scale.y from 1.0 to 0.0).
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.15).
## [param pivot_offset]: Custom pivot offset for scaling (default: Vector2(-1, -1) uses center).
## [param auto_visible]: If true, automatically sets visible=true before animation and visible=false after completion (default: false).
## [param auto_setup]: If true, automatically sets scale.y=1.0 before animation (default: false).
## [param auto_reset]: If true, automatically resets scale.y=1.0 after animation completes (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_shrink_y(source_node: Node, target: Control, speed := SHRINK_ANIMATION_SPEED, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false, auto_setup: bool = false, auto_reset: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not source_node or not target:
		push_warning("UiAnimUtils: Invalid source_node or target for animate_shrink_y")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		if pivot_offset == Vector2(-1, -1):
			target.pivot_offset = get_center_pivot_offset(target)
		else:
			target.pivot_offset = pivot_offset
		
		if auto_setup:
			target.scale.y = SCALE_MAX.y

		var tween = source_node.create_tween()
		if not tween:
			push_warning("UiAnimUtils: Failed to create tween")
			return Signal()
		
		tween.tween_property(target, 'scale:y', ALPHA_MIN, speed).set_trans(Tween.TRANS_BACK).set_ease(easing)
		
		if auto_visible:
			tween.finished.connect(func(): target.visible = false)
		
		if auto_reset:
			tween.finished.connect(func(): target.scale.y = SCALE_MAX.y)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control fading in (modulate.a from 0.0 to 1.0).
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_fade_in(source_node: Node, target: Control, speed := DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not source_node or not target:
		push_warning("UiAnimUtils: Invalid source_node or target for animate_fade_in")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		target.modulate.a = ALPHA_MIN
		
		var tween = source_node.create_tween()
		if not tween:
			push_warning("UiAnimUtils: Failed to create tween")
			return Signal()
		
		tween.tween_property(target, 'modulate:a', ALPHA_MAX, speed).set_trans(Tween.TRANS_CUBIC).set_ease(easing)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control fading out (modulate.a from 1.0 to 0.0).
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation and visible=false after completion (default: false).
## [param auto_reset]: If true, automatically resets modulate.a=1.0 after animation completes (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_fade_out(source_node: Node, target: Control, speed := DEFAULT_SPEED, auto_visible: bool = false, auto_reset: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not source_node or not target:
		push_warning("UiAnimUtils: Invalid source_node or target for animate_fade_out")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		var tween = source_node.create_tween()
		if not tween:
			push_warning("UiAnimUtils: Failed to create tween")
			return Signal()
		
		tween.tween_property(target, 'modulate:a', ALPHA_MIN, speed).set_trans(Tween.TRANS_CUBIC).set_ease(easing)
		
		if auto_visible:
			tween.finished.connect(func(): target.visible = false)
		
		if auto_reset:
			tween.finished.connect(func(): target.modulate.a = ALPHA_MAX)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control sliding from the left edge to the center of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_from_left_to_center(source_node: Node, target: Control, speed := DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		target.position.x = -target.size.x
		
		var tween = source_node.create_tween()
		tween.tween_property(target, 'position:x', get_node_center(source_node, target), speed).set_trans(Tween.TRANS_BACK).set_ease(easing)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control sliding from the center to the left edge of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation and visible=false after completion (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_from_center_to_left(source_node: Node, target: Control, speed := DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		var tween = source_node.create_tween()
		tween.tween_property(target, 'position:x', -target.size.x, speed).set_trans(Tween.TRANS_BACK).set_ease(easing)
		
		if auto_visible:
			tween.finished.connect(func(): target.visible = false)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control sliding from the right edge to the center of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_from_right_to_center(source_node: Node, target: Control, speed := DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not source_node or not target:
		push_warning("UiAnimUtils: Invalid source_node or target for animate_from_right_to_center")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		var viewport = source_node.get_viewport()
		if not viewport:
			push_warning("UiAnimUtils: source_node has no viewport")
			return Signal()
		
		target.position.x = viewport.get_visible_rect().size.x
		
		var tween = source_node.create_tween()
		if not tween:
			push_warning("UiAnimUtils: Failed to create tween")
			return Signal()
		
		tween.tween_property(target, 'position:x', get_node_center(source_node, target), speed).set_trans(Tween.TRANS_BACK).set_ease(easing)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control sliding from the center to the right edge of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation and visible=false after completion (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_from_center_to_right(source_node: Node, target: Control, speed := DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		var tween = source_node.create_tween()
		tween.tween_property(target, 'position:x', target.size.x, speed).set_trans(Tween.TRANS_BACK).set_ease(easing)
		
		if auto_visible:
			tween.finished.connect(func(): target.visible = false)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control sliding in from the bottom of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param offset]: Final position offset from bottom edge (default: 8.0).
## [param speed]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_slide_from_bottom(source_node: Node, target: Control, offset: float = DEFAULT_OFFSET, speed := DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not source_node or not target:
		push_warning("UiAnimUtils: Invalid source_node or target for animate_slide_from_bottom")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		var viewport = source_node.get_viewport()
		if not viewport:
			push_warning("UiAnimUtils: source_node has no viewport")
			return Signal()
		
		var viewport_size = viewport.get_visible_rect().size.y
		target.position.y = viewport_size
		
		var tween = source_node.create_tween()
		if not tween:
			push_warning("UiAnimUtils: Failed to create tween")
			return Signal()
		
		tween.tween_property(target, 'position:y', (viewport_size - target.size.y) - offset, speed).set_trans(Tween.TRANS_BACK).set_ease(easing)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control sliding out to the bottom of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation and visible=false after completion (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_slide_to_bottom(source_node: Node, target: Control, speed := DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not source_node or not target:
		push_warning("UiAnimUtils: Invalid source_node or target for animate_slide_to_bottom")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		var viewport = source_node.get_viewport()
		if not viewport:
			push_warning("UiAnimUtils: source_node has no viewport")
			return Signal()
		
		var tween = source_node.create_tween()
		if not tween:
			push_warning("UiAnimUtils: Failed to create tween")
			return Signal()
		
		tween.tween_property(target, 'position:y', viewport.get_visible_rect().size.y, speed).set_trans(Tween.TRANS_BACK).set_ease(easing)
		
		if auto_visible:
			tween.finished.connect(func(): target.visible = false)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Calculates the center Y position of a node relative to the viewport.
## [param source_node]: The node to get viewport from.
## [param target]: The control to calculate center for.
## [return]: The center Y position, or 0.0 if calculation fails.
static func get_node_center_y(source_node: Node, target: Control) -> float:
	return UiAnimTweenFactory.get_node_center_y(source_node, target)

## Animates a control sliding from the top edge to the center of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_from_top_to_center(source_node: Node, target: Control, speed := DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not source_node or not target:
		push_warning("UiAnimUtils: Invalid source_node or target for animate_from_top_to_center")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		target.position.y = -target.size.y
		
		var tween = source_node.create_tween()
		if not tween:
			push_warning("UiAnimUtils: Failed to create tween")
			return Signal()
		
		tween.tween_property(target, 'position:y', get_node_center_y(source_node, target), speed).set_trans(Tween.TRANS_BACK).set_ease(easing)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control sliding from the center to the top edge of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation and visible=false after completion (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_from_center_to_top(source_node: Node, target: Control, speed := DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not source_node or not target:
		push_warning("UiAnimUtils: Invalid source_node or target for animate_from_center_to_top")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		var tween = source_node.create_tween()
		if not tween:
			push_warning("UiAnimUtils: Failed to create tween")
			return Signal()
		
		tween.tween_property(target, 'position:y', -target.size.y, speed).set_trans(Tween.TRANS_BACK).set_ease(easing)
		
		if auto_visible:
			tween.finished.connect(func(): target.visible = false)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control sliding from the bottom edge to the center of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_from_bottom_to_center(source_node: Node, target: Control, speed := DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not source_node or not target:
		push_warning("UiAnimUtils: Invalid source_node or target for animate_from_bottom_to_center")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		var viewport = source_node.get_viewport()
		if not viewport:
			push_warning("UiAnimUtils: source_node has no viewport")
			return Signal()
		
		target.position.y = viewport.get_visible_rect().size.y
		
		var tween = source_node.create_tween()
		if not tween:
			push_warning("UiAnimUtils: Failed to create tween")
			return Signal()
		
		tween.tween_property(target, 'position:y', get_node_center_y(source_node, target), speed).set_trans(Tween.TRANS_BACK).set_ease(easing)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control sliding from the center to the bottom edge of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation and visible=false after completion (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_from_center_to_bottom(source_node: Node, target: Control, speed := DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not source_node or not target:
		push_warning("UiAnimUtils: Invalid source_node or target for animate_from_center_to_bottom")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		var viewport = source_node.get_viewport()
		if not viewport:
			push_warning("UiAnimUtils: source_node has no viewport")
			return Signal()
		
		var tween = source_node.create_tween()
		if not tween:
			push_warning("UiAnimUtils: Failed to create tween")
			return Signal()
		
		tween.tween_property(target, 'position:y', viewport.get_visible_rect().size.y, speed).set_trans(Tween.TRANS_BACK).set_ease(easing)
		
		if auto_visible:
			tween.finished.connect(func(): target.visible = false)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control expanding with a bounce effect (scale from 0 to 1 with bounce).
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.3).
## [param pivot_offset]: Custom pivot offset for scaling (default: Vector2(-1, -1) uses center).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_bounce_in(source_node: Node, target: Control, speed := DEFAULT_SPEED, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not source_node or not target:
		push_warning("UiAnimUtils: Invalid source_node or target for animate_bounce_in")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		if pivot_offset == Vector2(-1, -1):
			target.pivot_offset = get_center_pivot_offset(target)
		else:
			target.pivot_offset = pivot_offset
		
		target.scale = SCALE_MIN
		
		var tween = source_node.create_tween()
		if not tween:
			push_warning("UiAnimUtils: Failed to create tween")
			return Signal()
		
		tween.tween_property(target, 'scale', SCALE_MAX, speed).set_trans(Tween.TRANS_BOUNCE).set_ease(easing)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control shrinking with a bounce effect (scale from 1 to 0 with bounce).
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.3).
## [param pivot_offset]: Custom pivot offset for scaling (default: Vector2(-1, -1) uses center).
## [param auto_visible]: If true, automatically sets visible=true before animation and visible=false after completion (default: false).
## [param auto_setup]: If true, automatically sets scale=Vector2.ONE before animation (default: false).
## [param auto_reset]: If true, automatically resets scale=Vector2.ONE after animation completes (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_bounce_out(source_node: Node, target: Control, speed := DEFAULT_SPEED, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false, auto_setup: bool = false, auto_reset: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not source_node or not target:
		push_warning("UiAnimUtils: Invalid source_node or target for animate_bounce_out")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		if pivot_offset == Vector2(-1, -1):
			target.pivot_offset = get_center_pivot_offset(target)
		else:
			target.pivot_offset = pivot_offset
		
		if auto_setup:
			target.scale = SCALE_MAX

		var tween = source_node.create_tween()
		if not tween:
			push_warning("UiAnimUtils: Failed to create tween")
			return Signal()
		
		tween.tween_property(target, 'scale', SCALE_MIN, speed).set_trans(Tween.TRANS_BOUNCE).set_ease(easing)
		
		if auto_visible:
			tween.finished.connect(func(): target.visible = false)
		
		if auto_reset:
			tween.finished.connect(func(): target.scale = SCALE_MAX)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control expanding with an elastic effect (scale from 0 to 1 with elastic).
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.3).
## [param pivot_offset]: Custom pivot offset for scaling (default: Vector2(-1, -1) uses center).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_elastic_in(source_node: Node, target: Control, speed := DEFAULT_SPEED, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not source_node or not target:
		push_warning("UiAnimUtils: Invalid source_node or target for animate_elastic_in")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		if pivot_offset == Vector2(-1, -1):
			target.pivot_offset = get_center_pivot_offset(target)
		else:
			target.pivot_offset = pivot_offset
		
		target.scale = SCALE_MIN
		
		var tween = source_node.create_tween()
		if not tween:
			push_warning("UiAnimUtils: Failed to create tween")
			return Signal()
		
		tween.tween_property(target, 'scale', SCALE_MAX, speed).set_trans(Tween.TRANS_ELASTIC).set_ease(easing)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control shrinking with an elastic effect (scale from 1 to 0 with elastic).
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.3).
## [param pivot_offset]: Custom pivot offset for scaling (default: Vector2(-1, -1) uses center).
## [param auto_visible]: If true, automatically sets visible=true before animation and visible=false after completion (default: false).
## [param auto_setup]: If true, automatically sets scale=Vector2.ONE before animation (default: false).
## [param auto_reset]: If true, automatically resets scale=Vector2.ONE after animation completes (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_elastic_out(source_node: Node, target: Control, speed := DEFAULT_SPEED, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false, auto_setup: bool = false, auto_reset: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not source_node or not target:
		push_warning("UiAnimUtils: Invalid source_node or target for animate_elastic_out")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		if pivot_offset == Vector2(-1, -1):
			target.pivot_offset = get_center_pivot_offset(target)
		else:
			target.pivot_offset = pivot_offset
		
		if auto_setup:
			target.scale = SCALE_MAX

		var tween = source_node.create_tween()
		if not tween:
			push_warning("UiAnimUtils: Failed to create tween")
			return Signal()
		
		tween.tween_property(target, 'scale', SCALE_MIN, speed).set_trans(Tween.TRANS_ELASTIC).set_ease(easing)
		
		if auto_visible:
			tween.finished.connect(func(): target.visible = false)
		
		if auto_reset:
			tween.finished.connect(func(): target.scale = SCALE_MAX)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control rotating in (rotation from -360 to 0 degrees).
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.3).
## [param start_angle]: Starting rotation angle in degrees (default: -360).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_rotate_in(source_node: Node, target: Control, speed := DEFAULT_SPEED, start_angle: float = -360.0, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not source_node or not target:
		push_warning("UiAnimUtils: Invalid source_node or target for animate_rotate_in")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		# Set pivot offset for rotation center
		if pivot_offset == Vector2(-1, -1):
			target.pivot_offset = get_center_pivot_offset(target)
		else:
			target.pivot_offset = pivot_offset
		
		target.rotation_degrees = start_angle
		
		var tween = source_node.create_tween()
		if not tween:
			push_warning("UiAnimUtils: Failed to create tween")
			return Signal()
		
		tween.tween_property(target, 'rotation_degrees', 0.0, speed).set_trans(Tween.TRANS_BACK).set_ease(easing)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control rotating out (rotation from 0 to 360 degrees).
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.3).
## [param end_angle]: Ending rotation angle in degrees (default: 360).
## [param auto_visible]: If true, automatically sets visible=true before animation and visible=false after completion (default: false).
## [param auto_setup]: If true, automatically sets rotation_degrees=0.0 before animation (default: false).
## [param auto_reset]: If true, automatically resets rotation_degrees=0.0 after animation completes (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_rotate_out(source_node: Node, target: Control, speed := DEFAULT_SPEED, end_angle: float = 360.0, auto_visible: bool = false, auto_setup: bool = false, auto_reset: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not source_node or not target:
		push_warning("UiAnimUtils: Invalid source_node or target for animate_rotate_out")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		if auto_setup:
			target.rotation_degrees = 0.0
		
		var tween = source_node.create_tween()
		if not tween:
			push_warning("UiAnimUtils: Failed to create tween")
			return Signal()
		
		tween.tween_property(target, 'rotation_degrees', end_angle, speed).set_trans(Tween.TRANS_BACK).set_ease(easing)
		
		if auto_visible:
			tween.finished.connect(func(): target.visible = false)
		
		if auto_reset:
			tween.finished.connect(func(): target.rotation_degrees = 0.0)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control with a pop effect (scale overshoots then settles to 1.0).
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.3).
## [param overshoot]: Scale overshoot amount (default: 1.2).
## [param pivot_offset]: Custom pivot offset for scaling (default: Vector2(-1, -1) uses center).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_pop(source_node: Node, target: Control, speed := DEFAULT_SPEED, overshoot: float = 1.2, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not source_node or not target:
		push_warning("UiAnimUtils: Invalid source_node or target for animate_pop")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		if pivot_offset == Vector2(-1, -1):
			target.pivot_offset = get_center_pivot_offset(target)
		else:
			target.pivot_offset = pivot_offset
		
		target.scale = SCALE_MIN
		
		var tween = source_node.create_tween()
		if not tween:
			push_warning("UiAnimUtils: Failed to create tween")
			return Signal()
		
		# First tween: scale to overshoot
		tween.tween_property(target, 'scale', Vector2(overshoot, overshoot) * SCALE_MAX, speed * 0.6).set_trans(Tween.TRANS_BACK).set_ease(easing)
		# Second tween: settle back to 1.0
		tween.tween_property(target, 'scale', SCALE_MAX, speed * 0.4).set_trans(Tween.TRANS_BACK).set_ease(easing)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control with a pulse effect (repeated scale up and down).
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Duration for each pulse cycle in seconds (default: 0.5).
## [param pulse_amount]: Scale amount to pulse to (default: 1.1).
## [param pulse_count]: Number of pulse cycles (default: 2).
## [param pivot_offset]: Custom pivot offset for scaling (default: Vector2(-1, -1) uses center).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_pulse(source_node: Node, target: Control, speed := 0.5, pulse_amount: float = 1.1, pulse_count: int = 2, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not source_node or not target:
		push_warning("UiAnimUtils: Invalid source_node or target for animate_pulse")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		if pivot_offset == Vector2(-1, -1):
			target.pivot_offset = get_center_pivot_offset(target)
		else:
			target.pivot_offset = pivot_offset
		
		var original_scale = target.scale
		var tween = source_node.create_tween()
		if not tween:
			push_warning("UiAnimUtils: Failed to create tween")
			return Signal()
		
		# Create pulse cycles
		for i in range(pulse_count):
			tween.tween_property(target, 'scale', Vector2(pulse_amount, pulse_amount) * original_scale, speed * 0.5).set_trans(Tween.TRANS_SINE).set_ease(easing)
			tween.tween_property(target, 'scale', original_scale, speed * 0.5).set_trans(Tween.TRANS_SINE).set_ease(easing)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control with a shake effect (rapid position changes).
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Total shake duration in seconds (default: 0.5).
## [param intensity]: Shake intensity in pixels (default: 10.0).
## [param shake_count]: Number of shake movements (default: 5).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## Note: Position is automatically preserved using the unified baseline snapshot system.
## [return]: Signal that emits when animation finishes.
static func animate_shake(source_node: Node, target: Control, speed := 0.5, intensity: float = 10.0, shake_count: int = 5, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not source_node or not target:
		push_warning("UiAnimUtils: Invalid source_node or target for animate_shake")
		return Signal()

	# Acquire baseline snapshot (automatic state preservation)
	var snapshot = _acquire_unified_snapshot(source_node, target)
	var saved_position: Vector2
	if snapshot:
		saved_position = snapshot.position
	else:
		push_warning("UiAnimUtils.animate_shake(): Failed to acquire baseline snapshot, using current position")
		saved_position = target.position
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		# Use saved position from baseline snapshot
		var original_position = saved_position
		var tween = source_node.create_tween()
		if not tween:
			push_warning("UiAnimUtils: Failed to create tween")
			return Signal()
		
		var shake_duration = speed / shake_count
		
		# Create shake movements
		for i in range(shake_count):
			var offset_x = intensity * (1.0 if i % 2 == 0 else -1.0)
			var y_index = int(i * 0.5)
			var offset_y = intensity * 0.5 * (1.0 if y_index % 2 == 0 else -1.0)
			tween.tween_property(target, 'position', original_position + Vector2(offset_x, offset_y), shake_duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(easing)
			tween.tween_property(target, 'position', original_position, shake_duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(easing)
		
		return tween.finished
	
	var result_signal: Signal
	if repeat_count != 0:
		result_signal = UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		result_signal = animation_callable.call()

	# Connect to final completion to release unified snapshot
	result_signal.connect(func():
		_release_unified_snapshot(target, true)
	, CONNECT_ONE_SHOT)

	return result_signal

## Animates a control back to its unified original state (all properties).
## If no unified snapshot exists, uses current state (no animation).
## This function is used by the RESET animation action (with duration=0 for instant reset).
## Can also be called directly for animated reset in animation chains.
## Restores: position, scale, modulate (color + alpha), rotation, pivot_offset, and visible.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param duration]: Duration of the reset animation in seconds (default: 0.3). Use 0.0 for instant reset.
## [param easing]: Easing type for the animation (default: EASE_OUT). Ignored if duration=0.
## [param clear_unified_after]: If true, clears unified snapshot after reset (default: true).
## [return]: Signal that emits when animation finishes (or immediately if duration=0).
static func animate_reset_all(source_node: Node, target: Control, duration: float = 0.3, easing: int = Tween.EASE_OUT, clear_unified_after: bool = true) -> Signal:
	if not source_node or not target:
		push_warning("UiAnimUtils: Invalid source_node or target for animate_reset_all")
		return Signal()

	# Get the unified original snapshot (or current state if not set)
	var snapshot: UiAnimSnapshotStore.ControlStateSnapshot
	if UiAnimSnapshotStore.has_unified_snapshot(target):
		snapshot = UiAnimSnapshotStore.get_unified_snapshot(target)
	else:
		# No unified snapshot, use current state (no animation needed)
		return Signal()

	# Validate snapshot exists and is valid
	if not snapshot:
		push_warning("UiAnimUtils.animate_reset_all(): Unified snapshot exists but is null for target '%s'" % target.name)
		return Signal()

	# If duration is 0, perform instant reset
	if duration <= 0.0:
		restore_control_state(target, snapshot)
		if clear_unified_after:
			_clear_unified_snapshot(target)
		# Return an empty signal (caller can't await it, but it's consistent with API)
		# For instant reset, the work is done synchronously
		return Signal()

	# Create independent tweens for each property to animate them in parallel
	# This is the Godot 4 approach since set_parallel() is no longer supported
	var tween_position = source_node.create_tween()
	var tween_scale = source_node.create_tween()
	var tween_modulate = source_node.create_tween()
	var tween_rotation = source_node.create_tween()

	# Validate all tweens were created successfully
	if not tween_position or not tween_scale or not tween_modulate or not tween_rotation:
		push_warning("UiAnimUtils.animate_reset_all(): Failed to create one or more tweens for target '%s'" % target.name)
		# Clean up any successfully created tweens
		if tween_position:
			tween_position.kill()
		if tween_scale:
			tween_scale.kill()
		if tween_modulate:
			tween_modulate.kill()
		if tween_rotation:
			tween_rotation.kill()
		return Signal()

	# Animate all properties in parallel using independent tweens
	tween_position.tween_property(target, 'position', snapshot.position, duration).set_trans(Tween.TRANS_SINE).set_ease(easing)
	tween_scale.tween_property(target, 'scale', snapshot.scale, duration).set_trans(Tween.TRANS_SINE).set_ease(easing)
	tween_modulate.tween_property(target, 'modulate', snapshot.modulate, duration).set_trans(Tween.TRANS_SINE).set_ease(easing)
	tween_rotation.tween_property(target, 'rotation_degrees', snapshot.rotation_degrees, duration).set_trans(Tween.TRANS_SINE).set_ease(easing)

	# Use position tween's finished signal as the primary completion signal
	# All tweens will complete at the same time since they have the same duration
	var tween = tween_position

	# Set non-animated properties immediately (pivot_offset and visible don't animate smoothly)
	target.pivot_offset = snapshot.pivot_offset
	target.visible = snapshot.visible

	# Connect to completion to optionally clear unified snapshot
	if clear_unified_after:
		tween.finished.connect(func():
			_clear_unified_snapshot(target)
		, CONNECT_ONE_SHOT)

	return tween.finished

## Manually clears the unified snapshot system for a target control.
## Useful for edge cases where animations are stopped manually or nodes are freed.
## This should be called if a control is removed from the scene while animations are active.
## [param target]: The control to clear unified snapshot for.
static func clear_unified_snapshot_for_target(target: Control) -> void:
	if not target:
		return

	_clear_unified_snapshot(target)

## Animates a control with a continuous breathing effect (subtle scale pulse).
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param duration]: Duration per cycle in seconds (default: 2.0).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: -1).
## [param pivot_offset]: Custom pivot offset for scaling (default: Vector2(-1, -1) uses center).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [return]: Signal that emits when animation finishes (or can be used to track infinite loops).
static func animate_breathing(source_node: Node, target: Control, duration: float = 2.0, repeat_count: int = -1, easing: int = Tween.EASE_OUT, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false) -> Signal:
	if not source_node or not target:
		push_warning("UiAnimUtils: Invalid source_node or target for animate_breathing")
		return Signal()
	
	if auto_visible:
		target.visible = true
	
	if pivot_offset == Vector2(-1, -1):
		target.pivot_offset = get_center_pivot_offset(target)
	else:
		target.pivot_offset = pivot_offset
	
	var original_scale = target.scale

	var animation_callable = func() -> Signal:
		var tween = UiAnimLoopRunner.create_tracked_tween(source_node)
		if not tween:
			push_warning("UiAnimUtils: Failed to create tween")
			return Signal()
		
		# Scale up
		tween.tween_property(target, 'scale', original_scale * BREATHING_SCALE_MULTIPLIER, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(easing)
		# Scale down
		tween.tween_property(target, 'scale', original_scale, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(easing)
		
		return tween.finished
	
	return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)

## Animates a control with a continuous wobble effect (subtle rotation oscillation).
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param duration]: Duration per cycle in seconds (default: 1.5).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: -1).
## [param pivot_offset]: Custom pivot offset for rotation (default: Vector2(-1, -1) uses center).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [return]: Signal that emits when animation finishes (or can be used to track infinite loops).
static func animate_wobble(source_node: Node, target: Control, duration: float = 1.5, repeat_count: int = -1, easing: int = Tween.EASE_OUT, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false) -> Signal:
	if not source_node or not target:
		push_warning("UiAnimUtils: Invalid source_node or target for animate_wobble")
		return Signal()
	
	if auto_visible:
		target.visible = true
	
	if pivot_offset == Vector2(-1, -1):
		target.pivot_offset = get_center_pivot_offset(target)
	else:
		target.pivot_offset = pivot_offset
	
	var original_rotation = target.rotation_degrees

	var animation_callable = func() -> Signal:
		var tween = UiAnimLoopRunner.create_tracked_tween(source_node)
		if not tween:
			push_warning("UiAnimUtils: Failed to create tween")
			return Signal()
		
		# Rotate left
		tween.tween_property(target, 'rotation_degrees', original_rotation - WOBBLE_ROTATION_DEGREES, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(easing)
		# Rotate right
		tween.tween_property(target, 'rotation_degrees', original_rotation + WOBBLE_ROTATION_DEGREES, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(easing)
		# Back to center
		tween.tween_property(target, 'rotation_degrees', original_rotation, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(easing)
		
		return tween.finished
	
	return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)

## Animates a control with a continuous float effect (gentle up/down movement).
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param duration]: Duration per cycle in seconds (default: 2.0).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: -1).
## [param easing]: Easing type for the animation (default: EASE_OUT).
## [param float_distance]: Distance to float in pixels (default: 10.0).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## Note: Position is automatically preserved using the unified baseline snapshot system.
## [return]: Signal that emits when animation finishes (or can be used to track infinite loops).
static func animate_float(source_node: Node, target: Control, duration: float = 2.0, repeat_count: int = -1, easing: int = Tween.EASE_OUT, float_distance: float = DEFAULT_FLOAT_DISTANCE_PX, auto_visible: bool = false) -> Signal:
	if not source_node or not target:
		push_warning("UiAnimUtils: Invalid source_node or target for animate_float")
		return Signal()

	if auto_visible:
		target.visible = true

	# Acquire baseline snapshot (automatic state preservation)
	var snapshot = _acquire_unified_snapshot(source_node, target)
	var saved_position: Vector2
	if snapshot:
		saved_position = snapshot.position
	else:
		push_warning("UiAnimUtils.animate_float(): Failed to acquire baseline snapshot, using current position")
		saved_position = target.position
	
	var animation_callable = func() -> Signal:
		var tween = UiAnimLoopRunner.create_tracked_tween(source_node)
		if not tween:
			push_warning("UiAnimUtils: Failed to create tween")
			return Signal()
		
		# Use saved position from baseline snapshot
		var original_position = saved_position
		
		# Move up
		tween.tween_property(target, 'position:y', original_position.y - float_distance, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(easing)
		# Move down
		tween.tween_property(target, 'position:y', original_position.y, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(easing)
		
		return tween.finished

	var result_signal = UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)

	# Connect to final completion to release unified snapshot
	result_signal.connect(func():
		_release_unified_snapshot(target, true)
	, CONNECT_ONE_SHOT)

	return result_signal

## Animates a control with a continuous glow pulse effect (modulate alpha pulse).
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param duration]: Duration per cycle in seconds (default: 1.5).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: -1).
## [param glow_min_alpha]: Minimum alpha for glow effect (default: 0.7).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [return]: Signal that emits when animation finishes (or can be used to track infinite loops).
static func animate_glow_pulse(source_node: Node, target: Control, duration: float = 1.5, repeat_count: int = -1, easing: int = Tween.EASE_OUT, glow_min_alpha: float = 0.7, auto_visible: bool = false) -> Signal:
	if not source_node or not target:
		push_warning("UiAnimUtils: Invalid source_node or target for animate_glow_pulse")
		return Signal()
	
	if auto_visible:
		target.visible = true
	
	var original_alpha = target.modulate.a
	
	var animation_callable = func() -> Signal:
		var tween = UiAnimLoopRunner.create_tracked_tween(source_node)
		if not tween:
			push_warning("UiAnimUtils: Failed to create tween")
			return Signal()
		
		# Fade to min
		tween.tween_property(target, 'modulate:a', glow_min_alpha, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(easing)
		# Fade back to original
		tween.tween_property(target, 'modulate:a', original_alpha, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(easing)
		
		return tween.finished
	
	return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)

## Animates a control with a color flash effect (quick color change and back).
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param flash_color]: Color to flash to (default: Color.YELLOW).
## [param duration]: Total flash duration in seconds (default: 0.2).
## [param flash_intensity]: How intense the flash (multiplier for color, default: 1.5).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [return]: Signal that emits when animation finishes.
static func animate_color_flash(source_node: Node, target: Control, flash_color: Color = Color.YELLOW, duration: float = 0.2, flash_intensity: float = 1.5, auto_visible: bool = false, easing: int = Tween.EASE_OUT) -> Signal:
	if not source_node or not target:
		push_warning("UiAnimUtils: Invalid source_node or target for animate_color_flash")
		return Signal()
	
	if auto_visible:
		target.visible = true

	# Use unified snapshot system for consistency
	var snapshot = _acquire_unified_snapshot(source_node, target)
	var original_modulate: Color
	if snapshot:
		original_modulate = snapshot.modulate
	else:
		# Fallback to current modulate if snapshot failed (null snapshot or acquisition failed)
		push_warning("UiAnimUtils.animate_color_flash(): Failed to acquire unified snapshot for target '%s', using current modulate" % target.name)
		original_modulate = target.modulate
	
	# Kill any existing tweens on modulate by creating a zero-duration tween
	# This interrupts any active flash animations before starting a new one
	var interrupt_tween = source_node.create_tween()
	if interrupt_tween:
		interrupt_tween.tween_property(target, "modulate", target.modulate, 0.0)
		interrupt_tween.kill()
	
	var flash_modulate = Color(
		flash_color.r * flash_intensity,
		flash_color.g * flash_intensity,
		flash_color.b * flash_intensity,
		original_modulate.a
	)
	
	var tween = source_node.create_tween()
	if not tween:
		push_warning("UiAnimUtils: Failed to create tween")
		return Signal()
	
	# Flash to color
	tween.tween_property(target, 'modulate', flash_modulate, duration * 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(easing)
	# Flash back to original (using the stored original from snapshot)
	tween.tween_property(target, 'modulate', original_modulate, duration * 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(easing)

	# Connect to completion to release unified snapshot
	tween.finished.connect(func():
		_release_unified_snapshot(target, true)
	, CONNECT_ONE_SHOT)

	return tween.finished

## Stagger animations (delegates to [UiAnimStaggerRunner]).
static func stop_stagger_animations(source_node: Node, targets: Array[Control]) -> void:
	UiAnimStaggerRunner.stop_stagger_animations(source_node, targets)

static func animate_stagger(source_node: Node, targets: Array[Control], delay_between: float = 0.1, animation_config: UiAnimTarget = null) -> Signal:
	return UiAnimStaggerRunner.animate_stagger(source_node, targets, delay_between, animation_config)

static func animate_stagger_multi(source_node: Node, targets: Array[Control], delay_between: float = 0.1, animation_configs: Array[UiAnimTarget] = []) -> Signal:
	return UiAnimStaggerRunner.animate_stagger_multi(source_node, targets, delay_between, animation_configs)

## Creates a delay signal that can be used in animation sequences.
## [param source_node]: The node to get the scene tree from.
## [param duration]: Delay duration in seconds.
## [return]: Signal that emits when delay finishes.
static func delay(source_node: Node, duration: float) -> Signal:
	return UiAnimDelayHelpers.delay(source_node, duration)

## Shows a control with an animation. Sets visible to true and plays the specified animation.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to show and animate.
## [param animation_type]: Animation type string ("pop", "slide_from_left", "slide_from_right", "slide_from_top", "fade_in", or empty string for no animation).
## [param speed]: Animation duration in seconds (default: 0.3).
static func show_animated(
	source_node: Node,
	target: Control,
	animation_type: String,
	speed: float = DEFAULT_SPEED
) -> void:
	await UiAnimPresetRunner.show_animated(source_node, target, animation_type, speed)

## Hides a control with an animation. Plays the specified animation then sets visible to false.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to hide and animate.
## [param animation_type]: Animation type string ("shrink", "slide_to_left", "slide_to_right", "slide_to_top", "fade_out", or empty string for no animation).
## [param speed]: Animation duration in seconds (default: 0.3).
static func hide_animated(
	source_node: Node,
	target: Control,
	animation_type: String,
	speed: float = DEFAULT_SPEED
) -> void:
	await UiAnimPresetRunner.hide_animated(source_node, target, animation_type, speed)

## Animation preset types for use with [method preset].
enum Preset {
	## Expand in animation (scale from 0 to 1).
	EXPAND_IN,
	## Expand out animation (scale from 1 to 0).
	EXPAND_OUT,
	## Pop in animation (same as EXPAND_IN, kept for backwards compatibility).
	POP_IN,
	## Pop out animation (same as EXPAND_OUT, kept for backwards compatibility).
	POP_OUT,
	## Slide in from left.
	SLIDE_IN_LEFT,
	## Slide in from right.
	SLIDE_IN_RIGHT,
	## Slide in from top.
	SLIDE_IN_TOP,
	## Slide out to left.
	SLIDE_OUT_LEFT,
	## Slide out to right.
	SLIDE_OUT_RIGHT,
	## Slide out to top.
	SLIDE_OUT_TOP,
	## Fade in animation.
	FADE_IN,
	## Fade out animation.
	FADE_OUT,
}

## Executes a preset animation type. Convenience method for using [enum Preset] values.
## [param preset_type]: The preset animation type to execute.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.3).
## [return]: Signal that emits when animation finishes.
static func preset(preset_type: Preset, source_node: Node, target: Control, speed := DEFAULT_SPEED) -> Signal:
	return UiAnimPresetRunner.preset(preset_type, source_node, target, speed)

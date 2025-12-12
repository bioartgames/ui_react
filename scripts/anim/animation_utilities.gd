## Static animation functions for UI element transitions.
##
## UIAnimationUtils provides a comprehensive set of common UI animations for animating UI elements
## with transitions like slides, fades, pops, and shrinks. All animation functions return a Signal
## that can be awaited for sequencing multiple animations. This makes it ideal for animating panel
## show and hide transitions, creating smooth UI transitions, sequencing multiple animations together,
## and custom animation needs beyond what reactive components provide. Unlike writing custom animation
## code, UIAnimationUtils provides a comprehensive set of common UI animations, consistent animation
## timing and easing, awaitable signals for sequencing, safe handling of edge cases like null nodes
## and viewport issues, and utility functions for animation setup like pivot calculation and tween
## creation. Reactive components like ReactivePanel and ReactiveButton use these functions internally,
## but you can also call them directly for custom animations.
##
## Example:
## [codeblock]
## # Animate panel expansion
## await UIAnimationUtils.animate_expand(self, panel).finished
##
## # Fade in a label
## await UIAnimationUtils.animate_fade_in(self, label).finished
##
## # Sequence multiple animations
## var sequence = AnimationSequence.create()
## sequence.add(func(): return UIAnimationUtils.animate_expand(self, panel))
## sequence.add(func(): return UIAnimationUtils.animate_fade_in(self, label))
## await sequence.play()
## [/codeblock]
class_name UIAnimationUtils
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
## Multiplier for calculating center pivot offset (0.5 = center).
const PIVOT_CENTER_MULTIPLIER := 0.5

## Calculates the center X position of a node relative to the viewport.
## [param source_node]: The node to get viewport from.
## [param target]: The control to calculate center for.
## [return]: The center X position, or 0.0 if calculation fails.
static func get_node_center(source_node: Node, target: Control) -> float:
	if not source_node or not target:
		var source_name: String = "null"
		var target_name: String = "null"
		if source_node != null:
			source_name = source_node.name
		if target != null:
			target_name = target.name
		push_warning("UIAnimationUtils.get_node_center(): Invalid source_node (%s) or target (%s). Tip: Ensure both nodes are valid and in the scene tree before calling this function." % [source_name, target_name])
		return 0.0
	
	var viewport = source_node.get_viewport()
	if not viewport:
		push_warning("UIAnimationUtils.get_node_center(): source_node '%s' has no viewport. Tip: Ensure the node is added to the scene tree and has a viewport (usually happens after _ready())." % source_node.name)
		return 0.0
	
	return (viewport.get_visible_rect().size.x * PIVOT_CENTER_MULTIPLIER) - (target.size.x * PIVOT_CENTER_MULTIPLIER)

## Calculates the pivot offset to center a control for scale animations.
## [param target]: The control to calculate pivot for.
## [return]: The pivot offset Vector2, or Vector2.ZERO if target is null.
static func get_center_pivot_offset(target: Control) -> Vector2:
	if not target:
		return Vector2.ZERO
	return Vector2(target.size.x * PIVOT_CENTER_MULTIPLIER, target.size.y * PIVOT_CENTER_MULTIPLIER)

## Creates a tween with null checking and error handling.
## [param node]: The node to create tween for.
## [return]: The created Tween, or null if creation failed.
static func create_safe_tween(node: Node) -> Tween:
	if not node:
		push_warning("UIAnimationUtils.create_safe_tween(): Cannot create tween - node is null. Tip: Ensure the node is valid and in the scene tree before creating tweens.")
		return null
	var t = node.create_tween()
	if not t:
		push_warning("UIAnimationUtils.create_safe_tween(): Failed to create tween on node '%s'. Tip: Check if the node is in the scene tree and not already processing (e.g., during _ready())." % node.name)
	return t

## Snapshot of a control's state for restoration.
## Contains position, scale, modulate, rotation, pivot_offset, and visible properties.
class ControlStateSnapshot:
	var position: Vector2
	var scale: Vector2
	var modulate: Color
	var rotation_degrees: float
	var pivot_offset: Vector2
	var visible: bool

## Creates a snapshot of a control's current state.
## [param target]: The control to snapshot.
## [return]: A ControlStateSnapshot containing the current state, or null if target is null.
static func snapshot_control_state(target: Control) -> ControlStateSnapshot:
	if not target:
		push_warning("UIAnimationUtils.snapshot_control_state(): Cannot snapshot state of null control. Tip: Ensure the target Control is valid and in the scene tree before calling this function.")
		return null
	
	var snapshot = ControlStateSnapshot.new()
	snapshot.position = target.position
	snapshot.scale = target.scale
	snapshot.modulate = target.modulate
	snapshot.rotation_degrees = target.rotation_degrees
	snapshot.pivot_offset = target.pivot_offset
	snapshot.visible = target.visible
	return snapshot

## Restores a control to a previously snapshotted state.
## [param target]: The control to restore.
## [param snapshot]: The ControlStateSnapshot to restore from.
static func restore_control_state(target: Control, snapshot: ControlStateSnapshot) -> void:
	if not target:
		push_warning("UIAnimationUtils.restore_control_state(): Cannot restore state of null control. Tip: Ensure the target Control is valid and in the scene tree before calling this function.")
		return
	
	if not snapshot:
		push_warning("UIAnimationUtils.restore_control_state(): Cannot restore from null snapshot. Tip: Ensure you have a valid ControlStateSnapshot from snapshot_control_state() before calling restore.")
		return
	
	target.position = snapshot.position
	target.scale = snapshot.scale
	target.modulate = snapshot.modulate
	target.rotation_degrees = snapshot.rotation_degrees
	target.pivot_offset = snapshot.pivot_offset
	target.visible = snapshot.visible

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
static func animate_slide_from_left(source_node: Node, target: Control, offset := DEFAULT_OFFSET, speed := DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0) -> Signal:
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		target.position.x = -target.size.x
		
		var t = source_node.create_tween()
		t.tween_property(target, 'position:x', offset, speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		return t.finished
	
	if repeat_count != 0:
		return _loop_animation(source_node, target, animation_callable, repeat_count)
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
static func animate_slide_to_left(source_node: Node, target: Control, _offset := DEFAULT_OFFSET, speed := DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0) -> Signal:
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		var t = source_node.create_tween()
		t.tween_property(target, 'position:x', -target.size.x, speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		
		if auto_visible:
			t.finished.connect(func(): target.visible = false)
		
		return t.finished
	
	if repeat_count != 0:
		return _loop_animation(source_node, target, animation_callable, repeat_count)
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
static func animate_slide_from_right(source_node: Node, target: Control, offset := DEFAULT_OFFSET, speed := DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0) -> Signal:
	var animation_callable = func() -> Signal:
		if not source_node or not target:
			push_warning("UIAnimationUtils: Invalid source_node or target for animate_slide_from_right")
			return Signal()
		
		if auto_visible:
			target.visible = true
		
		var viewport = source_node.get_viewport()
		if not viewport:
			push_warning("UIAnimationUtils: source_node has no viewport")
			return Signal()
		
		var viewport_size = viewport.get_visible_rect().size.x
		target.position.x = viewport_size
		
		var t = source_node.create_tween()
		if not t:
			push_warning("UIAnimationUtils: Failed to create tween")
			return Signal()
		
		t.tween_property(target, "position:x", (viewport_size - target.size.x) - offset, speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		return t.finished
	
	if repeat_count != 0:
		return _loop_animation(source_node, target, animation_callable, repeat_count)
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
static func animate_slide_to_right(source_node: Node, target: Control, _offset := DEFAULT_OFFSET, speed := DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0) -> Signal:
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		var t = source_node.create_tween()
		t.tween_property(target, 'position:x', source_node.get_viewport().size.x, speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		
		if auto_visible:
			t.finished.connect(func(): target.visible = false)
		
		return t.finished
	
	if repeat_count != 0:
		return _loop_animation(source_node, target, animation_callable, repeat_count)
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
static func animate_slide_from_top(source_node: Node, target: Control, offset: float = DEFAULT_OFFSET, speed := DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0) -> Signal:
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		target.position.y = -target.size.y
		
		var t = source_node.create_tween()
		t.tween_property(target, 'position:y', offset, speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		return t.finished
	
	if repeat_count != 0:
		return _loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control sliding out to the top of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation and visible=false after completion (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_slide_to_top(source_node: Node, target: Control, speed := DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0) -> Signal:
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		var t = source_node.create_tween()
		t.tween_property(target, 'position:y', -target.size.y, speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		
		if auto_visible:
			t.finished.connect(func(): target.visible = false)
		
		return t.finished
	
	if repeat_count != 0:
		return _loop_animation(source_node, target, animation_callable, repeat_count)
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
static func animate_expand(source_node: Node, target: Control, speed := DEFAULT_SPEED, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false, auto_setup: bool = false, auto_reset: bool = false, repeat_count: int = 0) -> Signal:
	if not source_node or not target:
		push_warning("UIAnimationUtils: Invalid source_node or target for animate_expand")
		return Signal()
	
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
		
		var t = source_node.create_tween()
		if not t:
			push_warning("UIAnimationUtils: Failed to create tween")
			return Signal()
		
		t.tween_property(target, 'scale', SCALE_MAX, speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		if auto_reset:
			t.finished.connect(func(): target.scale = SCALE_MAX)
		
		return t.finished
	
	if repeat_count != 0:
		return _loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control expanding horizontally (scale.x from 0.0 to 1.0).
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.15).
## [param pivot_offset]: Custom pivot offset for scaling (default: Vector2(-1, -1) uses center).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_expand_x(source_node: Node, target: Control, speed := SHRINK_ANIMATION_SPEED, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false, repeat_count: int = 0) -> Signal:
	if not source_node or not target:
		push_warning("UIAnimationUtils: Invalid source_node or target for animate_expand_x")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		if pivot_offset == Vector2(-1, -1):
			target.pivot_offset = get_center_pivot_offset(target)
		else:
			target.pivot_offset = pivot_offset
		
		# Always start from 0 on x-axis, preserve y-axis
		target.scale.x = ALPHA_MIN
		
		var t = source_node.create_tween()
		if not t:
			push_warning("UIAnimationUtils: Failed to create tween")
			return Signal()
		
		t.tween_property(target, 'scale:x', SCALE_MAX.x, speed).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
		return t.finished
	
	if repeat_count != 0:
		return _loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control expanding vertically (scale.y from 0.0 to 1.0).
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.15).
## [param pivot_offset]: Custom pivot offset for scaling (default: Vector2(-1, -1) uses center).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_expand_y(source_node: Node, target: Control, speed := SHRINK_ANIMATION_SPEED, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false, repeat_count: int = 0) -> Signal:
	if not source_node or not target:
		push_warning("UIAnimationUtils: Invalid source_node or target for animate_expand_y")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		if pivot_offset == Vector2(-1, -1):
			target.pivot_offset = get_center_pivot_offset(target)
		else:
			target.pivot_offset = pivot_offset
		
		# Always start from 0 on y-axis, preserve x-axis
		target.scale.y = ALPHA_MIN
		
		var t = source_node.create_tween()
		if not t:
			push_warning("UIAnimationUtils: Failed to create tween")
			return Signal()
		
		t.tween_property(target, 'scale:y', SCALE_MAX.y, speed).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
		return t.finished
	
	if repeat_count != 0:
		return _loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

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
static func animate_shrink(source_node: Node, target: Control, speed := DEFAULT_SPEED, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false, auto_setup: bool = false, auto_reset: bool = false, repeat_count: int = 0) -> Signal:
	if not source_node or not target:
		push_warning("UIAnimationUtils: Invalid source_node or target for animate_shrink")
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

		var t = source_node.create_tween()
		if not t:
			push_warning("UIAnimationUtils: Failed to create tween")
			return Signal()
		
		t.tween_property(target, 'scale', SCALE_MIN, speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		
		if auto_visible:
			t.finished.connect(func(): target.visible = false)
		
		if auto_reset:
			t.finished.connect(func(): target.scale = SCALE_MAX)
		
		return t.finished
	
	if repeat_count != 0:
		return _loop_animation(source_node, target, animation_callable, repeat_count)
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
static func animate_shrink_x(source_node: Node, target: Control, speed := SHRINK_ANIMATION_SPEED, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false, auto_setup: bool = false, auto_reset: bool = false, repeat_count: int = 0) -> Signal:
	if not source_node or not target:
		push_warning("UIAnimationUtils: Invalid source_node or target for animate_shrink_x")
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

		var t = source_node.create_tween()
		if not t:
			push_warning("UIAnimationUtils: Failed to create tween")
			return Signal()
		
		t.tween_property(target, 'scale:x', ALPHA_MIN, speed)
		
		if auto_visible:
			t.finished.connect(func(): target.visible = false)
		
		if auto_reset:
			t.finished.connect(func(): target.scale.x = SCALE_MAX.x)
		
		return t.finished
	
	if repeat_count != 0:
		return _loop_animation(source_node, target, animation_callable, repeat_count)
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
static func animate_shrink_y(source_node: Node, target: Control, speed := SHRINK_ANIMATION_SPEED, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false, auto_setup: bool = false, auto_reset: bool = false, repeat_count: int = 0) -> Signal:
	if not source_node or not target:
		push_warning("UIAnimationUtils: Invalid source_node or target for animate_shrink_y")
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

		var t = source_node.create_tween()
		if not t:
			push_warning("UIAnimationUtils: Failed to create tween")
			return Signal()
		
		t.tween_property(target, 'scale:y', ALPHA_MIN, speed)
		
		if auto_visible:
			t.finished.connect(func(): target.visible = false)
		
		if auto_reset:
			t.finished.connect(func(): target.scale.y = SCALE_MAX.y)
		
		return t.finished
	
	if repeat_count != 0:
		return _loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control fading in (modulate.a from 0.0 to 1.0).
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_fade_in(source_node: Node, target: Control, speed := DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0) -> Signal:
	if not source_node or not target:
		push_warning("UIAnimationUtils: Invalid source_node or target for animate_fade_in")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		target.modulate.a = ALPHA_MIN
		
		var t = source_node.create_tween()
		if not t:
			push_warning("UIAnimationUtils: Failed to create tween")
			return Signal()
		
		t.tween_property(target, 'modulate:a', ALPHA_MAX, speed).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
		return t.finished
	
	if repeat_count != 0:
		return _loop_animation(source_node, target, animation_callable, repeat_count)
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
static func animate_fade_out(source_node: Node, target: Control, speed := DEFAULT_SPEED, auto_visible: bool = false, auto_reset: bool = false, repeat_count: int = 0) -> Signal:
	if not source_node or not target:
		push_warning("UIAnimationUtils: Invalid source_node or target for animate_fade_out")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		var t = source_node.create_tween()
		if not t:
			push_warning("UIAnimationUtils: Failed to create tween")
			return Signal()
		
		t.tween_property(target, 'modulate:a', ALPHA_MIN, speed).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		
		if auto_visible:
			t.finished.connect(func(): target.visible = false)
		
		if auto_reset:
			t.finished.connect(func(): target.modulate.a = ALPHA_MAX)
		
		return t.finished
	
	if repeat_count != 0:
		return _loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control sliding from the left edge to the center of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_from_left_to_center(source_node: Node, target: Control, speed := DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0) -> Signal:
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		target.position.x = -target.size.x
		
		var t = source_node.create_tween()
		t.tween_property(target, 'position:x', get_node_center(source_node, target), speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		return t.finished
	
	if repeat_count != 0:
		return _loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control sliding from the center to the left edge of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation and visible=false after completion (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_from_center_to_left(source_node: Node, target: Control, speed := DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0) -> Signal:
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		var t = source_node.create_tween()
		t.tween_property(target, 'position:x', -target.size.x, speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		
		if auto_visible:
			t.finished.connect(func(): target.visible = false)
		
		return t.finished
	
	if repeat_count != 0:
		return _loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control sliding from the right edge to the center of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_from_right_to_center(source_node: Node, target: Control, speed := DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0) -> Signal:
	if not source_node or not target:
		push_warning("UIAnimationUtils: Invalid source_node or target for animate_from_right_to_center")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		var viewport = source_node.get_viewport()
		if not viewport:
			push_warning("UIAnimationUtils: source_node has no viewport")
			return Signal()
		
		target.position.x = viewport.get_visible_rect().size.x
		
		var t = source_node.create_tween()
		if not t:
			push_warning("UIAnimationUtils: Failed to create tween")
			return Signal()
		
		t.tween_property(target, 'position:x', get_node_center(source_node, target), speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		return t.finished
	
	if repeat_count != 0:
		return _loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control sliding from the center to the right edge of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation and visible=false after completion (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_from_center_to_right(source_node: Node, target: Control, speed := DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0) -> Signal:
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		var t = source_node.create_tween()
		t.tween_property(target, 'position:x', target.size.x, speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		
		if auto_visible:
			t.finished.connect(func(): target.visible = false)
		
		return t.finished
	
	if repeat_count != 0:
		return _loop_animation(source_node, target, animation_callable, repeat_count)
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
static func animate_slide_from_bottom(source_node: Node, target: Control, offset: float = DEFAULT_OFFSET, speed := DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0) -> Signal:
	if not source_node or not target:
		push_warning("UIAnimationUtils: Invalid source_node or target for animate_slide_from_bottom")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		var viewport = source_node.get_viewport()
		if not viewport:
			push_warning("UIAnimationUtils: source_node has no viewport")
			return Signal()
		
		var viewport_size = viewport.get_visible_rect().size.y
		target.position.y = viewport_size
		
		var t = source_node.create_tween()
		if not t:
			push_warning("UIAnimationUtils: Failed to create tween")
			return Signal()
		
		t.tween_property(target, 'position:y', (viewport_size - target.size.y) - offset, speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		return t.finished
	
	if repeat_count != 0:
		return _loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control sliding out to the bottom of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation and visible=false after completion (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_slide_to_bottom(source_node: Node, target: Control, speed := DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0) -> Signal:
	if not source_node or not target:
		push_warning("UIAnimationUtils: Invalid source_node or target for animate_slide_to_bottom")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		var viewport = source_node.get_viewport()
		if not viewport:
			push_warning("UIAnimationUtils: source_node has no viewport")
			return Signal()
		
		var t = source_node.create_tween()
		if not t:
			push_warning("UIAnimationUtils: Failed to create tween")
			return Signal()
		
		t.tween_property(target, 'position:y', viewport.get_visible_rect().size.y, speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		
		if auto_visible:
			t.finished.connect(func(): target.visible = false)
		
		return t.finished
	
	if repeat_count != 0:
		return _loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Calculates the center Y position of a node relative to the viewport.
## [param source_node]: The node to get viewport from.
## [param target]: The control to calculate center for.
## [return]: The center Y position, or 0.0 if calculation fails.
static func get_node_center_y(source_node: Node, target: Control) -> float:
	if not source_node or not target:
		push_warning("UIAnimationUtils: Invalid source_node or target for get_node_center_y")
		return 0.0
	
	var viewport = source_node.get_viewport()
	if not viewport:
		push_warning("UIAnimationUtils: source_node has no viewport")
		return 0.0
	
	return (viewport.get_visible_rect().size.y * PIVOT_CENTER_MULTIPLIER) - (target.size.y * PIVOT_CENTER_MULTIPLIER)

## Animates a control sliding from the top edge to the center of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_from_top_to_center(source_node: Node, target: Control, speed := DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0) -> Signal:
	if not source_node or not target:
		push_warning("UIAnimationUtils: Invalid source_node or target for animate_from_top_to_center")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		target.position.y = -target.size.y
		
		var t = source_node.create_tween()
		if not t:
			push_warning("UIAnimationUtils: Failed to create tween")
			return Signal()
		
		t.tween_property(target, 'position:y', get_node_center_y(source_node, target), speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		return t.finished
	
	if repeat_count != 0:
		return _loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control sliding from the center to the top edge of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation and visible=false after completion (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_from_center_to_top(source_node: Node, target: Control, speed := DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0) -> Signal:
	if not source_node or not target:
		push_warning("UIAnimationUtils: Invalid source_node or target for animate_from_center_to_top")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		var t = source_node.create_tween()
		if not t:
			push_warning("UIAnimationUtils: Failed to create tween")
			return Signal()
		
		t.tween_property(target, 'position:y', -target.size.y, speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		
		if auto_visible:
			t.finished.connect(func(): target.visible = false)
		
		return t.finished
	
	if repeat_count != 0:
		return _loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control sliding from the bottom edge to the center of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_from_bottom_to_center(source_node: Node, target: Control, speed := DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0) -> Signal:
	if not source_node or not target:
		push_warning("UIAnimationUtils: Invalid source_node or target for animate_from_bottom_to_center")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		var viewport = source_node.get_viewport()
		if not viewport:
			push_warning("UIAnimationUtils: source_node has no viewport")
			return Signal()
		
		target.position.y = viewport.get_visible_rect().size.y
		
		var t = source_node.create_tween()
		if not t:
			push_warning("UIAnimationUtils: Failed to create tween")
			return Signal()
		
		t.tween_property(target, 'position:y', get_node_center_y(source_node, target), speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		return t.finished
	
	if repeat_count != 0:
		return _loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control sliding from the center to the bottom edge of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation and visible=false after completion (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_from_center_to_bottom(source_node: Node, target: Control, speed := DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0) -> Signal:
	if not source_node or not target:
		push_warning("UIAnimationUtils: Invalid source_node or target for animate_from_center_to_bottom")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		var viewport = source_node.get_viewport()
		if not viewport:
			push_warning("UIAnimationUtils: source_node has no viewport")
			return Signal()
		
		var t = source_node.create_tween()
		if not t:
			push_warning("UIAnimationUtils: Failed to create tween")
			return Signal()
		
		t.tween_property(target, 'position:y', viewport.get_visible_rect().size.y, speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		
		if auto_visible:
			t.finished.connect(func(): target.visible = false)
		
		return t.finished
	
	if repeat_count != 0:
		return _loop_animation(source_node, target, animation_callable, repeat_count)
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
static func animate_bounce_in(source_node: Node, target: Control, speed := DEFAULT_SPEED, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false, repeat_count: int = 0) -> Signal:
	if not source_node or not target:
		push_warning("UIAnimationUtils: Invalid source_node or target for animate_bounce_in")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		if pivot_offset == Vector2(-1, -1):
			target.pivot_offset = get_center_pivot_offset(target)
		else:
			target.pivot_offset = pivot_offset
		
		target.scale = SCALE_MIN
		
		var t = source_node.create_tween()
		if not t:
			push_warning("UIAnimationUtils: Failed to create tween")
			return Signal()
		
		t.tween_property(target, 'scale', SCALE_MAX, speed).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		
		return t.finished
	
	if repeat_count != 0:
		return _loop_animation(source_node, target, animation_callable, repeat_count)
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
static func animate_bounce_out(source_node: Node, target: Control, speed := DEFAULT_SPEED, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false, auto_setup: bool = false, auto_reset: bool = false, repeat_count: int = 0) -> Signal:
	if not source_node or not target:
		push_warning("UIAnimationUtils: Invalid source_node or target for animate_bounce_out")
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

		var t = source_node.create_tween()
		if not t:
			push_warning("UIAnimationUtils: Failed to create tween")
			return Signal()
		
		t.tween_property(target, 'scale', SCALE_MIN, speed).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_IN)
		
		if auto_visible:
			t.finished.connect(func(): target.visible = false)
		
		if auto_reset:
			t.finished.connect(func(): target.scale = SCALE_MAX)
		
		return t.finished
	
	if repeat_count != 0:
		return _loop_animation(source_node, target, animation_callable, repeat_count)
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
static func animate_elastic_in(source_node: Node, target: Control, speed := DEFAULT_SPEED, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false, repeat_count: int = 0) -> Signal:
	if not source_node or not target:
		push_warning("UIAnimationUtils: Invalid source_node or target for animate_elastic_in")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		if pivot_offset == Vector2(-1, -1):
			target.pivot_offset = get_center_pivot_offset(target)
		else:
			target.pivot_offset = pivot_offset
		
		target.scale = SCALE_MIN
		
		var t = source_node.create_tween()
		if not t:
			push_warning("UIAnimationUtils: Failed to create tween")
			return Signal()
		
		t.tween_property(target, 'scale', SCALE_MAX, speed).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		
		return t.finished
	
	if repeat_count != 0:
		return _loop_animation(source_node, target, animation_callable, repeat_count)
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
static func animate_elastic_out(source_node: Node, target: Control, speed := DEFAULT_SPEED, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false, auto_setup: bool = false, auto_reset: bool = false, repeat_count: int = 0) -> Signal:
	if not source_node or not target:
		push_warning("UIAnimationUtils: Invalid source_node or target for animate_elastic_out")
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

		var t = source_node.create_tween()
		if not t:
			push_warning("UIAnimationUtils: Failed to create tween")
			return Signal()
		
		t.tween_property(target, 'scale', SCALE_MIN, speed).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_IN)
		
		if auto_visible:
			t.finished.connect(func(): target.visible = false)
		
		if auto_reset:
			t.finished.connect(func(): target.scale = SCALE_MAX)
		
		return t.finished
	
	if repeat_count != 0:
		return _loop_animation(source_node, target, animation_callable, repeat_count)
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
static func animate_rotate_in(source_node: Node, target: Control, speed := DEFAULT_SPEED, start_angle: float = -360.0, auto_visible: bool = false, repeat_count: int = 0) -> Signal:
	if not source_node or not target:
		push_warning("UIAnimationUtils: Invalid source_node or target for animate_rotate_in")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		target.rotation_degrees = start_angle
		
		var t = source_node.create_tween()
		if not t:
			push_warning("UIAnimationUtils: Failed to create tween")
			return Signal()
		
		t.tween_property(target, 'rotation_degrees', 0.0, speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		return t.finished
	
	if repeat_count != 0:
		return _loop_animation(source_node, target, animation_callable, repeat_count)
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
static func animate_rotate_out(source_node: Node, target: Control, speed := DEFAULT_SPEED, end_angle: float = 360.0, auto_visible: bool = false, auto_setup: bool = false, auto_reset: bool = false, repeat_count: int = 0) -> Signal:
	if not source_node or not target:
		push_warning("UIAnimationUtils: Invalid source_node or target for animate_rotate_out")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		if auto_setup:
			target.rotation_degrees = 0.0
		
		var t = source_node.create_tween()
		if not t:
			push_warning("UIAnimationUtils: Failed to create tween")
			return Signal()
		
		t.tween_property(target, 'rotation_degrees', end_angle, speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		
		if auto_visible:
			t.finished.connect(func(): target.visible = false)
		
		if auto_reset:
			t.finished.connect(func(): target.rotation_degrees = 0.0)
		
		return t.finished
	
	if repeat_count != 0:
		return _loop_animation(source_node, target, animation_callable, repeat_count)
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
static func animate_pop(source_node: Node, target: Control, speed := DEFAULT_SPEED, overshoot: float = 1.2, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false, repeat_count: int = 0) -> Signal:
	if not source_node or not target:
		push_warning("UIAnimationUtils: Invalid source_node or target for animate_pop")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		if pivot_offset == Vector2(-1, -1):
			target.pivot_offset = get_center_pivot_offset(target)
		else:
			target.pivot_offset = pivot_offset
		
		target.scale = SCALE_MIN
		
		var t = source_node.create_tween()
		if not t:
			push_warning("UIAnimationUtils: Failed to create tween")
			return Signal()
		
		# First tween: scale to overshoot
		t.tween_property(target, 'scale', Vector2(overshoot, overshoot) * SCALE_MAX, speed * 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		# Second tween: settle back to 1.0
		t.tween_property(target, 'scale', SCALE_MAX, speed * 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		
		return t.finished
	
	if repeat_count != 0:
		return _loop_animation(source_node, target, animation_callable, repeat_count)
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
static func animate_pulse(source_node: Node, target: Control, speed := 0.5, pulse_amount: float = 1.1, pulse_count: int = 2, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false, repeat_count: int = 0) -> Signal:
	if not source_node or not target:
		push_warning("UIAnimationUtils: Invalid source_node or target for animate_pulse")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		if pivot_offset == Vector2(-1, -1):
			target.pivot_offset = get_center_pivot_offset(target)
		else:
			target.pivot_offset = pivot_offset
		
		var original_scale = target.scale
		var t = source_node.create_tween()
		if not t:
			push_warning("UIAnimationUtils: Failed to create tween")
			return Signal()
		
		# Create pulse cycles
		for i in range(pulse_count):
			t.tween_property(target, 'scale', Vector2(pulse_amount, pulse_amount) * original_scale, speed * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			t.tween_property(target, 'scale', original_scale, speed * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		return t.finished
	
	if repeat_count != 0:
		return _loop_animation(source_node, target, animation_callable, repeat_count)
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
## [return]: Signal that emits when animation finishes.
static func animate_shake(source_node: Node, target: Control, speed := 0.5, intensity: float = 10.0, shake_count: int = 5, auto_visible: bool = false, repeat_count: int = 0) -> Signal:
	if not source_node or not target:
		push_warning("UIAnimationUtils: Invalid source_node or target for animate_shake")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		var original_position = target.position
		var t = source_node.create_tween()
		if not t:
			push_warning("UIAnimationUtils: Failed to create tween")
			return Signal()
		
		var shake_duration = speed / shake_count
		
		# Create shake movements
		for i in range(shake_count):
			var offset_x = intensity * (1.0 if i % 2 == 0 else -1.0)
			var y_index = int(i * 0.5)
			var offset_y = intensity * 0.5 * (1.0 if y_index % 2 == 0 else -1.0)
			t.tween_property(target, 'position', original_position + Vector2(offset_x, offset_y), shake_duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			t.tween_property(target, 'position', original_position, shake_duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		return t.finished
	
	if repeat_count != 0:
		return _loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control with a continuous breathing effect (subtle scale pulse).
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param duration]: Duration per cycle in seconds (default: 2.0).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: -1).
## [param pivot_offset]: Custom pivot offset for scaling (default: Vector2(-1, -1) uses center).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [return]: Signal that emits when animation finishes (or can be used to track infinite loops).
static func animate_breathing(source_node: Node, target: Control, duration: float = 2.0, repeat_count: int = -1, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false) -> Signal:
	if not source_node or not target:
		push_warning("UIAnimationUtils: Invalid source_node or target for animate_breathing")
		return Signal()
	
	if auto_visible:
		target.visible = true
	
	if pivot_offset == Vector2(-1, -1):
		target.pivot_offset = get_center_pivot_offset(target)
	else:
		target.pivot_offset = pivot_offset
	
	var original_scale = target.scale
	var breath_amount = 1.05  # Subtle 5% scale increase
	
	var animation_callable = func() -> Signal:
		# Get helper from source_node metadata if available
		var helper: _AnimationLoopHelper = null
		if source_node.has_meta("_animation_helper_ref"):
			var helper_ref = source_node.get_meta("_animation_helper_ref") as WeakRef
			if helper_ref and helper_ref.get_ref():
				helper = helper_ref.get_ref() as _AnimationLoopHelper
		
		var t = _AnimationLoopHelper.create_tracked_tween(source_node, helper)
		if not t:
			push_warning("UIAnimationUtils: Failed to create tween")
			return Signal()
		
		# Scale up
		t.tween_property(target, 'scale', original_scale * breath_amount, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		# Scale down
		t.tween_property(target, 'scale', original_scale, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		return t.finished
	
	return _loop_animation(source_node, target, animation_callable, repeat_count)

## Animates a control with a continuous wobble effect (subtle rotation oscillation).
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param duration]: Duration per cycle in seconds (default: 1.5).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: -1).
## [param pivot_offset]: Custom pivot offset for rotation (default: Vector2(-1, -1) uses center).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [return]: Signal that emits when animation finishes (or can be used to track infinite loops).
static func animate_wobble(source_node: Node, target: Control, duration: float = 1.5, repeat_count: int = -1, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false) -> Signal:
	if not source_node or not target:
		push_warning("UIAnimationUtils: Invalid source_node or target for animate_wobble")
		return Signal()
	
	if auto_visible:
		target.visible = true
	
	if pivot_offset == Vector2(-1, -1):
		target.pivot_offset = get_center_pivot_offset(target)
	else:
		target.pivot_offset = pivot_offset
	
	var original_rotation = target.rotation_degrees
	var wobble_amount = 3.0  # Subtle 3 degree rotation
	
	var animation_callable = func() -> Signal:
		var t = source_node.create_tween()
		if not t:
			push_warning("UIAnimationUtils: Failed to create tween")
			return Signal()
		
		# Rotate left
		t.tween_property(target, 'rotation_degrees', original_rotation - wobble_amount, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		# Rotate right
		t.tween_property(target, 'rotation_degrees', original_rotation + wobble_amount, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		# Back to center
		t.tween_property(target, 'rotation_degrees', original_rotation, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		return t.finished
	
	return _loop_animation(source_node, target, animation_callable, repeat_count)

## Animates a control with a continuous float effect (gentle up/down movement).
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param duration]: Duration per cycle in seconds (default: 2.0).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: -1).
## [param float_distance]: Distance to float in pixels (default: 10.0).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [return]: Signal that emits when animation finishes (or can be used to track infinite loops).
static func animate_float(source_node: Node, target: Control, duration: float = 2.0, repeat_count: int = -1, float_distance: float = 10.0, auto_visible: bool = false) -> Signal:
	if not source_node or not target:
		push_warning("UIAnimationUtils: Invalid source_node or target for animate_float")
		return Signal()
	
	if auto_visible:
		target.visible = true
	
	var original_position = target.position
	
	var animation_callable = func() -> Signal:
		var t = source_node.create_tween()
		if not t:
			push_warning("UIAnimationUtils: Failed to create tween")
			return Signal()
		
		# Move up
		t.tween_property(target, 'position:y', original_position.y - float_distance, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		# Move down
		t.tween_property(target, 'position:y', original_position.y, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		return t.finished
	
	return _loop_animation(source_node, target, animation_callable, repeat_count)

## Animates a control with a continuous glow pulse effect (modulate alpha pulse).
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param duration]: Duration per cycle in seconds (default: 1.5).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: -1).
## [param glow_min_alpha]: Minimum alpha for glow effect (default: 0.7).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [return]: Signal that emits when animation finishes (or can be used to track infinite loops).
static func animate_glow_pulse(source_node: Node, target: Control, duration: float = 1.5, repeat_count: int = -1, glow_min_alpha: float = 0.7, auto_visible: bool = false) -> Signal:
	if not source_node or not target:
		push_warning("UIAnimationUtils: Invalid source_node or target for animate_glow_pulse")
		return Signal()
	
	if auto_visible:
		target.visible = true
	
	var original_alpha = target.modulate.a
	
	var animation_callable = func() -> Signal:
		# Get helper from source_node metadata if available
		var helper: _AnimationLoopHelper = null
		if source_node.has_meta("_animation_helper_ref"):
			var helper_ref = source_node.get_meta("_animation_helper_ref") as WeakRef
			if helper_ref and helper_ref.get_ref():
				helper = helper_ref.get_ref() as _AnimationLoopHelper
		
		var t = _AnimationLoopHelper.create_tracked_tween(source_node, helper)
		if not t:
			push_warning("UIAnimationUtils: Failed to create tween")
			return Signal()
		
		# Fade to min
		t.tween_property(target, 'modulate:a', glow_min_alpha, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		# Fade back to original
		t.tween_property(target, 'modulate:a', original_alpha, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		return t.finished
	
	return _loop_animation(source_node, target, animation_callable, repeat_count)

## Animates a control with a color flash effect (quick color change and back).
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param flash_color]: Color to flash to (default: Color.YELLOW).
## [param duration]: Total flash duration in seconds (default: 0.2).
## [param flash_intensity]: How intense the flash (multiplier for color, default: 1.5).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [return]: Signal that emits when animation finishes.
static func animate_color_flash(source_node: Node, target: Control, flash_color: Color = Color.YELLOW, duration: float = 0.2, flash_intensity: float = 1.5, auto_visible: bool = false) -> Signal:
	if not source_node or not target:
		push_warning("UIAnimationUtils: Invalid source_node or target for animate_color_flash")
		return Signal()
	
	if auto_visible:
		target.visible = true
	
	# Store the true original modulate in metadata if not already stored
	# This ensures we always restore to the original color, not an intermediate flash color
	# when button mashing causes multiple flashes to overlap
	if not target.has_meta("_original_modulate"):
		target.set_meta("_original_modulate", target.modulate)
	
	# Get the true original modulate from metadata (always use the stored original)
	var original_modulate: Color = target.get_meta("_original_modulate") as Color
	
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
	
	var t = source_node.create_tween()
	if not t:
		push_warning("UIAnimationUtils: Failed to create tween")
		return Signal()
	
	# Flash to color
	t.tween_property(target, 'modulate', flash_modulate, duration * 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# Flash back to original (using the stored original from metadata)
	t.tween_property(target, 'modulate', original_modulate, duration * 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	return t.finished

## Stops all active stagger animations (reveal and hide) for the given targets.
## Kills all tweens and stops helper nodes to prevent animation conflicts.
## [param source_node]: The node that owns the stagger helpers (usually self).
## [param targets]: Array of controls that may have active stagger animations.
static func stop_stagger_animations(source_node: Node, targets: Array[Control]) -> void:
	if not source_node:
		return
	
	# Find and stop all stagger helpers
	for child in source_node.get_children():
		if child.has_meta("_is_stagger_helper"):
			if child.has_method("stop"):
				child.stop()
			else:
				child.queue_free()
	
	# Kill all tweens on all targets by interrupting them
	for target in targets:
		if target and is_instance_valid(target):
			# Create and immediately kill a tween to interrupt any active tweens
			# This is the Godot 4 way to stop tweens
			var interrupt_tween = source_node.create_tween()
			if interrupt_tween:
				# Interrupt common animated properties
				interrupt_tween.tween_property(target, "modulate", target.modulate, 0.0)
				interrupt_tween.tween_property(target, "scale", target.scale, 0.0)
				interrupt_tween.tween_property(target, "position", target.position, 0.0)
				interrupt_tween.kill()
			
			# Also directly set properties to ensure tweens are interrupted
			var current_modulate = target.modulate
			var current_scale = target.scale
			var current_position = target.position
			target.modulate = current_modulate
			target.scale = current_scale
			target.position = current_position

## Animates multiple controls with a stagger effect (each animates with a delay).
## Automatically interrupts any existing stagger animations before starting.
## [param source_node]: The node to create tweens from (usually self).
## [param targets]: Array of controls to animate.
## [param delay_between]: Delay between each item in seconds (default: 0.1).
## [param animation_config]: AnimationActionConfig that defines the animation to apply to each target.
## The config's reverse property determines if items are revealed (false) or hidden (true).
## All customization options (flash_color, pop_overshoot, etc.) are supported.
## [return]: Signal that emits when all animations complete.
static func animate_stagger(source_node: Node, targets: Array[Control], delay_between: float = 0.1, animation_config: AnimationActionConfig = null) -> Signal:
	if not source_node or targets.size() == 0:
		push_warning("UIAnimationUtils: Invalid source_node or empty targets for animate_stagger")
		return Signal()
	
	if not animation_config:
		push_warning("UIAnimationUtils: animate_stagger requires animation_config")
		return Signal()
	
	# Stop any existing stagger animations first
	stop_stagger_animations(source_node, targets)
	
	# Reset targets based on whether we're revealing or hiding
	var is_reveal = not animation_config.reverse

	for target in targets:
		if target and is_instance_valid(target):
			if is_reveal:
				# For reveal: ensure target is visible (animation will handle its own initial state via auto_visible)
				# Don't pre-set scale/alpha - let each animation handle what it needs
				target.visible = true
			else:
				# For hide: ensure target is visible so hide animation can work
				target.visible = true
				# Reset to normal state so hide animations start from visible state
				target.modulate.a = 1.0
				target.scale = Vector2.ONE
	
	var helper = _StaggerHelper.new()
	source_node.add_child(helper)
	helper.execute_stagger(source_node, targets, delay_between, animation_config, is_reveal)
	return helper.all_finished

## Animates multiple controls with a stagger effect using per-target configs.
## Automatically interrupts any existing stagger animations before starting.
## [param source_node]: The node to create tweens from (usually self).
## [param targets]: Array of controls to animate.
## [param delay_between]: Delay between each item in seconds (default: 0.1).
## [param animation_configs]: Array of AnimationActionConfig, one per target.
## Each config's reverse property determines if items are revealed (false) or hidden (true).
## All customization options (flash_color, pop_overshoot, etc.) are supported per target.
## If configs array is smaller than targets, the last config is reused for remaining targets.
## [return]: Signal that emits when all animations complete.
static func animate_stagger_multi(source_node: Node, targets: Array[Control], delay_between: float = 0.1, animation_configs: Array[AnimationActionConfig] = []) -> Signal:
	if not source_node or targets.size() == 0:
		push_warning("UIAnimationUtils: Invalid source_node or empty targets for animate_stagger_multi")
		return Signal()
	
	if animation_configs.size() == 0:
		push_warning("UIAnimationUtils: animate_stagger_multi requires at least one animation_config")
		return Signal()
	
	# Stop any existing stagger animations first
	stop_stagger_animations(source_node, targets)
	
	# Reset targets based on their individual configs
	for i in range(targets.size()):
		var target = targets[i]
		if not target or not is_instance_valid(target):
			continue
		
		# Get config for this target (use last config if not enough provided)
		var config_idx = min(i, animation_configs.size() - 1)
		var config = animation_configs[config_idx]
		if not config:
			continue
		
		var is_reveal = not config.reverse
		
		if is_reveal:
			# For reveal: ensure target is visible (animation will handle its own initial state)
			target.visible = true
		else:
			# For hide: ensure target is visible so hide animation can work
			target.visible = true
			# Reset to normal state so hide animations start from visible state
			target.modulate.a = 1.0
			target.scale = Vector2.ONE
	
	var helper = _StaggerHelper.new()
	source_node.add_child(helper)
	helper.execute_stagger_multi(source_node, targets, delay_between, animation_configs)
	return helper.all_finished

## Helper node for stagger animations.
class _StaggerHelper extends Node:
	var all_finished = Signal()
	var _is_running = false
	var _source_node: Node = null
	var _targets: Array[Control] = []

	func _init():
		set_meta("_is_stagger_helper", true)
		set_meta("_stagger_type", "stagger")

	## Stops the stagger animation and cleans up.
	func stop() -> void:
		_is_running = false
		# Kill all tweens on all targets
		for target in _targets:
			if target and is_instance_valid(target):
				# Create and kill a tween to interrupt any active tweens
				var interrupt_tween = _source_node.create_tween()
				if interrupt_tween:
					interrupt_tween.kill()
				# Directly set properties to interrupt tweens
				var current_modulate = target.modulate
				var current_scale = target.scale
				var current_position = target.position
				target.modulate = current_modulate
				target.scale = current_scale
				target.position = current_position
		queue_free()

	func execute_stagger(source_node: Node, targets: Array[Control], delay_between: float, animation_config: AnimationActionConfig, is_reveal: bool) -> void:
		_source_node = source_node
		_targets = targets
		_is_running = true

		# Determine iteration order: forward for reveal, reverse for hide
		var start_idx = 0
		var end_idx = targets.size()
		var step = 1
		if not is_reveal:
			start_idx = targets.size() - 1
			end_idx = -1
			step = -1

		var i = start_idx
		while i != end_idx:
			if not _is_running:
				return

			var target = targets[i]
			if target == null or not is_instance_valid(target):
				i += step
				continue

			# Wait for delay (skip delay for first item)
			if i != start_idx:
				await UIAnimationUtils.delay(source_node, delay_between)
				if not _is_running:
					return

			# Apply animation using the config's apply_to_control method
			var animation_signal = animation_config.apply_to_control(source_node, target)
			if animation_signal:
				await animation_signal

			if not _is_running:
				return

			i += step

		if _is_running:
			all_finished.emit()
		queue_free()

	func execute_stagger_multi(source_node: Node, targets: Array[Control], delay_between: float, animation_configs: Array[AnimationActionConfig]) -> void:
		_source_node = source_node
		_targets = targets
		_is_running = true

		# Determine iteration order based on first config (all should have same reverse state)
		var is_reveal = true
		if animation_configs.size() > 0 and animation_configs[0]:
			is_reveal = not animation_configs[0].reverse

		var start_idx = 0
		var end_idx = targets.size()
		var step = 1
		if not is_reveal:
			start_idx = targets.size() - 1
			end_idx = -1
			step = -1

		var i = start_idx
		while i != end_idx:
			if not _is_running:
				return

			var target = targets[i]
			if target == null or not is_instance_valid(target):
				i += step
				continue

			# Wait for delay (skip delay for first item)
			if i != start_idx:
				await UIAnimationUtils.delay(source_node, delay_between)
				if not _is_running:
					return

			# Get config for this target (use last config if not enough provided)
			var config_idx = min(i if is_reveal else (targets.size() - 1 - i), animation_configs.size() - 1)
			var config = animation_configs[config_idx]
			if not config:
				i += step
				continue

			# Apply animation using the config's apply_to_control method
			# This reuses the single source of truth for animation logic
			var animation_signal = config.apply_to_control(source_node, target)
			if animation_signal:
				await animation_signal

			if not _is_running:
				return

			i += step

		if _is_running:
			all_finished.emit()
		queue_free()

## Creates a delay signal that can be used in animation sequences.
## [param source_node]: The node to get the scene tree from.
## [param duration]: Delay duration in seconds.
## [return]: Signal that emits when delay finishes.
static func delay(source_node: Node, duration: float) -> Signal:
	if not source_node:
		push_warning("UIAnimationUtils: Invalid source_node for delay")
		return Signal()

	var tree = source_node.get_tree()
	if not tree:
		push_warning("UIAnimationUtils: source_node has no tree")
		return Signal()

	return tree.create_timer(duration).timeout

## Helper function to loop a tween animation.
## [param source_node]: The node to create tweens from (captured by animation_callable, not used directly here).
## [param target]: The control being animated (where loop helpers will be attached).
## [param animation_callable]: A callable that creates and returns a tween's finished signal.
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop).
## [return]: Signal that emits when animation finishes.
static func _loop_animation(_source_node: Node, target: Control, animation_callable: Callable, repeat_count: int) -> Signal:
	if repeat_count == 0:
		# No repeats, just execute once
		return animation_callable.call()

	if repeat_count == -1:
		# Infinite loop - attach helper to target control
		var infinite_helper = _AnimationLoopHelper.new()
		infinite_helper._target_control = target  # Store target reference to interrupt animations
		target.add_child(infinite_helper)
		# Wrap the callable to capture tween references and pass helper directly
		var wrapped_callable = infinite_helper._wrap_animation_callable(animation_callable, _source_node)
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

	# Execute sequence asynchronously using existing helper from animation_sequence_action_config
	var finite_helper = _FiniteLoopHelper.new()
	target.add_child(finite_helper)
	finite_helper.execute_sequence(sequence)
	return finite_helper.sequence_finished

## Helper node for executing finite animation loops.
class _FiniteLoopHelper extends Node:
	var sequence_finished = Signal()

	func execute_sequence(sequence: AnimationSequence) -> void:
		await sequence.play()
		sequence_finished.emit()
		queue_free()

## Helper node for managing infinite animation loops.
class _AnimationLoopHelper extends Node:
	const HELPER_TYPE = "_AnimationLoopHelper"  # Identifier for helper detection
	var loop_finished = Signal()
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
			# Try to extract tween from the signal's source if possible
			# Since we can't easily do that, we'll track tweens differently
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
	target.visible = true
	if animation_type != "":
		match animation_type:
			"pop", "expand":
				await animate_expand(source_node, target, speed)
			"slide_from_left":
				await animate_slide_from_left(source_node, target, DEFAULT_OFFSET, speed)
			"slide_from_right":
				await animate_slide_from_right(source_node, target, DEFAULT_OFFSET, speed)
			"slide_from_top":
				await animate_slide_from_top(source_node, target, DEFAULT_OFFSET, speed)
			"fade_in":
				await animate_fade_in(source_node, target, speed)

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
	if animation_type != "":
		match animation_type:
			"shrink":
				await animate_shrink(source_node, target, speed)
			"slide_to_left":
				await animate_slide_to_left(source_node, target, DEFAULT_OFFSET, speed)
			"slide_to_right":
				await animate_slide_to_right(source_node, target, DEFAULT_OFFSET, speed)
			"slide_to_top":
				await animate_slide_to_top(source_node, target, speed)
			"fade_out":
				await animate_fade_out(source_node, target, speed)
	target.visible = false

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
	match preset_type:
		Preset.EXPAND_IN, Preset.POP_IN:
			return animate_expand(source_node, target, speed)
		Preset.EXPAND_OUT, Preset.POP_OUT:
			return animate_shrink(source_node, target, speed)
		Preset.SLIDE_IN_LEFT:
			return animate_slide_from_left(source_node, target, DEFAULT_OFFSET, speed)
		Preset.SLIDE_IN_RIGHT:
			return animate_slide_from_right(source_node, target, DEFAULT_OFFSET, speed)
		Preset.SLIDE_IN_TOP:
			return animate_slide_from_top(source_node, target, DEFAULT_OFFSET, speed)
		Preset.SLIDE_OUT_LEFT:
			return animate_slide_to_left(source_node, target, DEFAULT_OFFSET, speed)
		Preset.SLIDE_OUT_RIGHT:
			return animate_slide_to_right(source_node, target, DEFAULT_OFFSET, speed)
		Preset.SLIDE_OUT_TOP:
			return animate_slide_to_top(source_node, target, speed)
		Preset.FADE_IN:
			return animate_fade_in(source_node, target, speed)
		Preset.FADE_OUT:
			return animate_fade_out(source_node, target, speed)
		_:
			return Signal()

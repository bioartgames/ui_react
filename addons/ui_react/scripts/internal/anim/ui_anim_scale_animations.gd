## Scale, pop, bounce, and elastic animations (extracted from [UiAnimUtils]).
class_name UiAnimScaleAnimations
extends RefCounted

static func animate_expand(source_node: Node, target: Control, speed := UiAnimConstants.DEFAULT_SPEED, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false, auto_setup: bool = false, auto_reset: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not UiAnimTweenFactory.guard_anim_pair(source_node, target, "animate_expand"):
		return Signal()

	# Acquire baseline snapshot for universal reset support
	UiAnimSnapshotStore.acquire_unified_snapshot(source_node, target)

	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		if pivot_offset == Vector2(-1, -1):
			target.pivot_offset = UiAnimTweenFactory.get_center_pivot_offset(target)
		else:
			target.pivot_offset = pivot_offset
		
		if auto_setup:
			target.scale = UiAnimConstants.SCALE_MIN
		else:
			target.scale = UiAnimConstants.SCALE_MIN  # Always set internally for consistency
		
		var tween := UiAnimTweenFactory.create_safe_tween(source_node)
		if not tween:
			return Signal()
		
		tween.tween_property(target, 'scale', UiAnimConstants.SCALE_MAX, speed).set_trans(Tween.TRANS_BACK).set_ease(easing)
		
		if auto_reset:
			tween.finished.connect(func(): target.scale = UiAnimConstants.SCALE_MAX)
		
		return tween.finished
	
	var result_signal: Signal
	if repeat_count != 0:
		result_signal = UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		result_signal = animation_callable.call()

	# Connect to completion to release unified snapshot
	result_signal.connect(func():
		UiAnimSnapshotStore.release_unified_snapshot(target, true)
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
static func animate_expand_x(source_node: Node, target: Control, speed := UiAnimConstants.SHRINK_ANIMATION_SPEED, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not UiAnimTweenFactory.guard_anim_pair(source_node, target, "animate_expand_x"):
		return Signal()

	# Acquire baseline snapshot for universal reset support
	UiAnimSnapshotStore.acquire_unified_snapshot(source_node, target)

	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		if pivot_offset == Vector2(-1, -1):
			target.pivot_offset = UiAnimTweenFactory.get_center_pivot_offset(target)
		else:
			target.pivot_offset = pivot_offset
		
		# Always start from 0 on x-axis, preserve y-axis
		target.scale.x = UiAnimConstants.ALPHA_MIN
		
		var tween := UiAnimTweenFactory.create_safe_tween(source_node)
		if not tween:
			return Signal()
		
		tween.tween_property(target, 'scale:x', UiAnimConstants.SCALE_MAX.x, speed).set_trans(Tween.TRANS_CUBIC).set_ease(easing)
		
		return tween.finished
	
	var result_signal: Signal
	if repeat_count != 0:
		result_signal = UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		result_signal = animation_callable.call()

	# Connect to completion to release unified snapshot
	result_signal.connect(func():
		UiAnimSnapshotStore.release_unified_snapshot(target, true)
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
static func animate_expand_y(source_node: Node, target: Control, speed := UiAnimConstants.SHRINK_ANIMATION_SPEED, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not source_node or not target:
		push_warning("UiAnimUtils: Invalid source_node or target for animate_expand_y")
		return Signal()

	# Acquire baseline snapshot for universal reset support
	UiAnimSnapshotStore.acquire_unified_snapshot(source_node, target)

	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		if pivot_offset == Vector2(-1, -1):
			target.pivot_offset = UiAnimTweenFactory.get_center_pivot_offset(target)
		else:
			target.pivot_offset = pivot_offset
		
		# Always start from 0 on y-axis, preserve x-axis
		target.scale.y = UiAnimConstants.ALPHA_MIN
		
		var tween := UiAnimTweenFactory.create_safe_tween(source_node)
		if not tween:
			return Signal()
		
		tween.tween_property(target, 'scale:y', UiAnimConstants.SCALE_MAX.y, speed).set_trans(Tween.TRANS_CUBIC).set_ease(easing)
		
		return tween.finished
	
	var result_signal: Signal
	if repeat_count != 0:
		result_signal = UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		result_signal = animation_callable.call()

	# Connect to completion to release unified snapshot
	result_signal.connect(func():
		UiAnimSnapshotStore.release_unified_snapshot(target, true)
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
static func animate_shrink(source_node: Node, target: Control, speed := UiAnimConstants.DEFAULT_SPEED, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false, auto_setup: bool = false, auto_reset: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not UiAnimTweenFactory.guard_anim_pair(source_node, target, "animate_shrink"):
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		if pivot_offset == Vector2(-1, -1):
			target.pivot_offset = UiAnimTweenFactory.get_center_pivot_offset(target)
		else:
			target.pivot_offset = pivot_offset
		
		if auto_setup:
			target.scale = UiAnimConstants.SCALE_MAX

		var tween := UiAnimTweenFactory.create_safe_tween(source_node)
		if not tween:
			return Signal()
		
		tween.tween_property(target, 'scale', UiAnimConstants.SCALE_MIN, speed).set_trans(Tween.TRANS_BACK).set_ease(easing)
		
		if auto_visible:
			tween.finished.connect(func(): target.visible = false)
		
		if auto_reset:
			tween.finished.connect(func(): target.scale = UiAnimConstants.SCALE_MAX)
		
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
static func animate_shrink_x(source_node: Node, target: Control, speed := UiAnimConstants.SHRINK_ANIMATION_SPEED, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false, auto_setup: bool = false, auto_reset: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not UiAnimTweenFactory.guard_anim_pair(source_node, target, "animate_shrink_x"):
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		if pivot_offset == Vector2(-1, -1):
			target.pivot_offset = UiAnimTweenFactory.get_center_pivot_offset(target)
		else:
			target.pivot_offset = pivot_offset
		
		if auto_setup:
			target.scale.x = UiAnimConstants.SCALE_MAX.x

		var tween := UiAnimTweenFactory.create_safe_tween(source_node)
		if not tween:
			return Signal()
		
		tween.tween_property(target, 'scale:x', UiAnimConstants.ALPHA_MIN, speed).set_trans(Tween.TRANS_BACK).set_ease(easing)
		
		if auto_visible:
			tween.finished.connect(func(): target.visible = false)
		
		if auto_reset:
			tween.finished.connect(func(): target.scale.x = UiAnimConstants.SCALE_MAX.x)
		
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
static func animate_shrink_y(source_node: Node, target: Control, speed := UiAnimConstants.SHRINK_ANIMATION_SPEED, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false, auto_setup: bool = false, auto_reset: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not source_node or not target:
		push_warning("UiAnimUtils: Invalid source_node or target for animate_shrink_y")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		if pivot_offset == Vector2(-1, -1):
			target.pivot_offset = UiAnimTweenFactory.get_center_pivot_offset(target)
		else:
			target.pivot_offset = pivot_offset
		
		if auto_setup:
			target.scale.y = UiAnimConstants.SCALE_MAX.y

		var tween := UiAnimTweenFactory.create_safe_tween(source_node)
		if not tween:
			return Signal()
		
		tween.tween_property(target, 'scale:y', UiAnimConstants.ALPHA_MIN, speed).set_trans(Tween.TRANS_BACK).set_ease(easing)
		
		if auto_visible:
			tween.finished.connect(func(): target.visible = false)
		
		if auto_reset:
			tween.finished.connect(func(): target.scale.y = UiAnimConstants.SCALE_MAX.y)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

static func animate_bounce_in(source_node: Node, target: Control, speed := UiAnimConstants.DEFAULT_SPEED, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not UiAnimTweenFactory.guard_anim_pair(source_node, target, "animate_bounce_in"):
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		if pivot_offset == Vector2(-1, -1):
			target.pivot_offset = UiAnimTweenFactory.get_center_pivot_offset(target)
		else:
			target.pivot_offset = pivot_offset
		
		target.scale = UiAnimConstants.SCALE_MIN
		
		var tween := UiAnimTweenFactory.create_safe_tween(source_node)
		if not tween:
			return Signal()
		
		tween.tween_property(target, 'scale', UiAnimConstants.SCALE_MAX, speed).set_trans(Tween.TRANS_BOUNCE).set_ease(easing)
		
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
static func animate_bounce_out(source_node: Node, target: Control, speed := UiAnimConstants.DEFAULT_SPEED, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false, auto_setup: bool = false, auto_reset: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not source_node or not target:
		push_warning("UiAnimUtils: Invalid source_node or target for animate_bounce_out")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		if pivot_offset == Vector2(-1, -1):
			target.pivot_offset = UiAnimTweenFactory.get_center_pivot_offset(target)
		else:
			target.pivot_offset = pivot_offset
		
		if auto_setup:
			target.scale = UiAnimConstants.SCALE_MAX

		var tween := UiAnimTweenFactory.create_safe_tween(source_node)
		if not tween:
			return Signal()
		
		tween.tween_property(target, 'scale', UiAnimConstants.SCALE_MIN, speed).set_trans(Tween.TRANS_BOUNCE).set_ease(easing)
		
		if auto_visible:
			tween.finished.connect(func(): target.visible = false)
		
		if auto_reset:
			tween.finished.connect(func(): target.scale = UiAnimConstants.SCALE_MAX)
		
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
static func animate_elastic_in(source_node: Node, target: Control, speed := UiAnimConstants.DEFAULT_SPEED, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not UiAnimTweenFactory.guard_anim_pair(source_node, target, "animate_elastic_in"):
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		if pivot_offset == Vector2(-1, -1):
			target.pivot_offset = UiAnimTweenFactory.get_center_pivot_offset(target)
		else:
			target.pivot_offset = pivot_offset
		
		target.scale = UiAnimConstants.SCALE_MIN
		
		var tween := UiAnimTweenFactory.create_safe_tween(source_node)
		if not tween:
			return Signal()
		
		tween.tween_property(target, 'scale', UiAnimConstants.SCALE_MAX, speed).set_trans(Tween.TRANS_ELASTIC).set_ease(easing)
		
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
static func animate_elastic_out(source_node: Node, target: Control, speed := UiAnimConstants.DEFAULT_SPEED, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false, auto_setup: bool = false, auto_reset: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not UiAnimTweenFactory.guard_anim_pair(source_node, target, "animate_elastic_out"):
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		if pivot_offset == Vector2(-1, -1):
			target.pivot_offset = UiAnimTweenFactory.get_center_pivot_offset(target)
		else:
			target.pivot_offset = pivot_offset
		
		if auto_setup:
			target.scale = UiAnimConstants.SCALE_MAX

		var tween := UiAnimTweenFactory.create_safe_tween(source_node)
		if not tween:
			return Signal()
		
		tween.tween_property(target, 'scale', UiAnimConstants.SCALE_MIN, speed).set_trans(Tween.TRANS_ELASTIC).set_ease(easing)
		
		if auto_visible:
			tween.finished.connect(func(): target.visible = false)
		
		if auto_reset:
			tween.finished.connect(func(): target.scale = UiAnimConstants.SCALE_MAX)
		
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
static func animate_pop(source_node: Node, target: Control, speed := UiAnimConstants.DEFAULT_SPEED, overshoot: float = 1.2, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not UiAnimTweenFactory.guard_anim_pair(source_node, target, "animate_pop"):
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		if pivot_offset == Vector2(-1, -1):
			target.pivot_offset = UiAnimTweenFactory.get_center_pivot_offset(target)
		else:
			target.pivot_offset = pivot_offset
		
		target.scale = UiAnimConstants.SCALE_MIN
		
		var tween := UiAnimTweenFactory.create_safe_tween(source_node)
		if not tween:
			return Signal()
		
		# First tween: scale to overshoot
		tween.tween_property(target, 'scale', Vector2(overshoot, overshoot) * UiAnimConstants.SCALE_MAX, speed * 0.6).set_trans(Tween.TRANS_BACK).set_ease(easing)
		# Second tween: settle back to 1.0
		tween.tween_property(target, 'scale', UiAnimConstants.SCALE_MAX, speed * 0.4).set_trans(Tween.TRANS_BACK).set_ease(easing)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()
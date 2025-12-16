## Scale animation utilities for expanding and shrinking controls.
##
## Provides functions for scaling controls in and out of view with pivot offset support.
## All functions use standardized patterns from AnimationCoreUtils.
class_name ScaleAnimationUtils

## Animates a control expanding from zero scale to full scale.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param duration]: Animation duration in seconds (default: 0.3).
## [param pivot_offset]: Custom pivot offset for scaling (default: Vector2(-1, -1) uses center).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param auto_setup]: If true, automatically sets scale=Vector2.ZERO before animation (default: false).
## [param auto_reset]: If true, automatically sets scale=Vector2.ONE after animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [param easing]: Easing type to use (default: Tween.EASE_OUT).
## [return]: Signal that emits when animation finishes.
static func animate_expand(source_node: Node, target: Control, duration := 0.3, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false, auto_setup: bool = false, auto_reset: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not AnimationCoreUtils.validate_animation_params(source_node, target, "animate_expand"):
		return Signal()

	# Acquire baseline snapshot for universal reset support
	AnimationStateUtils._acquire_unified_snapshot(source_node, target)

	var animation_callable = func() -> Signal:
		AnimationCoreUtils.handle_auto_visible(target, auto_visible)
		AnimationCoreUtils.setup_pivot_offset(target, pivot_offset)

		if auto_setup:
			target.scale = AnimationCoreUtils.SCALE_MIN
		else:
			target.scale = AnimationCoreUtils.SCALE_MIN  # Always set internally for consistency

		var t = source_node.create_tween()
		t.tween_property(target, 'scale', AnimationCoreUtils.SCALE_MAX, duration).set_trans(Tween.TRANS_BACK).set_ease(easing)

		if auto_reset:
			t.finished.connect(func(): target.scale = AnimationCoreUtils.SCALE_MAX)

		return t.finished

	var result_signal = AnimationCoreUtils.wrap_with_loop(source_node, target, animation_callable, repeat_count)

	# Connect to completion to release unified snapshot
	result_signal.connect(func():
		AnimationStateUtils._release_unified_snapshot(target, true)
	, CONNECT_ONE_SHOT)

	return result_signal

## Animates a control expanding horizontally (scale.x from 0.0 to 1.0).
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param duration]: Animation duration in seconds (default: 0.15).
## [param pivot_offset]: Custom pivot offset for scaling (default: Vector2(-1, -1) uses center).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [param easing]: Easing type to use (default: Tween.EASE_OUT).
## [return]: Signal that emits when animation finishes.
static func animate_expand_x(source_node: Node, target: Control, duration := 0.15, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not AnimationCoreUtils.validate_animation_params(source_node, target, "animate_expand_x"):
		return Signal()

	# Acquire baseline snapshot for universal reset support
	AnimationStateUtils._acquire_unified_snapshot(source_node, target)

	var animation_callable = func() -> Signal:
		AnimationCoreUtils.handle_auto_visible(target, auto_visible)
		AnimationCoreUtils.setup_pivot_offset(target, pivot_offset)

		# Always start from 0 on x-axis, preserve y-axis
		target.scale.x = AnimationCoreUtils.ALPHA_MIN

		var t = source_node.create_tween()
		t.tween_property(target, 'scale:x', AnimationCoreUtils.SCALE_MAX.x, duration).set_trans(Tween.TRANS_CUBIC).set_ease(easing)

		return t.finished

	var result_signal = AnimationCoreUtils.wrap_with_loop(source_node, target, animation_callable, repeat_count)

	# Connect to completion to release unified snapshot
	result_signal.connect(func():
		AnimationStateUtils._release_unified_snapshot(target, true)
	, CONNECT_ONE_SHOT)

	return result_signal

## Animates a control expanding vertically (scale.y from 0.0 to 1.0).
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param duration]: Animation duration in seconds (default: 0.15).
## [param pivot_offset]: Custom pivot offset for scaling (default: Vector2(-1, -1) uses center).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [param easing]: Easing type to use (default: Tween.EASE_OUT).
## [return]: Signal that emits when animation finishes.
static func animate_expand_y(source_node: Node, target: Control, duration := 0.15, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not AnimationCoreUtils.validate_animation_params(source_node, target, "animate_expand_y"):
		return Signal()

	# Acquire baseline snapshot for universal reset support
	AnimationStateUtils._acquire_unified_snapshot(source_node, target)

	var animation_callable = func() -> Signal:
		AnimationCoreUtils.handle_auto_visible(target, auto_visible)
		AnimationCoreUtils.setup_pivot_offset(target, pivot_offset)

		# Always start from 0 on y-axis, preserve x-axis
		target.scale.y = AnimationCoreUtils.ALPHA_MIN

		var t = source_node.create_tween()
		t.tween_property(target, 'scale:y', AnimationCoreUtils.SCALE_MAX.y, duration).set_trans(Tween.TRANS_CUBIC).set_ease(easing)

		return t.finished

	var result_signal = AnimationCoreUtils.wrap_with_loop(source_node, target, animation_callable, repeat_count)

	# Connect to completion to release unified snapshot
	result_signal.connect(func():
		AnimationStateUtils._release_unified_snapshot(target, true)
	, CONNECT_ONE_SHOT)

	return result_signal

## Animates a control shrinking from full scale to zero scale.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param duration]: Animation duration in seconds (default: 0.3).
## [param pivot_offset]: Custom pivot offset for scaling (default: Vector2(-1, -1) uses center).
## [param auto_visible]: If true, automatically sets visible=true before animation and visible=false after completion (default: false).
## [param auto_setup]: If true, automatically sets scale=Vector2.ONE before animation (default: false).
## [param auto_reset]: If true, automatically sets scale=Vector2.ZERO after animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [param easing]: Easing type to use (default: Tween.EASE_OUT).
## [return]: Signal that emits when animation finishes.
static func animate_shrink(source_node: Node, target: Control, duration := 0.3, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false, auto_setup: bool = false, auto_reset: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not AnimationCoreUtils.validate_animation_params(source_node, target, "animate_shrink"):
		return Signal()

	# Acquire baseline snapshot for universal reset support
	AnimationStateUtils._acquire_unified_snapshot(source_node, target)

	var animation_callable = func() -> Signal:
		AnimationCoreUtils.handle_auto_visible(target, auto_visible)
		AnimationCoreUtils.setup_pivot_offset(target, pivot_offset)

		if auto_setup:
			target.scale = AnimationCoreUtils.SCALE_MAX

		var t = source_node.create_tween()
		t.tween_property(target, 'scale', AnimationCoreUtils.SCALE_MIN, duration).set_trans(Tween.TRANS_BACK).set_ease(easing)

		if auto_reset:
			t.finished.connect(func(): target.scale = AnimationCoreUtils.SCALE_MIN)

		return t.finished

	var result_signal = AnimationCoreUtils.wrap_with_loop(source_node, target, animation_callable, repeat_count)

	# Connect to completion to release unified snapshot
	result_signal.connect(func():
		AnimationStateUtils._release_unified_snapshot(target, true)
	, CONNECT_ONE_SHOT)

	# Hide after animation completes if auto_visible was true
	if auto_visible:
		result_signal.connect(func(): target.visible = false, CONNECT_ONE_SHOT)

	return result_signal

## Animates a control shrinking horizontally (scale.x from 1.0 to 0.0).
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param duration]: Animation duration in seconds (default: 0.15).
## [param pivot_offset]: Custom pivot offset for scaling (default: Vector2(-1, -1) uses center).
## [param auto_visible]: If true, automatically sets visible=true before animation and visible=false after completion (default: false).
## [param auto_setup]: If true, automatically sets scale.x=1.0 before animation (default: false).
## [param auto_reset]: If true, automatically sets scale.x=0.0 after animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [param easing]: Easing type to use (default: Tween.EASE_OUT).
## [return]: Signal that emits when animation finishes.
static func animate_shrink_x(source_node: Node, target: Control, duration := 0.15, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false, auto_setup: bool = false, auto_reset: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not AnimationCoreUtils.validate_animation_params(source_node, target, "animate_shrink_x"):
		return Signal()

	# Acquire baseline snapshot for universal reset support
	AnimationStateUtils._acquire_unified_snapshot(source_node, target)

	var animation_callable = func() -> Signal:
		AnimationCoreUtils.handle_auto_visible(target, auto_visible)
		AnimationCoreUtils.setup_pivot_offset(target, pivot_offset)

		if auto_setup:
			target.scale.x = AnimationCoreUtils.ALPHA_MAX

		var t = source_node.create_tween()
		t.tween_property(target, 'scale:x', AnimationCoreUtils.ALPHA_MIN, duration).set_trans(Tween.TRANS_BACK).set_ease(easing)

		if auto_reset:
			t.finished.connect(func(): target.scale.x = AnimationCoreUtils.ALPHA_MIN)

		return t.finished

	var result_signal = AnimationCoreUtils.wrap_with_loop(source_node, target, animation_callable, repeat_count)

	# Connect to completion to release unified snapshot
	result_signal.connect(func():
		AnimationStateUtils._release_unified_snapshot(target, true)
	, CONNECT_ONE_SHOT)

	# Hide after animation completes if auto_visible was true
	if auto_visible:
		result_signal.connect(func(): target.visible = false, CONNECT_ONE_SHOT)

	return result_signal

## Animates a control shrinking vertically (scale.y from 1.0 to 0.0).
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param duration]: Animation duration in seconds (default: 0.15).
## [param pivot_offset]: Custom pivot offset for scaling (default: Vector2(-1, -1) uses center).
## [param auto_visible]: If true, automatically sets visible=true before animation and visible=false after completion (default: false).
## [param auto_setup]: If true, automatically sets scale.y=1.0 before animation (default: false).
## [param auto_reset]: If true, automatically sets scale.y=0.0 after animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [param easing]: Easing type to use (default: Tween.EASE_OUT).
## [return]: Signal that emits when animation finishes.
static func animate_shrink_y(source_node: Node, target: Control, duration := 0.15, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false, auto_setup: bool = false, auto_reset: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not AnimationCoreUtils.validate_animation_params(source_node, target, "animate_shrink_y"):
		return Signal()

	# Acquire baseline snapshot for universal reset support
	AnimationStateUtils._acquire_unified_snapshot(source_node, target)

	var animation_callable = func() -> Signal:
		AnimationCoreUtils.handle_auto_visible(target, auto_visible)
		AnimationCoreUtils.setup_pivot_offset(target, pivot_offset)

		if auto_setup:
			target.scale.y = AnimationCoreUtils.ALPHA_MAX

		var t = source_node.create_tween()
		t.tween_property(target, 'scale:y', AnimationCoreUtils.ALPHA_MIN, duration).set_trans(Tween.TRANS_BACK).set_ease(easing)

		if auto_reset:
			t.finished.connect(func(): target.scale.y = AnimationCoreUtils.ALPHA_MIN)

		return t.finished

	var result_signal = AnimationCoreUtils.wrap_with_loop(source_node, target, animation_callable, repeat_count)

	# Connect to completion to release unified snapshot
	result_signal.connect(func():
		AnimationStateUtils._release_unified_snapshot(target, true)
	, CONNECT_ONE_SHOT)

	# Hide after animation completes if auto_visible was true
	if auto_visible:
		result_signal.connect(func(): target.visible = false, CONNECT_ONE_SHOT)

	return result_signal

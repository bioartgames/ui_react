## Rotation, pulse, shake, and loop motion effects (extracted from [UiAnimUtils]).
class_name UiAnimTransformEffects
extends RefCounted

static func animate_rotate_in(source_node: Node, target: Control, speed := UiAnimConstants.DEFAULT_SPEED, start_angle: float = -360.0, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not UiAnimTweenFactory.guard_anim_pair(source_node, target, "animate_rotate_in"):
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		# Set pivot offset for rotation center
		if pivot_offset == Vector2(-1, -1):
			target.pivot_offset = UiAnimTweenFactory.get_center_pivot_offset(target)
		else:
			target.pivot_offset = pivot_offset
		
		target.rotation_degrees = start_angle
		
		var tween := UiAnimTweenFactory.create_safe_tween(source_node)
		if not tween:
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
static func animate_rotate_out(source_node: Node, target: Control, speed := UiAnimConstants.DEFAULT_SPEED, end_angle: float = 360.0, auto_visible: bool = false, auto_setup: bool = false, auto_reset: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not UiAnimTweenFactory.guard_anim_pair(source_node, target, "animate_rotate_out"):
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		if auto_setup:
			target.rotation_degrees = 0.0
		
		var tween := UiAnimTweenFactory.create_safe_tween(source_node)
		if not tween:
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
	if not UiAnimTweenFactory.guard_anim_pair(source_node, target, "animate_pulse"):
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		if pivot_offset == Vector2(-1, -1):
			target.pivot_offset = UiAnimTweenFactory.get_center_pivot_offset(target)
		else:
			target.pivot_offset = pivot_offset
		
		var original_scale = target.scale
		var tween := UiAnimTweenFactory.create_safe_tween(source_node)
		if not tween:
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
	if not UiAnimTweenFactory.guard_anim_pair(source_node, target, "animate_shake"):
		return Signal()

	# Acquire baseline snapshot (automatic state preservation)
	var snapshot = UiAnimSnapshotStore.acquire_unified_snapshot(source_node, target)
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
		var tween := UiAnimTweenFactory.create_safe_tween(source_node)
		if not tween:
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
		UiAnimSnapshotStore.release_unified_snapshot(target, true)
	, CONNECT_ONE_SHOT)

	return result_signal
static func animate_breathing(source_node: Node, target: Control, duration: float = 2.0, repeat_count: int = -1, easing: int = Tween.EASE_OUT, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false) -> Signal:
	if not UiAnimTweenFactory.guard_anim_pair(source_node, target, "animate_breathing"):
		return Signal()
	
	if auto_visible:
		target.visible = true
	
	if pivot_offset == Vector2(-1, -1):
		target.pivot_offset = UiAnimTweenFactory.get_center_pivot_offset(target)
	else:
		target.pivot_offset = pivot_offset
	
	var original_scale = target.scale

	var animation_callable = func() -> Signal:
		var tween = UiAnimLoopRunner.create_tracked_tween(source_node)
		if not tween:
			push_warning("UiAnimUtils: Failed to create tween")
			return Signal()
		
		# Scale up
		tween.tween_property(target, 'scale', original_scale * UiAnimConstants.BREATHING_SCALE_MULTIPLIER, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(easing)
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
	if not UiAnimTweenFactory.guard_anim_pair(source_node, target, "animate_wobble"):
		return Signal()
	
	if auto_visible:
		target.visible = true
	
	if pivot_offset == Vector2(-1, -1):
		target.pivot_offset = UiAnimTweenFactory.get_center_pivot_offset(target)
	else:
		target.pivot_offset = pivot_offset
	
	var original_rotation = target.rotation_degrees

	var animation_callable = func() -> Signal:
		var tween = UiAnimLoopRunner.create_tracked_tween(source_node)
		if not tween:
			push_warning("UiAnimUtils: Failed to create tween")
			return Signal()
		
		# Rotate left
		tween.tween_property(target, 'rotation_degrees', original_rotation - UiAnimConstants.WOBBLE_ROTATION_DEGREES, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(easing)
		# Rotate right
		tween.tween_property(target, 'rotation_degrees', original_rotation + UiAnimConstants.WOBBLE_ROTATION_DEGREES, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(easing)
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
static func animate_float(source_node: Node, target: Control, duration: float = 2.0, repeat_count: int = -1, easing: int = Tween.EASE_OUT, float_distance: float = UiAnimConstants.DEFAULT_FLOAT_DISTANCE_PX, auto_visible: bool = false) -> Signal:
	if not UiAnimTweenFactory.guard_anim_pair(source_node, target, "animate_float"):
		return Signal()

	if auto_visible:
		target.visible = true

	# Acquire baseline snapshot (automatic state preservation)
	var snapshot = UiAnimSnapshotStore.acquire_unified_snapshot(source_node, target)
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
		UiAnimSnapshotStore.release_unified_snapshot(target, true)
	, CONNECT_ONE_SHOT)

	return result_signal
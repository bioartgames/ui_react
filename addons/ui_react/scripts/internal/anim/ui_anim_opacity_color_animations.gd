## Opacity, glow, and color flash (extracted from [UiAnimUtils]).
class_name UiAnimOpacityColorAnimations
extends RefCounted

static func animate_fade_in(source_node: Node, target: Control, speed := UiAnimConstants.DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not UiAnimTweenFactory.guard_anim_pair(source_node, target, "animate_fade_in"):
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		target.modulate.a = UiAnimConstants.ALPHA_MIN
		
		var tween := UiAnimTweenFactory.create_safe_tween(source_node)
		if not tween:
			return Signal()
		
		tween.tween_property(target, 'modulate:a', UiAnimConstants.ALPHA_MAX, speed).set_trans(Tween.TRANS_CUBIC).set_ease(easing)
		
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
static func animate_fade_out(source_node: Node, target: Control, speed := UiAnimConstants.DEFAULT_SPEED, auto_visible: bool = false, auto_reset: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not UiAnimTweenFactory.guard_anim_pair(source_node, target, "animate_fade_out"):
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		var tween := UiAnimTweenFactory.create_safe_tween(source_node)
		if not tween:
			return Signal()
		
		tween.tween_property(target, 'modulate:a', UiAnimConstants.ALPHA_MIN, speed).set_trans(Tween.TRANS_CUBIC).set_ease(easing)
		
		if auto_visible:
			tween.finished.connect(func(): target.visible = false)
		
		if auto_reset:
			tween.finished.connect(func(): target.modulate.a = UiAnimConstants.ALPHA_MAX)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

static func animate_glow_pulse(source_node: Node, target: Control, duration: float = 1.5, repeat_count: int = -1, easing: int = Tween.EASE_OUT, glow_min_alpha: float = 0.7, auto_visible: bool = false) -> Signal:
	if not UiAnimTweenFactory.guard_anim_pair(source_node, target, "animate_glow_pulse"):
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
static func animate_color_flash(source_node: Node, target: Control, flash_color: Color = Color.YELLOW, duration: float = 0.2, flash_intensity: float = 1.5, auto_visible: bool = false, easing: int = Tween.EASE_OUT) -> Signal:
	if not UiAnimTweenFactory.guard_anim_pair(source_node, target, "animate_color_flash"):
		return Signal()
	
	if auto_visible:
		target.visible = true

	# Use unified snapshot system for consistency
	var snapshot = UiAnimSnapshotStore.acquire_unified_snapshot(source_node, target)
	var original_modulate: Color
	if snapshot:
		original_modulate = snapshot.modulate
	else:
		# Fallback to current modulate if snapshot failed (null snapshot or acquisition failed)
		push_warning("UiAnimUtils.animate_color_flash(): Failed to acquire unified snapshot for target '%s', using current modulate" % target.name)
		original_modulate = target.modulate
	
	# Kill any existing tweens on modulate by creating a zero-duration tween
	# This interrupts any active flash animations before starting a new one
	var interrupt_tween := UiAnimTweenFactory.create_safe_tween(source_node)
	if interrupt_tween:
		interrupt_tween.tween_property(target, "modulate", target.modulate, 0.0)
		interrupt_tween.kill()
	
	var flash_modulate = Color(
		flash_color.r * flash_intensity,
		flash_color.g * flash_intensity,
		flash_color.b * flash_intensity,
		original_modulate.a
	)
	
	var tween := UiAnimTweenFactory.create_safe_tween(source_node)
	if not tween:
		return Signal()
	
	# Flash to color
	tween.tween_property(target, 'modulate', flash_modulate, duration * 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(easing)
	# Flash back to original (using the stored original from snapshot)
	tween.tween_property(target, 'modulate', original_modulate, duration * 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(easing)

	# Connect to completion to release unified snapshot
	tween.finished.connect(func():
		UiAnimSnapshotStore.release_unified_snapshot(target, true)
	, CONNECT_ONE_SHOT)

	return tween.finished
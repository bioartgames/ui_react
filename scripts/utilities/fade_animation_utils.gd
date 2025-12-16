## Fade animation utilities for changing control opacity.
##
## Provides functions for fading controls in and out of view.
## All functions use standardized patterns from AnimationCoreUtils.
class_name FadeAnimationUtils

## Animates a control fading in from transparent to opaque.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param duration]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [param easing]: Easing type to use (default: Tween.EASE_OUT).
## [return]: Signal that emits when animation finishes.
static func animate_fade_in(source_node: Node, target: Control, duration := 0.3, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not AnimationCoreUtils.validate_animation_params(source_node, target, "animate_fade_in"):
		return Signal()

	var animation_callable = func() -> Signal:
		AnimationCoreUtils.handle_auto_visible(target, auto_visible)

		var t = source_node.create_tween()
		t.tween_property(target, 'modulate:a', AnimationCoreUtils.ALPHA_MAX, duration).set_trans(Tween.TRANS_CUBIC).set_ease(easing)

		return t.finished

	return AnimationCoreUtils.wrap_with_loop(source_node, target, animation_callable, repeat_count)

## Animates a control fading out from opaque to transparent.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param duration]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation and visible=false after completion (default: false).
## [param auto_reset]: If true, automatically sets modulate.a=0.0 after animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [param easing]: Easing type to use (default: Tween.EASE_OUT).
## [return]: Signal that emits when animation finishes.
static func animate_fade_out(source_node: Node, target: Control, duration := 0.3, auto_visible: bool = false, auto_reset: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not AnimationCoreUtils.validate_animation_params(source_node, target, "animate_fade_out"):
		return Signal()

	var animation_callable = func() -> Signal:
		AnimationCoreUtils.handle_auto_visible(target, auto_visible)

		var t = source_node.create_tween()
		t.tween_property(target, 'modulate:a', AnimationCoreUtils.ALPHA_MIN, duration).set_trans(Tween.TRANS_CUBIC).set_ease(easing)

		if auto_reset:
			t.finished.connect(func(): target.modulate.a = AnimationCoreUtils.ALPHA_MIN)

		return t.finished

	var result_signal = AnimationCoreUtils.wrap_with_loop(source_node, target, animation_callable, repeat_count)

	# Hide after animation completes if auto_visible was true
	if auto_visible:
		result_signal.connect(func(): target.visible = false, CONNECT_ONE_SHOT)

	return result_signal

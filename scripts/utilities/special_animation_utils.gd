## Special animation utilities for advanced effects.
##
## Provides functions for bounce, elastic, rotation, pop, pulse, shake, breathing,
## wobble, float, glow pulse, and color flash animations.
## All functions use standardized patterns from AnimationCoreUtils.
class_name SpecialAnimationUtils

# TODO: Add all 14 special animation functions here
# For now, including just animate_pop as an example

## Animates a control with a popping effect (quick scale up then down).
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param duration]: Animation duration in seconds (default: 0.3).
## [param overshoot]: How much to overshoot the scale (default: 1.2).
## [param pivot_offset]: Custom pivot offset for scaling (default: Vector2(-1, -1) uses center).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [param easing]: Easing type to use (default: Tween.EASE_OUT).
## [return]: Signal that emits when animation finishes.
static func animate_pop(source_node: Node, target: Control, duration := 0.3, overshoot: float = 1.2, pivot_offset: Vector2 = Vector2(-1, -1), auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not AnimationCoreUtils.validate_animation_params(source_node, target, "animate_pop"):
		return Signal()

	var animation_callable = func() -> Signal:
		AnimationCoreUtils.handle_auto_visible(target, auto_visible)
		AnimationCoreUtils.setup_pivot_offset(target, pivot_offset)

		var t = source_node.create_tween()
		# First tween: scale to overshoot
		t.tween_property(target, 'scale', Vector2(overshoot, overshoot) * AnimationCoreUtils.SCALE_MAX, duration * 0.6).set_trans(Tween.TRANS_BACK).set_ease(easing)
		# Second tween: settle back to 1.0
		t.tween_property(target, 'scale', AnimationCoreUtils.SCALE_MAX, duration * 0.4).set_trans(Tween.TRANS_BACK).set_ease(easing)

		return t.finished

	return AnimationCoreUtils.wrap_with_loop(source_node, target, animation_callable, repeat_count)

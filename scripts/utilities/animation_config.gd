## Inline animation configuration (no resource file needed).
## All animation properties are configured directly in the Inspector with a dropdown menu.
class_name AnimationConfig
extends Resource

## Animation action types.
enum AnimationAction {
	EXPAND, EXPAND_X, EXPAND_Y,
	FADE_IN,
	SLIDE_FROM_LEFT, SLIDE_FROM_RIGHT, SLIDE_FROM_TOP, SLIDE_FROM_BOTTOM,
	FROM_LEFT_TO_CENTER,
	FROM_RIGHT_TO_CENTER,
	FROM_TOP_TO_CENTER,
	FROM_BOTTOM_TO_CENTER,
	BOUNCE_IN,
	ELASTIC_IN,
	ROTATE_IN,
	POP, PULSE, SHAKE,
	BREATHING, WOBBLE, FLOAT, GLOW_PULSE,
	COLOR_FLASH,
	RESET
}

## Animation action to perform (dropdown selection in Inspector).
@export var action: AnimationAction = AnimationAction.EXPAND

## Animation duration in seconds.
@export_range(0.001, 60.0) var duration: float = 0.3

## Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop).
## For continuous animations like breathing/wobble, set to -1 for infinite.
@export_range(-1, 999) var repeat_count: int = 0


## If true, reverses/inverts the animation (e.g., EXPAND becomes SHRINK, FADE_IN becomes FADE_OUT).
@export var reverse: bool = false

@export_group("Color Flash")
## Flash color for COLOR_FLASH action (default: Color.YELLOW).
@export var flash_color: Color = Color.YELLOW

## Flash intensity multiplier for COLOR_FLASH action (default: 1.5).
@export var flash_intensity: float = 1.5

@export_group("Pop")
## Overshoot amount for POP animation (default: 1.2, meaning 20% overshoot).
@export var pop_overshoot: float = 1.2

@export_group("Pulse")
## Pulse scale amount for PULSE animation (default: 1.1, meaning 10% scale increase).
@export var pulse_amount: float = 1.1

## Number of pulses for PULSE animation (default: 2).
@export var pulse_count: int = 2

@export_group("Shake")
## Shake intensity in pixels for SHAKE animation (default: 10.0).
@export var shake_intensity: float = 10.0

## Number of shakes for SHAKE animation (default: 5).
@export var shake_count: int = 5

@export_group("Rotate")
## Starting angle in degrees for ROTATE_IN animation (default: -360.0).
@export var rotate_start_angle: float = -360.0

## Applies this animation config to a single control target.
## [param owner]: The node that owns the animation (for creating tweens).
## [param target]: The control to animate.
## [return]: Signal that emits when animation completes (or empty Signal if not applicable).
func apply_to_control(owner: Node, target: Control) -> Signal:
	if not target:
		return Signal()
	
	match action:
		AnimationAction.EXPAND:
			if reverse:
				return UIAnimationUtils.animate_shrink(owner, target, duration, Vector2(-1, -1), true, true, true, repeat_count)
			else:
				return UIAnimationUtils.animate_expand(owner, target, duration, Vector2(-1, -1), true, false, false, repeat_count)
		AnimationAction.EXPAND_X:
			if reverse:
				return UIAnimationUtils.animate_shrink_x(owner, target, duration, Vector2(-1, -1), true, true, true, repeat_count)
			else:
				return UIAnimationUtils.animate_expand_x(owner, target, duration, Vector2(-1, -1), true, repeat_count)
		AnimationAction.EXPAND_Y:
			if reverse:
				return UIAnimationUtils.animate_shrink_y(owner, target, duration, Vector2(-1, -1), true, true, true, repeat_count)
			else:
				return UIAnimationUtils.animate_expand_y(owner, target, duration, Vector2(-1, -1), true, repeat_count)
		AnimationAction.FADE_IN:
			if reverse:
				return UIAnimationUtils.animate_fade_out(owner, target, duration, true, true, repeat_count)
			else:
				return UIAnimationUtils.animate_fade_in(owner, target, duration, true, repeat_count)
		AnimationAction.SLIDE_FROM_LEFT:
			if reverse:
				return UIAnimationUtils.animate_slide_to_left(owner, target, 8.0, duration, true)
			else:
				return UIAnimationUtils.animate_slide_from_left(owner, target, 8.0, duration, true)
		AnimationAction.SLIDE_FROM_RIGHT:
			if reverse:
				return UIAnimationUtils.animate_slide_to_right(owner, target, 8.0, duration, true)
			else:
				return UIAnimationUtils.animate_slide_from_right(owner, target, 8.0, duration, true)
		AnimationAction.SLIDE_FROM_TOP:
			if reverse:
				return UIAnimationUtils.animate_slide_to_top(owner, target, duration, true)
			else:
				return UIAnimationUtils.animate_slide_from_top(owner, target, 8.0, duration, true)
		AnimationAction.SLIDE_FROM_BOTTOM:
			if reverse:
				return UIAnimationUtils.animate_slide_to_bottom(owner, target, duration, true)
			else:
				return UIAnimationUtils.animate_slide_from_bottom(owner, target, 8.0, duration, true)
		AnimationAction.FROM_LEFT_TO_CENTER:
			if reverse:
				return UIAnimationUtils.animate_from_center_to_left(owner, target, duration, true)
			else:
				return UIAnimationUtils.animate_from_left_to_center(owner, target, duration, true)
		AnimationAction.FROM_RIGHT_TO_CENTER:
			if reverse:
				return UIAnimationUtils.animate_from_center_to_right(owner, target, duration, true)
			else:
				return UIAnimationUtils.animate_from_right_to_center(owner, target, duration, true)
		AnimationAction.FROM_TOP_TO_CENTER:
			if reverse:
				return UIAnimationUtils.animate_from_center_to_top(owner, target, duration, true)
			else:
				return UIAnimationUtils.animate_from_top_to_center(owner, target, duration, true)
		AnimationAction.FROM_BOTTOM_TO_CENTER:
			if reverse:
				return UIAnimationUtils.animate_from_center_to_bottom(owner, target, duration, true)
			else:
				return UIAnimationUtils.animate_from_bottom_to_center(owner, target, duration, true)
		AnimationAction.BOUNCE_IN:
			if reverse:
				return UIAnimationUtils.animate_bounce_out(owner, target, duration, Vector2(-1, -1), true, true, true, repeat_count)
			else:
				return UIAnimationUtils.animate_bounce_in(owner, target, duration, Vector2(-1, -1), true)
		AnimationAction.ELASTIC_IN:
			if reverse:
				return UIAnimationUtils.animate_elastic_out(owner, target, duration, Vector2(-1, -1), true, true, true, repeat_count)
			else:
				return UIAnimationUtils.animate_elastic_in(owner, target, duration, Vector2(-1, -1), true)
		AnimationAction.ROTATE_IN:
			if reverse:
				return UIAnimationUtils.animate_rotate_out(owner, target, duration, 360.0, true, true, true)
			else:
				return UIAnimationUtils.animate_rotate_in(owner, target, duration, rotate_start_angle, Vector2(-1, -1), true, repeat_count)
		AnimationAction.POP:
			return UIAnimationUtils.animate_pop(owner, target, duration, pop_overshoot, Vector2(-1, -1), true, repeat_count)
		AnimationAction.PULSE:
			return UIAnimationUtils.animate_pulse(owner, target, duration, pulse_amount, pulse_count, Vector2(-1, -1), true, repeat_count)
		AnimationAction.SHAKE:
			return UIAnimationUtils.animate_shake(owner, target, duration, shake_intensity, shake_count, true, repeat_count)
		AnimationAction.BREATHING:
			return UIAnimationUtils.animate_breathing(owner, target, duration, repeat_count)
		AnimationAction.WOBBLE:
			return UIAnimationUtils.animate_wobble(owner, target, duration, repeat_count)
		AnimationAction.FLOAT:
			return UIAnimationUtils.animate_float(owner, target, duration, repeat_count)
		AnimationAction.GLOW_PULSE:
			return UIAnimationUtils.animate_glow_pulse(owner, target, duration, repeat_count)
		AnimationAction.COLOR_FLASH:
			return UIAnimationUtils.animate_color_flash(owner, target, flash_color, duration, flash_intensity, true)
		AnimationAction.RESET:
			# Use comprehensive reset with duration=0 for instant reset
			# This resets all properties using the unified snapshot system
			return UIAnimationUtils.animate_reset_all(owner, target, 0.0, 0, true)
		_:
			push_warning("AnimationConfig: Unsupported animation action %d" % action)
			return Signal()


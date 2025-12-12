## Simple animation target configuration (no resource file needed).
## All properties are configured directly in the Inspector with a dropdown menu.
class_name AnimationTarget
extends Resource

## When to trigger this animation.
enum Trigger {
	PRESSED,           # When button is pressed (default)
	HOVER_ENTER,       # When mouse enters button
	HOVER_EXIT,        # When mouse exits button
	TOGGLED_ON,        # When toggle is turned on
	TOGGLED_OFF,       # When toggle is turned off
}

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

## The target control to animate.
## Drag and drop a node from the scene tree to this field.
@export var target: NodePath = NodePath()

## When to trigger this animation (dropdown selection in Inspector).
@export var trigger: Trigger = Trigger.PRESSED

## Animation action to perform (dropdown selection in Inspector).
@export var action: AnimationAction = AnimationAction.EXPAND

## Animation duration in seconds.
@export var duration: float = 0.3

## If true, reverses/inverts the animation (e.g., EXPAND becomes SHRINK).
@export var reverse: bool = false

## If true, this animation will not trigger when the button is disabled.
## Set to false if you want animations to play even when disabled (e.g., for visual feedback).
@export var respect_disabled: bool = true

## Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop).
@export_range(-1, 999) var repeat_count: int = 0

@export_group("Color Flash (for COLOR_FLASH action)")
## Flash color for COLOR_FLASH action.
@export var flash_color: Color = Color.YELLOW

## Flash intensity multiplier for COLOR_FLASH action.
@export var flash_intensity: float = 1.5

@export_group("Pop (for POP action)")
## Overshoot amount for POP animation (default: 1.2, meaning 20% overshoot).
@export var pop_overshoot: float = 1.2

@export_group("Pulse (for PULSE action)")
## Pulse scale amount for PULSE animation (default: 1.1, meaning 10% scale increase).
@export var pulse_amount: float = 1.1

## Number of pulses for PULSE animation (default: 2).
@export var pulse_count: int = 2

@export_group("Shake (for SHAKE action)")
## Shake intensity in pixels for SHAKE animation (default: 10.0).
@export var shake_intensity: float = 10.0

## Number of shakes for SHAKE animation (default: 5).
@export var shake_count: int = 5

@export_group("Rotate (for ROTATE_IN action)")
## Starting angle in degrees for ROTATE_IN animation (default: -360.0).
@export var rotate_start_angle: float = -360.0

## Applies this animation to the target control.
## [param owner]: The node that owns the animation (for creating tweens).
## [return]: Signal that emits when animation completes (or empty Signal if not applicable).
func apply(owner: Node) -> Signal:
	if target.is_empty():
		return Signal()
	
	var target_node = owner.get_node_or_null(target)
	if not target_node or not (target_node is Control):
		return Signal()
	
	var control_target = target_node as Control
	
	match action:
		AnimationAction.EXPAND:
			if reverse:
				return UIAnimationUtils.animate_shrink(owner, control_target, duration, Vector2(-1, -1), true, true, true, repeat_count)
			else:
				return UIAnimationUtils.animate_expand(owner, control_target, duration, Vector2(-1, -1), true, false, false, repeat_count)
		AnimationAction.EXPAND_X:
			if reverse:
				return UIAnimationUtils.animate_shrink_x(owner, control_target, duration, Vector2(-1, -1), true, true, true, repeat_count)
			else:
				return UIAnimationUtils.animate_expand_x(owner, control_target, duration, Vector2(-1, -1), true, repeat_count)
		AnimationAction.EXPAND_Y:
			if reverse:
				return UIAnimationUtils.animate_shrink_y(owner, control_target, duration, Vector2(-1, -1), true, true, true, repeat_count)
			else:
				return UIAnimationUtils.animate_expand_y(owner, control_target, duration, Vector2(-1, -1), true, repeat_count)
		AnimationAction.FADE_IN:
			if reverse:
				return UIAnimationUtils.animate_fade_out(owner, control_target, duration, true, true, repeat_count)
			else:
				return UIAnimationUtils.animate_fade_in(owner, control_target, duration, true, repeat_count)
		AnimationAction.SLIDE_FROM_LEFT:
			if reverse:
				return UIAnimationUtils.animate_slide_to_left(owner, control_target, 8.0, duration, true)
			else:
				return UIAnimationUtils.animate_slide_from_left(owner, control_target, 8.0, duration, true)
		AnimationAction.SLIDE_FROM_RIGHT:
			if reverse:
				return UIAnimationUtils.animate_slide_to_right(owner, control_target, 8.0, duration, true)
			else:
				return UIAnimationUtils.animate_slide_from_right(owner, control_target, 8.0, duration, true)
		AnimationAction.SLIDE_FROM_TOP:
			if reverse:
				return UIAnimationUtils.animate_slide_to_top(owner, control_target, duration, true)
			else:
				return UIAnimationUtils.animate_slide_from_top(owner, control_target, 8.0, duration, true)
		AnimationAction.SLIDE_FROM_BOTTOM:
			if reverse:
				return UIAnimationUtils.animate_slide_to_bottom(owner, control_target, duration, true)
			else:
				return UIAnimationUtils.animate_slide_from_bottom(owner, control_target, 8.0, duration, true)
		AnimationAction.FROM_LEFT_TO_CENTER:
			if reverse:
				return UIAnimationUtils.animate_from_center_to_left(owner, control_target, duration, true)
			else:
				return UIAnimationUtils.animate_from_left_to_center(owner, control_target, duration, true)
		AnimationAction.FROM_RIGHT_TO_CENTER:
			if reverse:
				return UIAnimationUtils.animate_from_center_to_right(owner, control_target, duration, true)
			else:
				return UIAnimationUtils.animate_from_right_to_center(owner, control_target, duration, true)
		AnimationAction.FROM_TOP_TO_CENTER:
			if reverse:
				return UIAnimationUtils.animate_from_center_to_top(owner, control_target, duration, true)
			else:
				return UIAnimationUtils.animate_from_top_to_center(owner, control_target, duration, true)
		AnimationAction.FROM_BOTTOM_TO_CENTER:
			if reverse:
				return UIAnimationUtils.animate_from_center_to_bottom(owner, control_target, duration, true)
			else:
				return UIAnimationUtils.animate_from_bottom_to_center(owner, control_target, duration, true)
		AnimationAction.BOUNCE_IN:
			if reverse:
				return UIAnimationUtils.animate_bounce_out(owner, control_target, duration, Vector2(-1, -1), true, true, true, repeat_count)
			else:
				return UIAnimationUtils.animate_bounce_in(owner, control_target, duration, Vector2(-1, -1), true)
		AnimationAction.ELASTIC_IN:
			if reverse:
				return UIAnimationUtils.animate_elastic_out(owner, control_target, duration, Vector2(-1, -1), true, true, true, repeat_count)
			else:
				return UIAnimationUtils.animate_elastic_in(owner, control_target, duration, Vector2(-1, -1), true)
		AnimationAction.ROTATE_IN:
			if reverse:
				return UIAnimationUtils.animate_rotate_out(owner, control_target, duration, 360.0, true, true, true)
			else:
				return UIAnimationUtils.animate_rotate_in(owner, control_target, duration, rotate_start_angle, true, repeat_count)
		AnimationAction.POP:
			return UIAnimationUtils.animate_pop(owner, control_target, duration, pop_overshoot, Vector2(-1, -1), true, repeat_count)
		AnimationAction.PULSE:
			return UIAnimationUtils.animate_pulse(owner, control_target, duration, pulse_amount, pulse_count, Vector2(-1, -1), true, repeat_count)
		AnimationAction.SHAKE:
			return UIAnimationUtils.animate_shake(owner, control_target, duration, shake_intensity, shake_count, true, repeat_count)
		AnimationAction.BREATHING:
			return UIAnimationUtils.animate_breathing(owner, control_target, duration, repeat_count)
		AnimationAction.WOBBLE:
			return UIAnimationUtils.animate_wobble(owner, control_target, duration, repeat_count)
		AnimationAction.FLOAT:
			return UIAnimationUtils.animate_float(owner, control_target, duration, repeat_count)
		AnimationAction.GLOW_PULSE:
			return UIAnimationUtils.animate_glow_pulse(owner, control_target, duration, repeat_count)
		AnimationAction.COLOR_FLASH:
			return UIAnimationUtils.animate_color_flash(owner, control_target, flash_color, duration, flash_intensity, true)
		AnimationAction.RESET:
			UIAnimationUtils.reset_control_to_normal(control_target)
			return Signal()
		_:
			push_warning("AnimationTarget: Unsupported animation action %d" % action)
			return Signal()


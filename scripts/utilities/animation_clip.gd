## Animation configuration for a single animation clip.
##
## AnimationClip contains all the properties for a single animation type,
## including timing, easing, and animation-specific parameters. It can
## execute animations on target controls through its execute() method.
@tool
class_name AnimationClip
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

## Easing types for animations.
enum Easing {
	EASE_IN,        # Slow start, fast end
	EASE_OUT,       # Fast start, slow end (default)
	EASE_IN_OUT,    # Slow start and end, fast middle
	EASE_OUT_IN,    # Fast start and end, slow middle
}

## ============================================
## CORE SETTINGS
## ============================================

## Animation type to perform (dropdown selection in Inspector).
var _animation: AnimationAction = AnimationAction.EXPAND

## Animation type to perform (dropdown selection in Inspector).
@export var animation: AnimationAction:
	set(value):
		if _animation != value:
			_animation = value
			notify_property_list_changed()
	get:
		return _animation

## ============================================
## TIMING & EASING
## ============================================

## Delay before this animation starts (for sequences).
## Set to > 0.0 to add delay before this clip begins.
@export_range(0.0, 10.0) var delay: float = 0.0

## Stagger delay between targets when used in multi-target animations.
## Only used when the reel has multiple targets. Set to > 0.0 to enable stagger.
@export_range(0.0, 10.0) var stagger: float = 0.0

## Animation duration in seconds.
@export_range(0.001, 60.0) var duration: float = 0.3

## Easing type for the animation (dropdown selection in Inspector).
@export var easing: Easing = Easing.EASE_OUT

## Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop).
@export_range(-1, 999) var repeat_count: int = 0

## ============================================
## ANIMATION BEHAVIOR
## ============================================

## If true, reverses/inverts the animation (e.g., EXPAND becomes SHRINK).
@export var reverse: bool = false

## If true, this animation will not trigger when the owner control is disabled.
## Set to false if you want animations to play even when disabled (e.g., for visual feedback).
@export var respect_disabled: bool = true

## ============================================
## ADVANCED SETTINGS
## ============================================

## Custom pivot offset for scaling/rotation animations.
## Use Vector2(-1, -1) for center (default), or specify custom offset in pixels.
## Only affects animations that use pivot (EXPAND, SHRINK, POP, PULSE, ROTATE, etc.).
@export var pivot_offset: Vector2 = Vector2(-1, -1)

## ============================================
## ANIMATION-SPECIFIC SETTINGS
## ============================================
## These properties are conditionally shown based on the selected animation type.

## Starting angle in degrees for ROTATE_IN animation.
var rotate_start_angle: float = -360.0

## Overshoot amount for POP animation.
var pop_overshoot: float = 1.2

## Pulse scale amount for PULSE animation.
var pulse_amount: float = 1.1

## Number of pulses for PULSE animation.
var pulse_count: int = 2

## Shake intensity in pixels for SHAKE animation.
var shake_intensity: float = 10.0

## Number of shakes for SHAKE animation.
var shake_count: int = 5

## Flash color for COLOR_FLASH animation.
var flash_color: Color = Color.YELLOW

## Flash intensity multiplier for COLOR_FLASH animation.
var flash_intensity: float = 1.5

## Returns the property list for conditional display of animation-specific properties.
func _get_property_list() -> Array:
	var properties: Array = []
	
	# Conditionally show animation-specific groups based on selected animation
	match _animation:
		AnimationAction.ROTATE_IN:
			properties.append({
				"name": "Rotate",
				"type": TYPE_NIL,
				"usage": PROPERTY_USAGE_GROUP,
				"hint_string": "rotate_"
			})
			properties.append({
				"name": "rotate_start_angle",
				"type": TYPE_FLOAT,
				"usage": PROPERTY_USAGE_DEFAULT,
				"hint": PROPERTY_HINT_NONE
			})
		
		AnimationAction.POP:
			properties.append({
				"name": "Pop",
				"type": TYPE_NIL,
				"usage": PROPERTY_USAGE_GROUP,
				"hint_string": "pop_"
			})
			properties.append({
				"name": "pop_overshoot",
				"type": TYPE_FLOAT,
				"usage": PROPERTY_USAGE_DEFAULT,
				"hint": PROPERTY_HINT_NONE
			})
		
		AnimationAction.PULSE:
			properties.append({
				"name": "Pulse",
				"type": TYPE_NIL,
				"usage": PROPERTY_USAGE_GROUP,
				"hint_string": "pulse_"
			})
			properties.append({
				"name": "pulse_amount",
				"type": TYPE_FLOAT,
				"usage": PROPERTY_USAGE_DEFAULT,
				"hint": PROPERTY_HINT_NONE
			})
			properties.append({
				"name": "pulse_count",
				"type": TYPE_INT,
				"usage": PROPERTY_USAGE_DEFAULT,
				"hint": PROPERTY_HINT_NONE
			})
		
		AnimationAction.SHAKE:
			properties.append({
				"name": "Shake",
				"type": TYPE_NIL,
				"usage": PROPERTY_USAGE_GROUP,
				"hint_string": "shake_"
			})
			properties.append({
				"name": "shake_intensity",
				"type": TYPE_FLOAT,
				"usage": PROPERTY_USAGE_DEFAULT,
				"hint": PROPERTY_HINT_NONE
			})
			properties.append({
				"name": "shake_count",
				"type": TYPE_INT,
				"usage": PROPERTY_USAGE_DEFAULT,
				"hint": PROPERTY_HINT_NONE
			})
		
		AnimationAction.COLOR_FLASH:
			properties.append({
				"name": "Color Flash",
				"type": TYPE_NIL,
				"usage": PROPERTY_USAGE_GROUP,
				"hint_string": "flash_"
			})
			properties.append({
				"name": "flash_color",
				"type": TYPE_COLOR,
				"usage": PROPERTY_USAGE_DEFAULT,
				"hint": PROPERTY_HINT_NONE
			})
			properties.append({
				"name": "flash_intensity",
				"type": TYPE_FLOAT,
				"usage": PROPERTY_USAGE_DEFAULT,
				"hint": PROPERTY_HINT_NONE
			})
	
	return properties

## Handles setting animation-specific properties.
func _set(property: StringName, value: Variant) -> bool:
	if property == "rotate_start_angle":
		rotate_start_angle = value
		return true
	elif property == "pop_overshoot":
		pop_overshoot = value
		return true
	elif property == "pulse_amount":
		pulse_amount = value
		return true
	elif property == "pulse_count":
		pulse_count = value
		return true
	elif property == "shake_intensity":
		shake_intensity = value
		return true
	elif property == "shake_count":
		shake_count = value
		return true
	elif property == "flash_color":
		flash_color = value
		return true
	elif property == "flash_intensity":
		flash_intensity = value
		return true
	return false

## Handles getting animation-specific properties.
func _get(property: StringName) -> Variant:
	if property == "rotate_start_angle":
		return rotate_start_angle
	elif property == "pop_overshoot":
		return pop_overshoot
	elif property == "pulse_amount":
		return pulse_amount
	elif property == "pulse_count":
		return pulse_count
	elif property == "shake_intensity":
		return shake_intensity
	elif property == "shake_count":
		return shake_count
	elif property == "flash_color":
		return flash_color
	elif property == "flash_intensity":
		return flash_intensity
	return null

## Executes this animation clip on the specified target control.
## [param owner]: The node that owns the animation (for creating tweens).
## [param target]: The control to animate.
## [param tween_easing]: The easing type (Tween.EASE_* constant).
## [return]: Signal that emits when animation completes (or empty Signal if not applicable).
func execute(owner: Node, target: Control, tween_easing: int) -> Signal:
	# Match on animation type and call appropriate UIAnimationUtils function
	match _animation:
		AnimationAction.EXPAND:
			if reverse:
				return UIAnimationUtils.animate_shrink(owner, target, duration, pivot_offset, true, true, true, repeat_count, tween_easing)
			else:
				return UIAnimationUtils.animate_expand(owner, target, duration, pivot_offset, true, false, false, repeat_count, tween_easing)
		AnimationAction.EXPAND_X:
			if reverse:
				return UIAnimationUtils.animate_shrink_x(owner, target, duration, pivot_offset, true, true, true, repeat_count, tween_easing)
			else:
				return UIAnimationUtils.animate_expand_x(owner, target, duration, pivot_offset, true, repeat_count, tween_easing)
		AnimationAction.EXPAND_Y:
			if reverse:
				return UIAnimationUtils.animate_shrink_y(owner, target, duration, pivot_offset, true, true, true, repeat_count, tween_easing)
			else:
				return UIAnimationUtils.animate_expand_y(owner, target, duration, pivot_offset, true, repeat_count, tween_easing)
		AnimationAction.FADE_IN:
			if reverse:
				return UIAnimationUtils.animate_fade_out(owner, target, duration, true, true, repeat_count, tween_easing)
			else:
				return UIAnimationUtils.animate_fade_in(owner, target, duration, true, repeat_count, tween_easing)
		AnimationAction.SLIDE_FROM_LEFT:
			if reverse:
				return UIAnimationUtils.animate_slide_to_left(owner, target, 8.0, duration, true, tween_easing)
			else:
				return UIAnimationUtils.animate_slide_from_left(owner, target, 8.0, duration, true, tween_easing)
		AnimationAction.SLIDE_FROM_RIGHT:
			if reverse:
				return UIAnimationUtils.animate_slide_to_right(owner, target, 8.0, duration, true, tween_easing)
			else:
				return UIAnimationUtils.animate_slide_from_right(owner, target, 8.0, duration, true, tween_easing)
		AnimationAction.SLIDE_FROM_TOP:
			if reverse:
				return UIAnimationUtils.animate_slide_to_top(owner, target, duration, true, tween_easing)
			else:
				return UIAnimationUtils.animate_slide_from_top(owner, target, 8.0, duration, true, tween_easing)
		AnimationAction.SLIDE_FROM_BOTTOM:
			if reverse:
				return UIAnimationUtils.animate_slide_to_bottom(owner, target, duration, true, tween_easing)
			else:
				return UIAnimationUtils.animate_slide_from_bottom(owner, target, 8.0, duration, true, tween_easing)
		AnimationAction.FROM_LEFT_TO_CENTER:
			if reverse:
				return UIAnimationUtils.animate_from_center_to_left(owner, target, duration, true, tween_easing)
			else:
				return UIAnimationUtils.animate_from_left_to_center(owner, target, duration, true, tween_easing)
		AnimationAction.FROM_RIGHT_TO_CENTER:
			if reverse:
				return UIAnimationUtils.animate_from_center_to_right(owner, target, duration, true, tween_easing)
			else:
				return UIAnimationUtils.animate_from_right_to_center(owner, target, duration, true, tween_easing)
		AnimationAction.FROM_TOP_TO_CENTER:
			if reverse:
				return UIAnimationUtils.animate_from_center_to_top(owner, target, duration, true, tween_easing)
			else:
				return UIAnimationUtils.animate_from_top_to_center(owner, target, duration, true, tween_easing)
		AnimationAction.FROM_BOTTOM_TO_CENTER:
			if reverse:
				return UIAnimationUtils.animate_from_center_to_bottom(owner, target, duration, true, tween_easing)
			else:
				return UIAnimationUtils.animate_from_bottom_to_center(owner, target, duration, true, tween_easing)
		AnimationAction.BOUNCE_IN:
			if reverse:
				return UIAnimationUtils.animate_bounce_out(owner, target, duration, pivot_offset, true, true, true, repeat_count, tween_easing)
			else:
				return UIAnimationUtils.animate_bounce_in(owner, target, duration, pivot_offset, true, tween_easing)
		AnimationAction.ELASTIC_IN:
			if reverse:
				return UIAnimationUtils.animate_elastic_out(owner, target, duration, pivot_offset, true, true, true, repeat_count, tween_easing)
			else:
				return UIAnimationUtils.animate_elastic_in(owner, target, duration, pivot_offset, true, tween_easing)
		AnimationAction.ROTATE_IN:
			if reverse:
				return UIAnimationUtils.animate_rotate_out(owner, target, duration, 360.0, true, true, true, tween_easing)
			else:
				return UIAnimationUtils.animate_rotate_in(owner, target, duration, rotate_start_angle, pivot_offset, true, repeat_count, tween_easing)
		AnimationAction.POP:
			return UIAnimationUtils.animate_pop(owner, target, duration, pop_overshoot, pivot_offset, true, repeat_count, tween_easing)
		AnimationAction.PULSE:
			return UIAnimationUtils.animate_pulse(owner, target, duration, pulse_amount, pulse_count, pivot_offset, true, repeat_count, tween_easing)
		AnimationAction.SHAKE:
			return UIAnimationUtils.animate_shake(owner, target, duration, shake_intensity, shake_count, true, repeat_count, tween_easing)
		AnimationAction.BREATHING:
			return UIAnimationUtils.animate_breathing(owner, target, duration, repeat_count, tween_easing, pivot_offset)
		AnimationAction.WOBBLE:
			return UIAnimationUtils.animate_wobble(owner, target, duration, repeat_count, tween_easing, pivot_offset)
		AnimationAction.FLOAT:
			return UIAnimationUtils.animate_float(owner, target, duration, repeat_count, tween_easing, 10.0, false)
		AnimationAction.GLOW_PULSE:
			return UIAnimationUtils.animate_glow_pulse(owner, target, duration, repeat_count, tween_easing)
		AnimationAction.COLOR_FLASH:
			return UIAnimationUtils.animate_color_flash(owner, target, flash_color, duration, flash_intensity, true, tween_easing)
		AnimationAction.RESET:
			# Use comprehensive reset with duration=0 for instant reset
			# This resets all properties using the unified snapshot system
			return UIAnimationUtils.animate_reset_all(owner, target, 0.0, tween_easing, true)
		_:
			push_warning("AnimationClip: Unsupported animation type %d" % _animation)
			return Signal()
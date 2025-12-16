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

@export_group("Animation Settings")
## Animation type to perform (dropdown selection in Inspector).
@export var animation: AnimationAction:
	set(value):
		if _animation != value:
			_animation = value
			notify_property_list_changed()
	get:
		return _animation

@export_group("Timing & Easing")
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

## Converts AnimationClip.Easing enum to Tween.EASE_* constant.
## [param easing]: The AnimationClip.Easing enum value (can be passed directly or from clip.easing)
## [return]: The corresponding Tween.EASE_* constant
static func to_tween_easing(easing: Easing) -> int:
	# Within AnimationClip class, Easing refers to AnimationClip.Easing
	match easing:
		Easing.EASE_IN:
			return Tween.EASE_IN
		Easing.EASE_OUT:
			return Tween.EASE_OUT
		Easing.EASE_IN_OUT:
			return Tween.EASE_IN_OUT
		Easing.EASE_OUT_IN:
			return Tween.EASE_OUT_IN
		_:
			return Tween.EASE_OUT

## Animation strategy registry for extensible animation execution.
static var _animation_strategies: Dictionary = {}

## Registers an animation strategy for an AnimationAction.
## [param action]: The AnimationAction enum value
## [param strategy]: Callable that takes (owner, target, clip, tween_easing) and returns Signal
static func register_animation_strategy(action: AnimationAction, strategy: Callable) -> void:
	_animation_strategies[action] = strategy

## Initializes default animation strategies.
static func _initialize_default_strategies() -> void:
	register_animation_strategy(AnimationAction.EXPAND, _strategy_expand)
	register_animation_strategy(AnimationAction.EXPAND_X, _strategy_expand_x)
	register_animation_strategy(AnimationAction.EXPAND_Y, _strategy_expand_y)
	register_animation_strategy(AnimationAction.FADE_IN, _strategy_fade_in)
	register_animation_strategy(AnimationAction.SLIDE_FROM_LEFT, _strategy_slide_from_left)
	register_animation_strategy(AnimationAction.SLIDE_FROM_RIGHT, _strategy_slide_from_right)
	register_animation_strategy(AnimationAction.SLIDE_FROM_TOP, _strategy_slide_from_top)
	register_animation_strategy(AnimationAction.SLIDE_FROM_BOTTOM, _strategy_slide_from_bottom)
	register_animation_strategy(AnimationAction.FROM_LEFT_TO_CENTER, _strategy_from_left_to_center)
	register_animation_strategy(AnimationAction.FROM_RIGHT_TO_CENTER, _strategy_from_right_to_center)
	register_animation_strategy(AnimationAction.FROM_TOP_TO_CENTER, _strategy_from_top_to_center)
	register_animation_strategy(AnimationAction.FROM_BOTTOM_TO_CENTER, _strategy_from_bottom_to_center)
	register_animation_strategy(AnimationAction.BOUNCE_IN, _strategy_bounce_in)
	register_animation_strategy(AnimationAction.ELASTIC_IN, _strategy_elastic_in)
	register_animation_strategy(AnimationAction.ROTATE_IN, _strategy_rotate_in)
	register_animation_strategy(AnimationAction.POP, _strategy_pop)
	register_animation_strategy(AnimationAction.PULSE, _strategy_pulse)
	register_animation_strategy(AnimationAction.SHAKE, _strategy_shake)
	register_animation_strategy(AnimationAction.BREATHING, _strategy_breathing)
	register_animation_strategy(AnimationAction.WOBBLE, _strategy_wobble)
	register_animation_strategy(AnimationAction.FLOAT, _strategy_float)
	register_animation_strategy(AnimationAction.GLOW_PULSE, _strategy_glow_pulse)
	register_animation_strategy(AnimationAction.COLOR_FLASH, _strategy_color_flash)
	register_animation_strategy(AnimationAction.RESET, _strategy_reset)

## Executes this animation clip on the specified target control.
## [param owner]: The node that owns the animation (for creating tweens).
## [param target]: The control to animate.
## [param tween_easing]: The easing type (Tween.EASE_* constant).
## [return]: Signal that emits when animation completes (or empty Signal if not applicable).
func execute(owner: Node, target: Control, tween_easing: int) -> Signal:
	# Lazy initialization: register strategies on first call
	if _animation_strategies.is_empty():
		_initialize_default_strategies()

	var strategy = _animation_strategies.get(_animation)
	if strategy == null:
		push_warning("AnimationClip: No strategy registered for %s" % _animation)
		return Signal()

	# Call the strategy function with clip instance (self) so it can access clip properties including reverse
	return strategy.call(owner, target, self, tween_easing)

## Strategy functions for each animation type

static func _strategy_expand(owner: Node, target: Control, clip: AnimationClip, tween_easing: int) -> Signal:
	if clip.reverse:
		return ScaleAnimationUtils.animate_shrink(owner, target, clip.duration, clip.pivot_offset, true, true, true, clip.repeat_count, tween_easing)
	else:
		return ScaleAnimationUtils.animate_expand(owner, target, clip.duration, clip.pivot_offset, true, false, false, clip.repeat_count, tween_easing)

static func _strategy_expand_x(owner: Node, target: Control, clip: AnimationClip, tween_easing: int) -> Signal:
	if clip.reverse:
		return ScaleAnimationUtils.animate_shrink_x(owner, target, clip.duration, clip.pivot_offset, true, true, true, clip.repeat_count, tween_easing)
	else:
		return ScaleAnimationUtils.animate_expand_x(owner, target, clip.duration, clip.pivot_offset, true, clip.repeat_count, tween_easing)

static func _strategy_expand_y(owner: Node, target: Control, clip: AnimationClip, tween_easing: int) -> Signal:
	if clip.reverse:
		return ScaleAnimationUtils.animate_shrink_y(owner, target, clip.duration, clip.pivot_offset, true, true, true, clip.repeat_count, tween_easing)
	else:
		return ScaleAnimationUtils.animate_expand_y(owner, target, clip.duration, clip.pivot_offset, true, clip.repeat_count, tween_easing)

static func _strategy_fade_in(owner: Node, target: Control, clip: AnimationClip, tween_easing: int) -> Signal:
	if clip.reverse:
		return FadeAnimationUtils.animate_fade_out(owner, target, clip.duration, true, true, clip.repeat_count, tween_easing)
	else:
		return FadeAnimationUtils.animate_fade_in(owner, target, clip.duration, true, clip.repeat_count, tween_easing)

static func _strategy_slide_from_left(owner: Node, target: Control, clip: AnimationClip, tween_easing: int) -> Signal:
	if clip.reverse:
		return SlideAnimationUtils.animate_slide_to_left(owner, target, AnimationCoreUtils.DEFAULT_OFFSET, clip.duration, true, clip.repeat_count, tween_easing)
	else:
		return SlideAnimationUtils.animate_slide_from_left(owner, target, AnimationCoreUtils.DEFAULT_OFFSET, clip.duration, true, clip.repeat_count, tween_easing)

static func _strategy_slide_from_right(owner: Node, target: Control, clip: AnimationClip, tween_easing: int) -> Signal:
	if clip.reverse:
		return SlideAnimationUtils.animate_slide_to_right(owner, target, AnimationCoreUtils.DEFAULT_OFFSET, clip.duration, true, clip.repeat_count, tween_easing)
	else:
		return SlideAnimationUtils.animate_slide_from_right(owner, target, AnimationCoreUtils.DEFAULT_OFFSET, clip.duration, true, clip.repeat_count, tween_easing)

static func _strategy_slide_from_top(owner: Node, target: Control, clip: AnimationClip, tween_easing: int) -> Signal:
	if clip.reverse:
		return SlideAnimationUtils.animate_slide_to_top(owner, target, clip.duration, true, clip.repeat_count, tween_easing)
	else:
		return SlideAnimationUtils.animate_slide_from_top(owner, target, AnimationCoreUtils.DEFAULT_OFFSET, clip.duration, true, clip.repeat_count, tween_easing)

static func _strategy_slide_from_bottom(owner: Node, target: Control, clip: AnimationClip, tween_easing: int) -> Signal:
	if clip.reverse:
		return SlideAnimationUtils.animate_slide_to_bottom(owner, target, clip.duration, true, clip.repeat_count, tween_easing)
	else:
		return SlideAnimationUtils.animate_slide_from_bottom(owner, target, AnimationCoreUtils.DEFAULT_OFFSET, clip.duration, true, clip.repeat_count, tween_easing)

static func _strategy_from_left_to_center(owner: Node, target: Control, clip: AnimationClip, tween_easing: int) -> Signal:
	if clip.reverse:
		return SlideAnimationUtils.animate_from_center_to_left(owner, target, clip.duration, true, clip.repeat_count, tween_easing)
	else:
		return SlideAnimationUtils.animate_from_left_to_center(owner, target, clip.duration, true, clip.repeat_count, tween_easing)

static func _strategy_from_right_to_center(owner: Node, target: Control, clip: AnimationClip, tween_easing: int) -> Signal:
	if clip.reverse:
		return SlideAnimationUtils.animate_from_center_to_right(owner, target, clip.duration, true, clip.repeat_count, tween_easing)
	else:
		return SlideAnimationUtils.animate_from_right_to_center(owner, target, clip.duration, true, clip.repeat_count, tween_easing)

static func _strategy_from_top_to_center(owner: Node, target: Control, clip: AnimationClip, tween_easing: int) -> Signal:
	if clip.reverse:
		return SlideAnimationUtils.animate_from_center_to_top(owner, target, clip.duration, true, clip.repeat_count, tween_easing)
	else:
		return SlideAnimationUtils.animate_from_top_to_center(owner, target, clip.duration, true, clip.repeat_count, tween_easing)

static func _strategy_from_bottom_to_center(owner: Node, target: Control, clip: AnimationClip, tween_easing: int) -> Signal:
	if clip.reverse:
		return SlideAnimationUtils.animate_from_center_to_bottom(owner, target, clip.duration, true, clip.repeat_count, tween_easing)
	else:
		return SlideAnimationUtils.animate_from_bottom_to_center(owner, target, clip.duration, true, clip.repeat_count, tween_easing)

static func _strategy_bounce_in(owner: Node, target: Control, clip: AnimationClip, tween_easing: int) -> Signal:
	return UIAnimationUtils.animate_bounce_in(owner, target, clip.duration, clip.pivot_offset, true, clip.repeat_count, tween_easing)

static func _strategy_elastic_in(owner: Node, target: Control, clip: AnimationClip, tween_easing: int) -> Signal:
	return UIAnimationUtils.animate_elastic_in(owner, target, clip.duration, clip.pivot_offset, true, clip.repeat_count, tween_easing)

static func _strategy_rotate_in(owner: Node, target: Control, clip: AnimationClip, tween_easing: int) -> Signal:
	return UIAnimationUtils.animate_rotate_in(owner, target, clip.duration, clip.rotate_start_angle, clip.pivot_offset, true, clip.repeat_count, tween_easing)

static func _strategy_pop(owner: Node, target: Control, clip: AnimationClip, tween_easing: int) -> Signal:
	return SpecialAnimationUtils.animate_pop(owner, target, clip.duration, clip.pop_overshoot, clip.pivot_offset, true, clip.repeat_count, tween_easing)

static func _strategy_pulse(owner: Node, target: Control, clip: AnimationClip, tween_easing: int) -> Signal:
	return UIAnimationUtils.animate_pulse(owner, target, clip.duration, clip.pulse_amount, clip.pulse_count, clip.pivot_offset, true, clip.repeat_count, tween_easing)

static func _strategy_shake(owner: Node, target: Control, clip: AnimationClip, tween_easing: int) -> Signal:
	return UIAnimationUtils.animate_shake(owner, target, clip.duration, clip.shake_intensity, clip.shake_count, true, clip.repeat_count, tween_easing)

static func _strategy_breathing(owner: Node, target: Control, clip: AnimationClip, tween_easing: int) -> Signal:
	return UIAnimationUtils.animate_breathing(owner, target, clip.duration, clip.repeat_count, tween_easing, clip.pivot_offset, true)

static func _strategy_wobble(owner: Node, target: Control, clip: AnimationClip, tween_easing: int) -> Signal:
	return UIAnimationUtils.animate_wobble(owner, target, clip.duration, clip.repeat_count, tween_easing, clip.pivot_offset, true)

static func _strategy_float(owner: Node, target: Control, clip: AnimationClip, tween_easing: int) -> Signal:
	return UIAnimationUtils.animate_float(owner, target, clip.duration, clip.repeat_count, tween_easing, 10.0, true)

static func _strategy_glow_pulse(owner: Node, target: Control, clip: AnimationClip, tween_easing: int) -> Signal:
	return UIAnimationUtils.animate_glow_pulse(owner, target, clip.duration, clip.repeat_count, tween_easing, 0.7, true)

static func _strategy_color_flash(owner: Node, target: Control, clip: AnimationClip, tween_easing: int) -> Signal:
	return UIAnimationUtils.animate_color_flash(owner, target, clip.flash_color, clip.duration, clip.flash_intensity, true, tween_easing)

static func _strategy_reset(owner: Node, target: Control, clip: AnimationClip, tween_easing: int) -> Signal:
	return AnimationStateUtils.animate_reset_all(owner, target, clip.duration, tween_easing)

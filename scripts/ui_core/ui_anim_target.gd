## Simple animation target configuration (no resource file needed).
## All properties are configured directly in the Inspector with a dropdown menu.
class_name UiAnimTarget
extends Resource

## When to trigger this animation.
enum Trigger {
	PRESSED,           # When button is pressed (default)
	HOVER_ENTER,       # When mouse enters control
	HOVER_EXIT,        # When mouse exits control
	TOGGLED_ON,        # When toggle is turned on
	TOGGLED_OFF,       # When toggle is turned off
	TEXT_CHANGED,      # When text value changes
	SELECTION_CHANGED, # When selection changes
	VALUE_CHANGED,     # When value changes
	VALUE_INCREASED,   # When value increases
	VALUE_DECREASED,   # When value decreases
	DRAG_STARTED,      # When user starts dragging
	DRAG_ENDED,        # When user stops dragging
	COMPLETED,         # When progress reaches completion
	TEXT_ENTERED,      # When user presses Enter in text input
	FOCUS_ENTERED,     # When input gains focus
	FOCUS_EXITED,      # When input loses focus
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

## The target control to animate.
## Drag and drop a node from the scene tree to this field.
@export var target: NodePath = NodePath()

## When to trigger this animation (dropdown selection in Inspector).
@export var trigger: Trigger = Trigger.PRESSED

## Animation type to perform (dropdown selection in Inspector).
@export var animation: AnimationAction = AnimationAction.EXPAND

## ============================================
## TIMING & EASING
## ============================================

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

## If true, this animation will not trigger when the control is disabled.
## Set to false if you want animations to play even when disabled (e.g., for visual feedback).
@export var respect_disabled: bool = true

## ============================================
## ADVANCED SETTINGS
## ============================================

## Custom pivot offset for scaling/rotation animations.
## Use Vector2(-1, -1) for center (default), or specify custom offset in pixels.
## Only affects animations that use pivot (EXPAND, SHRINK, POP, PULSE, ROTATE, etc.).
@export var pivot_offset: Vector2 = Vector2(-1, -1)

## Note: All animations now automatically preserve their initial state for consistent RESET behavior.
## The preserve_position parameter has been removed as all animations use unified baseline snapshots.

## ============================================
## ANIMATION-SPECIFIC SETTINGS
## ============================================

@export_group("Rotate (for ROTATE_IN animation)")
## Starting angle in degrees for ROTATE_IN animation (default: -360.0).
@export var rotate_start_angle: float = -360.0

@export_group("Pop (for POP animation)")
## Overshoot amount for POP animation (default: 1.2, meaning 20% overshoot).
@export var pop_overshoot: float = 1.2

@export_group("Pulse (for PULSE animation)")
## Pulse scale amount for PULSE animation (default: 1.1, meaning 10% scale increase).
@export var pulse_amount: float = 1.1

## Number of pulses for PULSE animation (default: 2).
@export var pulse_count: int = 2

@export_group("Shake (for SHAKE animation)")
## Shake intensity in pixels for SHAKE animation (default: 10.0).
@export var shake_intensity: float = 10.0

## Number of shakes for SHAKE animation (default: 5).
@export var shake_count: int = 5

@export_group("Color Flash (for COLOR_FLASH animation)")
## Flash color for COLOR_FLASH animation.
@export var flash_color: Color = Color.YELLOW

## Flash intensity multiplier for COLOR_FLASH animation.
@export var flash_intensity: float = 1.5

## Applies this animation to the target control.
## [param owner]: The node that owns the animation (for creating tweens).
## [return]: Signal that emits when animation completes (or empty Signal if not applicable).
func apply(owner: Node) -> Signal:
	if target.is_empty():
		return Signal()

	var target_node = owner.get_node_or_null(target)
	if not target_node or not (target_node is Control):
		return Signal()

	return apply_to_control(owner, target_node as Control)

## Applies this animation to a specific control target.
## [param owner]: The node that owns the animation (for creating tweens).
## [param control_target]: The already-resolved control to animate.
## [return]: Signal that emits when animation completes (or empty Signal if not applicable).
func apply_to_control(owner: Node, control_target: Control) -> Signal:
	if not owner or not control_target:
		return Signal()

	# Convert Easing enum to Tween.EASE_* constant
	var tween_easing: int
	match easing:
		Easing.EASE_IN:
			tween_easing = Tween.EASE_IN
		Easing.EASE_OUT:
			tween_easing = Tween.EASE_OUT
		Easing.EASE_IN_OUT:
			tween_easing = Tween.EASE_IN_OUT
		Easing.EASE_OUT_IN:
			tween_easing = Tween.EASE_OUT_IN

	match animation:
		AnimationAction.EXPAND:
			if reverse:
				return UiAnimUtils.animate_shrink(owner, control_target, duration, pivot_offset, true, true, true, repeat_count, tween_easing)
			else:
				return UiAnimUtils.animate_expand(owner, control_target, duration, pivot_offset, true, false, false, repeat_count, tween_easing)
		AnimationAction.EXPAND_X:
			if reverse:
				return UiAnimUtils.animate_shrink_x(owner, control_target, duration, pivot_offset, true, true, true, repeat_count, tween_easing)
			else:
				return UiAnimUtils.animate_expand_x(owner, control_target, duration, pivot_offset, true, repeat_count, tween_easing)
		AnimationAction.EXPAND_Y:
			if reverse:
				return UiAnimUtils.animate_shrink_y(owner, control_target, duration, pivot_offset, true, true, true, repeat_count, tween_easing)
			else:
				return UiAnimUtils.animate_expand_y(owner, control_target, duration, pivot_offset, true, repeat_count, tween_easing)
		AnimationAction.FADE_IN:
			if reverse:
				return UiAnimUtils.animate_fade_out(owner, control_target, duration, true, true, repeat_count, tween_easing)
			else:
				return UiAnimUtils.animate_fade_in(owner, control_target, duration, true, repeat_count, tween_easing)
		AnimationAction.SLIDE_FROM_LEFT:
			if reverse:
				return UiAnimUtils.animate_slide_to_left(owner, control_target, 8.0, duration, true, tween_easing)
			else:
				return UiAnimUtils.animate_slide_from_left(owner, control_target, 8.0, duration, true, tween_easing)
		AnimationAction.SLIDE_FROM_RIGHT:
			if reverse:
				return UiAnimUtils.animate_slide_to_right(owner, control_target, 8.0, duration, true, tween_easing)
			else:
				return UiAnimUtils.animate_slide_from_right(owner, control_target, 8.0, duration, true, tween_easing)
		AnimationAction.SLIDE_FROM_TOP:
			if reverse:
				return UiAnimUtils.animate_slide_to_top(owner, control_target, duration, true, tween_easing)
			else:
				return UiAnimUtils.animate_slide_from_top(owner, control_target, 8.0, duration, true, tween_easing)
		AnimationAction.SLIDE_FROM_BOTTOM:
			if reverse:
				return UiAnimUtils.animate_slide_to_bottom(owner, control_target, duration, true, tween_easing)
			else:
				return UiAnimUtils.animate_slide_from_bottom(owner, control_target, 8.0, duration, true, tween_easing)
		AnimationAction.FROM_LEFT_TO_CENTER:
			if reverse:
				return UiAnimUtils.animate_from_center_to_left(owner, control_target, duration, true, tween_easing)
			else:
				return UiAnimUtils.animate_from_left_to_center(owner, control_target, duration, true, tween_easing)
		AnimationAction.FROM_RIGHT_TO_CENTER:
			if reverse:
				return UiAnimUtils.animate_from_center_to_right(owner, control_target, duration, true, tween_easing)
			else:
				return UiAnimUtils.animate_from_right_to_center(owner, control_target, duration, true, tween_easing)
		AnimationAction.FROM_TOP_TO_CENTER:
			if reverse:
				return UiAnimUtils.animate_from_center_to_top(owner, control_target, duration, true, tween_easing)
			else:
				return UiAnimUtils.animate_from_top_to_center(owner, control_target, duration, true, tween_easing)
		AnimationAction.FROM_BOTTOM_TO_CENTER:
			if reverse:
				return UiAnimUtils.animate_from_center_to_bottom(owner, control_target, duration, true, tween_easing)
			else:
				return UiAnimUtils.animate_from_bottom_to_center(owner, control_target, duration, true, tween_easing)
		AnimationAction.BOUNCE_IN:
			if reverse:
				return UiAnimUtils.animate_bounce_out(owner, control_target, duration, pivot_offset, true, true, true, repeat_count, tween_easing)
			else:
				return UiAnimUtils.animate_bounce_in(owner, control_target, duration, pivot_offset, true, tween_easing)
		AnimationAction.ELASTIC_IN:
			if reverse:
				return UiAnimUtils.animate_elastic_out(owner, control_target, duration, pivot_offset, true, true, true, repeat_count, tween_easing)
			else:
				return UiAnimUtils.animate_elastic_in(owner, control_target, duration, pivot_offset, true, tween_easing)
		AnimationAction.ROTATE_IN:
			if reverse:
				return UiAnimUtils.animate_rotate_out(owner, control_target, duration, 360.0, true, true, true, tween_easing)
			else:
				return UiAnimUtils.animate_rotate_in(owner, control_target, duration, rotate_start_angle, pivot_offset, true, repeat_count, tween_easing)
		AnimationAction.POP:
			return UiAnimUtils.animate_pop(owner, control_target, duration, pop_overshoot, pivot_offset, true, repeat_count, tween_easing)
		AnimationAction.PULSE:
			return UiAnimUtils.animate_pulse(owner, control_target, duration, pulse_amount, pulse_count, pivot_offset, true, repeat_count, tween_easing)
		AnimationAction.SHAKE:
			return UiAnimUtils.animate_shake(owner, control_target, duration, shake_intensity, shake_count, true, repeat_count, tween_easing)
		AnimationAction.BREATHING:
			return UiAnimUtils.animate_breathing(owner, control_target, duration, repeat_count, tween_easing, pivot_offset)
		AnimationAction.WOBBLE:
			return UiAnimUtils.animate_wobble(owner, control_target, duration, repeat_count, tween_easing, pivot_offset)
		AnimationAction.FLOAT:
			return UiAnimUtils.animate_float(owner, control_target, duration, repeat_count, tween_easing, 10.0, false)
		AnimationAction.GLOW_PULSE:
			return UiAnimUtils.animate_glow_pulse(owner, control_target, duration, repeat_count, tween_easing)
		AnimationAction.COLOR_FLASH:
			return UiAnimUtils.animate_color_flash(owner, control_target, flash_color, duration, flash_intensity, true, tween_easing)
		AnimationAction.RESET:
			# Use comprehensive reset with duration=0 for instant reset
			# This resets all properties (position, scale, modulate, rotation, pivot_offset, visible)
			# using the unified snapshot system
			return UiAnimUtils.animate_reset_all(owner, control_target, 0.0, tween_easing, true)
		_:
			push_warning("UiAnimTarget: Unsupported animation type %d" % animation)
			return Signal()

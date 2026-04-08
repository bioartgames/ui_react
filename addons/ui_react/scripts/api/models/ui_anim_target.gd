@tool
## Simple animation target configuration (no resource file needed).
## All properties are configured directly in the Inspector with a dropdown menu.
## Animation-specific fields are shown/hidden based on the selected [member animation] (editor only).
class_name UiAnimTarget
extends Resource

## When to trigger this animation.
enum Trigger {
	## When a button is pressed (default).
	PRESSED,
	## When the mouse enters the control.
	HOVER_ENTER,
	## When the mouse exits the control.
	HOVER_EXIT,
	## When a toggle is turned on.
	TOGGLED_ON,
	## When a toggle is turned off.
	TOGGLED_OFF,
	## When text value changes.
	TEXT_CHANGED,
	## When selection changes.
	SELECTION_CHANGED,
	## When a value changes.
	VALUE_CHANGED,
	## When a value increases.
	VALUE_INCREASED,
	## When a value decreases.
	VALUE_DECREASED,
	## When the user starts dragging.
	DRAG_STARTED,
	## When the user stops dragging.
	DRAG_ENDED,
	## When progress reaches completion.
	COMPLETED,
	## When the user presses Enter in a text input.
	TEXT_ENTERED,
	## When the control gains focus.
	FOCUS_ENTERED,
	## When the control loses focus.
	FOCUS_EXITED,
}

## Animation action types.
enum AnimationAction {
	## Uniform scale expand from pivot (or shrink when [member reverse]).
	EXPAND,
	## Horizontal scale expand only.
	EXPAND_X,
	## Vertical scale expand only.
	EXPAND_Y,
	## Fade opacity in (or out when [member reverse]).
	FADE_IN,
	## Slide in from the left edge.
	SLIDE_FROM_LEFT,
	## Slide in from the right edge.
	SLIDE_FROM_RIGHT,
	## Slide in from the top edge.
	SLIDE_FROM_TOP,
	## Slide in from the bottom edge.
	SLIDE_FROM_BOTTOM,
	## Move from the left toward center.
	FROM_LEFT_TO_CENTER,
	## Move from the right toward center.
	FROM_RIGHT_TO_CENTER,
	## Move from the top toward center.
	FROM_TOP_TO_CENTER,
	## Move from the bottom toward center.
	FROM_BOTTOM_TO_CENTER,
	## Bouncy scale-in from pivot.
	BOUNCE_IN,
	## Elastic overshoot scale-in from pivot.
	ELASTIC_IN,
	## Rotate in from [member rotate_start_angle] (uses pivot).
	ROTATE_IN,
	## Pop scale with overshoot ([member pop_overshoot]).
	POP,
	## Pulse scale ([member pulse_amount], [member pulse_count]).
	PULSE,
	## Shake position ([member shake_intensity], [member shake_count]).
	SHAKE,
	## Subtle breathing scale motion.
	BREATHING,
	## Wobble rotation.
	WOBBLE,
	## Vertical floating motion.
	FLOAT,
	## Pulsing glow/outline style effect.
	GLOW_PULSE,
	## Flash modulate toward [member flash_color] ([member flash_intensity]).
	COLOR_FLASH,
	## Restore baseline transform/modulate/state.
	RESET,
}

## Easing types for animations.
enum Easing {
	## Slow start, fast end.
	EASE_IN,
	## Fast start, slow end (default).
	EASE_OUT,
	## Slow start and end, fast middle.
	EASE_IN_OUT,
	## Fast start and end, slow middle.
	EASE_OUT_IN,
}

## How [enum AnimationAction.RESET] restores baseline (main animation or lead-in preamble).
enum ResetBehavior {
	## Restore unified snapshot only (default).
	RESET_VISUAL_ONLY,
	## Stop loop/sequence helpers on [member target] via [method UiAnimUtils.stop_all_animations], then restore snapshot.
	RESET_AND_STOP,
}

## Dispatch defaults aligned with [UiAnimUtils] slide/float/reset behavior.
const DEFAULT_SLIDE_OFFSET_PX := 8.0
const ROTATE_OUT_END_DEGREES := 360.0
const FLOAT_DEFAULT_AMPLITUDE_PX := 10.0
const RESET_INSTANT_DURATION_SECONDS := 0.0

## Animations that use [member pivot_offset] in [method apply_to_control].
const _PIVOT_ANIMATIONS: Array[AnimationAction] = [
	AnimationAction.EXPAND, AnimationAction.EXPAND_X, AnimationAction.EXPAND_Y,
	AnimationAction.BOUNCE_IN, AnimationAction.ELASTIC_IN, AnimationAction.ROTATE_IN,
	AnimationAction.POP, AnimationAction.PULSE, AnimationAction.BREATHING, AnimationAction.WOBBLE,
]

func _is_pivot_visible_for(action: AnimationAction) -> bool:
	return _PIVOT_ANIMATIONS.has(action)

## ============================================
## CORE SETTINGS
## ============================================

## The target control to animate.
## Drag and drop a node from the scene tree to this field (only [Control] nodes are accepted).
@export_node_path("Control") var target: NodePath = NodePath()

## Row / selection index for this row in the **host** [UiAnimTarget] array (not the animated [member target]'s node type).
## [code]-1[/code] (default): not row-scoped; always participates in [member trigger] dispatch when applicable.
## [code]>= 0[/code]: on hosts that implement [method Node.get_animation_selection_index] (e.g. [UiReactItemList], [UiReactTree]),
## [UiReactAnimTargetHelper.trigger_animations] only runs this row when the index matches (if any row uses slot gating).
## On [UiReactItemList], [method UiReactItemList.play_selected_row_animation] / [method UiReactItemList.play_preamble_reset_only]
## run every [UiAnimTarget] whose slot equals the selected row, in array order.
## If the host has no [code]get_animation_selection_index()[/code] but slot gating is requested, only [code]selection_slot == -1[/code] rows run (see helper warning).
@export var selection_slot: int = -1

## When to trigger this animation (dropdown selection in Inspector).
@export var trigger: Trigger = Trigger.PRESSED:
	set(value):
		if trigger == value:
			return
		trigger = value
		notify_property_list_changed()

## Before the main [member animation], optionally run [enum AnimationAction.RESET] on the same [member target].
## This is the **lead-in** reset duration—not the main tween [member duration]. [code]-1[/code] = disabled. [code]0[/code] = instant reset; [code]> 0[/code] = soft reset over that many seconds.
## Lead-in reset always uses [enum ResetBehavior.RESET_AND_STOP] on the internal copy (stop loops, then restore).
@export_range(-1.0, 3600.0, 0.001, "or_greater", "or_less") var reset_duration: float = -1.0:
	set(value):
		if reset_duration == value:
			return
		reset_duration = value
		notify_property_list_changed()

## When [code]true[/code] (default), the main animation starts **after** the lead-in [code]RESET[/code] tween finishes.
## When [code]false[/code], the main animation is scheduled immediately; both may overlap on the same [member target].
@export var wait_after_reset: bool = true

## Animation type to perform (dropdown selection in Inspector).
## Changing this refreshes which advanced fields are visible in the Inspector.
@export var animation: AnimationAction = AnimationAction.EXPAND:
	set(value):
		if animation == value:
			return
		animation = value
		notify_property_list_changed()

## ============================================
## TIMING & EASING
## ============================================

## Animation duration in seconds.
## For [enum AnimationAction.RESET], `0` is an instant (hard) restore; larger values tween to the stored snapshot (soft reset).
@export_range(0.0, 60.0, 0.001, "or_greater") var duration: float = 0.3

## For [enum AnimationAction.RESET] only (ignored for other [member animation] values). See [enum ResetBehavior].
@export var reset_behavior: ResetBehavior = ResetBehavior.RESET_VISUAL_ONLY:
	set(value):
		if reset_behavior == value:
			return
		reset_behavior = value
		notify_property_list_changed()

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

## When true (default), animations that support it capture a unified baseline snapshot and release it when the tween completes (see slide, expand, shake, etc.).
## When false, baseline capture is skipped for those animations so motion can persist without a matching release—legacy escape hatch; [enum AnimationAction.RESET] still requires an existing snapshot.
@export var use_unified_baseline: bool = true

## ============================================
## ADVANCED SETTINGS
## (Editor: pivot and animation-specific fields below are shown only when relevant to [member animation].)
## ============================================

## Custom pivot offset for scaling/rotation animations.
## Use `UiAnimConstants.PIVOT_USE_CONTROL_DEFAULT` for center (default), or specify custom offset in pixels.
## Only affects animations that use pivot (EXPAND, SHRINK, POP, PULSE, ROTATE, etc.).
@export var pivot_offset: Vector2 = UiAnimConstants.PIVOT_USE_CONTROL_DEFAULT

## Note: All animations now automatically preserve their initial state for consistent RESET behavior.
## The preserve_position parameter has been removed as all animations use unified baseline snapshots.

## ============================================
## ANIMATION-SPECIFIC SETTINGS
## (Inspector: shown inline when relevant to [member animation]; no separate group headers.)
## ============================================

## Starting angle in degrees for ROTATE_IN animation (default: -360.0).
@export_range(-720.0, 720.0, 0.1, "or_greater", "or_less") var rotate_start_angle: float = -360.0

## Overshoot amount for POP animation (default: 1.2, meaning 20% overshoot).
@export_range(0.0, 5.0, 0.01, "or_greater") var pop_overshoot: float = 1.2

## Pulse scale amount for PULSE animation (default: 1.1, meaning 10% scale increase).
@export_range(0.0, 5.0, 0.01, "or_greater") var pulse_amount: float = 1.1

## Number of pulses for PULSE animation (default: 2).
@export_range(0, 999) var pulse_count: int = 2

## Shake intensity in pixels for SHAKE animation (default: 10.0).
@export_range(0.0, 500.0, 0.1, "or_greater") var shake_intensity: float = 10.0

## Number of shakes for SHAKE animation (default: 5).
@export_range(0, 999) var shake_count: int = 5

## Flash color for COLOR_FLASH animation.
@export var flash_color: Color = Color.YELLOW

## Flash intensity multiplier for COLOR_FLASH animation.
@export_range(0.0, 10.0, 0.01, "or_greater") var flash_intensity: float = 1.5


func _validate_property(property: Dictionary) -> void:
	var pname: StringName = property.name
	if pname == &"animation":
		return
	if pname == &"wait_after_reset":
		if reset_duration < 0.0:
			property.usage = PROPERTY_USAGE_STORAGE
		else:
			property.usage = PROPERTY_USAGE_DEFAULT
		return
	# Core + timing + behavior: always visible in the Inspector.
	var always_visible: Array[StringName] = [
		&"target", &"selection_slot", &"trigger", &"duration", &"easing", &"repeat_count",
		&"reverse", &"respect_disabled", &"reset_duration",
	]
	if pname in always_visible:
		return
	var show_in_editor: bool = false
	match pname:
		&"reset_behavior":
			show_in_editor = animation == AnimationAction.RESET
		&"pivot_offset":
			show_in_editor = _is_pivot_visible_for(animation)
		&"rotate_start_angle":
			show_in_editor = animation == AnimationAction.ROTATE_IN
		&"pop_overshoot":
			show_in_editor = animation == AnimationAction.POP
		&"pulse_amount", &"pulse_count":
			show_in_editor = animation == AnimationAction.PULSE
		&"shake_intensity", &"shake_count":
			show_in_editor = animation == AnimationAction.SHAKE
		&"flash_color", &"flash_intensity":
			show_in_editor = animation == AnimationAction.COLOR_FLASH
		_:
			return
	if show_in_editor:
		property.usage = PROPERTY_USAGE_DEFAULT
	else:
		property.usage = PROPERTY_USAGE_STORAGE


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


func _create_preamble_reset_resource() -> UiAnimTarget:
	var t := UiAnimTarget.new()
	t.animation = AnimationAction.RESET
	t.target = target
	t.duration = reset_duration
	t.easing = easing
	t.use_unified_baseline = use_unified_baseline
	t.reset_behavior = ResetBehavior.RESET_AND_STOP
	return t


## Runs optional preamble [enum AnimationAction.RESET] on [member target], then the main [member animation].
## When [member reset_duration] is [code]< 0[/code], only the main animation runs (awaited to completion when a tween exists).
func apply_with_preamble(owner: Node) -> void:
	if target.is_empty():
		return
	if reset_duration < 0.0:
		if animation == AnimationAction.RESET:
			var only_sig := apply(owner)
			if not only_sig.is_null():
				await only_sig
			return
		var ms0 := apply(owner)
		if not ms0.is_null():
			await ms0
		return
	var reset_res := _create_preamble_reset_resource()
	var preamble_sig := reset_res.apply(owner)
	if wait_after_reset and not preamble_sig.is_null():
		await preamble_sig
	if animation == AnimationAction.RESET:
		return
	var main_sig := apply(owner)
	if not main_sig.is_null():
		await main_sig


## Runs only the preamble [code]RESET[/code] when [member reset_duration] is [code]>= 0[/code].
func apply_preamble_reset_only(owner: Node) -> void:
	if reset_duration < 0.0:
		return
	var reset_res := _create_preamble_reset_resource()
	var preamble_sig := reset_res.apply(owner)
	if not preamble_sig.is_null():
		await preamble_sig


## Applies this animation to a specific control target.
## [param owner]: The node that owns the animation (for creating tweens).
## [param control_target]: The already-resolved control to animate.
## [return]: Signal that emits when animation completes (or empty Signal if not applicable).
func apply_to_control(owner: Node, control_target: Control) -> Signal:
	if not UiAnimTweenFactory.guard_anim_pair(owner, control_target, "UiAnimTarget.apply_to_control"):
		return Signal()

	UiAnimBaselineApplyContext.push(use_unified_baseline)
	var result: Signal = _apply_to_control_impl(owner, control_target)
	UiAnimBaselineApplyContext.pop()
	return result


func _apply_to_control_impl(owner: Node, control_target: Control) -> Signal:
	var tween_easing: int = _tween_easing_from_enum()

	match animation:
		AnimationAction.EXPAND, AnimationAction.EXPAND_X, AnimationAction.EXPAND_Y:
			return _apply_expand_family(owner, control_target, tween_easing)
		AnimationAction.FADE_IN:
			return _apply_fade_family(owner, control_target, tween_easing)
		AnimationAction.SLIDE_FROM_LEFT, AnimationAction.SLIDE_FROM_RIGHT, AnimationAction.SLIDE_FROM_TOP, AnimationAction.SLIDE_FROM_BOTTOM:
			return _apply_slide_family(owner, control_target, tween_easing)
		AnimationAction.FROM_LEFT_TO_CENTER, AnimationAction.FROM_RIGHT_TO_CENTER, AnimationAction.FROM_TOP_TO_CENTER, AnimationAction.FROM_BOTTOM_TO_CENTER:
			return _apply_center_slide_family(owner, control_target, tween_easing)
		AnimationAction.BOUNCE_IN, AnimationAction.ELASTIC_IN, AnimationAction.ROTATE_IN:
			return _apply_elastic_bounce_rotate_family(owner, control_target, tween_easing)
		AnimationAction.POP, AnimationAction.PULSE, AnimationAction.SHAKE, AnimationAction.BREATHING, AnimationAction.WOBBLE, AnimationAction.FLOAT, AnimationAction.GLOW_PULSE, AnimationAction.COLOR_FLASH:
			return _apply_effect_family(owner, control_target, tween_easing)
		AnimationAction.RESET:
			return _apply_reset(owner, control_target, tween_easing)
		_:
			push_warning("UiAnimTarget: Unsupported animation type %d" % animation)
			return Signal()


func _tween_easing_from_enum() -> int:
	match easing:
		Easing.EASE_IN:
			return Tween.EASE_IN
		Easing.EASE_OUT:
			return Tween.EASE_OUT
		Easing.EASE_IN_OUT:
			return Tween.EASE_IN_OUT
		Easing.EASE_OUT_IN:
			return Tween.EASE_OUT_IN
	return Tween.EASE_OUT


func _apply_expand_family(owner: Node, control_target: Control, tween_easing: int) -> Signal:
	match animation:
		AnimationAction.EXPAND:
			if reverse:
				return UiAnimUtils.animate_shrink(owner, control_target, duration, pivot_offset, true, true, true, repeat_count, tween_easing)
			return UiAnimUtils.animate_expand(owner, control_target, duration, pivot_offset, true, false, false, repeat_count, tween_easing)
		AnimationAction.EXPAND_X:
			if reverse:
				return UiAnimUtils.animate_shrink_x(owner, control_target, duration, pivot_offset, true, true, true, repeat_count, tween_easing)
			return UiAnimUtils.animate_expand_x(owner, control_target, duration, pivot_offset, true, repeat_count, tween_easing)
		AnimationAction.EXPAND_Y:
			if reverse:
				return UiAnimUtils.animate_shrink_y(owner, control_target, duration, pivot_offset, true, true, true, repeat_count, tween_easing)
			return UiAnimUtils.animate_expand_y(owner, control_target, duration, pivot_offset, true, repeat_count, tween_easing)
	return Signal()


func _apply_fade_family(owner: Node, control_target: Control, tween_easing: int) -> Signal:
	match animation:
		AnimationAction.FADE_IN:
			if reverse:
				return UiAnimUtils.animate_fade_out(owner, control_target, duration, true, true, repeat_count, tween_easing)
			return UiAnimUtils.animate_fade_in(owner, control_target, duration, true, repeat_count, tween_easing)
	return Signal()


func _apply_slide_family(owner: Node, control_target: Control, tween_easing: int) -> Signal:
	match animation:
		AnimationAction.SLIDE_FROM_LEFT:
			if reverse:
				return UiAnimUtils.animate_slide_to_left(owner, control_target, DEFAULT_SLIDE_OFFSET_PX, duration, true, repeat_count, tween_easing)
			return UiAnimUtils.animate_slide_from_left(owner, control_target, DEFAULT_SLIDE_OFFSET_PX, duration, true, repeat_count, tween_easing)
		AnimationAction.SLIDE_FROM_RIGHT:
			if reverse:
				return UiAnimUtils.animate_slide_to_right(owner, control_target, DEFAULT_SLIDE_OFFSET_PX, duration, true, repeat_count, tween_easing)
			return UiAnimUtils.animate_slide_from_right(owner, control_target, DEFAULT_SLIDE_OFFSET_PX, duration, true, repeat_count, tween_easing)
		AnimationAction.SLIDE_FROM_TOP:
			if reverse:
				return UiAnimUtils.animate_slide_to_top(owner, control_target, duration, true, repeat_count, tween_easing)
			return UiAnimUtils.animate_slide_from_top(owner, control_target, DEFAULT_SLIDE_OFFSET_PX, duration, true, repeat_count, tween_easing)
		AnimationAction.SLIDE_FROM_BOTTOM:
			if reverse:
				return UiAnimUtils.animate_slide_to_bottom(owner, control_target, duration, true, repeat_count, tween_easing)
			return UiAnimUtils.animate_slide_from_bottom(owner, control_target, DEFAULT_SLIDE_OFFSET_PX, duration, true, repeat_count, tween_easing)
	return Signal()


func _apply_center_slide_family(owner: Node, control_target: Control, tween_easing: int) -> Signal:
	match animation:
		AnimationAction.FROM_LEFT_TO_CENTER:
			if reverse:
				return UiAnimUtils.animate_from_center_to_left(owner, control_target, duration, true, repeat_count, tween_easing)
			return UiAnimUtils.animate_from_left_to_center(owner, control_target, duration, true, repeat_count, tween_easing)
		AnimationAction.FROM_RIGHT_TO_CENTER:
			if reverse:
				return UiAnimUtils.animate_from_center_to_right(owner, control_target, duration, true, repeat_count, tween_easing)
			return UiAnimUtils.animate_from_right_to_center(owner, control_target, duration, true, repeat_count, tween_easing)
		AnimationAction.FROM_TOP_TO_CENTER:
			if reverse:
				return UiAnimUtils.animate_from_center_to_top(owner, control_target, duration, true, repeat_count, tween_easing)
			return UiAnimUtils.animate_from_top_to_center(owner, control_target, duration, true, repeat_count, tween_easing)
		AnimationAction.FROM_BOTTOM_TO_CENTER:
			if reverse:
				return UiAnimUtils.animate_from_center_to_bottom(owner, control_target, duration, true, repeat_count, tween_easing)
			return UiAnimUtils.animate_from_bottom_to_center(owner, control_target, duration, true, repeat_count, tween_easing)
	return Signal()


func _apply_elastic_bounce_rotate_family(owner: Node, control_target: Control, tween_easing: int) -> Signal:
	match animation:
		AnimationAction.BOUNCE_IN:
			if reverse:
				return UiAnimUtils.animate_bounce_out(owner, control_target, duration, pivot_offset, true, true, true, repeat_count, tween_easing)
			return UiAnimUtils.animate_bounce_in(owner, control_target, duration, pivot_offset, true, repeat_count, tween_easing)
		AnimationAction.ELASTIC_IN:
			if reverse:
				return UiAnimUtils.animate_elastic_out(owner, control_target, duration, pivot_offset, true, true, true, repeat_count, tween_easing)
			return UiAnimUtils.animate_elastic_in(owner, control_target, duration, pivot_offset, true, repeat_count, tween_easing)
		AnimationAction.ROTATE_IN:
			if reverse:
				return UiAnimUtils.animate_rotate_out(owner, control_target, duration, ROTATE_OUT_END_DEGREES, true, true, true, repeat_count, tween_easing)
			return UiAnimUtils.animate_rotate_in(owner, control_target, duration, rotate_start_angle, pivot_offset, true, repeat_count, tween_easing)
	return Signal()


func _apply_effect_family(owner: Node, control_target: Control, tween_easing: int) -> Signal:
	match animation:
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
			return UiAnimUtils.animate_float(owner, control_target, duration, repeat_count, tween_easing, FLOAT_DEFAULT_AMPLITUDE_PX, false)
		AnimationAction.GLOW_PULSE:
			return UiAnimUtils.animate_glow_pulse(owner, control_target, duration, repeat_count, tween_easing)
		AnimationAction.COLOR_FLASH:
			return UiAnimUtils.animate_color_flash(owner, control_target, flash_color, duration, flash_intensity, true, tween_easing)
	return Signal()


func _apply_reset(owner: Node, control_target: Control, tween_easing: int) -> Signal:
	# Mirrors [method UiAnimUtils.animate_reset_all] with [code]stop_before_reset[/code] — keep behavior aligned with the façade API.
	if reset_behavior == ResetBehavior.RESET_AND_STOP:
		UiAnimUtils.stop_all_animations(owner, control_target)
	return UiAnimUtils.animate_reset_all(owner, control_target, duration, tween_easing, true)

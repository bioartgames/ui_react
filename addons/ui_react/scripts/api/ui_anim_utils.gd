## Static animation functions for UI element transitions (facade).
##
## Ownership (implementations live in family modules):
## - Slide/center motion: [UiAnimSlideAnimations]
## - Scale/pop/bounce/elastic (pop is scale-only): [UiAnimScaleAnimations]
## - Fade/glow/color: [UiAnimOpacityColorAnimations]
## - Rotate/pulse/shake/breathing/wobble/float (rotate is transform-only): [UiAnimTransformEffects]
## - Reset/focus/snapshot clear: [UiAnimStateUtils] ([method animate_reset_all] optionally stops loops first via [method stop_all_animations])
## - Stop/interrupt: [UiAnimRuntimeControl]
## - Loop orchestration: [UiAnimLoopRunner]
## - Enum presets: [UiAnimPresetRunner]
## - Stagger: [UiAnimStaggerRunner]
## - Delay: [UiAnimDelayHelpers]
##
## Example:
## [codeblock]
## await UiAnimUtils.animate_expand(self, panel).finished
## await UiAnimUtils.animate_fade_in(self, label).finished
## var sequence = UiAnimSequence.create()
## sequence.add(func(): return UiAnimUtils.animate_expand(self, panel))
## await sequence.play()
## [/codeblock]
class_name UiAnimUtils
extends RefCounted

## Numeric defaults for composing animations live in [UiAnimConstants]; this façade forwards to family modules.

static func get_node_center(source_node: Node, target: Control) -> float:
	return UiAnimTweenFactory.get_node_center(source_node, target)

static func get_center_pivot_offset(target: Control) -> Vector2:
	return UiAnimTweenFactory.get_center_pivot_offset(target)

static func create_safe_tween(node: Node) -> Tween:
	return UiAnimTweenFactory.create_safe_tween(node)

static func snapshot_control_state(target: Control) -> UiAnimSnapshotStore.ControlStateSnapshot:
	return UiAnimSnapshotStore.snapshot_control_state(target)

static func restore_control_state(target: Control, snapshot: UiAnimSnapshotStore.ControlStateSnapshot) -> void:
	UiAnimSnapshotStore.restore_control_state(target, snapshot)

static func reset_control_to_normal(target: Control) -> void:
	UiAnimStateUtils.reset_control_to_normal(target)

static func disable_focus_on_children(parent: Control, _exclude_self: bool = true) -> void:
	UiAnimStateUtils.disable_focus_on_children(parent, _exclude_self)

static func stop_all_animations(source_node: Node, target: Control) -> void:
	UiAnimRuntimeControl.stop_all_animations(source_node, target)

static func animate_slide_from_left(source_node: Node, target: Control, offset: float = UiAnimConstants.DEFAULT_OFFSET, speed: float = UiAnimConstants.DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	return UiAnimSlideAnimations.animate_slide_from_left(source_node, target, offset, speed, auto_visible, repeat_count, easing)

static func animate_slide_to_left(source_node: Node, target: Control, _offset: float = UiAnimConstants.DEFAULT_OFFSET, speed: float = UiAnimConstants.DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	return UiAnimSlideAnimations.animate_slide_to_left(source_node, target, _offset, speed, auto_visible, repeat_count, easing)

static func animate_slide_from_right(source_node: Node, target: Control, offset: float = UiAnimConstants.DEFAULT_OFFSET, speed: float = UiAnimConstants.DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	return UiAnimSlideAnimations.animate_slide_from_right(source_node, target, offset, speed, auto_visible, repeat_count, easing)

static func animate_slide_to_right(source_node: Node, target: Control, _offset: float = UiAnimConstants.DEFAULT_OFFSET, speed: float = UiAnimConstants.DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	return UiAnimSlideAnimations.animate_slide_to_right(source_node, target, _offset, speed, auto_visible, repeat_count, easing)

static func animate_slide_from_top(source_node: Node, target: Control, offset: float = UiAnimConstants.DEFAULT_OFFSET, speed: float = UiAnimConstants.DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	return UiAnimSlideAnimations.animate_slide_from_top(source_node, target, offset, speed, auto_visible, repeat_count, easing)

static func animate_slide_to_top(source_node: Node, target: Control, speed: float = UiAnimConstants.DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	return UiAnimSlideAnimations.animate_slide_to_top(source_node, target, speed, auto_visible, repeat_count, easing)

static func animate_expand(source_node: Node, target: Control, speed: float = UiAnimConstants.DEFAULT_SPEED, pivot_offset: Vector2 = UiAnimConstants.PIVOT_USE_CONTROL_DEFAULT, auto_visible: bool = false, auto_setup: bool = false, auto_reset: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	return UiAnimScaleAnimations.animate_expand(source_node, target, speed, pivot_offset, auto_visible, auto_setup, auto_reset, repeat_count, easing)

static func animate_expand_x(source_node: Node, target: Control, speed: float = UiAnimConstants.SHRINK_ANIMATION_SPEED, pivot_offset: Vector2 = UiAnimConstants.PIVOT_USE_CONTROL_DEFAULT, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	return UiAnimScaleAnimations.animate_expand_x(source_node, target, speed, pivot_offset, auto_visible, repeat_count, easing)

static func animate_expand_y(source_node: Node, target: Control, speed: float = UiAnimConstants.SHRINK_ANIMATION_SPEED, pivot_offset: Vector2 = UiAnimConstants.PIVOT_USE_CONTROL_DEFAULT, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	return UiAnimScaleAnimations.animate_expand_y(source_node, target, speed, pivot_offset, auto_visible, repeat_count, easing)

static func animate_shrink(source_node: Node, target: Control, speed: float = UiAnimConstants.DEFAULT_SPEED, pivot_offset: Vector2 = UiAnimConstants.PIVOT_USE_CONTROL_DEFAULT, auto_visible: bool = false, auto_setup: bool = false, auto_reset: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	return UiAnimScaleAnimations.animate_shrink(source_node, target, speed, pivot_offset, auto_visible, auto_setup, auto_reset, repeat_count, easing)

static func animate_shrink_x(source_node: Node, target: Control, speed: float = UiAnimConstants.SHRINK_ANIMATION_SPEED, pivot_offset: Vector2 = UiAnimConstants.PIVOT_USE_CONTROL_DEFAULT, auto_visible: bool = false, auto_setup: bool = false, auto_reset: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	return UiAnimScaleAnimations.animate_shrink_x(source_node, target, speed, pivot_offset, auto_visible, auto_setup, auto_reset, repeat_count, easing)

static func animate_shrink_y(source_node: Node, target: Control, speed: float = UiAnimConstants.SHRINK_ANIMATION_SPEED, pivot_offset: Vector2 = UiAnimConstants.PIVOT_USE_CONTROL_DEFAULT, auto_visible: bool = false, auto_setup: bool = false, auto_reset: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	return UiAnimScaleAnimations.animate_shrink_y(source_node, target, speed, pivot_offset, auto_visible, auto_setup, auto_reset, repeat_count, easing)

static func animate_fade_in(source_node: Node, target: Control, speed: float = UiAnimConstants.DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	return UiAnimOpacityColorAnimations.animate_fade_in(source_node, target, speed, auto_visible, repeat_count, easing)

static func animate_fade_out(source_node: Node, target: Control, speed: float = UiAnimConstants.DEFAULT_SPEED, auto_visible: bool = false, auto_reset: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	return UiAnimOpacityColorAnimations.animate_fade_out(source_node, target, speed, auto_visible, auto_reset, repeat_count, easing)

static func animate_from_left_to_center(source_node: Node, target: Control, speed: float = UiAnimConstants.DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	return UiAnimSlideAnimations.animate_from_left_to_center(source_node, target, speed, auto_visible, repeat_count, easing)

static func animate_from_center_to_left(source_node: Node, target: Control, speed: float = UiAnimConstants.DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	return UiAnimSlideAnimations.animate_from_center_to_left(source_node, target, speed, auto_visible, repeat_count, easing)

static func animate_from_right_to_center(source_node: Node, target: Control, speed: float = UiAnimConstants.DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	return UiAnimSlideAnimations.animate_from_right_to_center(source_node, target, speed, auto_visible, repeat_count, easing)

static func animate_from_center_to_right(source_node: Node, target: Control, speed: float = UiAnimConstants.DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	return UiAnimSlideAnimations.animate_from_center_to_right(source_node, target, speed, auto_visible, repeat_count, easing)

static func animate_slide_from_bottom(source_node: Node, target: Control, offset: float = UiAnimConstants.DEFAULT_OFFSET, speed: float = UiAnimConstants.DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	return UiAnimSlideAnimations.animate_slide_from_bottom(source_node, target, offset, speed, auto_visible, repeat_count, easing)

static func animate_slide_to_bottom(source_node: Node, target: Control, speed: float = UiAnimConstants.DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	return UiAnimSlideAnimations.animate_slide_to_bottom(source_node, target, speed, auto_visible, repeat_count, easing)

static func get_node_center_y(source_node: Node, target: Control) -> float:
	return UiAnimTweenFactory.get_node_center_y(source_node, target)

static func animate_from_top_to_center(source_node: Node, target: Control, speed: float = UiAnimConstants.DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	return UiAnimSlideAnimations.animate_from_top_to_center(source_node, target, speed, auto_visible, repeat_count, easing)

static func animate_from_center_to_top(source_node: Node, target: Control, speed: float = UiAnimConstants.DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	return UiAnimSlideAnimations.animate_from_center_to_top(source_node, target, speed, auto_visible, repeat_count, easing)

static func animate_from_bottom_to_center(source_node: Node, target: Control, speed: float = UiAnimConstants.DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	return UiAnimSlideAnimations.animate_from_bottom_to_center(source_node, target, speed, auto_visible, repeat_count, easing)

static func animate_from_center_to_bottom(source_node: Node, target: Control, speed: float = UiAnimConstants.DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	return UiAnimSlideAnimations.animate_from_center_to_bottom(source_node, target, speed, auto_visible, repeat_count, easing)

static func animate_bounce_in(source_node: Node, target: Control, speed: float = UiAnimConstants.DEFAULT_SPEED, pivot_offset: Vector2 = UiAnimConstants.PIVOT_USE_CONTROL_DEFAULT, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	return UiAnimScaleAnimations.animate_bounce_in(source_node, target, speed, pivot_offset, auto_visible, repeat_count, easing)

static func animate_bounce_out(source_node: Node, target: Control, speed: float = UiAnimConstants.DEFAULT_SPEED, pivot_offset: Vector2 = UiAnimConstants.PIVOT_USE_CONTROL_DEFAULT, auto_visible: bool = false, auto_setup: bool = false, auto_reset: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	return UiAnimScaleAnimations.animate_bounce_out(source_node, target, speed, pivot_offset, auto_visible, auto_setup, auto_reset, repeat_count, easing)

static func animate_elastic_in(source_node: Node, target: Control, speed: float = UiAnimConstants.DEFAULT_SPEED, pivot_offset: Vector2 = UiAnimConstants.PIVOT_USE_CONTROL_DEFAULT, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	return UiAnimScaleAnimations.animate_elastic_in(source_node, target, speed, pivot_offset, auto_visible, repeat_count, easing)

static func animate_elastic_out(source_node: Node, target: Control, speed: float = UiAnimConstants.DEFAULT_SPEED, pivot_offset: Vector2 = UiAnimConstants.PIVOT_USE_CONTROL_DEFAULT, auto_visible: bool = false, auto_setup: bool = false, auto_reset: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	return UiAnimScaleAnimations.animate_elastic_out(source_node, target, speed, pivot_offset, auto_visible, auto_setup, auto_reset, repeat_count, easing)

static func animate_rotate_in(source_node: Node, target: Control, speed: float = UiAnimConstants.DEFAULT_SPEED, start_angle: float = -360.0, pivot_offset: Vector2 = UiAnimConstants.PIVOT_USE_CONTROL_DEFAULT, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	return UiAnimTransformEffects.animate_rotate_in(source_node, target, speed, start_angle, pivot_offset, auto_visible, repeat_count, easing)

static func animate_rotate_out(source_node: Node, target: Control, speed: float = UiAnimConstants.DEFAULT_SPEED, end_angle: float = 360.0, auto_visible: bool = false, auto_setup: bool = false, auto_reset: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	return UiAnimTransformEffects.animate_rotate_out(source_node, target, speed, end_angle, auto_visible, auto_setup, auto_reset, repeat_count, easing)

static func animate_pop(source_node: Node, target: Control, speed: float = UiAnimConstants.DEFAULT_SPEED, overshoot: float = 1.2, pivot_offset: Vector2 = UiAnimConstants.PIVOT_USE_CONTROL_DEFAULT, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	return UiAnimScaleAnimations.animate_pop(source_node, target, speed, overshoot, pivot_offset, auto_visible, repeat_count, easing)

static func animate_pulse(source_node: Node, target: Control, speed: float = 0.5, pulse_amount: float = 1.1, pulse_count: int = 2, pivot_offset: Vector2 = UiAnimConstants.PIVOT_USE_CONTROL_DEFAULT, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	return UiAnimTransformEffects.animate_pulse(source_node, target, speed, pulse_amount, pulse_count, pivot_offset, auto_visible, repeat_count, easing)

static func animate_shake(source_node: Node, target: Control, speed: float = 0.5, intensity: float = 10.0, shake_count: int = 5, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	return UiAnimTransformEffects.animate_shake(source_node, target, speed, intensity, shake_count, auto_visible, repeat_count, easing)

## [param stop_before_reset]: When [code]true[/code], calls [method stop_all_animations] on [param target] before delegating to [UiAnimStateUtils.animate_reset_all] (stops infinite/finite loop helpers under the control).
static func animate_reset_all(source_node: Node, target: Control, duration: float = 0.3, easing: int = Tween.EASE_OUT, clear_unified_after: bool = true, stop_before_reset: bool = false) -> Signal:
	if stop_before_reset:
		UiAnimRuntimeControl.stop_all_animations(source_node, target)
	return UiAnimStateUtils.animate_reset_all(source_node, target, duration, easing, clear_unified_after)

static func clear_unified_snapshot_for_target(target: Control) -> void:
	UiAnimStateUtils.clear_unified_snapshot_for_target(target)

static func animate_breathing(source_node: Node, target: Control, duration: float = 2.0, repeat_count: int = -1, easing: int = Tween.EASE_OUT, pivot_offset: Vector2 = UiAnimConstants.PIVOT_USE_CONTROL_DEFAULT, auto_visible: bool = false) -> Signal:
	return UiAnimTransformEffects.animate_breathing(source_node, target, duration, repeat_count, easing, pivot_offset, auto_visible)

static func animate_wobble(source_node: Node, target: Control, duration: float = 1.5, repeat_count: int = -1, easing: int = Tween.EASE_OUT, pivot_offset: Vector2 = UiAnimConstants.PIVOT_USE_CONTROL_DEFAULT, auto_visible: bool = false) -> Signal:
	return UiAnimTransformEffects.animate_wobble(source_node, target, duration, repeat_count, easing, pivot_offset, auto_visible)

static func animate_float(source_node: Node, target: Control, duration: float = 2.0, repeat_count: int = -1, easing: int = Tween.EASE_OUT, float_distance: float = UiAnimConstants.DEFAULT_FLOAT_DISTANCE_PX, auto_visible: bool = false) -> Signal:
	return UiAnimTransformEffects.animate_float(source_node, target, duration, repeat_count, easing, float_distance, auto_visible)

static func animate_glow_pulse(source_node: Node, target: Control, duration: float = 1.5, repeat_count: int = -1, easing: int = Tween.EASE_OUT, glow_min_alpha: float = 0.7, auto_visible: bool = false) -> Signal:
	return UiAnimOpacityColorAnimations.animate_glow_pulse(source_node, target, duration, repeat_count, easing, glow_min_alpha, auto_visible)

static func animate_color_flash(source_node: Node, target: Control, flash_color: Color = Color.YELLOW, duration: float = 0.2, flash_intensity: float = 1.5, auto_visible: bool = false, easing: int = Tween.EASE_OUT) -> Signal:
	return UiAnimOpacityColorAnimations.animate_color_flash(source_node, target, flash_color, duration, flash_intensity, auto_visible, easing)

static func stop_stagger_animations(source_node: Node, targets: Array[Control]) -> void:
	UiAnimStaggerRunner.stop_stagger_animations(source_node, targets)

static func animate_stagger(source_node: Node, targets: Array[Control], delay_between: float = 0.1, animation_config: UiAnimTarget = null) -> Signal:
	return UiAnimStaggerRunner.animate_stagger(source_node, targets, delay_between, animation_config)

static func animate_stagger_multi(source_node: Node, targets: Array[Control], delay_between: float = 0.1, animation_configs: Array[UiAnimTarget] = []) -> Signal:
	return UiAnimStaggerRunner.animate_stagger_multi(source_node, targets, delay_between, animation_configs)

static func delay(source_node: Node, duration: float) -> Signal:
	return UiAnimDelayHelpers.delay(source_node, duration)

enum Preset {
	EXPAND_IN,
	EXPAND_OUT,
	POP_IN,
	POP_OUT,
	SLIDE_IN_LEFT,
	SLIDE_IN_RIGHT,
	SLIDE_IN_TOP,
	SLIDE_OUT_LEFT,
	SLIDE_OUT_RIGHT,
	SLIDE_OUT_TOP,
	FADE_IN,
	FADE_OUT,
}

## Named show/hide presets: routes through [UiAnimPresetRunner] using [enum Preset].
static func preset(preset_type: Preset, source_node: Node, target: Control, speed: float = UiAnimConstants.DEFAULT_SPEED) -> Signal:
	return UiAnimPresetRunner.preset(preset_type, source_node, target, speed)

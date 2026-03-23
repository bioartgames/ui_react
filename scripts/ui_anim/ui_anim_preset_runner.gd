## Show/hide string presets and [enum UiAnimUtils.Preset] dispatch for [UiAnimUtils].
class_name UiAnimPresetRunner
extends RefCounted

## Shows a control with an animation. Sets visible to true and plays the specified animation.
static func show_animated(
	source_node: Node,
	target: Control,
	animation_type: String,
	speed: float
) -> void:
	target.visible = true
	if animation_type != "":
		match animation_type:
			"pop", "expand":
				await UiAnimUtils.animate_expand(source_node, target, speed)
			"slide_from_left":
				await UiAnimUtils.animate_slide_from_left(source_node, target, UiAnimUtils.DEFAULT_OFFSET, speed)
			"slide_from_right":
				await UiAnimUtils.animate_slide_from_right(source_node, target, UiAnimUtils.DEFAULT_OFFSET, speed)
			"slide_from_top":
				await UiAnimUtils.animate_slide_from_top(source_node, target, UiAnimUtils.DEFAULT_OFFSET, speed)
			"fade_in":
				await UiAnimUtils.animate_fade_in(source_node, target, speed)


## Hides a control with an animation. Plays the specified animation then sets visible to false.
static func hide_animated(
	source_node: Node,
	target: Control,
	animation_type: String,
	speed: float
) -> void:
	if animation_type != "":
		match animation_type:
			"shrink":
				await UiAnimUtils.animate_shrink(source_node, target, speed)
			"slide_to_left":
				await UiAnimUtils.animate_slide_to_left(source_node, target, UiAnimUtils.DEFAULT_OFFSET, speed)
			"slide_to_right":
				await UiAnimUtils.animate_slide_to_right(source_node, target, UiAnimUtils.DEFAULT_OFFSET, speed)
			"slide_to_top":
				await UiAnimUtils.animate_slide_to_top(source_node, target, speed)
			"fade_out":
				await UiAnimUtils.animate_fade_out(source_node, target, speed)
	target.visible = false


## Executes a preset animation type from [enum UiAnimUtils.Preset].
static func preset(preset_type: UiAnimUtils.Preset, source_node: Node, target: Control, speed: float) -> Signal:
	match preset_type:
		UiAnimUtils.Preset.EXPAND_IN, UiAnimUtils.Preset.POP_IN:
			return UiAnimUtils.animate_expand(source_node, target, speed)
		UiAnimUtils.Preset.EXPAND_OUT, UiAnimUtils.Preset.POP_OUT:
			return UiAnimUtils.animate_shrink(source_node, target, speed)
		UiAnimUtils.Preset.SLIDE_IN_LEFT:
			return UiAnimUtils.animate_slide_from_left(source_node, target, UiAnimUtils.DEFAULT_OFFSET, speed)
		UiAnimUtils.Preset.SLIDE_IN_RIGHT:
			return UiAnimUtils.animate_slide_from_right(source_node, target, UiAnimUtils.DEFAULT_OFFSET, speed)
		UiAnimUtils.Preset.SLIDE_IN_TOP:
			return UiAnimUtils.animate_slide_from_top(source_node, target, UiAnimUtils.DEFAULT_OFFSET, speed)
		UiAnimUtils.Preset.SLIDE_OUT_LEFT:
			return UiAnimUtils.animate_slide_to_left(source_node, target, UiAnimUtils.DEFAULT_OFFSET, speed)
		UiAnimUtils.Preset.SLIDE_OUT_RIGHT:
			return UiAnimUtils.animate_slide_to_right(source_node, target, UiAnimUtils.DEFAULT_OFFSET, speed)
		UiAnimUtils.Preset.SLIDE_OUT_TOP:
			return UiAnimUtils.animate_slide_to_top(source_node, target, speed)
		UiAnimUtils.Preset.FADE_IN:
			return UiAnimUtils.animate_fade_in(source_node, target, speed)
		UiAnimUtils.Preset.FADE_OUT:
			return UiAnimUtils.animate_fade_out(source_node, target, speed)
		_:
			return Signal()

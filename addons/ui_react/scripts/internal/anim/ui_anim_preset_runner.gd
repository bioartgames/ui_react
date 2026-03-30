## [enum UiAnimUtils.Preset] dispatch for [UiAnimUtils.preset].
class_name UiAnimPresetRunner
extends RefCounted


static func preset(preset_type: UiAnimUtils.Preset, source_node: Node, target: Control, speed: float) -> Signal:
	match preset_type:
		UiAnimUtils.Preset.EXPAND_IN, UiAnimUtils.Preset.POP_IN:
			return UiAnimUtils.animate_expand(source_node, target, speed)
		UiAnimUtils.Preset.EXPAND_OUT, UiAnimUtils.Preset.POP_OUT:
			return UiAnimUtils.animate_shrink(source_node, target, speed)
		UiAnimUtils.Preset.SLIDE_IN_LEFT:
			return UiAnimUtils.animate_slide_from_left(source_node, target, UiAnimConstants.DEFAULT_OFFSET, speed)
		UiAnimUtils.Preset.SLIDE_IN_RIGHT:
			return UiAnimUtils.animate_slide_from_right(source_node, target, UiAnimConstants.DEFAULT_OFFSET, speed)
		UiAnimUtils.Preset.SLIDE_IN_TOP:
			return UiAnimUtils.animate_slide_from_top(source_node, target, UiAnimConstants.DEFAULT_OFFSET, speed)
		UiAnimUtils.Preset.SLIDE_OUT_LEFT:
			return UiAnimUtils.animate_slide_to_left(source_node, target, UiAnimConstants.DEFAULT_OFFSET, speed)
		UiAnimUtils.Preset.SLIDE_OUT_RIGHT:
			return UiAnimUtils.animate_slide_to_right(source_node, target, UiAnimConstants.DEFAULT_OFFSET, speed)
		UiAnimUtils.Preset.SLIDE_OUT_TOP:
			return UiAnimUtils.animate_slide_to_top(source_node, target, speed)
		UiAnimUtils.Preset.FADE_IN:
			return UiAnimUtils.animate_fade_in(source_node, target, speed)
		UiAnimUtils.Preset.FADE_OUT:
			return UiAnimUtils.animate_fade_out(source_node, target, speed)
		_:
			return Signal()

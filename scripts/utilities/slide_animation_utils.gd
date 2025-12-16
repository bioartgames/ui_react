## Slide animation utilities for moving controls in and out of view.
##
## Provides functions for sliding controls from various directions (left, right, top, bottom)
## and center-based sliding animations. All functions use standardized patterns from AnimationCoreUtils.
class_name SlideAnimationUtils

## Default offset for slide animations in pixels.
const DEFAULT_OFFSET := 8.0

## Animates a control sliding in from the left side of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param offset]: Final position offset from left edge (default: 8.0).
## [param duration]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [param easing]: Easing type to use (default: Tween.EASE_OUT).
## [return]: Signal that emits when animation finishes.
static func animate_slide_from_left(source_node: Node, target: Control, offset := DEFAULT_OFFSET, duration := 0.3, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not AnimationCoreUtils.validate_animation_params(source_node, target, "animate_slide_from_left"):
		return Signal()

	var animation_callable = func() -> Signal:
		AnimationCoreUtils.handle_auto_visible(target, auto_visible)

		target.position.x = -target.size.x

		var t = source_node.create_tween()
		t.tween_property(target, 'position:x', offset, duration).set_trans(Tween.TRANS_BACK).set_ease(easing)

		return t.finished

	return AnimationCoreUtils.wrap_with_loop(source_node, target, animation_callable, repeat_count)

## Animates a control sliding out to the left side of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param _offset]: Unused parameter (kept for API consistency).
## [param duration]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation and visible=false after completion (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [param easing]: Easing type to use (default: Tween.EASE_OUT).
## [return]: Signal that emits when animation finishes.
static func animate_slide_to_left(source_node: Node, target: Control, _offset := DEFAULT_OFFSET, duration := 0.3, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not AnimationCoreUtils.validate_animation_params(source_node, target, "animate_slide_to_left"):
		return Signal()

	var animation_callable = func() -> Signal:
		AnimationCoreUtils.handle_auto_visible(target, auto_visible)

		var t = source_node.create_tween()
		t.tween_property(target, 'position:x', -target.size.x, duration).set_trans(Tween.TRANS_BACK).set_ease(easing)

		return t.finished

	var result_signal = AnimationCoreUtils.wrap_with_loop(source_node, target, animation_callable, repeat_count)

	# Hide after animation completes if auto_visible was true
	if auto_visible:
		result_signal.connect(func(): target.visible = false, CONNECT_ONE_SHOT)

	return result_signal

## Animates a control sliding in from the right side of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param offset]: Final position offset from right edge (default: 8.0).
## [param duration]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [param easing]: Easing type to use (default: Tween.EASE_OUT).
## [return]: Signal that emits when animation finishes.
static func animate_slide_from_right(source_node: Node, target: Control, offset := DEFAULT_OFFSET, duration := 0.3, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not AnimationCoreUtils.validate_animation_params(source_node, target, "animate_slide_from_right"):
		return Signal()

	var animation_callable = func() -> Signal:
		AnimationCoreUtils.handle_auto_visible(target, auto_visible)

		var viewport = source_node.get_viewport()
		if not viewport:
			push_warning("SlideAnimationUtils: source_node has no viewport")
			return Signal()

		target.position.x = viewport.size.x

		var t = source_node.create_tween()
		t.tween_property(target, "position:x", (viewport.size - target.size.x) - offset, duration).set_trans(Tween.TRANS_BACK).set_ease(easing)

		return t.finished

	return AnimationCoreUtils.wrap_with_loop(source_node, target, animation_callable, repeat_count)

## Animates a control sliding out to the right side of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param _offset]: Unused parameter (kept for API consistency).
## [param duration]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation and visible=false after completion (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [param easing]: Easing type to use (default: Tween.EASE_OUT).
## [return]: Signal that emits when animation finishes.
static func animate_slide_to_right(source_node: Node, target: Control, _offset := DEFAULT_OFFSET, duration := 0.3, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not AnimationCoreUtils.validate_animation_params(source_node, target, "animate_slide_to_right"):
		return Signal()

	var animation_callable = func() -> Signal:
		AnimationCoreUtils.handle_auto_visible(target, auto_visible)

		var t = source_node.create_tween()
		t.tween_property(target, 'position:x', source_node.get_viewport().size.x, duration).set_trans(Tween.TRANS_BACK).set_ease(easing)

		return t.finished

	var result_signal = AnimationCoreUtils.wrap_with_loop(source_node, target, animation_callable, repeat_count)

	# Hide after animation completes if auto_visible was true
	if auto_visible:
		result_signal.connect(func(): target.visible = false, CONNECT_ONE_SHOT)

	return result_signal

## Animates a control sliding in from the top of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param offset]: Final position offset from top edge (default: 8.0).
## [param duration]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [param easing]: Easing type to use (default: Tween.EASE_OUT).
## [return]: Signal that emits when animation finishes.
static func animate_slide_from_top(source_node: Node, target: Control, offset: float = DEFAULT_OFFSET, duration := 0.3, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not AnimationCoreUtils.validate_animation_params(source_node, target, "animate_slide_from_top"):
		return Signal()

	var animation_callable = func() -> Signal:
		AnimationCoreUtils.handle_auto_visible(target, auto_visible)

		target.position.y = -target.size.y

		var t = source_node.create_tween()
		t.tween_property(target, 'position:y', offset, duration).set_trans(Tween.TRANS_BACK).set_ease(easing)

		return t.finished

	return AnimationCoreUtils.wrap_with_loop(source_node, target, animation_callable, repeat_count)

## Animates a control sliding out to the top of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param duration]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation and visible=false after completion (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [param easing]: Easing type to use (default: Tween.EASE_OUT).
## [return]: Signal that emits when animation finishes.
static func animate_slide_to_top(source_node: Node, target: Control, duration := 0.3, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not AnimationCoreUtils.validate_animation_params(source_node, target, "animate_slide_to_top"):
		return Signal()

	var animation_callable = func() -> Signal:
		AnimationCoreUtils.handle_auto_visible(target, auto_visible)

		var t = source_node.create_tween()
		t.tween_property(target, 'position:y', -target.size.y, duration).set_trans(Tween.TRANS_BACK).set_ease(easing)

		return t.finished

	var result_signal = AnimationCoreUtils.wrap_with_loop(source_node, target, animation_callable, repeat_count)

	# Hide after animation completes if auto_visible was true
	if auto_visible:
		result_signal.connect(func(): target.visible = false, CONNECT_ONE_SHOT)

	return result_signal

## Animates a control sliding in from the bottom of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param offset]: Final position offset from bottom edge (default: 8.0).
## [param duration]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [param easing]: Easing type to use (default: Tween.EASE_OUT).
## [return]: Signal that emits when animation finishes.
static func animate_slide_from_bottom(source_node: Node, target: Control, offset: float = DEFAULT_OFFSET, duration := 0.3, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not AnimationCoreUtils.validate_animation_params(source_node, target, "animate_slide_from_bottom"):
		return Signal()

	var animation_callable = func() -> Signal:
		AnimationCoreUtils.handle_auto_visible(target, auto_visible)

		var viewport = source_node.get_viewport()
		if not viewport:
			push_warning("SlideAnimationUtils: source_node has no viewport")
			return Signal()

		target.position.y = viewport.size.y

		var t = source_node.create_tween()
		t.tween_property(target, 'position:y', (viewport.size - target.size.y) - offset, duration).set_trans(Tween.TRANS_BACK).set_ease(easing)

		return t.finished

	return AnimationCoreUtils.wrap_with_loop(source_node, target, animation_callable, repeat_count)

## Animates a control sliding out to the bottom of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param duration]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation and visible=false after completion (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [param easing]: Easing type to use (default: Tween.EASE_OUT).
## [return]: Signal that emits when animation finishes.
static func animate_slide_to_bottom(source_node: Node, target: Control, duration := 0.3, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not AnimationCoreUtils.validate_animation_params(source_node, target, "animate_slide_to_bottom"):
		return Signal()

	var animation_callable = func() -> Signal:
		AnimationCoreUtils.handle_auto_visible(target, auto_visible)

		var viewport = source_node.get_viewport()
		if not viewport:
			push_warning("SlideAnimationUtils: source_node has no viewport")
			return Signal()

		var t = source_node.create_tween()
		t.tween_property(target, 'position:y', viewport.get_visible_rect().size.y, duration).set_trans(Tween.TRANS_BACK).set_ease(easing)

		return t.finished

	var result_signal = AnimationCoreUtils.wrap_with_loop(source_node, target, animation_callable, repeat_count)

	# Hide after animation completes if auto_visible was true
	if auto_visible:
		result_signal.connect(func(): target.visible = false, CONNECT_ONE_SHOT)

	return result_signal

## Animates a control sliding from the left edge to the center of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param duration]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [param easing]: Easing type to use (default: Tween.EASE_OUT).
## [return]: Signal that emits when animation finishes.
static func animate_from_left_to_center(source_node: Node, target: Control, duration := 0.3, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not AnimationCoreUtils.validate_animation_params(source_node, target, "animate_from_left_to_center"):
		return Signal()

	var animation_callable = func() -> Signal:
		AnimationCoreUtils.handle_auto_visible(target, auto_visible)

		target.position.x = -target.size.x

		var t = source_node.create_tween()
		t.tween_property(target, 'position:x', AnimationCoreUtils.get_node_center(source_node, target), duration).set_trans(Tween.TRANS_BACK).set_ease(easing)

		return t.finished

	return AnimationCoreUtils.wrap_with_loop(source_node, target, animation_callable, repeat_count)

## Animates a control sliding from the center of the screen to the left edge.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param duration]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation and visible=false after completion (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [param easing]: Easing type to use (default: Tween.EASE_OUT).
## [return]: Signal that emits when animation finishes.
static func animate_from_center_to_left(source_node: Node, target: Control, duration := 0.3, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not AnimationCoreUtils.validate_animation_params(source_node, target, "animate_from_center_to_left"):
		return Signal()

	var animation_callable = func() -> Signal:
		AnimationCoreUtils.handle_auto_visible(target, auto_visible)

		var t = source_node.create_tween()
		t.tween_property(target, 'position:x', -target.size.x, duration).set_trans(Tween.TRANS_BACK).set_ease(easing)

		return t.finished

	var result_signal = AnimationCoreUtils.wrap_with_loop(source_node, target, animation_callable, repeat_count)

	# Hide after animation completes if auto_visible was true
	if auto_visible:
		result_signal.connect(func(): target.visible = false, CONNECT_ONE_SHOT)

	return result_signal

## Animates a control sliding from the right edge to the center of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param duration]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [param easing]: Easing type to use (default: Tween.EASE_OUT).
## [return]: Signal that emits when animation finishes.
static func animate_from_right_to_center(source_node: Node, target: Control, duration := 0.3, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not AnimationCoreUtils.validate_animation_params(source_node, target, "animate_from_right_to_center"):
		return Signal()

	var animation_callable = func() -> Signal:
		AnimationCoreUtils.handle_auto_visible(target, auto_visible)

		var viewport = source_node.get_viewport()
		if not viewport:
			push_warning("SlideAnimationUtils: source_node has no viewport")
			return Signal()

		target.position.x = viewport.size.x

		var t = source_node.create_tween()
		t.tween_property(target, 'position:x', AnimationCoreUtils.get_node_center(source_node, target), duration).set_trans(Tween.TRANS_BACK).set_ease(easing)

		return t.finished

	return AnimationCoreUtils.wrap_with_loop(source_node, target, animation_callable, repeat_count)

## Animates a control sliding from the center of the screen to the right edge.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param duration]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation and visible=false after completion (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [param easing]: Easing type to use (default: Tween.EASE_OUT).
## [return]: Signal that emits when animation finishes.
static func animate_from_center_to_right(source_node: Node, target: Control, duration := 0.3, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not AnimationCoreUtils.validate_animation_params(source_node, target, "animate_from_center_to_right"):
		return Signal()

	var animation_callable = func() -> Signal:
		AnimationCoreUtils.handle_auto_visible(target, auto_visible)

		var t = source_node.create_tween()
		t.tween_property(target, 'position:x', target.size.x, duration).set_trans(Tween.TRANS_BACK).set_ease(easing)

		return t.finished

	var result_signal = AnimationCoreUtils.wrap_with_loop(source_node, target, animation_callable, repeat_count)

	# Hide after animation completes if auto_visible was true
	if auto_visible:
		result_signal.connect(func(): target.visible = false, CONNECT_ONE_SHOT)

	return result_signal

## Animates a control sliding from the top edge to the center of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param duration]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [param easing]: Easing type to use (default: Tween.EASE_OUT).
## [return]: Signal that emits when animation finishes.
static func animate_from_top_to_center(source_node: Node, target: Control, duration := 0.3, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not AnimationCoreUtils.validate_animation_params(source_node, target, "animate_from_top_to_center"):
		return Signal()

	var animation_callable = func() -> Signal:
		AnimationCoreUtils.handle_auto_visible(target, auto_visible)

		target.position.y = -target.size.y

		var t = source_node.create_tween()
		t.tween_property(target, 'position:y', AnimationCoreUtils.get_node_center_y(source_node, target), duration).set_trans(Tween.TRANS_BACK).set_ease(easing)

		return t.finished

	return AnimationCoreUtils.wrap_with_loop(source_node, target, animation_callable, repeat_count)

## Animates a control sliding from the center of the screen to the top edge.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param duration]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation and visible=false after completion (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [param easing]: Easing type to use (default: Tween.EASE_OUT).
## [return]: Signal that emits when animation finishes.
static func animate_from_center_to_top(source_node: Node, target: Control, duration := 0.3, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not AnimationCoreUtils.validate_animation_params(source_node, target, "animate_from_center_to_top"):
		return Signal()

	var animation_callable = func() -> Signal:
		AnimationCoreUtils.handle_auto_visible(target, auto_visible)

		var t = source_node.create_tween()
		t.tween_property(target, 'position:y', -target.size.y, duration).set_trans(Tween.TRANS_BACK).set_ease(easing)

		return t.finished

	var result_signal = AnimationCoreUtils.wrap_with_loop(source_node, target, animation_callable, repeat_count)

	# Hide after animation completes if auto_visible was true
	if auto_visible:
		result_signal.connect(func(): target.visible = false, CONNECT_ONE_SHOT)

	return result_signal

## Animates a control sliding from the bottom edge to the center of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param duration]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [param easing]: Easing type to use (default: Tween.EASE_OUT).
## [return]: Signal that emits when animation finishes.
static func animate_from_bottom_to_center(source_node: Node, target: Control, duration := 0.3, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not AnimationCoreUtils.validate_animation_params(source_node, target, "animate_from_bottom_to_center"):
		return Signal()

	var animation_callable = func() -> Signal:
		AnimationCoreUtils.handle_auto_visible(target, auto_visible)

		var viewport = source_node.get_viewport()
		if not viewport:
			push_warning("SlideAnimationUtils: source_node has no viewport")
			return Signal()

		target.position.y = viewport.size.y

		var t = source_node.create_tween()
		t.tween_property(target, 'position:y', AnimationCoreUtils.get_node_center_y(source_node, target), duration).set_trans(Tween.TRANS_BACK).set_ease(easing)

		return t.finished

	return AnimationCoreUtils.wrap_with_loop(source_node, target, animation_callable, repeat_count)

## Animates a control sliding from the center of the screen to the bottom edge.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param duration]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation and visible=false after completion (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [param easing]: Easing type to use (default: Tween.EASE_OUT).
## [return]: Signal that emits when animation finishes.
static func animate_from_center_to_bottom(source_node: Node, target: Control, duration := 0.3, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not AnimationCoreUtils.validate_animation_params(source_node, target, "animate_from_center_to_bottom"):
		return Signal()

	var animation_callable = func() -> Signal:
		AnimationCoreUtils.handle_auto_visible(target, auto_visible)

		var viewport = source_node.get_viewport()
		if not viewport:
			push_warning("SlideAnimationUtils: source_node has no viewport")
			return Signal()

		var t = source_node.create_tween()
		t.tween_property(target, 'position:y', viewport.get_visible_rect().size.y, duration).set_trans(Tween.TRANS_BACK).set_ease(easing)

		return t.finished

	var result_signal = AnimationCoreUtils.wrap_with_loop(source_node, target, animation_callable, repeat_count)

	# Hide after animation completes if auto_visible was true
	if auto_visible:
		result_signal.connect(func(): target.visible = false, CONNECT_ONE_SHOT)

	return result_signal

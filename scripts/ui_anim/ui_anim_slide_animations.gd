## Edge slides and center-position motion (extracted from [UiAnimUtils]).
class_name UiAnimSlideAnimations
extends RefCounted

## Animates a control sliding in from the left side of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param offset]: Final position offset from left edge (default: 8.0).
## [param speed]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_slide_from_left(source_node: Node, target: Control, offset := UiAnimConstants.DEFAULT_OFFSET, speed := UiAnimConstants.DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		target.position.x = -target.size.x
		
		var tween = source_node.create_tween()
		tween.tween_property(target, 'position:x', offset, speed).set_trans(Tween.TRANS_BACK).set_ease(easing)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control sliding out to the left side of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param _offset]: Unused parameter (kept for API consistency).
## [param speed]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation and visible=false after completion (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_slide_to_left(source_node: Node, target: Control, _offset := UiAnimConstants.DEFAULT_OFFSET, speed := UiAnimConstants.DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		var tween = source_node.create_tween()
		tween.tween_property(target, 'position:x', -target.size.x, speed).set_trans(Tween.TRANS_BACK).set_ease(easing)
		
		if auto_visible:
			tween.finished.connect(func(): target.visible = false)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control sliding in from the right side of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param offset]: Final position offset from right edge (default: 8.0).
## [param speed]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_slide_from_right(source_node: Node, target: Control, offset := UiAnimConstants.DEFAULT_OFFSET, speed := UiAnimConstants.DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	var animation_callable = func() -> Signal:
		if not source_node or not target:
			push_warning("UiAnimUtils: Invalid source_node or target for animate_slide_from_right")
			return Signal()
		
		if auto_visible:
			target.visible = true
		
		var viewport = source_node.get_viewport()
		if not viewport:
			push_warning("UiAnimUtils: source_node has no viewport")
			return Signal()
		
		var viewport_size = viewport.get_visible_rect().size.x
		target.position.x = viewport_size
		
		var tween = source_node.create_tween()
		if not tween:
			push_warning("UiAnimUtils: Failed to create tween")
			return Signal()
		
		tween.tween_property(target, "position:x", (viewport_size - target.size.x) - offset, speed).set_trans(Tween.TRANS_BACK).set_ease(easing)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control sliding out to the right side of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param _offset]: Unused parameter (kept for API consistency).
## [param speed]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation and visible=false after completion (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_slide_to_right(source_node: Node, target: Control, _offset := UiAnimConstants.DEFAULT_OFFSET, speed := UiAnimConstants.DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		var tween = source_node.create_tween()
		tween.tween_property(target, 'position:x', source_node.get_viewport().size.x, speed).set_trans(Tween.TRANS_BACK).set_ease(easing)
		
		if auto_visible:
			tween.finished.connect(func(): target.visible = false)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control sliding in from the top of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param offset]: Final position offset from top edge (default: 8.0).
## [param speed]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_slide_from_top(source_node: Node, target: Control, offset: float = UiAnimConstants.DEFAULT_OFFSET, speed := UiAnimConstants.DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		target.position.y = -target.size.y
		
		var tween = source_node.create_tween()
		tween.tween_property(target, 'position:y', offset, speed).set_trans(Tween.TRANS_BACK).set_ease(easing)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control sliding out to the top of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation and visible=false after completion (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_slide_to_top(source_node: Node, target: Control, speed := UiAnimConstants.DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		var tween = source_node.create_tween()
		tween.tween_property(target, 'position:y', -target.size.y, speed).set_trans(Tween.TRANS_BACK).set_ease(easing)
		
		if auto_visible:
			tween.finished.connect(func(): target.visible = false)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control sliding from the left edge to the center of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_from_left_to_center(source_node: Node, target: Control, speed := UiAnimConstants.DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		target.position.x = -target.size.x
		
		var tween = source_node.create_tween()
		tween.tween_property(target, 'position:x', UiAnimTweenFactory.get_node_center(source_node, target), speed).set_trans(Tween.TRANS_BACK).set_ease(easing)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control sliding from the center to the left edge of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation and visible=false after completion (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_from_center_to_left(source_node: Node, target: Control, speed := UiAnimConstants.DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		var tween = source_node.create_tween()
		tween.tween_property(target, 'position:x', -target.size.x, speed).set_trans(Tween.TRANS_BACK).set_ease(easing)
		
		if auto_visible:
			tween.finished.connect(func(): target.visible = false)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control sliding from the right edge to the center of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_from_right_to_center(source_node: Node, target: Control, speed := UiAnimConstants.DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not source_node or not target:
		push_warning("UiAnimUtils: Invalid source_node or target for animate_from_right_to_center")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		var viewport = source_node.get_viewport()
		if not viewport:
			push_warning("UiAnimUtils: source_node has no viewport")
			return Signal()
		
		target.position.x = viewport.get_visible_rect().size.x
		
		var tween = source_node.create_tween()
		if not tween:
			push_warning("UiAnimUtils: Failed to create tween")
			return Signal()
		
		tween.tween_property(target, 'position:x', UiAnimTweenFactory.get_node_center(source_node, target), speed).set_trans(Tween.TRANS_BACK).set_ease(easing)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control sliding from the center to the right edge of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation and visible=false after completion (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_from_center_to_right(source_node: Node, target: Control, speed := UiAnimConstants.DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		var tween = source_node.create_tween()
		tween.tween_property(target, 'position:x', target.size.x, speed).set_trans(Tween.TRANS_BACK).set_ease(easing)
		
		if auto_visible:
			tween.finished.connect(func(): target.visible = false)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control sliding in from the bottom of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param offset]: Final position offset from bottom edge (default: 8.0).
## [param speed]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_slide_from_bottom(source_node: Node, target: Control, offset: float = UiAnimConstants.DEFAULT_OFFSET, speed := UiAnimConstants.DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not source_node or not target:
		push_warning("UiAnimUtils: Invalid source_node or target for animate_slide_from_bottom")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		var viewport = source_node.get_viewport()
		if not viewport:
			push_warning("UiAnimUtils: source_node has no viewport")
			return Signal()
		
		var viewport_size = viewport.get_visible_rect().size.y
		target.position.y = viewport_size
		
		var tween = source_node.create_tween()
		if not tween:
			push_warning("UiAnimUtils: Failed to create tween")
			return Signal()
		
		tween.tween_property(target, 'position:y', (viewport_size - target.size.y) - offset, speed).set_trans(Tween.TRANS_BACK).set_ease(easing)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control sliding out to the bottom of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation and visible=false after completion (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_slide_to_bottom(source_node: Node, target: Control, speed := UiAnimConstants.DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not source_node or not target:
		push_warning("UiAnimUtils: Invalid source_node or target for animate_slide_to_bottom")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		var viewport = source_node.get_viewport()
		if not viewport:
			push_warning("UiAnimUtils: source_node has no viewport")
			return Signal()
		
		var tween = source_node.create_tween()
		if not tween:
			push_warning("UiAnimUtils: Failed to create tween")
			return Signal()
		
		tween.tween_property(target, 'position:y', viewport.get_visible_rect().size.y, speed).set_trans(Tween.TRANS_BACK).set_ease(easing)
		
		if auto_visible:
			tween.finished.connect(func(): target.visible = false)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

static func animate_from_top_to_center(source_node: Node, target: Control, speed := UiAnimConstants.DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not source_node or not target:
		push_warning("UiAnimUtils: Invalid source_node or target for animate_from_top_to_center")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		target.position.y = -target.size.y
		
		var tween = source_node.create_tween()
		if not tween:
			push_warning("UiAnimUtils: Failed to create tween")
			return Signal()
		
		tween.tween_property(target, 'position:y', UiAnimTweenFactory.get_node_center_y(source_node, target), speed).set_trans(Tween.TRANS_BACK).set_ease(easing)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control sliding from the center to the top edge of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation and visible=false after completion (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_from_center_to_top(source_node: Node, target: Control, speed := UiAnimConstants.DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not source_node or not target:
		push_warning("UiAnimUtils: Invalid source_node or target for animate_from_center_to_top")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		var tween = source_node.create_tween()
		if not tween:
			push_warning("UiAnimUtils: Failed to create tween")
			return Signal()
		
		tween.tween_property(target, 'position:y', -target.size.y, speed).set_trans(Tween.TRANS_BACK).set_ease(easing)
		
		if auto_visible:
			tween.finished.connect(func(): target.visible = false)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control sliding from the bottom edge to the center of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_from_bottom_to_center(source_node: Node, target: Control, speed := UiAnimConstants.DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not source_node or not target:
		push_warning("UiAnimUtils: Invalid source_node or target for animate_from_bottom_to_center")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		var viewport = source_node.get_viewport()
		if not viewport:
			push_warning("UiAnimUtils: source_node has no viewport")
			return Signal()
		
		target.position.y = viewport.get_visible_rect().size.y
		
		var tween = source_node.create_tween()
		if not tween:
			push_warning("UiAnimUtils: Failed to create tween")
			return Signal()
		
		tween.tween_property(target, 'position:y', UiAnimTweenFactory.get_node_center_y(source_node, target), speed).set_trans(Tween.TRANS_BACK).set_ease(easing)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()

## Animates a control sliding from the center to the bottom edge of the screen.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param speed]: Animation duration in seconds (default: 0.3).
## [param auto_visible]: If true, automatically sets visible=true before animation and visible=false after completion (default: false).
## [param repeat_count]: Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop) (default: 0).
## [return]: Signal that emits when animation finishes.
static func animate_from_center_to_bottom(source_node: Node, target: Control, speed := UiAnimConstants.DEFAULT_SPEED, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT) -> Signal:
	if not source_node or not target:
		push_warning("UiAnimUtils: Invalid source_node or target for animate_from_center_to_bottom")
		return Signal()
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		var viewport = source_node.get_viewport()
		if not viewport:
			push_warning("UiAnimUtils: source_node has no viewport")
			return Signal()
		
		var tween = source_node.create_tween()
		if not tween:
			push_warning("UiAnimUtils: Failed to create tween")
			return Signal()
		
		tween.tween_property(target, 'position:y', viewport.get_visible_rect().size.y, speed).set_trans(Tween.TRANS_BACK).set_ease(easing)
		
		if auto_visible:
			tween.finished.connect(func(): target.visible = false)
		
		return tween.finished
	
	if repeat_count != 0:
		return UiAnimLoopRunner.loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		return animation_callable.call()
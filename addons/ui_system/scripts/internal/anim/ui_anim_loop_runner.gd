## Orchestrates finite and infinite animation loop helpers for [UiAnimUtils].
## Uses an explicit helper stack so tween creation can register with the active loop
## without storing metadata on the source node.
class_name UiAnimLoopRunner
extends RefCounted

## Must match [member UiAnimRuntimeControl.META_ANIMATION_LOOP_HELPER].
const META_ANIMATION_LOOP_HELPER: StringName = &"_is_animation_loop_helper"

static var _helper_stack: Array = []

static func push_loop_helper(helper: Node) -> void:
	_helper_stack.append(helper)


static func pop_loop_helper() -> void:
	if _helper_stack.size() > 0:
		_helper_stack.pop_back()


static func peek_loop_helper() -> Node:
	if _helper_stack.size() > 0:
		return _helper_stack[_helper_stack.size() - 1]
	return null


## Creates a tween and registers it with the active infinite-loop helper when applicable.
static func create_tracked_tween(source_node: Node) -> Tween:
	var tween = source_node.create_tween()
	if not tween:
		return null
	var h = peek_loop_helper()
	if h and h.has_method("_track_tween"):
		h.call("_track_tween", tween)
	return tween


## Loops a tween animation (finite repeats or infinite).
## [param source_node]: Node used by animation callables for tween creation.
## [param target]: Control receiving loop helper nodes.
## [param animation_callable]: Callable returning a tween's finished [Signal].
## [param repeat_count]: 0 = once, -1 = infinite, N = N repeats after first play (total N+1).
static func loop_animation(_source_node: Node, target: Control, animation_callable: Callable, repeat_count: int) -> Signal:
	if repeat_count == 0:
		return animation_callable.call()

	if repeat_count == -1:
		var infinite_helper = _AnimationLoopHelper.new()
		infinite_helper._target_control = target
		target.add_child(infinite_helper)
		var wrapped_callable = infinite_helper._wrap_animation_callable(animation_callable)
		infinite_helper.start_infinite_loop(wrapped_callable)
		return infinite_helper.loop_finished

	var sequence = UiAnimSequence.create()
	var total_plays = repeat_count + 1
	for i in range(total_plays):
		sequence.add(animation_callable)

	var finite_helper = _FiniteLoopHelper.new()
	target.add_child(finite_helper)
	finite_helper.execute_sequence(sequence)
	return finite_helper.sequence_finished


## Helper node for executing finite animation loops.
class _FiniteLoopHelper extends Node:
	var sequence_finished = Signal()

	func execute_sequence(sequence: UiAnimSequence) -> void:
		await sequence.play()
		sequence_finished.emit()
		queue_free()


## Helper node for managing infinite animation loops.
class _AnimationLoopHelper extends Node:
	var loop_finished = Signal()
	var _is_running = false
	var _target_control: Control = null
	var _active_tweens: Array[Tween] = []

	func _init() -> void:
		set_meta(META_ANIMATION_LOOP_HELPER, true)

	func _track_tween(tween: Tween) -> void:
		_active_tweens.append(tween)

	func _wrap_animation_callable(original_callable: Callable) -> Callable:
		return func() -> Signal:
			UiAnimLoopRunner.push_loop_helper(self)
			var signal_result = original_callable.call()
			UiAnimLoopRunner.pop_loop_helper()
			return signal_result

	func start_infinite_loop(animation_callable: Callable) -> void:
		_is_running = true
		_continue_loop(animation_callable)

	func _continue_loop(animation_callable: Callable) -> void:
		if not _is_running:
			return

		_active_tweens = _active_tweens.filter(func(t: Tween) -> bool:
			return is_instance_valid(t) and t.is_valid() and t.is_running()
		)

		var signal_result = animation_callable.call()
		if signal_result is Signal:
			await signal_result
			if _is_running:
				_continue_loop(animation_callable)

	func stop() -> void:
		_is_running = false

		for tween in _active_tweens:
			if is_instance_valid(tween) and tween.is_valid():
				tween.kill()
		_active_tweens.clear()

		if _target_control:
			var current_pos = _target_control.position
			var current_scale = _target_control.scale
			var current_modulate = _target_control.modulate
			var current_rotation = _target_control.rotation_degrees
			_target_control.position = current_pos
			_target_control.scale = current_scale
			_target_control.modulate = current_modulate
			_target_control.rotation_degrees = current_rotation

		loop_finished.emit()
		queue_free()

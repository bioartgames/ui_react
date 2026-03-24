## Stagger animation orchestration (extracted from UiAnimUtils).
class_name UiAnimStaggerRunner
extends RefCounted

const META_STAGGER_HELPER: StringName = &"_is_stagger_helper"
const META_STAGGER_TYPE: StringName = &"_stagger_type"
const METHOD_STOP: StringName = &"stop"

## Stops all active stagger animations for the given targets.
static func stop_stagger_animations(source_node: Node, targets: Array[Control]) -> void:
	if not source_node:
		return

	for child in source_node.get_children():
		if child.has_meta(META_STAGGER_HELPER):
			if child.has_method(METHOD_STOP):
				child.call(METHOD_STOP)
			else:
				child.queue_free()

	for target in targets:
		if target and is_instance_valid(target):
			var interrupt_tween = source_node.create_tween()
			if interrupt_tween:
				interrupt_tween.tween_property(target, "modulate", target.modulate, 0.0)
				interrupt_tween.tween_property(target, "scale", target.scale, 0.0)
				interrupt_tween.tween_property(target, "position", target.position, 0.0)
				interrupt_tween.kill()

			var current_modulate = target.modulate
			var current_scale = target.scale
			var current_position = target.position
			target.modulate = current_modulate
			target.scale = current_scale
			target.position = current_position

## Animates multiple controls with a stagger effect.
static func animate_stagger(source_node: Node, targets: Array[Control], delay_between: float = 0.1, animation_config: UiAnimTarget = null) -> Signal:
	if not source_node or targets.size() == 0:
		push_warning("UiAnimStaggerRunner: Invalid source_node or empty targets. Fix: Pass a valid node and a non-empty Array of controls.")
		return Signal()

	if not animation_config:
		push_warning("UiAnimStaggerRunner: animate_stagger called without animation_config. Fix: Pass a UiAnimTarget resource describing the animation.")
		return Signal()

	stop_stagger_animations(source_node, targets)

	var is_reveal = not animation_config.reverse

	for target in targets:
		if target and is_instance_valid(target):
			if is_reveal:
				target.visible = true
			else:
				target.visible = true
				target.modulate.a = 1.0
				target.scale = Vector2.ONE

	var helper = _StaggerHelper.new()
	source_node.add_child(helper)
	helper.execute_stagger(source_node, targets, delay_between, animation_config, is_reveal)
	return helper.all_finished

## Animates multiple controls with per-target configs.
static func animate_stagger_multi(source_node: Node, targets: Array[Control], delay_between: float = 0.1, animation_configs: Array[UiAnimTarget] = []) -> Signal:
	if not source_node or targets.size() == 0:
		push_warning("UiAnimStaggerRunner: Invalid source_node or empty targets for animate_stagger_multi. Fix: Pass a valid node and a non-empty Array of controls.")
		return Signal()

	if animation_configs.size() == 0:
		push_warning("UiAnimStaggerRunner: animate_stagger_multi requires at least one UiAnimTarget in animation_configs. Fix: Add at least one entry to the array.")
		return Signal()

	stop_stagger_animations(source_node, targets)

	for i in range(targets.size()):
		var target = targets[i]
		if not target or not is_instance_valid(target):
			continue

		var config_idx = min(i, animation_configs.size() - 1)
		var config = animation_configs[config_idx]
		if not config:
			continue

		var is_reveal = not config.reverse

		if is_reveal:
			target.visible = true
		else:
			target.visible = true
			target.modulate.a = 1.0
			target.scale = Vector2.ONE

	var helper = _StaggerHelper.new()
	source_node.add_child(helper)
	helper.execute_stagger_multi(source_node, targets, delay_between, animation_configs)
	return helper.all_finished

## Helper node for stagger animations.
class _StaggerHelper extends Node:
	var all_finished = Signal()
	var _is_running = false
	var _source_node: Node = null
	var _targets: Array[Control] = []

	func _init() -> void:
		set_meta(META_STAGGER_HELPER, true)
		set_meta(META_STAGGER_TYPE, &"stagger")

	func stop() -> void:
		_is_running = false
		for target in _targets:
			if target and is_instance_valid(target):
				var interrupt_tween = _source_node.create_tween()
				if interrupt_tween:
					interrupt_tween.kill()
				var current_modulate = target.modulate
				var current_scale = target.scale
				var current_position = target.position
				target.modulate = current_modulate
				target.scale = current_scale
				target.position = current_position
		queue_free()

	func execute_stagger(source_node: Node, targets: Array[Control], delay_between: float, animation_config: UiAnimTarget, is_reveal: bool) -> void:
		_source_node = source_node
		_targets = targets
		_is_running = true

		var start_idx = 0
		var end_idx = targets.size()
		var step = 1
		if not is_reveal:
			start_idx = targets.size() - 1
			end_idx = -1
			step = -1

		var i = start_idx
		while i != end_idx:
			if not _is_running:
				return

			var target = targets[i]
			if target == null or not is_instance_valid(target):
				i += step
				continue

			if i != start_idx:
				await UiAnimDelayHelpers.delay(source_node, delay_between)
				if not _is_running:
					return

			var animation_signal = animation_config.apply_to_control(source_node, target)
			if animation_signal:
				await animation_signal

			if not _is_running:
				return

			i += step

		if _is_running:
			all_finished.emit()
		queue_free()

	func execute_stagger_multi(source_node: Node, targets: Array[Control], delay_between: float, animation_configs: Array[UiAnimTarget]) -> void:
		_source_node = source_node
		_targets = targets
		_is_running = true

		var is_reveal = true
		if animation_configs.size() > 0 and animation_configs[0]:
			is_reveal = not animation_configs[0].reverse

		var start_idx = 0
		var end_idx = targets.size()
		var step = 1
		if not is_reveal:
			start_idx = targets.size() - 1
			end_idx = -1
			step = -1

		var i = start_idx
		while i != end_idx:
			if not _is_running:
				return

			var target = targets[i]
			if target == null or not is_instance_valid(target):
				i += step
				continue

			if i != start_idx:
				await UiAnimDelayHelpers.delay(source_node, delay_between)
				if not _is_running:
					return

			var config_idx = min(i if is_reveal else (targets.size() - 1 - i), animation_configs.size() - 1)
			var config = animation_configs[config_idx]
			if not config:
				i += step
				continue

			var animation_signal = config.apply_to_control(source_node, target)
			if animation_signal:
				await animation_signal

			if not _is_running:
				return

			i += step

		if _is_running:
			all_finished.emit()
		queue_free()

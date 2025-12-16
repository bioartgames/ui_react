## Animation state management utilities for snapshots and restoration.
##
## Provides functions for capturing, storing, and restoring control states
## to support complex animation sequences and resets.
class_name AnimationStateUtils

## Tracks unified original state snapshots per target control.
## This snapshot is locked when the first animation starts and only unlocked
## when all animations complete. Contains position, scale, modulate, rotation, pivot_offset, and visible.
## Key: Control node (object ID), Value: ControlStateSnapshot
static var _unified_original_snapshots: Dictionary = {}
## Tracks active animation count per target control.
## Key: Control node (object ID), Value: int
static var _active_animation_count: Dictionary = {}

## Snapshot of a control's state for restoration.
## Contains position, scale, modulate, rotation, pivot_offset, and visible properties.
class ControlStateSnapshot:
	var position: Vector2
	var scale: Vector2
	var modulate: Color
	var rotation_degrees: float
	var pivot_offset: Vector2
	var visible: bool

## Acquires a unified snapshot of the target control's original state.
## Used internally by animation functions to support universal reset functionality.
## [param source_node]: The node requesting the snapshot (for validation).
## [param target]: The control to snapshot.
## [return]: The created snapshot.
static func _acquire_unified_snapshot(source_node: Node, target: Control) -> ControlStateSnapshot:
	if not source_node or not target:
		push_warning("AnimationStateUtils._acquire_unified_snapshot(): Failed to create baseline snapshot for target '%s'" % target.name)
		return null

	var target_id = target.get_instance_id()

	# If we don't have a snapshot yet, create one
	if not _unified_original_snapshots.has(target_id):
		var snapshot = ControlStateSnapshot.new()
		snapshot.position = target.position
		snapshot.scale = target.scale
		snapshot.modulate = target.modulate
		snapshot.rotation_degrees = target.rotation_degrees
		snapshot.pivot_offset = target.pivot_offset
		snapshot.visible = target.visible
		_unified_original_snapshots[target_id] = snapshot

	# Increment animation count
	_active_animation_count[target_id] = _active_animation_count.get(target_id, 0) + 1

	return _unified_original_snapshots[target_id]

## Releases a unified snapshot when an animation completes.
## [param target]: The control whose snapshot to release.
## [param restore_immediately]: If true, restores the control to its original state.
## [return]: true if snapshot was released, false otherwise.
static func _release_unified_snapshot(target: Control, restore_immediately: bool = true) -> bool:
	if not target:
		push_warning("AnimationStateUtils._release_unified_snapshot(): Cannot restore state of null control.")
		return false

	var target_id = target.get_instance_id()

	# Decrement animation count
	var current_count = _active_animation_count.get(target_id, 0)
	if current_count > 0:
		current_count -= 1
		_active_animation_count[target_id] = current_count

		# Only restore when all animations complete
		if current_count == 0 and restore_immediately:
			var snapshot = _unified_original_snapshots.get(target_id)
			if snapshot:
				target.position = snapshot.position
				target.scale = snapshot.scale
				target.modulate = snapshot.modulate
				target.rotation_degrees = snapshot.rotation_degrees
				target.pivot_offset = snapshot.pivot_offset
				target.visible = snapshot.visible
				_unified_original_snapshots.erase(target_id)
				return true

	return false

## Gets the unified snapshot for a target control.
## [param target]: The control to get snapshot for.
## [return]: The snapshot, or null if none exists.
static func _get_unified_snapshot(target: Control) -> ControlStateSnapshot:
	if not target:
		return null
	return _unified_original_snapshots.get(target.get_instance_id())

## Clears the unified snapshot for a target control.
## [param target]: The control whose snapshot to clear.
static func _clear_unified_snapshot(target: Control) -> void:
	if not target:
		return
	var target_id = target.get_instance_id()
	_unified_original_snapshots.erase(target_id)
	_active_animation_count.erase(target_id)

## Creates a snapshot of a control's current state.
## [param target]: The control to snapshot.
## [return]: A snapshot of the control's current state.
static func snapshot_control_state(target: Control) -> ControlStateSnapshot:
	if not target:
		push_warning("AnimationStateUtils.snapshot_control_state(): Cannot snapshot state of null control.")
		return null

	var snapshot = ControlStateSnapshot.new()
	snapshot.position = target.position
	snapshot.scale = target.scale
	snapshot.modulate = target.modulate
	snapshot.rotation_degrees = target.rotation_degrees
	snapshot.pivot_offset = target.pivot_offset
	snapshot.visible = target.visible

	return snapshot

## Restores a control to a previously captured state.
## [param target]: The control to restore.
## [param snapshot]: The snapshot to restore from.
static func restore_control_state(target: Control, snapshot: ControlStateSnapshot) -> void:
	if not target:
		push_warning("AnimationStateUtils.restore_control_state(): Cannot restore state of null control.")
		return

	if not snapshot:
		push_warning("AnimationStateUtils.restore_control_state(): Cannot restore from null snapshot.")
		return

	target.position = snapshot.position
	target.scale = snapshot.scale
	target.modulate = snapshot.modulate
	target.rotation_degrees = snapshot.rotation_degrees
	target.pivot_offset = snapshot.pivot_offset
	target.visible = snapshot.visible

## Resets all controls to their original states and clears snapshots.
## [param source_node]: The node requesting the reset (for validation).
## [param target]: Specific control to reset, or null to reset all.
## [param duration]: Duration for the reset animation (0.0 = instant).
## [param easing]: Easing type to use.
## [param auto_visible]: If true, ensures controls are visible after reset.
## [return]: Signal that emits when reset completes.
static func animate_reset_all(source_node: Node, target: Control, duration: float = 0.0, easing: int = Tween.EASE_OUT, auto_visible: bool = true) -> Signal:
	if not source_node or not target:
		push_warning("AnimationStateUtils.animate_reset_all(): Invalid source_node or target")
		return Signal()

	var snapshot = _get_unified_snapshot(target)
	if not snapshot:
		push_warning("AnimationStateUtils.animate_reset_all(): Unified snapshot exists but is null for target '%s'" % target.name)
		return Signal()

	# Create animation to reset to original state
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = snapshot.visible

		if duration <= 0.0:
			# Instant reset
			target.position = snapshot.position
			target.scale = snapshot.scale
			target.modulate = snapshot.modulate
			target.rotation_degrees = snapshot.rotation_degrees
			target.pivot_offset = snapshot.pivot_offset
			return Signal()  # Return empty signal for instant operations
		else:
			# Animated reset
			var t = source_node.create_tween()
			if not t:
				push_warning("AnimationStateUtils.animate_reset_all(): Failed to create one or more tweens for target '%s'" % target.name)
				return Signal()

			t.tween_property(target, 'position', snapshot.position, duration).set_ease(easing)
			t.tween_property(target, 'scale', snapshot.scale, duration).set_ease(easing)
			t.tween_property(target, 'modulate', snapshot.modulate, duration).set_ease(easing)
			t.tween_property(target, 'rotation_degrees', snapshot.rotation_degrees, duration).set_ease(easing)
			t.tween_property(target, 'pivot_offset', snapshot.pivot_offset, duration).set_ease(easing)

			return t.finished

	var result_signal = AnimationCoreUtils.wrap_with_loop(source_node, target, animation_callable, 0)

	# Clear snapshot after reset completes
	result_signal.connect(func():
		_clear_unified_snapshot(target)
	, CONNECT_ONE_SHOT)

	return result_signal

## Clears the unified snapshot for a specific target.
## [param target]: The control whose snapshot to clear.
static func clear_unified_snapshot_for_target(target: Control) -> void:
	_clear_unified_snapshot(target)

## Unified snapshot storage for UI animations (extracted from UiAnimUtils).
## Owns baseline Control snapshots and reference counts per animated Control.
class_name UiAnimSnapshotStore
extends RefCounted

## Tracks unified original state snapshots per target control.
static var _unified_original_snapshots: Dictionary = {}

## Tracks active animation count per target control.
static var _active_animation_count: Dictionary = {}

## Snapshot of a control's state for restoration.
class ControlStateSnapshot:
	var position: Vector2
	var scale: Vector2
	var modulate: Color
	var rotation_degrees: float
	var pivot_offset: Vector2
	var visible: bool

## Acquires the unified baseline snapshot for a target control.
static func acquire_unified_snapshot(source_node: Node, target: Control) -> ControlStateSnapshot:
	if not target:
		return null

	if not _unified_original_snapshots.has(target):
		var interrupt_tween = source_node.create_tween()
		if interrupt_tween:
			interrupt_tween.tween_property(target, "position", target.position, 0.0)
			interrupt_tween.tween_property(target, "scale", target.scale, 0.0)
			interrupt_tween.tween_property(target, "modulate", target.modulate, 0.0)
			interrupt_tween.tween_property(target, "rotation_degrees", target.rotation_degrees, 0.0)
			interrupt_tween.kill()

		var baseline_snapshot = snapshot_control_state(target)
		if not baseline_snapshot:
			push_warning("UiAnimSnapshotStore.acquire_unified_snapshot(): Failed to create baseline snapshot for target '%s'" % target.name)
			return null
		_unified_original_snapshots[target] = baseline_snapshot
		_active_animation_count[target] = 0

	_active_animation_count[target] = _active_animation_count[target] + 1

	return _unified_original_snapshots[target]

## Releases the unified original snapshot for a target control.
static func release_unified_snapshot(target: Control, restore_immediately: bool = true) -> bool:
	if not target:
		return false

	if not _active_animation_count.has(target):
		return false

	_active_animation_count[target] = _active_animation_count[target] - 1

	if _active_animation_count[target] <= 0:
		if _unified_original_snapshots.has(target):
			var snapshot = _unified_original_snapshots[target]
			if snapshot and restore_immediately:
				restore_control_state(target, snapshot)
			_unified_original_snapshots.erase(target)
			_active_animation_count.erase(target)
			return true

	return false

## Gets the unified original snapshot without acquiring.
static func get_unified_snapshot(target: Control) -> ControlStateSnapshot:
	if not target:
		return null
	if _unified_original_snapshots.has(target):
		return _unified_original_snapshots[target]
	return null

## Manually clears the unified snapshot system for a target.
static func clear_unified_snapshot(target: Control) -> void:
	if not target:
		return
	_unified_original_snapshots.erase(target)
	_active_animation_count.erase(target)

static func has_unified_snapshot(target: Control) -> bool:
	return target != null and _unified_original_snapshots.has(target)

static func snapshot_control_state(target: Control) -> ControlStateSnapshot:
	if not target:
		push_warning("UiAnimSnapshotStore.snapshot_control_state(): Cannot snapshot state of null control.")
		return null

	var snapshot = ControlStateSnapshot.new()
	snapshot.position = target.position
	snapshot.scale = target.scale
	snapshot.modulate = target.modulate
	snapshot.rotation_degrees = target.rotation_degrees
	snapshot.pivot_offset = target.pivot_offset
	snapshot.visible = target.visible
	return snapshot

static func restore_control_state(target: Control, snapshot: ControlStateSnapshot) -> void:
	if not target:
		push_warning("UiAnimSnapshotStore.restore_control_state(): Cannot restore state of null control.")
		return
	if not snapshot:
		push_warning("UiAnimSnapshotStore.restore_control_state(): Cannot restore from null snapshot.")
		return

	target.position = snapshot.position
	target.scale = snapshot.scale
	target.modulate = snapshot.modulate
	target.rotation_degrees = snapshot.rotation_degrees
	target.pivot_offset = snapshot.pivot_offset
	target.visible = snapshot.visible

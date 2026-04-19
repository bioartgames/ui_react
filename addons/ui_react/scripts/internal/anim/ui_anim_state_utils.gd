## Control reset, unified snapshot lifecycle, and focus helpers (extracted from [UiAnimUtils]).
class_name UiAnimStateUtils
extends RefCounted


static func reset_control_to_normal(target: Control) -> void:
	if not target:
		return
	target.scale = Vector2.ONE
	target.modulate.a = 1.0
	target.rotation_degrees = 0.0


static func disable_focus_on_children(parent: Control, _exclude_self: bool = true) -> void:
	if not parent:
		return
	for child in parent.get_children():
		if child is Control:
			var child_control = child as Control
			child_control.focus_mode = Control.FOCUS_NONE
			disable_focus_on_children(child_control, false)


## Manually clears the unified snapshot system for a target control.
static func clear_unified_snapshot_for_target(target: Control) -> void:
	if not target:
		return
	UiAnimSnapshotStore.clear_unified_snapshot(target)


static func animate_reset_all(source_node: Node, target: Control, duration: float = UiAnimConstants.DEFAULT_ANIMATE_RESET_DURATION, easing: int = Tween.EASE_OUT, clear_unified_after: bool = true) -> Signal:
	if not source_node or not target:
		push_warning("UiAnimStateUtils: Invalid source_node or target for animate_reset_all")
		return Signal()

	var snapshot: UiAnimSnapshotStore.ControlStateSnapshot
	if UiAnimSnapshotStore.has_unified_snapshot(target):
		snapshot = UiAnimSnapshotStore.get_unified_snapshot(target)
	else:
		return Signal()

	if not snapshot:
		push_warning("UiAnimStateUtils.animate_reset_all(): Unified snapshot exists but is null for target '%s'" % target.name)
		return Signal()

	if duration <= 0.0:
		UiAnimSnapshotStore.restore_control_state(target, snapshot)
		if clear_unified_after:
			UiAnimSnapshotStore.clear_unified_snapshot(target)
		return Signal()

	var tween_position = source_node.create_tween()
	var tween_scale = source_node.create_tween()
	var tween_modulate = source_node.create_tween()
	var tween_rotation = source_node.create_tween()

	if not tween_position or not tween_scale or not tween_modulate or not tween_rotation:
		push_warning("UiAnimStateUtils.animate_reset_all(): Failed to create one or more tweens for target '%s'" % target.name)
		if tween_position:
			tween_position.kill()
		if tween_scale:
			tween_scale.kill()
		if tween_modulate:
			tween_modulate.kill()
		if tween_rotation:
			tween_rotation.kill()
		return Signal()

	tween_position.tween_property(target, "position", snapshot.position, duration).set_trans(Tween.TRANS_SINE).set_ease(easing)
	tween_scale.tween_property(target, "scale", snapshot.scale, duration).set_trans(Tween.TRANS_SINE).set_ease(easing)
	tween_modulate.tween_property(target, "modulate", snapshot.modulate, duration).set_trans(Tween.TRANS_SINE).set_ease(easing)
	tween_rotation.tween_property(target, "rotation_degrees", snapshot.rotation_degrees, duration).set_trans(Tween.TRANS_SINE).set_ease(easing)

	var tween = tween_position
	target.pivot_offset = snapshot.pivot_offset
	target.visible = snapshot.visible

	if clear_unified_after:
		tween.finished.connect(func():
			UiAnimSnapshotStore.clear_unified_snapshot(target)
		, CONNECT_ONE_SHOT)

	return tween.finished

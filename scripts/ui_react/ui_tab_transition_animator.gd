## Tab switch transitions driven by [UiAnimTarget] SELECTION_CHANGED entries.
class_name UiTabTransitionAnimator
extends RefCounted

static func animate_tab_switch(tab_container: TabContainer, old_index: int, new_index: int, animation_targets: Array[UiAnimTarget]) -> void:
	var old_child = tab_container.get_tab_control(old_index)
	var new_child = tab_container.get_tab_control(new_index)

	if old_child == null or new_child == null:
		return

	for anim_target in animation_targets:
		if anim_target == null:
			continue
		if anim_target.trigger != UiAnimTarget.Trigger.SELECTION_CHANGED:
			continue

		var targets_old = false
		var targets_new = false
		if anim_target.target.is_empty():
			targets_old = true
			targets_new = true
		else:
			var configured_target = tab_container.get_node_or_null(anim_target.target)
			targets_old = configured_target == old_child
			targets_new = configured_target == new_child

		if targets_old:
			var fade_out = anim_target.duplicate()
			fade_out.reverse = true
			fade_out.target = NodePath(".")
			fade_out.apply(old_child)

		if targets_new:
			var fade_in = anim_target.duplicate()
			fade_in.reverse = false
			fade_in.target = NodePath(".")
			fade_in.apply(new_child)

		if anim_target.target.is_empty():
			break

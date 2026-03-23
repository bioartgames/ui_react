class_name ReactiveAnimationTargetHelper
extends RefCounted

static func validate_animation_targets(owner: Control, component_name: String, animation_targets: Array[AnimationTarget], allow_empty_for: Array[int] = []) -> Array[AnimationTarget]:
	var valid_targets: Array[AnimationTarget] = []

	for anim_target in animation_targets:
		if anim_target == null:
			continue

		if anim_target.target.is_empty():
			if allow_empty_for.has(anim_target.trigger):
				valid_targets.append(anim_target)
				continue
			push_warning("%s '%s': AnimationTarget has no target. Set target (NodePath) in the Inspector. Tip: Drag a node to target." % [component_name, owner.name])
			continue

		var target_node = owner.get_node_or_null(anim_target.target)
		if target_node == null:
			push_warning("%s '%s': AnimationTarget target '%s' not found. Check the NodePath." % [component_name, owner.name, anim_target.target])
			continue

		if not (target_node is Control):
			push_warning("%s '%s': AnimationTarget target '%s' is not a Control node." % [component_name, owner.name, anim_target.target])
			continue

		valid_targets.append(anim_target)

	return valid_targets

static func collect_triggers(animation_targets: Array[AnimationTarget]) -> Dictionary:
	var trigger_map: Dictionary = {}
	for anim_target in animation_targets:
		if anim_target == null:
			continue
		trigger_map[anim_target.trigger] = true
	return trigger_map

## Validates targets and returns both the filtered array and trigger map (reduces boilerplate).
static func validate_and_map_triggers(owner: Control, component_name: String, animation_targets: Array[AnimationTarget], allow_empty_for: Array[int] = []) -> Dictionary:
	var valid = validate_animation_targets(owner, component_name, animation_targets, allow_empty_for)
	return {"animation_targets": valid, "trigger_map": collect_triggers(valid)}

static func trigger_animations(owner: Node, animation_targets: Array[AnimationTarget], trigger_type: AnimationTarget.Trigger, respects_disabled: bool = false, is_disabled: bool = false) -> void:
	if animation_targets.is_empty():
		return

	for anim_target in animation_targets:
		if anim_target == null:
			continue
		if anim_target.trigger != trigger_type:
			continue
		if respects_disabled and anim_target.respect_disabled and is_disabled:
			continue
		anim_target.apply(owner)

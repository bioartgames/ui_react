class_name UiReactAnimTargetHelper
extends RefCounted

## Result of [method validate_and_map_triggers] (typed container; avoids stringly dictionary keys).
class AnimTargetValidationResult:
	extends RefCounted
	var animation_targets: Array[UiAnimTarget] = []
	var trigger_map: Dictionary = {}

static func validate_animation_targets(owner: Control, component_name: String, animation_targets: Array[UiAnimTarget], allow_empty_for: Array[int] = []) -> Array[UiAnimTarget]:
	var valid_targets: Array[UiAnimTarget] = []

	for anim_target in animation_targets:
		if anim_target == null:
			continue

		if anim_target.target.is_empty():
			if allow_empty_for.has(anim_target.trigger):
				valid_targets.append(anim_target)
				continue
			push_warning("%s '%s': UiAnimTarget has no target. Set target (NodePath) in the Inspector. Tip: Drag a node to target." % [component_name, owner.name])
			continue

		var target_node = owner.get_node_or_null(anim_target.target)
		if target_node == null:
			push_warning("%s '%s': UiAnimTarget target '%s' not found. Check the NodePath." % [component_name, owner.name, anim_target.target])
			continue

		if not (target_node is Control):
			push_warning("%s '%s': UiAnimTarget target '%s' is not a Control node." % [component_name, owner.name, anim_target.target])
			continue

		valid_targets.append(anim_target)

	return valid_targets

static func collect_triggers(animation_targets: Array[UiAnimTarget]) -> Dictionary:
	var trigger_map: Dictionary = {}
	for anim_target in animation_targets:
		if anim_target == null:
			continue
		trigger_map[anim_target.trigger] = true
	return trigger_map

## Validates targets and returns both the filtered array and trigger map (reduces boilerplate).
static func validate_and_map_triggers(owner: Control, component_name: String, animation_targets: Array[UiAnimTarget], allow_empty_for: Array[int] = []) -> AnimTargetValidationResult:
	var result := AnimTargetValidationResult.new()
	result.animation_targets = validate_animation_targets(owner, component_name, animation_targets, allow_empty_for)
	result.trigger_map = collect_triggers(result.animation_targets)
	return result

static func trigger_animations(owner: Node, animation_targets: Array[UiAnimTarget], trigger_type: UiAnimTarget.Trigger, respects_disabled: bool = false, is_disabled: bool = false) -> void:
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

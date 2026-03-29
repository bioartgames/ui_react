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
			UiReactStateBindingHelper.warn_setup(
				component_name,
				owner,
				"UiAnimTarget has no Target NodePath.",
				"Assign Target in the Inspector (drag a Control), or remove the empty animation target entry."
			)
			continue

		var target_node = owner.get_node_or_null(anim_target.target)
		if target_node == null:
			UiReactStateBindingHelper.warn_setup(
				component_name,
				owner,
				"UiAnimTarget NodePath '%s' could not be resolved from this node." % anim_target.target,
				"Fix the path or pick a node that exists under this control."
			)
			continue

		if not (target_node is Control):
			UiReactStateBindingHelper.warn_setup(
				component_name,
				owner,
				"UiAnimTarget NodePath '%s' does not reference a Control." % anim_target.target,
				"Point Target at a Control node."
			)
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


## Validates [param owner]'s animation targets at [param animation_targets_property] (default [code]animation_targets[/code]), assigns the filtered [UiAnimTarget] array back, and returns the trigger map.
## Use [param allow_empty_for] like [method validate_animation_targets] (e.g. [code]UiAnimTarget.Trigger.SELECTION_CHANGED[/code] for tab selection entries with no Target path).
## All current UiReact controls use the default property name; override only if a control uses a different export name.
static func apply_validated_targets(
	owner: Control,
	component_name: String,
	allow_empty_for: Array[int] = [],
	animation_targets_property: StringName = &"animation_targets",
) -> Dictionary:
	var raw: Variant = owner.get(animation_targets_property)
	var targets: Array[UiAnimTarget] = raw as Array[UiAnimTarget]
	var result := validate_and_map_triggers(owner, component_name, targets, allow_empty_for)
	owner.set(animation_targets_property, result.animation_targets)
	return result.trigger_map

## Connects [param callable] to [param sig] only if not already connected (shared trigger wiring).
static func connect_if_absent(sig: Signal, callable: Callable) -> void:
	if not sig.is_connected(callable):
		sig.connect(callable)

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

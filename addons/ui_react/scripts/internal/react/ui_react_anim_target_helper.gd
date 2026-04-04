class_name UiReactAnimTargetHelper
extends RefCounted

## How [method _run_animation_targets] filters [UiAnimTarget] rows.
enum AnimDispatchMode {
	## Match [member UiAnimTarget.trigger] and optional [member UiAnimTarget.selection_slot] (signal-driven).
	TRIGGER,
	## Ignore triggers; run listed targets with disabled gating only (legacy helpers; list row play uses [method collect_animation_targets_for_row_slot] + [method UiAnimTarget.apply_with_preamble]).
	MANUAL,
}

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


## Collects [UiAnimTarget] rows whose [member UiAnimTarget.selection_slot] equals [param slot_index] ([code]>= 0[/code] only), preserving [param animation_targets] order.
## Used by [method UiReactItemList.play_selected_row_animation] / [method UiReactItemList.play_preamble_reset_only].
static func collect_animation_targets_for_row_slot(animation_targets: Array[UiAnimTarget], slot_index: int) -> Array[UiAnimTarget]:
	var out: Array[UiAnimTarget] = []
	for anim_target in animation_targets:
		if anim_target == null:
			continue
		var s: int = anim_target.selection_slot
		if s >= 0 and s == slot_index:
			out.append(anim_target)
	return out


## Connects [param callable] to [param sig] only if not already connected (shared trigger wiring).
static func connect_if_absent(sig: Signal, callable: Callable) -> void:
	if not sig.is_connected(callable):
		sig.connect(callable)


## Returns [code]{ "use_filter": bool, "index": int }[/code] for [member UiAnimTarget.selection_slot] filtering.
static func _resolve_selection_index(owner: Node, animation_targets: Array[UiAnimTarget]) -> Dictionary:
	var out := {"use_filter": false, "index": -1}
	var need_slot := false
	for anim_target in animation_targets:
		if anim_target != null and anim_target.selection_slot >= 0:
			need_slot = true
			break
	if not need_slot:
		return out
	if not owner.has_method(&"get_animation_selection_index"):
		if not owner.has_meta(&"_ui_react_anim_sel_warn_no_method"):
			owner.set_meta(&"_ui_react_anim_sel_warn_no_method", true)
			push_warning(
				"UiReactAnimTargetHelper: animation_targets use selection_slot >= 0 but '%s' has no get_animation_selection_index(); only targets with selection_slot -1 run."
				% owner.name
			)
		out.use_filter = true
		out.index = -1
		return out
	out.use_filter = true
	out.index = int(owner.call(&"get_animation_selection_index"))
	return out


static func _run_animation_targets(
	owner: Node,
	candidates: Array[UiAnimTarget],
	mode: AnimDispatchMode,
	trigger_type: UiAnimTarget.Trigger,
	selection_index: int,
	use_selection_filter: bool,
	respects_disabled: bool,
	is_disabled: bool,
) -> void:
	for anim_target in candidates:
		if anim_target == null:
			continue
		if mode == AnimDispatchMode.TRIGGER:
			if anim_target.trigger != trigger_type:
				continue
			if use_selection_filter:
				var slot: int = anim_target.selection_slot
				if slot >= 0 and slot != selection_index:
					continue
		if respects_disabled and anim_target.respect_disabled and is_disabled:
			continue
		anim_target.apply(owner)


## Runs [param candidates] without matching [member UiAnimTarget.trigger] (manual row play, etc.).
static func run_manual_targets(
	owner: Node,
	candidates: Array[UiAnimTarget],
	respects_disabled: bool = false,
	is_disabled: bool = false,
) -> void:
	if candidates.is_empty():
		return
	_run_animation_targets(
		owner,
		candidates,
		AnimDispatchMode.MANUAL,
		UiAnimTarget.Trigger.PRESSED,
		-1,
		false,
		respects_disabled,
		is_disabled,
	)


static func trigger_animations(owner: Node, animation_targets: Array[UiAnimTarget], trigger_type: UiAnimTarget.Trigger, respects_disabled: bool = false, is_disabled: bool = false) -> void:
	if animation_targets.is_empty():
		return
	var sel: Dictionary = _resolve_selection_index(owner, animation_targets)
	var idx: int = int(sel.get("index", -1))
	var use_filter: bool = bool(sel.get("use_filter", false))
	_run_animation_targets(
		owner,
		animation_targets,
		AnimDispatchMode.TRIGGER,
		trigger_type,
		idx,
		use_filter,
		respects_disabled,
		is_disabled,
	)

## Validates [UiAnimTarget] rows on [UiReact*] controls (editor diagnostics).
class_name UiReactAnimValidator
extends RefCounted

const _TREE_NODE_SCRIPT: Script = preload("res://addons/ui_react/scripts/api/models/ui_react_tree_node.gd")


static func validate_anim_targets(
	component: String, owner: Control, node_path: NodePath
) -> Array[UiReactDiagnosticModel.DiagnosticIssue]:
	var out: Array[UiReactDiagnosticModel.DiagnosticIssue] = []
	if not &"animation_targets" in owner:
		return out
	var arr: Variant = owner.get(&"animation_targets")
	if not (arr is Array):
		return out
	var targets: Array = arr as Array
	for i in range(targets.size()):
		var anim_target: Variant = targets[i]
		if anim_target == null:
			out.append(
				UiReactDiagnosticModel.DiagnosticIssue.make_structured(
					UiReactDiagnosticModel.Severity.WARNING,
					component,
					str(owner.name),
					"Animation targets row %d is empty (null)." % i,
					"In the Inspector, remove that row or assign a UiAnimTarget resource.",
					node_path,
					&"animation_targets",
					&"",
					UiReactDiagnosticModel.IssueKind.GENERIC,
					"",
				)
			)
			continue
		if not (anim_target is UiAnimTarget):
			continue
		var at := anim_target as UiAnimTarget
		var tab_selection_empty_ok: bool = (
			component == "UiReactTabContainer"
			and at.trigger == UiAnimTarget.Trigger.SELECTION_CHANGED
			and at.target.is_empty()
		)
		if at.target.is_empty() and not tab_selection_empty_ok:
			out.append(
				UiReactDiagnosticModel.DiagnosticIssue.make_structured(
					UiReactDiagnosticModel.Severity.WARNING,
					component,
					str(owner.name),
					"Motion row %d has no target control picked." % i,
					"In the Inspector, drag a Control into Target, or remove this row if you do not need it.",
					node_path,
					&"animation_targets",
					&"",
					UiReactDiagnosticModel.IssueKind.GENERIC,
					"",
				)
			)
			continue
		if not at.target.is_empty():
			var tn := owner.get_node_or_null(at.target)
			if tn == null:
				out.append(
					UiReactDiagnosticModel.DiagnosticIssue.make_structured(
						UiReactDiagnosticModel.Severity.ERROR,
						component,
						str(owner.name),
						"Motion row %d points at a node that is not found: %s." % [i, at.target],
						"Fix the target path in the Inspector (path is relative to this control), or pick the node again by dragging.",
						node_path,
						&"animation_targets",
						&"",
						UiReactDiagnosticModel.IssueKind.GENERIC,
						"",
					)
				)
				continue
			if not (tn is Control):
				out.append(
					UiReactDiagnosticModel.DiagnosticIssue.make_structured(
						UiReactDiagnosticModel.Severity.ERROR,
						component,
						str(owner.name),
						"Motion row %d target is not a Control node." % i,
						"Pick a Control (or a child Control) in the Target field.",
						node_path,
						&"animation_targets",
						&"",
						UiReactDiagnosticModel.IssueKind.GENERIC,
						"",
					)
				)
				continue

		# Row-play presets (selection_slot >= 0) are driven by play_* APIs, not host signal dispatch; default trigger is ignored.
		if (
			not _skip_trigger_allowlist_for_row_play_preset(component, at)
			and not UiReactValidatorCommon.is_anim_trigger_allowed(component, at.trigger)
		):
			out.append(
				UiReactDiagnosticModel.DiagnosticIssue.make_structured(
					UiReactDiagnosticModel.Severity.WARNING,
					component,
					str(owner.name),
					(
						"Motion row %d uses trigger %s, but this control does not fire that signal."
						% [i, UiReactValidatorCommon.format_anim_trigger_name(at.trigger)]
					),
					(
						"For %s, use one of the supported triggers: %s."
						% [component, UiReactValidatorCommon.format_allowed_anim_triggers_hint(component)]
					),
					node_path,
					&"animation_targets",
					&"",
					UiReactDiagnosticModel.IssueKind.GENERIC,
					"",
				)
			)

		if component == "UiReactItemList" and owner is ItemList:
			var il := owner as ItemList
			if il.item_count > 0 and at.selection_slot >= 0 and at.selection_slot >= il.item_count:
				out.append(
					UiReactDiagnosticModel.DiagnosticIssue.make_structured(
						UiReactDiagnosticModel.Severity.ERROR,
						component,
						str(owner.name),
						"Motion row %d is tied to list row %d, but the list only has %d rows." % [i, at.selection_slot, il.item_count],
						"Set Selection slot to a valid index (0 .. last row), or -1 if this motion is not row-specific.",
						node_path,
						&"animation_targets",
						&"",
						UiReactDiagnosticModel.IssueKind.GENERIC,
						"",
					)
				)
		if component == "UiReactTree":
			var vc: int = _visible_row_count_from_tree_items_state(owner)
			if vc > 0 and at.selection_slot >= 0 and at.selection_slot >= vc:
				out.append(
					UiReactDiagnosticModel.DiagnosticIssue.make_structured(
						UiReactDiagnosticModel.Severity.ERROR,
						component,
						str(owner.name),
						"Motion row %d is tied to tree row %d, but only %d visible rows exist." % [i, at.selection_slot, vc],
						"Set Selection slot to a valid visible row index, or -1 if this motion is not row-specific.",
						node_path,
						&"animation_targets",
						&"",
						UiReactDiagnosticModel.IssueKind.GENERIC,
						"",
					)
				)
	return out


## Row-scoped [member UiAnimTarget.selection_slot] [code]>= 0[/code]: on [UiReactItemList], [method UiReactItemList.play_selected_row_animation] / [method UiReactItemList.play_preamble_reset_only] ignore [member UiAnimTarget.trigger] (default [code]PRESSED[/code] is a common false positive). On [UiReactTree], the same default on slot-gated rows is often unused; allowlist warnings are skipped for both.
static func _skip_trigger_allowlist_for_row_play_preset(component: String, anim_target: UiAnimTarget) -> bool:
	if anim_target.selection_slot < 0:
		return false
	return component == "UiReactItemList" or component == "UiReactTree"


## Matches [method UiReactTree.get_visible_row_count] when the tree is built from [member UiReactTree.tree_items_state] (one visible row per [UiReactTreeNode]). Editor-safe (no calls on placeholder [Tree] instances).
static func _visible_row_count_from_tree_items_state(owner: Control) -> int:
	if not &"tree_items_state" in owner:
		return 0
	var tis: Variant = owner.get(&"tree_items_state")
	if not (tis is UiArrayState):
		return 0
	var raw: Variant = (tis as UiArrayState).get_value()
	if raw == null or not (raw is Array):
		return 0
	var total: int = 0
	for entry in raw as Array:
		if is_instance_of(entry, _TREE_NODE_SCRIPT):
			total += _count_tree_node_recursive(entry as Resource)
	return total


static func _count_tree_node_recursive(node: Resource) -> int:
	if not is_instance_of(node, _TREE_NODE_SCRIPT):
		return 0
	var n: int = 1
	var ch: Variant = node.get(&"children")
	if typeof(ch) != TYPE_ARRAY:
		return n
	for child in ch as Array:
		if is_instance_of(child, _TREE_NODE_SCRIPT):
			n += _count_tree_node_recursive(child as Resource)
	return n

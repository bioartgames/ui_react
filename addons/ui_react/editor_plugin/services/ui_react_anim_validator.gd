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
					"animation_targets[%d] is null." % i,
					"Remove the empty array element or assign a UiAnimTarget.",
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
		if at.target.is_empty():
			out.append(
				UiReactDiagnosticModel.DiagnosticIssue.make_structured(
					UiReactDiagnosticModel.Severity.WARNING,
					component,
					str(owner.name),
					"UiAnimTarget #%d has no Target NodePath." % i,
					"Assign Target (drag a Control) or remove this entry.",
					node_path,
					&"animation_targets",
					&"",
					UiReactDiagnosticModel.IssueKind.GENERIC,
					"",
				)
			)
			continue
		var tn := owner.get_node_or_null(at.target)
		if tn == null:
			out.append(
				UiReactDiagnosticModel.DiagnosticIssue.make_structured(
					UiReactDiagnosticModel.Severity.ERROR,
					component,
					str(owner.name),
					"UiAnimTarget #%d Target '%s' could not be resolved." % [i, at.target],
					"Fix the NodePath relative to this control.",
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
					"UiAnimTarget #%d Target is not a Control." % i,
					"Point Target at a Control node.",
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
						"UiAnimTarget #%d selection_slot (%d) >= item_count (%d)." % [i, at.selection_slot, il.item_count],
						"Use selection_slot in 0..item_count-1, or -1 for non-row targets.",
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
						"UiAnimTarget #%d selection_slot (%d) >= visible row count (%d)." % [i, at.selection_slot, vc],
						"Use selection_slot in 0..visible_row_count-1, or -1 for non-row targets.",
						node_path,
						&"animation_targets",
						&"",
						UiReactDiagnosticModel.IssueKind.GENERIC,
						"",
					)
				)
	return out


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

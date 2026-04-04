## Validates [UiAnimTarget] rows on [UiReact*] controls (editor diagnostics).
class_name UiReactAnimValidator
extends RefCounted


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
	return out

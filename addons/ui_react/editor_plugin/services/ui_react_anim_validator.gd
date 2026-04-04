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
		if &"row_animation_targets" in owner:
			var rows_v: Variant = owner.get(&"row_animation_targets")
			if rows_v is Array:
				var ra: Array = rows_v as Array
				if ra.size() > 0 and ra.size() != il.item_count:
					out.append(
						UiReactDiagnosticModel.DiagnosticIssue.make_structured(
							UiReactDiagnosticModel.Severity.ERROR,
							component,
							str(owner.name),
							"row_animation_targets size (%d) != item_count (%d)." % [ra.size(), il.item_count],
							"Match one UiAnimTarget per list row or clear row_animation_targets.",
							node_path,
							&"row_animation_targets",
							&"",
							UiReactDiagnosticModel.IssueKind.GENERIC,
							"",
						)
					)
		if &"row_play_preamble_reset" in owner and &"row_play_soft_reset_duration" in owner:
			var pr: int = int(owner.get(&"row_play_preamble_reset"))
			if pr == UiReactItemList.RowPlayPreambleReset.SOFT:
				var dur: float = float(owner.get(&"row_play_soft_reset_duration"))
				if dur <= 0.0:
					out.append(
						UiReactDiagnosticModel.DiagnosticIssue.make_structured(
							UiReactDiagnosticModel.Severity.ERROR,
							component,
							str(owner.name),
							"row_play_soft_reset_duration must be > 0 when row_play_preamble_reset is SOFT.",
							"Set a positive duration or use HARD/NONE.",
							node_path,
							&"row_play_soft_reset_duration",
							&"",
							UiReactDiagnosticModel.IssueKind.GENERIC,
							"",
						)
					)
	return out

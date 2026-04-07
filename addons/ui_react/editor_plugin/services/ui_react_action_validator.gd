## Validates [UiReactActionTarget] rows (editor diagnostics).
class_name UiReactActionValidator
extends RefCounted


static func validate_action_targets(
	component: String, owner: Control, node_path: NodePath
) -> Array[UiReactDiagnosticModel.DiagnosticIssue]:
	var out: Array[UiReactDiagnosticModel.DiagnosticIssue] = []
	if not &"action_targets" in owner:
		return out
	var arr: Variant = owner.get(&"action_targets")
	if not (arr is Array):
		return out
	var rows: Array = arr as Array
	# Deprecated UiReactTransactionalActions only — not UiReactButton transactional exports.
	var transactional: bool = owner is UiReactTransactionalActions

	for i in range(rows.size()):
		var row_var: Variant = rows[i]
		if row_var == null:
			out.append(
				UiReactDiagnosticModel.DiagnosticIssue.make_structured(
					UiReactDiagnosticModel.Severity.WARNING,
					component,
					str(owner.name),
					"action_targets[%d] is null." % i,
					"Remove the empty entry or assign a UiReactActionTarget.",
					node_path,
					&"action_targets",
					&"",
					UiReactDiagnosticModel.IssueKind.GENERIC,
					"",
				)
			)
			continue
		if not (row_var is UiReactActionTarget):
			continue
		var row := row_var as UiReactActionTarget
		if not row.enabled:
			continue

		if transactional and row.state_watch == null:
			out.append(
				UiReactDiagnosticModel.DiagnosticIssue.make_structured(
					UiReactDiagnosticModel.Severity.ERROR,
					component,
					str(owner.name),
					"action_targets[%d]: control-triggered row is invalid on UiReactTransactionalActions." % i,
					"Use state_watch-driven rows only.",
					node_path,
					&"action_targets",
					&"",
					UiReactDiagnosticModel.IssueKind.GENERIC,
					"",
				)
			)
			continue

		if row.state_watch != null and row.trigger != UiAnimTarget.Trigger.PRESSED:
			out.append(
				UiReactDiagnosticModel.DiagnosticIssue.make_structured(
					UiReactDiagnosticModel.Severity.WARNING,
					component,
					str(owner.name),
					"action_targets[%d]: state_watch set but trigger is not PRESSED (ignored at runtime)." % i,
					"Set trigger to PRESSED when using state_watch, or clear state_watch for control-driven rows.",
					node_path,
					&"action_targets",
					&"",
					UiReactDiagnosticModel.IssueKind.GENERIC,
					"",
				)
			)

		if not transactional and row.state_watch == null:
			if not UiReactValidatorCommon.is_anim_trigger_allowed(component, row.trigger):
				out.append(
					UiReactDiagnosticModel.DiagnosticIssue.make_structured(
						UiReactDiagnosticModel.Severity.WARNING,
						component,
						str(owner.name),
						(
							"action_targets[%d] uses Trigger %s on %s, which this control never dispatches."
							% [i, UiReactValidatorCommon.format_anim_trigger_name(row.trigger), component]
						),
						"Supported triggers for %s: %s."
						% [component, UiReactValidatorCommon.format_allowed_anim_triggers_hint(component)],
						node_path,
						&"action_targets",
						&"",
						UiReactDiagnosticModel.IssueKind.GENERIC,
						"",
					)
				)

		if row.action == UiReactActionTarget.UiReactActionKind.SUBTRACT_PRODUCT_FROM_FLOAT:
			if row.state_watch != null:
				out.append(
					UiReactDiagnosticModel.DiagnosticIssue.make_structured(
						UiReactDiagnosticModel.Severity.ERROR,
						component,
						str(owner.name),
						"action_targets[%d]: SUBTRACT_PRODUCT_FROM_FLOAT is control-triggered only (clear state_watch)." % i,
						"Remove state_watch or use a different action kind.",
						node_path,
						&"action_targets",
						&"",
						UiReactDiagnosticModel.IssueKind.GENERIC,
						"",
					)
				)
			if row.float_accumulator == null:
				out.append(
					UiReactDiagnosticModel.DiagnosticIssue.make_structured(
						UiReactDiagnosticModel.Severity.WARNING,
						component,
						str(owner.name),
						"action_targets[%d] SUBTRACT_PRODUCT_FROM_FLOAT needs float_accumulator." % i,
						"Assign UiFloatState (e.g. gold).",
						node_path,
						&"action_targets",
						&"",
						UiReactDiagnosticModel.IssueKind.GENERIC,
						"",
					)
				)
			elif not (row.float_accumulator is UiFloatState):
				out.append(
					UiReactDiagnosticModel.DiagnosticIssue.make_structured(
						UiReactDiagnosticModel.Severity.WARNING,
						component,
						str(owner.name),
						"action_targets[%d] float_accumulator must be UiFloatState." % i,
						"Assign UiFloatState.",
						node_path,
						&"action_targets",
						&"",
						UiReactDiagnosticModel.IssueKind.GENERIC,
						"",
					)
				)
			if row.float_factor_a == null:
				out.append(
					UiReactDiagnosticModel.DiagnosticIssue.make_structured(
						UiReactDiagnosticModel.Severity.WARNING,
						component,
						str(owner.name),
						"action_targets[%d] SUBTRACT_PRODUCT_FROM_FLOAT needs float_factor_a." % i,
						"Assign UiFloatState (e.g. price).",
						node_path,
						&"action_targets",
						&"",
						UiReactDiagnosticModel.IssueKind.GENERIC,
						"",
					)
				)
			elif not (row.float_factor_a is UiFloatState):
				out.append(
					UiReactDiagnosticModel.DiagnosticIssue.make_structured(
						UiReactDiagnosticModel.Severity.WARNING,
						component,
						str(owner.name),
						"action_targets[%d] float_factor_a must be UiFloatState." % i,
						"Assign UiFloatState.",
						node_path,
						&"action_targets",
						&"",
						UiReactDiagnosticModel.IssueKind.GENERIC,
						"",
					)
				)
			if row.float_factor_b == null:
				out.append(
					UiReactDiagnosticModel.DiagnosticIssue.make_structured(
						UiReactDiagnosticModel.Severity.WARNING,
						component,
						str(owner.name),
						"action_targets[%d] SUBTRACT_PRODUCT_FROM_FLOAT needs float_factor_b." % i,
						"Assign UiFloatState (e.g. quantity).",
						node_path,
						&"action_targets",
						&"",
						UiReactDiagnosticModel.IssueKind.GENERIC,
						"",
					)
				)
			elif not (row.float_factor_b is UiFloatState):
				out.append(
					UiReactDiagnosticModel.DiagnosticIssue.make_structured(
						UiReactDiagnosticModel.Severity.WARNING,
						component,
						str(owner.name),
						"action_targets[%d] float_factor_b must be UiFloatState." % i,
						"Assign UiFloatState.",
						node_path,
						&"action_targets",
						&"",
						UiReactDiagnosticModel.IssueKind.GENERIC,
						"",
					)
				)
			continue

		if row.state_watch != null and row.bool_flag_state != null:
			if (
				row.action == UiReactActionTarget.UiReactActionKind.SET_UI_BOOL_FLAG
				and row.bool_flag_state == row.state_watch
			):
				out.append(
					UiReactDiagnosticModel.DiagnosticIssue.make_structured(
						UiReactDiagnosticModel.Severity.ERROR,
						component,
						str(owner.name),
						"action_targets[%d]: bool_flag_state duplicates state_watch (loop risk)." % i,
						"Use a different UiBoolState for SET_UI_BOOL_FLAG.",
						node_path,
						&"action_targets",
						&"",
						UiReactDiagnosticModel.IssueKind.GENERIC,
						"",
					)
				)

		var needs_target: bool = row.action in [
			UiReactActionTarget.UiReactActionKind.GRAB_FOCUS,
			UiReactActionTarget.UiReactActionKind.SET_VISIBLE,
			UiReactActionTarget.UiReactActionKind.SET_MOUSE_FILTER,
		]
		if needs_target and row.target.is_empty():
			out.append(
				UiReactDiagnosticModel.DiagnosticIssue.make_structured(
					UiReactDiagnosticModel.Severity.WARNING,
					component,
					str(owner.name),
					"action_targets[%d] needs a target NodePath." % i,
					"Assign target in the Inspector.",
					node_path,
					&"action_targets",
					&"",
					UiReactDiagnosticModel.IssueKind.GENERIC,
					"",
				)
			)
			continue

		if needs_target:
			var tn := owner.get_node_or_null(row.target)
			if tn == null:
				out.append(
					UiReactDiagnosticModel.DiagnosticIssue.make_structured(
						UiReactDiagnosticModel.Severity.ERROR,
						component,
						str(owner.name),
						"action_targets[%d] target '%s' could not be resolved." % [i, row.target],
						"Fix the NodePath relative to this control.",
						node_path,
						&"action_targets",
						&"",
						UiReactDiagnosticModel.IssueKind.GENERIC,
						"",
					)
				)
			elif row.action == UiReactActionTarget.UiReactActionKind.SET_VISIBLE:
				if not (tn is CanvasItem):
					out.append(
						UiReactDiagnosticModel.DiagnosticIssue.make_structured(
							UiReactDiagnosticModel.Severity.ERROR,
							component,
							str(owner.name),
							"action_targets[%d] SET_VISIBLE target must be CanvasItem/Control." % i,
							"Point target at a visible node.",
							node_path,
							&"action_targets",
							&"",
							UiReactDiagnosticModel.IssueKind.GENERIC,
							"",
						)
					)
			elif not (tn is Control):
				out.append(
					UiReactDiagnosticModel.DiagnosticIssue.make_structured(
						UiReactDiagnosticModel.Severity.ERROR,
						component,
						str(owner.name),
						"action_targets[%d] target must be a Control." % i,
						"Point target at a Control.",
						node_path,
						&"action_targets",
						&"",
						UiReactDiagnosticModel.IssueKind.GENERIC,
						"",
					)
				)

		if row.action == UiReactActionTarget.UiReactActionKind.SET_UI_BOOL_FLAG and row.bool_flag_state == null:
			out.append(
				UiReactDiagnosticModel.DiagnosticIssue.make_structured(
					UiReactDiagnosticModel.Severity.WARNING,
					component,
					str(owner.name),
					"action_targets[%d] SET_UI_BOOL_FLAG needs bool_flag_state." % i,
					"Assign bool_flag_state.",
					node_path,
					&"action_targets",
					&"",
					UiReactDiagnosticModel.IssueKind.GENERIC,
					"",
				)
			)

	return out

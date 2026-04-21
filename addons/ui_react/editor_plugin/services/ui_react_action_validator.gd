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
	for i in range(rows.size()):
		var row_var: Variant = rows[i]
		if row_var == null:
			out.append(
				UiReactDiagnosticModel.DiagnosticIssue.make_structured(
					UiReactDiagnosticModel.Severity.WARNING,
					component,
					str(owner.name),
					"Action targets row %d is empty (null)." % i,
					"Remove that row in the Inspector or assign a UiReactActionTarget resource.",
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

		if row.state_watch != null and row.trigger != UiAnimTarget.Trigger.PRESSED:
			out.append(
				UiReactDiagnosticModel.DiagnosticIssue.make_structured(
					UiReactDiagnosticModel.Severity.WARNING,
					component,
					str(owner.name),
					"Action row %d watches a state but Trigger is not Pressed (this combo is ignored at runtime)." % i,
					"Set Trigger to Pressed when using State watch, or clear State watch for button- or control-driven rows.",
					node_path,
					&"action_targets",
					&"",
					UiReactDiagnosticModel.IssueKind.GENERIC,
					"",
				)
			)

		if row.state_watch == null:
			if not UiReactValidatorCommon.is_anim_trigger_allowed(component, row.trigger):
				out.append(
					UiReactDiagnosticModel.DiagnosticIssue.make_structured(
						UiReactDiagnosticModel.Severity.WARNING,
						component,
						str(owner.name),
						(
							"Action row %d uses trigger %s, but this control does not fire that signal."
							% [i, UiReactValidatorCommon.format_anim_trigger_name(row.trigger)]
						),
						(
							"For %s, use one of the supported triggers: %s."
							% [component, UiReactValidatorCommon.format_allowed_anim_triggers_hint(component)]
						),
						node_path,
						&"action_targets",
						&"",
						UiReactDiagnosticModel.IssueKind.GENERIC,
						"",
					)
				)

		match row.action:
			UiReactActionTarget.UiReactActionKind.SUBTRACT_PRODUCT_FROM_FLOAT, UiReactActionTarget.UiReactActionKind.ADD_PRODUCT_TO_FLOAT:
				_append_error_state_watch_on_numeric_row(
					out, component, owner, node_path, i, row, _numeric_kind_label(row.action)
				)
				var _kl := _numeric_kind_label(row.action)
				_append_uifloat_ref(
					out, component, owner, node_path, i, row.float_accumulator,
					"action_targets[%d] %s needs float_accumulator." % [i, _kl],
					"In the Inspector, assign a UiFloatState (for example the total pool).",
					"action_targets[%d] float_accumulator must be UiFloatState." % i,
				)
				_append_uifloat_ref(
					out, component, owner, node_path, i, row.float_factor_a,
					"action_targets[%d] %s needs float_factor_a." % [i, _kl],
					"In the Inspector, assign a UiFloatState (for example unit price).",
					"action_targets[%d] float_factor_a must be UiFloatState." % i,
				)
				_append_uifloat_ref(
					out, component, owner, node_path, i, row.float_factor_b,
					"action_targets[%d] %s needs float_factor_b." % [i, _kl],
					"In the Inspector, assign a UiFloatState (for example quantity).",
					"action_targets[%d] float_factor_b must be UiFloatState." % i,
				)
				continue
			UiReactActionTarget.UiReactActionKind.TRANSFER_FLOAT_PRODUCT_CLAMPED:
				_append_error_state_watch_on_numeric_row(
					out, component, owner, node_path, i, row, "TRANSFER_FLOAT_PRODUCT_CLAMPED"
				)
				_append_uifloat_ref(
					out, component, owner, node_path, i, row.float_from,
					"action_targets[%d] TRANSFER_FLOAT_PRODUCT_CLAMPED needs float_from." % i,
					"In the Inspector, assign a UiFloatState for the source pool.",
					"action_targets[%d] float_from must be UiFloatState." % i,
				)
				_append_uifloat_ref(
					out, component, owner, node_path, i, row.float_to,
					"action_targets[%d] TRANSFER_FLOAT_PRODUCT_CLAMPED needs float_to." % i,
					"In the Inspector, assign a UiFloatState for the destination pool.",
					"action_targets[%d] float_to must be UiFloatState." % i,
				)
				_append_uifloat_ref(
					out, component, owner, node_path, i, row.float_factor_a,
					"action_targets[%d] TRANSFER_FLOAT_PRODUCT_CLAMPED needs float_factor_a." % i,
					"In the Inspector, assign a UiFloatState (for example unit price).",
					"action_targets[%d] float_factor_a must be UiFloatState." % i,
				)
				_append_uifloat_ref(
					out, component, owner, node_path, i, row.float_factor_b,
					"action_targets[%d] TRANSFER_FLOAT_PRODUCT_CLAMPED needs float_factor_b." % i,
					"In the Inspector, assign a UiFloatState (for example quantity).",
					"action_targets[%d] float_factor_b must be UiFloatState." % i,
				)
				continue
			UiReactActionTarget.UiReactActionKind.ADD_PRODUCT_TO_INT:
				_append_error_state_watch_on_numeric_row(
					out, component, owner, node_path, i, row, "ADD_PRODUCT_TO_INT"
				)
				_append_uiint_ref(
					out, component, owner, node_path, i, row.int_accumulator,
					"action_targets[%d] ADD_PRODUCT_TO_INT needs int_accumulator." % i,
					"In the Inspector, assign a UiIntState resource.",
					"action_targets[%d] int_accumulator must be UiIntState." % i,
				)
				_append_uiint_ref(
					out, component, owner, node_path, i, row.int_factor_a,
					"action_targets[%d] ADD_PRODUCT_TO_INT needs int_factor_a." % i,
					"In the Inspector, assign a UiIntState resource.",
					"action_targets[%d] int_factor_a must be UiIntState." % i,
				)
				_append_uiint_ref(
					out, component, owner, node_path, i, row.int_factor_b,
					"action_targets[%d] ADD_PRODUCT_TO_INT needs int_factor_b." % i,
					"In the Inspector, assign a UiIntState resource.",
					"action_targets[%d] int_factor_b must be UiIntState." % i,
				)
				continue
			UiReactActionTarget.UiReactActionKind.TRANSFER_INT_PRODUCT_CLAMPED:
				_append_error_state_watch_on_numeric_row(
					out, component, owner, node_path, i, row, "TRANSFER_INT_PRODUCT_CLAMPED"
				)
				_append_uiint_ref(
					out, component, owner, node_path, i, row.int_from,
					"action_targets[%d] TRANSFER_INT_PRODUCT_CLAMPED needs int_from." % i,
					"In the Inspector, assign a UiIntState for the source pool.",
					"action_targets[%d] int_from must be UiIntState." % i,
				)
				_append_uiint_ref(
					out, component, owner, node_path, i, row.int_to,
					"action_targets[%d] TRANSFER_INT_PRODUCT_CLAMPED needs int_to." % i,
					"In the Inspector, assign a UiIntState for the destination pool.",
					"action_targets[%d] int_to must be UiIntState." % i,
				)
				_append_uiint_ref(
					out, component, owner, node_path, i, row.int_factor_a,
					"action_targets[%d] TRANSFER_INT_PRODUCT_CLAMPED needs int_factor_a." % i,
					"In the Inspector, assign a UiIntState resource.",
					"action_targets[%d] int_factor_a must be UiIntState." % i,
				)
				_append_uiint_ref(
					out, component, owner, node_path, i, row.int_factor_b,
					"action_targets[%d] TRANSFER_INT_PRODUCT_CLAMPED needs int_factor_b." % i,
					"In the Inspector, assign a UiIntState resource.",
					"action_targets[%d] int_factor_b must be UiIntState." % i,
				)
				continue
			UiReactActionTarget.UiReactActionKind.SET_FLOAT_LITERAL:
				_append_error_state_watch_on_numeric_row(
					out, component, owner, node_path, i, row, "SET_FLOAT_LITERAL"
				)
				_append_uifloat_ref(
					out, component, owner, node_path, i, row.float_literal_target,
					"action_targets[%d] SET_FLOAT_LITERAL needs float_literal_target." % i,
					"In the Inspector, assign a UiFloatState resource.",
					"action_targets[%d] float_literal_target must be UiFloatState." % i,
				)
				continue
			_:
				## Non-numeric action kinds: no shared float/int field matrix in this validator branch.
				pass

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
						"Action row %d uses the same bool for both watch and flag (can loop)." % i,
						"Pick a different UiBoolState for the UI bool flag, or change State watch.",
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
					"Action row %d needs a target node picked." % i,
					"In the Inspector, set Target by dragging a node from the scene.",
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
						"Action row %d target node was not found: %s." % [i, row.target],
						"Fix the target path in the Inspector (relative to this control) or pick the node again.",
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
							"Action row %d Set visible must target something drawable (Control/CanvasItem)." % i,
							"Pick a Control or CanvasItem in the Target field.",
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
					"Action row %d (set UI bool flag) needs a bool flag state." % i,
					"In the Inspector, assign Bool flag state to a UiBoolState.",
					node_path,
					&"action_targets",
					&"",
					UiReactDiagnosticModel.IssueKind.GENERIC,
					"",
				)
			)

	return out


static func _numeric_kind_label(action: UiReactActionTarget.UiReactActionKind) -> String:
	match action:
		UiReactActionTarget.UiReactActionKind.SUBTRACT_PRODUCT_FROM_FLOAT:
			return "SUBTRACT_PRODUCT_FROM_FLOAT"
		UiReactActionTarget.UiReactActionKind.ADD_PRODUCT_TO_FLOAT:
			return "ADD_PRODUCT_TO_FLOAT"
		_:
			return ""


static func _append_error_state_watch_on_numeric_row(
	out: Array,
	component: String,
	owner: Control,
	node_path: NodePath,
	i: int,
	row: UiReactActionTarget,
	kind_name: String,
) -> void:
	if row.state_watch == null:
		return
	out.append(
		UiReactDiagnosticModel.DiagnosticIssue.make_structured(
			UiReactDiagnosticModel.Severity.ERROR,
			component,
			str(owner.name),
			"Action row %d (%s) is driven by a button or control, so State watch must be empty." % [i, kind_name],
			"Clear State watch on this row, or pick an action kind meant for state-driven rows.",
			node_path,
			&"action_targets",
			&"",
			UiReactDiagnosticModel.IssueKind.GENERIC,
			"",
		)
	)


static func _append_uifloat_ref(
	out: Array,
	component: String,
	owner: Control,
	node_path: NodePath,
	i: int,
	ref: Variant,
	missing_line: String,
	assign_hint: String,
	wrong_type_line: String,
) -> void:
	if ref == null:
		out.append(
			UiReactDiagnosticModel.DiagnosticIssue.make_structured(
				UiReactDiagnosticModel.Severity.WARNING,
				component,
				str(owner.name),
				missing_line,
				assign_hint,
				node_path,
				&"action_targets",
				&"",
				UiReactDiagnosticModel.IssueKind.GENERIC,
				"",
			)
		)
	elif not (ref is UiFloatState):
		out.append(
			UiReactDiagnosticModel.DiagnosticIssue.make_structured(
				UiReactDiagnosticModel.Severity.WARNING,
				component,
				str(owner.name),
				wrong_type_line,
				"In the Inspector, assign a UiFloatState resource.",
				node_path,
				&"action_targets",
				&"",
				UiReactDiagnosticModel.IssueKind.GENERIC,
				"",
			)
		)


static func _append_uiint_ref(
	out: Array,
	component: String,
	owner: Control,
	node_path: NodePath,
	i: int,
	ref: Variant,
	missing_line: String,
	assign_hint: String,
	wrong_type_line: String,
) -> void:
	if ref == null:
		out.append(
			UiReactDiagnosticModel.DiagnosticIssue.make_structured(
				UiReactDiagnosticModel.Severity.WARNING,
				component,
				str(owner.name),
				missing_line,
				assign_hint,
				node_path,
				&"action_targets",
				&"",
				UiReactDiagnosticModel.IssueKind.GENERIC,
				"",
			)
		)
	elif not (ref is UiIntState):
		out.append(
			UiReactDiagnosticModel.DiagnosticIssue.make_structured(
				UiReactDiagnosticModel.Severity.WARNING,
				component,
				str(owner.name),
				wrong_type_line,
				"In the Inspector, assign a UiIntState resource.",
				node_path,
				&"action_targets",
				&"",
				UiReactDiagnosticModel.IssueKind.GENERIC,
				"",
			)
		)

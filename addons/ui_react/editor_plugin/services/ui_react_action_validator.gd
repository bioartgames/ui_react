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

		if row.state_watch == null:
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

		match row.action:
			UiReactActionTarget.UiReactActionKind.SUBTRACT_PRODUCT_FROM_FLOAT, UiReactActionTarget.UiReactActionKind.ADD_PRODUCT_TO_FLOAT:
				_append_error_state_watch_on_numeric_row(
					out, component, owner, node_path, i, row, _numeric_kind_label(row.action)
				)
				var _kl := _numeric_kind_label(row.action)
				_append_uifloat_ref(
					out, component, owner, node_path, i, row.float_accumulator,
					"action_targets[%d] %s needs float_accumulator." % [i, _kl],
					"Assign UiFloatState (e.g. gold).",
					"action_targets[%d] float_accumulator must be UiFloatState." % i,
				)
				_append_uifloat_ref(
					out, component, owner, node_path, i, row.float_factor_a,
					"action_targets[%d] %s needs float_factor_a." % [i, _kl],
					"Assign UiFloatState (e.g. price).",
					"action_targets[%d] float_factor_a must be UiFloatState." % i,
				)
				_append_uifloat_ref(
					out, component, owner, node_path, i, row.float_factor_b,
					"action_targets[%d] %s needs float_factor_b." % [i, _kl],
					"Assign UiFloatState (e.g. quantity).",
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
					"Assign UiFloatState (source pool).",
					"action_targets[%d] float_from must be UiFloatState." % i,
				)
				_append_uifloat_ref(
					out, component, owner, node_path, i, row.float_to,
					"action_targets[%d] TRANSFER_FLOAT_PRODUCT_CLAMPED needs float_to." % i,
					"Assign UiFloatState (destination pool).",
					"action_targets[%d] float_to must be UiFloatState." % i,
				)
				_append_uifloat_ref(
					out, component, owner, node_path, i, row.float_factor_a,
					"action_targets[%d] TRANSFER_FLOAT_PRODUCT_CLAMPED needs float_factor_a." % i,
					"Assign UiFloatState (e.g. price).",
					"action_targets[%d] float_factor_a must be UiFloatState." % i,
				)
				_append_uifloat_ref(
					out, component, owner, node_path, i, row.float_factor_b,
					"action_targets[%d] TRANSFER_FLOAT_PRODUCT_CLAMPED needs float_factor_b." % i,
					"Assign UiFloatState (e.g. quantity).",
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
					"Assign UiIntState.",
					"action_targets[%d] int_accumulator must be UiIntState." % i,
				)
				_append_uiint_ref(
					out, component, owner, node_path, i, row.int_factor_a,
					"action_targets[%d] ADD_PRODUCT_TO_INT needs int_factor_a." % i,
					"Assign UiIntState.",
					"action_targets[%d] int_factor_a must be UiIntState." % i,
				)
				_append_uiint_ref(
					out, component, owner, node_path, i, row.int_factor_b,
					"action_targets[%d] ADD_PRODUCT_TO_INT needs int_factor_b." % i,
					"Assign UiIntState.",
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
					"Assign UiIntState (source).",
					"action_targets[%d] int_from must be UiIntState." % i,
				)
				_append_uiint_ref(
					out, component, owner, node_path, i, row.int_to,
					"action_targets[%d] TRANSFER_INT_PRODUCT_CLAMPED needs int_to." % i,
					"Assign UiIntState (destination).",
					"action_targets[%d] int_to must be UiIntState." % i,
				)
				_append_uiint_ref(
					out, component, owner, node_path, i, row.int_factor_a,
					"action_targets[%d] TRANSFER_INT_PRODUCT_CLAMPED needs int_factor_a." % i,
					"Assign UiIntState.",
					"action_targets[%d] int_factor_a must be UiIntState." % i,
				)
				_append_uiint_ref(
					out, component, owner, node_path, i, row.int_factor_b,
					"action_targets[%d] TRANSFER_INT_PRODUCT_CLAMPED needs int_factor_b." % i,
					"Assign UiIntState.",
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
					"Assign UiFloatState.",
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
			"action_targets[%d]: %s is control-triggered only (clear state_watch)." % [i, kind_name],
			"Remove state_watch or use a different action kind.",
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
				"Assign UiFloatState.",
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
				"Assign UiIntState.",
				node_path,
				&"action_targets",
				&"",
				UiReactDiagnosticModel.IssueKind.GENERIC,
				"",
			)
		)

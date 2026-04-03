## Validates [UiReact*] bindings and [UiAnimTarget] rows (editor-only; mirrors runtime helpers).
class_name UiReactValidatorService
extends RefCounted

const _VALUE_PREVIEW_HELPER := preload("res://addons/ui_react/editor_plugin/services/ui_react_value_preview_helper.gd")

static func validate_nodes(
	nodes: Array[Node],
	root_for_paths: Node,
) -> Array[UiReactDiagnosticModel.DiagnosticIssue]:
	var issues: Array[UiReactDiagnosticModel.DiagnosticIssue] = []
	for node in nodes:
		if node == null or not (node is Control):
			continue
		var component := UiReactScannerService.get_component_name_from_script(node.get_script() as Script)
		if component.is_empty():
			continue
		var node_path := root_for_paths.get_path_to(node) if root_for_paths and node.is_inside_tree() else NodePath(String(node.get_path()))
		issues.append_array(_validate_bindings(component, node as Control, node_path))
		issues.append_array(_validate_anim_targets(component, node as Control, node_path))
		issues.append_array(_validate_action_targets(component, node as Control, node_path))
		issues.append_array(_validate_wire_rules(component, node as Control, node_path))
	return issues


static func validate_wiring_under_root(root: Node) -> Array[UiReactDiagnosticModel.DiagnosticIssue]:
	return _validate_wiring_scope(root)


static func _expected_binding_state_class(component: String, prop: StringName, kind: String, owner: Control) -> StringName:
	if component == "UiReactItemList" and prop == &"selected_state":
		if owner is ItemList and (owner as ItemList).select_mode == ItemList.SELECT_SINGLE:
			return &"UiIntState"
		return &"UiArrayState"
	return UiReactScannerService.kind_to_suggested_class(kind)


static func _binding_type_ok(ui_state: UiState, expected: StringName, component: String, prop: StringName) -> bool:
	if (component == "UiReactLabel" or component == "UiReactRichTextLabel") and prop == &"text_state":
		if ui_state is UiStringState or ui_state is UiArrayState:
			return true
		return ui_state is UiTransactionalState and (
			(ui_state as UiTransactionalState).matches_expected_binding_class(&"UiStringState")
			or (ui_state as UiTransactionalState).matches_expected_binding_class(&"UiArrayState")
		)
	if ui_state is UiTransactionalState:
		return (ui_state as UiTransactionalState).matches_expected_binding_class(expected)
	if expected.is_empty():
		return true
	match String(expected):
		"UiBoolState":
			return ui_state is UiBoolState
		"UiIntState":
			return ui_state is UiIntState
		"UiFloatState":
			return ui_state is UiFloatState
		"UiStringState":
			return ui_state is UiStringState
		"UiArrayState":
			return ui_state is UiArrayState
		_:
			return true


static func _append_binding_issue_with_preview(
	out: Array[UiReactDiagnosticModel.DiagnosticIssue],
	issue: UiReactDiagnosticModel.DiagnosticIssue,
	ui_state: UiState,
) -> void:
	_VALUE_PREVIEW_HELPER.enrich_issue_from_state(issue, ui_state)
	out.append(issue)


static func _expected_type_phrase(component: String, prop: StringName, expected: StringName) -> String:
	if (component == "UiReactLabel" or component == "UiReactRichTextLabel") and prop == &"text_state":
		return "UiStringState, UiComputedStringState, UiArrayState, or UiTransactionalState (string/array payload)"
	if expected.is_empty():
		return "a concrete UiState subclass"
	return str(expected)


static func _validate_bindings(component: String, owner: Control, node_path: NodePath) -> Array[UiReactDiagnosticModel.DiagnosticIssue]:
	var out: Array[UiReactDiagnosticModel.DiagnosticIssue] = []
	var bindings: Array = UiReactScannerService.BINDINGS_BY_COMPONENT.get(component, [])
	for b in bindings:
		var prop: StringName = b.get("property", &"")
		var kind: String = str(b.get("kind", ""))
		var optional: bool = bool(b.get("optional", true))
		if prop == &"":
			continue
		if not prop in owner:
			continue
		var expected: StringName = _expected_binding_state_class(component, prop, kind, owner)
		var suggested: StringName = UiReactScannerService.kind_to_suggested_class(kind)
		if component == "UiReactItemList" and prop == &"selected_state":
			suggested = expected
		var property_value: Variant = owner.get(prop)
		if property_value == null:
			if optional:
				out.append(
					UiReactDiagnosticModel.DiagnosticIssue.make_structured(
						UiReactDiagnosticModel.Severity.INFO,
						component,
						str(owner.name),
						"%s is not assigned." % prop,
						"Create a concrete Ui*State resource and assign it, or leave empty if you do not need external sync.",
						node_path,
						prop,
						suggested,
						UiReactDiagnosticModel.IssueKind.GENERIC,
						"",
					)
				)
			else:
				out.append(
					UiReactDiagnosticModel.DiagnosticIssue.make_structured(
						UiReactDiagnosticModel.Severity.WARNING,
						component,
						str(owner.name),
						"%s is required but empty." % prop,
						"Assign a UiState subclass resource to this property.",
						node_path,
						prop,
						suggested,
						UiReactDiagnosticModel.IssueKind.GENERIC,
						"",
					)
				)
			continue
		if not (property_value is UiState):
			out.append(
				UiReactDiagnosticModel.DiagnosticIssue.make_structured(
					UiReactDiagnosticModel.Severity.ERROR,
					component,
					str(owner.name),
					"%s must be a UiState subclass (got %s)." % [prop, _variant_type_name(property_value)],
					"Assign a concrete UiBoolState, UiComputedBoolState, UiIntState, UiFloatState, UiStringState, UiComputedStringState, UiArrayState, or UiTransactionalState resource.",
					node_path,
					prop,
					suggested,
					UiReactDiagnosticModel.IssueKind.GENERIC,
					"",
				)
			)
			continue
		var ui_state := property_value as UiState
		if component == "UiReactItemList" and prop == &"selected_state" and owner is ItemList:
			var is_single := (owner as ItemList).select_mode == ItemList.SELECT_SINGLE
			var is_float_like := ui_state is UiFloatState
			if not is_float_like and ui_state is UiTransactionalState:
				is_float_like = (ui_state as UiTransactionalState).matches_expected_binding_class(&"UiFloatState")
			if is_single and is_float_like:
				var issue_il := UiReactDiagnosticModel.DiagnosticIssue.make_structured(
					UiReactDiagnosticModel.Severity.ERROR,
					component,
					str(owner.name),
					"%s cannot use UiFloatState in single-select mode." % prop,
					"Use UiIntState (int indices only). Float is not accepted for list selection.",
					node_path,
					prop,
					&"UiIntState",
					UiReactDiagnosticModel.IssueKind.GENERIC,
					"",
				)
				_append_binding_issue_with_preview(out, issue_il, ui_state)
				continue
		if not _binding_type_ok(ui_state, expected, component, prop):
			var phrase: String = _expected_type_phrase(component, prop, expected)
			var issue_bt := UiReactDiagnosticModel.DiagnosticIssue.make_structured(
				UiReactDiagnosticModel.Severity.ERROR,
				component,
				str(owner.name),
				"%s expects %s (got %s)." % [prop, phrase, ui_state.get_class()],
				"Assign a resource of the expected type.",
				node_path,
				prop,
				suggested,
				UiReactDiagnosticModel.IssueKind.GENERIC,
				"",
			)
			_append_binding_issue_with_preview(out, issue_bt, ui_state)
	return out


static func _variant_type_name(v: Variant) -> String:
	if v is Object and v:
		return v.get_class()
	return str(typeof(v))


static func _validate_anim_targets(
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
	return out


static func _validate_action_targets(
	component: String, owner: Control, node_path: NodePath
) -> Array[UiReactDiagnosticModel.DiagnosticIssue]:
	var out: Array[UiReactDiagnosticModel.DiagnosticIssue] = []
	if not &"action_targets" in owner:
		return out
	var arr: Variant = owner.get(&"action_targets")
	if not (arr is Array):
		return out
	var rows: Array = arr as Array
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


## Validates [member wire_rules] rows on §5 controls ([code]docs/WIRING_LAYER.md[/code] §5); enabled or not — avoids enable-then-break surprises.
static func _validate_wire_rules(
	component: String, owner: Control, node_path: NodePath
) -> Array[UiReactDiagnosticModel.DiagnosticIssue]:
	var out: Array[UiReactDiagnosticModel.DiagnosticIssue] = []
	if not &"wire_rules" in owner:
		return out
	var wr_variant: Variant = owner.get(&"wire_rules")
	if not (wr_variant is Array):
		return out
	var wr: Array = wr_variant
	for i in range(wr.size()):
		var item: Variant = wr[i]
		if item == null:
			out.append(
				UiReactDiagnosticModel.DiagnosticIssue.make_structured(
					UiReactDiagnosticModel.Severity.WARNING,
					component,
					str(owner.name),
					"wire_rules[%d] is null; remove the empty slot." % i,
					"Remove the array element or assign a UiReactWireRule subresource.",
					node_path,
					&"wire_rules",
					&"",
					UiReactDiagnosticModel.IssueKind.GENERIC,
					"",
				)
			)
			continue
		if not (item is UiReactWireRule):
			out.append(
				UiReactDiagnosticModel.DiagnosticIssue.make_structured(
					UiReactDiagnosticModel.Severity.WARNING,
					component,
					str(owner.name),
					"wire_rules[%d] must be a UiReactWireRule (got %s)." % [i, _variant_type_name(item)],
					"Assign a MapIntToString, RefreshItemsFromCatalog, or CopySelectionDetail rule resource.",
					node_path,
					&"wire_rules",
					&"",
					UiReactDiagnosticModel.IssueKind.GENERIC,
					"",
				)
			)
			continue
		var rule := item as UiReactWireRule
		if rule is UiReactWireMapIntToString:
			out.append_array(
				_validate_wire_rule_map_int(rule as UiReactWireMapIntToString, component, owner, node_path, i)
			)
		elif rule is UiReactWireRefreshItemsFromCatalog:
			out.append_array(
				_validate_wire_rule_refresh(
					rule as UiReactWireRefreshItemsFromCatalog, component, owner, node_path, i
				)
			)
		elif rule is UiReactWireCopySelectionDetail:
			out.append_array(
				_validate_wire_rule_copy_detail(rule as UiReactWireCopySelectionDetail, component, owner, node_path, i)
			)
	return out


static func _validate_wire_rule_map_int(
	rule: UiReactWireMapIntToString, component: String, owner: Control, node_path: NodePath, index_i: int
) -> Array[UiReactDiagnosticModel.DiagnosticIssue]:
	var out: Array[UiReactDiagnosticModel.DiagnosticIssue] = []
	if rule.source_int_state == null:
		out.append(_wire_rules_issue(component, owner, node_path, index_i, "source_int_state is required.", "Assign UiIntState."))
	elif not (rule.source_int_state is UiIntState):
		out.append(
			_wire_rules_issue(
				component, owner, node_path, index_i, "source_int_state must be UiIntState.", "Assign a UiIntState resource."
			)
		)
	if rule.target_string_state == null:
		out.append(_wire_rules_issue(component, owner, node_path, index_i, "target_string_state is required.", "Assign UiStringState."))
	elif not (rule.target_string_state is UiStringState):
		out.append(
			_wire_rules_issue(
				component, owner, node_path, index_i, "target_string_state must be UiStringState.", "Assign UiStringState."
			)
		)
	if rule.hint_state != null and not (rule.hint_state is UiStringState):
		out.append(
			_wire_rules_issue(component, owner, node_path, index_i, "hint_state must be UiStringState when set.", "Assign UiStringState or clear.")
		)
	return out


static func _validate_wire_rule_refresh(
	rule: UiReactWireRefreshItemsFromCatalog, component: String, owner: Control, node_path: NodePath, index_i: int
) -> Array[UiReactDiagnosticModel.DiagnosticIssue]:
	var out: Array[UiReactDiagnosticModel.DiagnosticIssue] = []
	if rule.items_state == null:
		out.append(_wire_rules_issue(component, owner, node_path, index_i, "items_state is required.", "Assign UiArrayState."))
	elif not (rule.items_state is UiArrayState):
		out.append(
			_wire_rules_issue(component, owner, node_path, index_i, "items_state must be UiArrayState.", "Assign UiArrayState.")
		)
	if rule.catalog == null:
		out.append(
			_wire_rules_issue(
				component, owner, node_path, index_i, "catalog is required.", "Assign UiReactWireCatalogData (or subclass)."
			)
		)
	elif not (rule.catalog is UiReactWireCatalogData):
		out.append(
			_wire_rules_issue(
				component,
				owner,
				node_path,
				index_i,
				"catalog must be UiReactWireCatalogData.",
				"Assign UiReactWireCatalogData or a game subclass.",
			)
		)
	if rule.filter_text_state != null and not (rule.filter_text_state is UiStringState):
		out.append(
			_wire_rules_issue(
				component, owner, node_path, index_i, "filter_text_state must be UiStringState when set.", "Assign UiStringState or clear."
			)
		)
	if rule.category_kind_state != null and not (rule.category_kind_state is UiStringState):
		out.append(
			_wire_rules_issue(
				component, owner, node_path, index_i, "category_kind_state must be UiStringState when set.", "Assign UiStringState or clear."
			)
		)
	if rule.selected_state != null and not (rule.selected_state is UiIntState):
		out.append(
			_wire_rules_issue(
				component, owner, node_path, index_i, "selected_state must be UiIntState when set.", "Assign UiIntState or clear."
			)
		)
	return out


static func _validate_wire_rule_copy_detail(
	rule: UiReactWireCopySelectionDetail, component: String, owner: Control, node_path: NodePath, index_i: int
) -> Array[UiReactDiagnosticModel.DiagnosticIssue]:
	var out: Array[UiReactDiagnosticModel.DiagnosticIssue] = []
	if rule.detail_state == null:
		out.append(_wire_rules_issue(component, owner, node_path, index_i, "detail_state is required.", "Assign UiStringState."))
	elif not (rule.detail_state is UiStringState):
		out.append(
			_wire_rules_issue(
				component, owner, node_path, index_i, "detail_state must be UiStringState.", "Assign UiStringState."
			)
		)
	if rule.selected_state == null:
		out.append(_wire_rules_issue(component, owner, node_path, index_i, "selected_state is required.", "Assign UiIntState."))
	elif not (rule.selected_state is UiIntState):
		out.append(
			_wire_rules_issue(component, owner, node_path, index_i, "selected_state must be UiIntState.", "Assign UiIntState.")
		)
	if rule.items_state != null and not (rule.items_state is UiArrayState):
		out.append(
			_wire_rules_issue(
				component, owner, node_path, index_i, "items_state must be UiArrayState when set.", "Assign UiArrayState or clear."
			)
		)
	if rule.suffix_note_state != null and not (rule.suffix_note_state is UiStringState):
		out.append(
			_wire_rules_issue(
				component, owner, node_path, index_i, "suffix_note_state must be UiStringState when set.", "Assign UiStringState or clear."
			)
		)
	return out


static func _wire_rules_issue(
	component: String, owner: Control, node_path: NodePath, index_i: int, text: String, hint: String
) -> UiReactDiagnosticModel.DiagnosticIssue:
	return UiReactDiagnosticModel.DiagnosticIssue.make_structured(
		UiReactDiagnosticModel.Severity.WARNING,
		component,
		str(owner.name),
		"wire_rules[%d]: %s" % [index_i, text],
		hint,
		node_path,
		&"wire_rules",
		&"",
		UiReactDiagnosticModel.IssueKind.GENERIC,
		"",
	)


static func _validate_wiring_scope(root: Node) -> Array[UiReactDiagnosticModel.DiagnosticIssue]:
	var out: Array[UiReactDiagnosticModel.DiagnosticIssue] = []
	if root == null:
		return out
	var state := {"runners": 0, "rules": 0}
	_scan_wiring_under(root, state)
	if state.rules > 0 and state.runners == 0:
		out.append(
			UiReactDiagnosticModel.DiagnosticIssue.make_structured(
				UiReactDiagnosticModel.Severity.WARNING,
				"UiReactWireRunner",
				str(root.name),
				"Scene has wire_rules but no UiReactWireRunner (see docs/WIRING_LAYER.md §3 / CB-034).",
				"Add a UiReactWireRunner node under the screen root (sibling of wired controls).",
				root.get_path(),
				&"wire_rules",
				&"",
				UiReactDiagnosticModel.IssueKind.GENERIC,
				"",
			)
		)
	if state.runners > 1:
		out.append(
			UiReactDiagnosticModel.DiagnosticIssue.make_structured(
				UiReactDiagnosticModel.Severity.WARNING,
				"UiReactWireRunner",
				str(root.name),
				"Multiple UiReactWireRunner nodes in this scene; use exactly one (docs/WIRING_LAYER.md §3).",
				"Keep a single runner per scene instance.",
				root.get_path(),
				&"wire_rules",
				&"",
				UiReactDiagnosticModel.IssueKind.GENERIC,
				"",
			)
		)
	return out


static func _scan_wiring_under(n: Node, state: Dictionary) -> void:
	if n is UiReactWireRunner:
		state.runners = int(state.runners) + 1
	var wr_variant: Variant = n.get("wire_rules")
	if wr_variant is Array:
		for item in wr_variant as Array:
			if item is UiReactWireRule:
				state.rules = int(state.rules) + 1
	for c in n.get_children():
		_scan_wiring_under(c, state)

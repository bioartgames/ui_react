## Validates [member wire_rules] and scene-level wiring scope (editor diagnostics).
class_name UiReactWiringValidator
extends RefCounted


static func validate_wire_rules(
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
					"wire_rules[%d] must be a UiReactWireRule (got %s)." % [i, UiReactValidatorCommon.variant_type_name(item)],
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


static func validate_wiring_under_root(root: Node) -> Array[UiReactDiagnosticModel.DiagnosticIssue]:
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

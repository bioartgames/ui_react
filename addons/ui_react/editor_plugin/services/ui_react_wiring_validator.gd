## Validates [member wire_rules] and scene-level duplicate rule references (editor diagnostics).
class_name UiReactWiringValidator
extends RefCounted

const _SCRIPT_WIRE_SORT_ARRAY_BY_KEY := "res://addons/ui_react/scripts/api/models/ui_react_wire_sort_array_by_key.gd"


static func _is_wire_sort_array_by_key(rule: UiReactWireRule) -> bool:
	var sc: Script = rule.get_script() as Script
	return sc != null and sc.resource_path == _SCRIPT_WIRE_SORT_ARRAY_BY_KEY


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
				_wire_rules_issue(
					component,
					owner,
					node_path,
					i,
					"is null; remove the empty slot.",
					"Remove the array element or assign a UiReactWireRule subresource.",
				)
			)
			continue
		if not (item is UiReactWireRule):
			out.append(
				_wire_rules_issue(
					component,
					owner,
					node_path,
					i,
					"must be a UiReactWireRule (got %s)." % UiReactValidatorCommon.variant_type_name(item),
					"Assign a UiReactWireRule subresource (MapIntToString, RefreshItemsFromCatalog, SortArrayByKey, CopySelectionDetail, SetStringOnBoolPulse, SyncBoolStateDebugLine).",
				)
			)
			continue
		var rule := item as UiReactWireRule
		if not rule.enabled:
			out.append(
				_wire_rules_issue(
					component,
					owner,
					node_path,
					i,
					"rule is disabled; helper skips binding and apply.",
					"Enable the rule in the inspector or remove the slot if unused.",
				)
			)
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
		elif _is_wire_sort_array_by_key(rule):
			out.append_array(_validate_wire_rule_sort_array_by_key(rule, component, owner, node_path, i))
		elif rule is UiReactWireCopySelectionDetail:
			out.append_array(
				_validate_wire_rule_copy_detail(rule as UiReactWireCopySelectionDetail, component, owner, node_path, i)
			)
		elif rule is UiReactWireSetStringOnBoolPulse:
			out.append_array(
				_validate_wire_rule_bool_pulse(rule as UiReactWireSetStringOnBoolPulse, component, owner, node_path, i)
			)
		elif rule is UiReactWireSyncBoolStateDebugLine:
			out.append_array(
				_validate_wire_rule_bool_debug_line(rule as UiReactWireSyncBoolStateDebugLine, component, owner, node_path, i)
			)
		else:
			out.append(
				_wire_rules_issue(
					component,
					owner,
					node_path,
					i,
					"unsupported concrete wire rule class for editor validation.",
					"Use a documented rule type or extend UiReactWiringValidator.",
				)
			)
	return out


static func validate_wiring_under_root(root: Node) -> Array[UiReactDiagnosticModel.DiagnosticIssue]:
	var out: Array[UiReactDiagnosticModel.DiagnosticIssue] = []
	if root == null:
		return out
	var first_host_by_rule: Dictionary = {}
	_collect_cross_node_duplicate_rules(root, first_host_by_rule, out)
	return out


static func _collect_cross_node_duplicate_rules(
	n: Node, first_host_by_rule: Dictionary, out: Array[UiReactDiagnosticModel.DiagnosticIssue]
) -> void:
	var wr_variant: Variant = n.get("wire_rules")
	if wr_variant is Array:
		for item in wr_variant as Array:
			if item is UiReactWireRule:
				var rule := item as UiReactWireRule
				var rid: int = rule.get_instance_id()
				if first_host_by_rule.has(rid):
					var prev_path: NodePath = first_host_by_rule[rid] as NodePath
					if prev_path != n.get_path():
						out.append(
							UiReactDiagnosticModel.DiagnosticIssue.make_structured(
								UiReactDiagnosticModel.Severity.WARNING,
								"UiReactWireRuleHelper",
								str(n.name),
								(
									"wire_rules: same UiReactWireRule instance is also on %s; use one rule instance per host (docs/WIRING_LAYER.md)."
									% prev_path
								),
								"Duplicate the subresource in the inspector or assign a separate rule per control.",
								n.get_path(),
								&"wire_rules",
								&"",
								UiReactDiagnosticModel.IssueKind.GENERIC,
								"",
							)
						)
				else:
					first_host_by_rule[rid] = n.get_path()
	for c in n.get_children():
		_collect_cross_node_duplicate_rules(c, first_host_by_rule, out)


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


static func _validate_wire_rule_sort_array_by_key(
	rule: UiReactWireRule, component: String, owner: Control, node_path: NodePath, index_i: int
) -> Array[UiReactDiagnosticModel.DiagnosticIssue]:
	var out: Array[UiReactDiagnosticModel.DiagnosticIssue] = []
	var items_st: Variant = rule.get(&"items_state")
	if items_st == null:
		out.append(_wire_rules_issue(component, owner, node_path, index_i, "items_state is required.", "Assign UiArrayState."))
	elif not (items_st is UiArrayState):
		out.append(
			_wire_rules_issue(
				component, owner, node_path, index_i, "items_state must be UiArrayState.", "Assign UiArrayState."
			)
		)
	var key_st: Variant = rule.get(&"sort_key_state")
	if key_st == null:
		out.append(_wire_rules_issue(component, owner, node_path, index_i, "sort_key_state is required.", "Assign UiStringState."))
	elif not (key_st is UiStringState):
		out.append(
			_wire_rules_issue(
				component, owner, node_path, index_i, "sort_key_state must be UiStringState.", "Assign UiStringState."
			)
		)
	var desc_st: Variant = rule.get(&"descending_state")
	if desc_st != null and not (desc_st is UiBoolState):
		out.append(
			_wire_rules_issue(
				component, owner, node_path, index_i, "descending_state must be UiBoolState when set.", "Assign UiBoolState or clear."
			)
		)
	if key_st is UiStringState:
		var key_trim := (key_st as UiStringState).get_string_value().strip_edges()
		if key_trim.is_empty():
			out.append(
				_wire_rules_issue(
					component,
					owner,
					node_path,
					index_i,
					"sort_key_state is empty after trim; apply() no-ops (no reorder).",
					"Set a non-empty sort key string.",
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


static func _validate_wire_rule_bool_pulse(
	rule: UiReactWireSetStringOnBoolPulse, component: String, owner: Control, node_path: NodePath, index_i: int
) -> Array[UiReactDiagnosticModel.DiagnosticIssue]:
	var out: Array[UiReactDiagnosticModel.DiagnosticIssue] = []
	if rule.pulse_bool == null:
		out.append(_wire_rules_issue(component, owner, node_path, index_i, "pulse_bool is required.", "Assign UiBoolState."))
	elif not (rule.pulse_bool is UiBoolState):
		out.append(
			_wire_rules_issue(component, owner, node_path, index_i, "pulse_bool must be UiBoolState.", "Assign UiBoolState.")
		)
	if rule.target_string_state == null:
		out.append(_wire_rules_issue(component, owner, node_path, index_i, "target_string_state is required.", "Assign UiStringState."))
	elif not (rule.target_string_state is UiStringState):
		out.append(
			_wire_rules_issue(component, owner, node_path, index_i, "target_string_state must be UiStringState.", "Assign UiStringState.")
		)
	var has_no_sel := not rule.template_no_selection.strip_edges().is_empty()
	var has_rising := not rule.template_rising.strip_edges().is_empty()
	if not has_no_sel and not has_rising:
		out.append(
			_wire_rules_issue(
				component,
				owner,
				node_path,
				index_i,
				"SetStringOnBoolPulse needs template_rising and/or template_no_selection.",
				"Set at least one non-empty template string.",
			)
		)
	if has_no_sel:
		if rule.selected_state == null:
			out.append(
				_wire_rules_issue(
					component, owner, node_path, index_i, "template_no_selection requires selected_state.", "Assign UiIntState for row lookup."
				)
			)
		elif not (rule.selected_state is UiIntState):
			out.append(
				_wire_rules_issue(component, owner, node_path, index_i, "selected_state must be UiIntState.", "Assign UiIntState.")
			)
		if rule.items_state == null:
			out.append(
				_wire_rules_issue(
					component, owner, node_path, index_i, "template_no_selection requires items_state.", "Assign UiArrayState for row lookup."
				)
			)
		elif not (rule.items_state is UiArrayState):
			out.append(
				_wire_rules_issue(component, owner, node_path, index_i, "items_state must be UiArrayState.", "Assign UiArrayState.")
			)
	if rule.selected_state != null and not (rule.selected_state is UiIntState):
		out.append(
			_wire_rules_issue(component, owner, node_path, index_i, "selected_state must be UiIntState when set.", "Assign UiIntState or clear.")
		)
	if rule.items_state != null and not (rule.items_state is UiArrayState):
		out.append(
			_wire_rules_issue(component, owner, node_path, index_i, "items_state must be UiArrayState when set.", "Assign UiArrayState or clear.")
		)
	return out


static func _validate_wire_rule_bool_debug_line(
	rule: UiReactWireSyncBoolStateDebugLine, component: String, owner: Control, node_path: NodePath, index_i: int
) -> Array[UiReactDiagnosticModel.DiagnosticIssue]:
	var out: Array[UiReactDiagnosticModel.DiagnosticIssue] = []
	if rule.bool_state == null:
		out.append(_wire_rules_issue(component, owner, node_path, index_i, "bool_state is required.", "Assign UiBoolState."))
	elif not (rule.bool_state is UiBoolState):
		out.append(
			_wire_rules_issue(component, owner, node_path, index_i, "bool_state must be UiBoolState.", "Assign UiBoolState.")
		)
	if rule.target_string_state == null:
		out.append(_wire_rules_issue(component, owner, node_path, index_i, "target_string_state is required.", "Assign UiStringState."))
	elif not (rule.target_string_state is UiStringState):
		out.append(
			_wire_rules_issue(component, owner, node_path, index_i, "target_string_state must be UiStringState.", "Assign UiStringState.")
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


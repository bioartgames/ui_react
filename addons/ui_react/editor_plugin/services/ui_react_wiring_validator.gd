## Validates [member wire_rules] and scene-level duplicate rule references (editor diagnostics).
class_name UiReactWiringValidator
extends RefCounted

const _WIRE_QUICK_EDIT_TEXT_MAX_LEN := 2048


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
					"this row is empty.",
					"Remove the row in the Inspector or assign a wire rule subresource.",
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
					"this slot is not a wire rule resource (found %s)." % UiReactValidatorCommon.variant_type_name(item),
					"Assign a supported wire rule type (map int to string, refresh list from catalog, sort array, copy selection text, set string on pulse, or debug line sync).",
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
					"this rule is turned off, so it will not run.",
					"Enable the rule in the Inspector or remove the row if you do not need it.",
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
		elif rule is UiReactWireSortArrayByKey:
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
					"this rule type is not covered by editor checks yet.",
					"Use a built-in wire rule type from the docs, or ask a maintainer to add validation for custom rules.",
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
									"Wire rules reuse the same rule resource as another control (%s); each control needs its own copy."
									% prev_path
								),
								"Duplicate the wire rule subresource in the Inspector, or assign a separate rule resource per control.",
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
		out.append(
			_wire_rules_issue(
				component,
				owner,
				node_path,
				index_i,
				"the source number state is missing.",
				"In the Inspector, assign Source int state to a UiIntState resource.",
			)
		)
	elif not (rule.source_int_state is UiIntState):
		out.append(
			_wire_rules_issue(
				component,
				owner,
				node_path,
				index_i,
				"Source int state must be a UiIntState resource.",
				"Pick a UiIntState resource for Source int state.",
			)
		)
	if rule.target_string_state == null:
		out.append(
			_wire_rules_issue(
				component,
				owner,
				node_path,
				index_i,
				"the target text state is missing.",
				"In the Inspector, assign Target string state to a UiStringState resource.",
			)
		)
	elif not (rule.target_string_state is UiStringState):
		out.append(
			_wire_rules_issue(
				component,
				owner,
				node_path,
				index_i,
				"Target string state must be a UiStringState resource.",
				"Pick a UiStringState for Target string state.",
			)
		)
	if rule.hint_state != null and not (rule.hint_state is UiStringState):
		out.append(
			_wire_rules_issue(
				component,
				owner,
				node_path,
				index_i,
				"Hint state must be a UiStringState when set.",
				"Assign a UiStringState or clear Hint state.",
			)
		)
	return out


static func _validate_wire_rule_refresh(
	rule: UiReactWireRefreshItemsFromCatalog, component: String, owner: Control, node_path: NodePath, index_i: int
) -> Array[UiReactDiagnosticModel.DiagnosticIssue]:
	var out: Array[UiReactDiagnosticModel.DiagnosticIssue] = []
	if rule.items_state == null:
		out.append(
			_wire_rules_issue(
				component,
				owner,
				node_path,
				index_i,
				"the list items state is missing.",
				"In the Inspector, assign Items state to a UiArrayState resource.",
			)
		)
	elif not (rule.items_state is UiArrayState):
		out.append(
			_wire_rules_issue(
				component,
				owner,
				node_path,
				index_i,
				"Items state must be a UiArrayState resource.",
				"Pick a UiArrayState for Items state.",
			)
		)
	if rule.catalog == null:
		out.append(
			_wire_rules_issue(
				component,
				owner,
				node_path,
				index_i,
				"the wire catalog resource is missing.",
				"In the Inspector, assign Catalog to a UiReactWireCatalogData (or your subclass).",
			)
		)
	elif not (rule.catalog is UiReactWireCatalogData):
		out.append(
			_wire_rules_issue(
				component,
				owner,
				node_path,
				index_i,
				"Catalog must be a UiReactWireCatalogData resource.",
				"Assign a catalog data resource or a game-specific subclass.",
			)
		)
	if rule.filter_text_state != null and not (rule.filter_text_state is UiStringState):
		out.append(
			_wire_rules_issue(
				component,
				owner,
				node_path,
				index_i,
				"Filter text state must be a UiStringState when set.",
				"Assign a UiStringState or clear Filter text state.",
			)
		)
	if rule.category_kind_state != null and not (rule.category_kind_state is UiStringState):
		out.append(
			_wire_rules_issue(
				component,
				owner,
				node_path,
				index_i,
				"Category kind state must be a UiStringState when set.",
				"Assign a UiStringState or clear Category kind state.",
			)
		)
	if rule.selected_state != null and not (rule.selected_state is UiIntState):
		out.append(
			_wire_rules_issue(
				component,
				owner,
				node_path,
				index_i,
				"Selected state must be a UiIntState when set.",
				"Assign a UiIntState or clear Selected state.",
			)
		)
	var icon_path := rule.first_row_icon_path.strip_edges()
	if not icon_path.is_empty() and not icon_path.begins_with("res://"):
		out.append(
			_wire_rules_issue(
				component,
				owner,
				node_path,
				index_i,
				"First row icon path should start with res:// so the editor and game load the same file.",
				"Use a project texture path (res://…) or clear First row icon path.",
			)
		)
	_append_wire_text_len_issue(
		out, component, owner, node_path, index_i, rule.first_row_icon_path, "first_row_icon_path"
	)
	return out


static func _validate_wire_rule_sort_array_by_key(
	rule: UiReactWireRule, component: String, owner: Control, node_path: NodePath, index_i: int
) -> Array[UiReactDiagnosticModel.DiagnosticIssue]:
	var out: Array[UiReactDiagnosticModel.DiagnosticIssue] = []
	var items_st: Variant = rule.get(&"items_state")
	if items_st == null:
		out.append(
			_wire_rules_issue(
				component,
				owner,
				node_path,
				index_i,
				"the list items state is missing.",
				"In the Inspector, assign Items state to a UiArrayState resource.",
			)
		)
	elif not (items_st is UiArrayState):
		out.append(
			_wire_rules_issue(
				component,
				owner,
				node_path,
				index_i,
				"Items state must be a UiArrayState resource.",
				"Pick a UiArrayState for Items state.",
			)
		)
	var key_st: Variant = rule.get(&"sort_key_state")
	if key_st == null:
		out.append(
			_wire_rules_issue(
				component,
				owner,
				node_path,
				index_i,
				"the sort key text state is missing.",
				"In the Inspector, assign Sort key state to a UiStringState resource.",
			)
		)
	elif not (key_st is UiStringState):
		out.append(
			_wire_rules_issue(
				component,
				owner,
				node_path,
				index_i,
				"Sort key state must be a UiStringState resource.",
				"Pick a UiStringState for Sort key state.",
			)
		)
	var desc_st: Variant = rule.get(&"descending_state")
	if desc_st != null and not (desc_st is UiBoolState):
		out.append(
			_wire_rules_issue(
				component,
				owner,
				node_path,
				index_i,
				"Descending state must be a UiBoolState when set.",
				"Assign a UiBoolState or clear Descending state.",
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
					"the sort key text is empty, so this rule will not reorder the list.",
					"Set Sort key state to a non-empty string (the field name to sort by).",
				)
			)
	return out


static func _validate_wire_rule_copy_detail(
	rule: UiReactWireCopySelectionDetail, component: String, owner: Control, node_path: NodePath, index_i: int
) -> Array[UiReactDiagnosticModel.DiagnosticIssue]:
	var out: Array[UiReactDiagnosticModel.DiagnosticIssue] = []
	if rule.detail_state == null:
		out.append(
			_wire_rules_issue(
				component,
				owner,
				node_path,
				index_i,
				"the detail text state is missing.",
				"In the Inspector, assign Detail state to a UiStringState resource.",
			)
		)
	elif not (rule.detail_state is UiStringState):
		out.append(
			_wire_rules_issue(
				component,
				owner,
				node_path,
				index_i,
				"Detail state must be a UiStringState resource.",
				"Pick a UiStringState for Detail state.",
			)
		)
	if rule.selected_state == null:
		out.append(
			_wire_rules_issue(
				component,
				owner,
				node_path,
				index_i,
				"the selected row index state is missing.",
				"In the Inspector, assign Selected state to a UiIntState resource.",
			)
		)
	elif not (rule.selected_state is UiIntState):
		out.append(
			_wire_rules_issue(
				component,
				owner,
				node_path,
				index_i,
				"Selected state must be a UiIntState resource.",
				"Pick a UiIntState for Selected state.",
			)
		)
	if rule.items_state != null and not (rule.items_state is UiArrayState):
		out.append(
			_wire_rules_issue(
				component,
				owner,
				node_path,
				index_i,
				"Items state must be a UiArrayState when set.",
				"Assign a UiArrayState or clear Items state.",
			)
		)
	if rule.suffix_note_state != null and not (rule.suffix_note_state is UiStringState):
		out.append(
			_wire_rules_issue(
				component,
				owner,
				node_path,
				index_i,
				"Suffix note state must be a UiStringState when set.",
				"Assign a UiStringState or clear Suffix note state.",
			)
		)
	_append_wire_text_len_issue(
		out, component, owner, node_path, index_i, rule.text_no_selection, "text_no_selection"
	)
	return out


static func _validate_wire_rule_bool_pulse(
	rule: UiReactWireSetStringOnBoolPulse, component: String, owner: Control, node_path: NodePath, index_i: int
) -> Array[UiReactDiagnosticModel.DiagnosticIssue]:
	var out: Array[UiReactDiagnosticModel.DiagnosticIssue] = []
	if rule.pulse_bool == null:
		out.append(
			_wire_rules_issue(
				component,
				owner,
				node_path,
				index_i,
				"the pulse bool state is missing.",
				"In the Inspector, assign Pulse bool to a UiBoolState resource.",
			)
		)
	elif not (rule.pulse_bool is UiBoolState):
		out.append(
			_wire_rules_issue(
				component,
				owner,
				node_path,
				index_i,
				"Pulse bool must be a UiBoolState resource.",
				"Pick a UiBoolState for Pulse bool.",
			)
		)
	if rule.target_string_state == null:
		out.append(
			_wire_rules_issue(
				component,
				owner,
				node_path,
				index_i,
				"the target text state is missing.",
				"In the Inspector, assign Target string state to a UiStringState resource.",
			)
		)
	elif not (rule.target_string_state is UiStringState):
		out.append(
			_wire_rules_issue(
				component,
				owner,
				node_path,
				index_i,
				"Target string state must be a UiStringState resource.",
				"Pick a UiStringState for Target string state.",
			)
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
				"this rule needs at least one non-empty template (rising edge or no-selection).",
				"In the Inspector, fill Template rising and/or Template no selection.",
			)
		)
	if has_no_sel:
		if rule.selected_state == null:
			out.append(
				_wire_rules_issue(
					component,
					owner,
					node_path,
					index_i,
					"Template no selection needs a selected row index state.",
					"Assign Selected state to a UiIntState used by your list.",
				)
			)
		elif not (rule.selected_state is UiIntState):
			out.append(
				_wire_rules_issue(
					component,
					owner,
					node_path,
					index_i,
					"Selected state must be a UiIntState resource.",
					"Pick a UiIntState for Selected state.",
				)
			)
		if rule.items_state == null:
			out.append(
				_wire_rules_issue(
					component,
					owner,
					node_path,
					index_i,
					"Template no selection needs the list items state.",
					"Assign Items state to a UiArrayState your rows come from.",
				)
			)
		elif not (rule.items_state is UiArrayState):
			out.append(
				_wire_rules_issue(
					component,
					owner,
					node_path,
					index_i,
					"Items state must be a UiArrayState resource.",
					"Pick a UiArrayState for Items state.",
				)
			)
	if rule.selected_state != null and not (rule.selected_state is UiIntState):
		out.append(
			_wire_rules_issue(
				component,
				owner,
				node_path,
				index_i,
				"Selected state must be a UiIntState when set.",
				"Assign a UiIntState or clear Selected state.",
			)
		)
	if rule.items_state != null and not (rule.items_state is UiArrayState):
		out.append(
			_wire_rules_issue(
				component,
				owner,
				node_path,
				index_i,
				"Items state must be a UiArrayState when set.",
				"Assign a UiArrayState or clear Items state.",
			)
		)
	_append_wire_text_len_issue(
		out, component, owner, node_path, index_i, rule.template_rising, "template_rising"
	)
	_append_wire_text_len_issue(
		out, component, owner, node_path, index_i, rule.template_no_selection, "template_no_selection"
	)
	return out


static func _validate_wire_rule_bool_debug_line(
	rule: UiReactWireSyncBoolStateDebugLine, component: String, owner: Control, node_path: NodePath, index_i: int
) -> Array[UiReactDiagnosticModel.DiagnosticIssue]:
	var out: Array[UiReactDiagnosticModel.DiagnosticIssue] = []
	if rule.bool_state == null:
		out.append(
			_wire_rules_issue(
				component,
				owner,
				node_path,
				index_i,
				"the bool state to mirror is missing.",
				"In the Inspector, assign Bool state to a UiBoolState resource.",
			)
		)
	elif not (rule.bool_state is UiBoolState):
		out.append(
			_wire_rules_issue(
				component,
				owner,
				node_path,
				index_i,
				"Bool state must be a UiBoolState resource.",
				"Pick a UiBoolState for Bool state.",
			)
		)
	if rule.target_string_state == null:
		out.append(
			_wire_rules_issue(
				component,
				owner,
				node_path,
				index_i,
				"the target text state is missing.",
				"In the Inspector, assign Target string state to a UiStringState resource.",
			)
		)
	elif not (rule.target_string_state is UiStringState):
		out.append(
			_wire_rules_issue(
				component,
				owner,
				node_path,
				index_i,
				"Target string state must be a UiStringState resource.",
				"Pick a UiStringState for Target string state.",
			)
		)
	_append_wire_text_len_issue(
		out, component, owner, node_path, index_i, rule.line_prefix, "line_prefix"
	)
	return out


static func _append_wire_text_len_issue(
	out: Array[UiReactDiagnosticModel.DiagnosticIssue],
	component: String,
	owner: Control,
	node_path: NodePath,
	index_i: int,
	value: String,
	field_name: String
) -> void:
	var t := value.strip_edges()
	if t.length() <= _WIRE_QUICK_EDIT_TEXT_MAX_LEN:
		return
	out.append(
		_wire_rules_issue(
			component,
			owner,
			node_path,
			index_i,
			"%s is longer than the quick-edit limit (%d characters)." % [field_name, _WIRE_QUICK_EDIT_TEXT_MAX_LEN],
			"Shorten that text in the Inspector, or edit it in an external file and paste a shorter snippet.",
		)
	)


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


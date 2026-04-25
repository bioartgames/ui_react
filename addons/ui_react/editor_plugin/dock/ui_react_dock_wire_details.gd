## Wire rules report for the dock details pane (static). Presentation matches [UiReactDockDetails] (bold label + value per line).
class_name UiReactDockWireDetails
extends Object

const _SCRIPT_SORT_ARRAY_BY_KEY := "res://addons/ui_react/scripts/api/models/ui_react_wire_sort_array_by_key.gd"
const _WIRE_RULE_INDEX_PATTERN := "^wire_rules\\[(\\d+)\\]:"

static var _wire_rule_index_re: RegEx


static func _wire_rule_index_regex() -> RegEx:
	if _wire_rule_index_re == null:
		_wire_rule_index_re = RegEx.create_from_string(_WIRE_RULE_INDEX_PATTERN)
	return _wire_rule_index_re


static func escape_bbcode_literal(s: String) -> String:
	return s.replace("[", "[lb]")


static func idle_placeholder_text() -> String:
	return "Pick a wire rule row above to see what it does, which states it uses, and how it runs on this control."


static func build_details_bbcode(
	rule: Variant, rule_index: int, host: Node, scene_root: Node
) -> String:
	var body := ""
	for row in _report_rows(rule, rule_index, host, scene_root):
		var lbl: String = row[&"label"]
		var val: String = row[&"value"]
		body += "[b]%s[/b]: %s\n" % [lbl, escape_bbcode_literal(val)]
	return body


static func build_details_plain_text(
	rule: Variant, rule_index: int, host: Node, scene_root: Node
) -> String:
	var lines: PackedStringArray = []
	for row in _report_rows(rule, rule_index, host, scene_root):
		lines.append("%s: %s" % [row[&"label"], row[&"value"]])
	return "\n".join(lines)


static func _report_rows(
	rule: Variant, rule_index: int, host: Node, scene_root: Node
) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	rows.append({&"label": &"Rule", &"value": _val_rule(rule, rule_index)})
	rows.append({&"label": &"Order", &"value": _val_order(rule_index, host)})
	rows.append({&"label": &"Enabled", &"value": _val_enabled(rule)})
	rows.append({&"label": &"Trigger", &"value": _val_trigger(rule)})
	if host == null:
		rows.append({&"label": &"Node", &"value": "—"})
		rows.append({&"label": &"Path", &"value": "—"})
	else:
		rows.append({&"label": &"Node", &"value": str(host.name)})
		rows.append({&"label": &"Path", &"value": _val_host_path(host, scene_root)})
	rows.append({&"label": &"Intent and Runtime", &"value": _val_intent_and_runtime(rule, host)})
	rows.append({&"label": &"Inputs", &"value": _val_inputs(rule)})
	rows.append({&"label": &"Outputs", &"value": _val_outputs(rule)})
	rows.append({&"label": &"Checks", &"value": _validation_row_from_validator(rule_index, host, scene_root)})
	return rows


static func _val_order(rule_index: int, host: Node) -> String:
	if rule_index < 0:
		return "—"
	if host == null or not (&"wire_rules" in host):
		return "%d" % (rule_index + 1)
	var wr: Variant = host.get(&"wire_rules")
	var arr: Array = wr as Array if wr is Array else []
	if arr.is_empty():
		return "%d" % (rule_index + 1)
	return "%d of %d" % [rule_index + 1, arr.size()]


static func _val_rule(rule: Variant, rule_index: int) -> String:
	if rule == null:
		return "(null slot) at index %d" % rule_index
	if rule is UiReactWireRule:
		var r := rule as UiReactWireRule
		var cls := _rule_class_name(r)
		var rid := r.rule_id.strip_edges()
		if rid.is_empty():
			rid = "—"
		return "%s · index %d · %s" % [cls, rule_index, rid]
	return "—"


static func _val_enabled(rule: Variant) -> String:
	if rule is UiReactWireRule:
		return str((rule as UiReactWireRule).enabled)
	return "—"


static func _val_trigger(rule: Variant) -> String:
	if rule is UiReactWireRule:
		return _trigger_label((rule as UiReactWireRule).trigger)
	return "—"


static func _val_host_path(host: Node, scene_root: Node) -> String:
	if scene_root == null:
		return "—"
	var rel := scene_root.get_path_to(host)
	var rs := String(rel)
	if rs == "." or rel.is_empty():
		return "(scene root)"
	return rs


static func _val_intent(rule: Variant, host: Node) -> String:
	if rule == null:
		return "—"
	if rule is UiReactWireMapIntToString:
		return (
			"Shows a label string (and optional hint) from the current index on lists, tabs, or option menus. "
			+ "Reads the control’s selection and your int-to-string map."
		)
	if rule is UiReactWireRefreshItemsFromCatalog:
		return (
			"Rebuilds the item list from your catalog using filter text and optional category, then keeps the selection sensible."
		)
	if rule is UiReactWireCopySelectionDetail:
		return (
			"Fills a detail line from the selected row (and optional suffix), using the list or tab’s stored rows."
		)
	if rule is UiReactWireSetStringOnBoolPulse:
		return (
			"Writes templated text into a string state when a bool pulses, optionally pulling fields from the selected row."
		)
	if rule is UiReactWireSyncBoolStateDebugLine:
		return "Keeps a short debug string in sync with a bool (prefix plus on/off text)."
	if _is_sort_array_by_key(rule):
		return "Sorts the items array by a named field (or plain text for non-dictionary rows), with optional descending order."
	return "—"


static func _val_intent_and_runtime(rule: Variant, host: Node) -> String:
	var intent := _val_intent(rule, host)
	var runtime := _val_runtime(rule, host)
	if intent == "—" and runtime == "—":
		return "—"
	if runtime == "—":
		return intent
	if intent == "—":
		return runtime
	return "%s\n%s" % [intent, runtime]


static func _val_inputs(rule: Variant) -> String:
	var lines: PackedStringArray = []
	if rule == null:
		return "—"
	if rule is UiReactWireMapIntToString:
		var r := rule as UiReactWireMapIntToString
		lines.append("- source_int_state: %s" % _state_ref_plain(r.source_int_state))
		lines.append("- index_to_string: %s" % _dict_summary_plain(r.index_to_string, 8))
		lines.append("- hint_labels_by_index: %s" % _dict_summary_plain(r.hint_labels_by_index, 8))
	elif rule is UiReactWireRefreshItemsFromCatalog:
		var r := rule as UiReactWireRefreshItemsFromCatalog
		lines.append("- filter_text_state: %s" % _state_ref_plain(r.filter_text_state))
		lines.append("- category_kind_state: %s" % _state_ref_plain(r.category_kind_state))
		lines.append("- catalog: %s" % _resource_ref_plain(r.catalog))
		lines.append("- first_row_icon_path: %s" % _str_or_dash_plain(r.first_row_icon_path))
	elif rule is UiReactWireCopySelectionDetail:
		var r := rule as UiReactWireCopySelectionDetail
		lines.append("- selected_state: %s" % _state_ref_plain(r.selected_state))
		lines.append("- items_state: %s" % _state_ref_plain(r.items_state))
		lines.append("- suffix_note_state: %s" % _state_ref_plain(r.suffix_note_state))
		lines.append("- text_no_selection: %s" % _str_or_dash_plain(r.text_no_selection))
		lines.append("- clear_suffix_on_selection_change: %s" % str(r.clear_suffix_on_selection_change))
	elif rule is UiReactWireSetStringOnBoolPulse:
		var r := rule as UiReactWireSetStringOnBoolPulse
		lines.append("- pulse_bool: %s" % _state_ref_plain(r.pulse_bool))
		lines.append("- selected_state: %s" % _state_ref_plain(r.selected_state))
		lines.append("- items_state: %s" % _state_ref_plain(r.items_state))
		lines.append("- template_rising: %s" % _str_or_dash_plain(r.template_rising))
		lines.append("- template_no_selection: %s" % _str_or_dash_plain(r.template_no_selection))
		lines.append("- require_rising_edge: %s" % str(r.require_rising_edge))
	elif rule is UiReactWireSyncBoolStateDebugLine:
		var r := rule as UiReactWireSyncBoolStateDebugLine
		lines.append("- bool_state: %s" % _state_ref_plain(r.bool_state))
		lines.append("- line_prefix: %s" % _str_or_dash_plain(r.line_prefix))
	elif _is_sort_array_by_key(rule):
		var r_sort: UiReactWireSortArrayByKey = rule as UiReactWireSortArrayByKey
		lines.append("- items_state: %s" % _state_ref_plain(r_sort.items_state))
		lines.append("- sort_key_state: %s" % _state_ref_plain(r_sort.sort_key_state))
		lines.append("- descending_state: %s" % _state_ref_plain(r_sort.descending_state))
	else:
		return "—"
	return "\n".join(lines)


static func _val_outputs(rule: Variant) -> String:
	var lines: PackedStringArray = []
	if rule == null:
		return "—"
	if rule is UiReactWireMapIntToString:
		var r := rule as UiReactWireMapIntToString
		lines.append("- target_string_state: %s" % _state_ref_plain(r.target_string_state))
		lines.append("- hint_state: %s" % _state_ref_plain(r.hint_state))
	elif rule is UiReactWireRefreshItemsFromCatalog:
		var r := rule as UiReactWireRefreshItemsFromCatalog
		lines.append("- items_state: %s" % _state_ref_plain(r.items_state))
		lines.append("- selected_state: %s" % _state_ref_plain(r.selected_state))
	elif rule is UiReactWireCopySelectionDetail:
		var r := rule as UiReactWireCopySelectionDetail
		lines.append("- detail_state: %s" % _state_ref_plain(r.detail_state))
	elif rule is UiReactWireSetStringOnBoolPulse:
		var r := rule as UiReactWireSetStringOnBoolPulse
		lines.append("- target_string_state: %s" % _state_ref_plain(r.target_string_state))
	elif rule is UiReactWireSyncBoolStateDebugLine:
		var r := rule as UiReactWireSyncBoolStateDebugLine
		lines.append("- target_string_state: %s" % _state_ref_plain(r.target_string_state))
	elif _is_sort_array_by_key(rule):
		lines.append(
			"- items_state (reordered in place): %s"
			% _state_ref_plain((rule as UiReactWireSortArrayByKey).items_state)
		)
	else:
		return "—"
	return "\n".join(lines)


static func _val_runtime(rule: Variant, host: Node) -> String:
	var lines: PackedStringArray = []
	if rule == null:
		return "—"
	if rule is UiReactWireMapIntToString:
		var r := rule as UiReactWireMapIntToString
		lines.append(
			"- Listens for selection changes on supported controls and when the source int state changes."
		)
		if r.trigger != UiReactWireRule.TriggerKind.SELECTION_CHANGED:
			lines.append(
				"- Note: this rule type expects Trigger set to selection changed; other triggers are warned in Checks."
			)
	elif rule is UiReactWireRefreshItemsFromCatalog:
		lines.append(
			"- Listens for the right control signals for its trigger, and when filter or category text changes."
		)
	elif _is_sort_array_by_key(rule):
		lines.append(
			"- Runs when items, sort key, or descending bool change; the trigger field does not drive binding for this rule."
		)
	elif rule is UiReactWireCopySelectionDetail:
		lines.append(
			"- When selection changes, it may clear the suffix first if you enabled that option, then rebuild the line."
		)
		lines.append("- Also reacts when the items list or suffix note state changes.")
	elif rule is UiReactWireSetStringOnBoolPulse:
		lines.append(
			"- Listens for changes on the pulse bool; the rule’s main work runs on that pulse, not on a generic apply step."
		)
	elif rule is UiReactWireSyncBoolStateDebugLine:
		lines.append("- Runs when the control attaches and whenever the watched bool changes.")
	else:
		return "—"
	if rule is UiReactWireRule:
		lines.append(
			"- Rule order on this control matters (for example, sort the list before copying detail text from it)."
		)
	return "\n".join(lines)


## Filters [UiReactWiringValidator] issues to one [code]wire_rules[/code] index ([param issue_text] prefix [code]wire_rules[N]:[/code]).
static func filter_wire_rule_issues_by_index(
	issues: Array, rule_index: int
) -> Array[UiReactDiagnosticModel.DiagnosticIssue]:
	var out: Array[UiReactDiagnosticModel.DiagnosticIssue] = []
	var rx := _wire_rule_index_regex()
	for it: Variant in issues:
		if it is not UiReactDiagnosticModel.DiagnosticIssue:
			continue
		var issue := it as UiReactDiagnosticModel.DiagnosticIssue
		var m := rx.search(issue.issue_text)
		if m == null:
			continue
		if int(m.get_string(1)) == rule_index:
			out.append(issue)
	return out


## Multi-line bullets for the details pane; same [member UiReactDiagnosticModel.DiagnosticIssue.issue_text] as Diagnostics.
static func format_wire_rule_diagnostic_issues(issues: Array) -> String:
	if issues.is_empty():
		return "—"
	var lines: PackedStringArray = []
	for it: Variant in issues:
		if it is not UiReactDiagnosticModel.DiagnosticIssue:
			continue
		var issue := it as UiReactDiagnosticModel.DiagnosticIssue
		lines.append("- %s" % issue.issue_text)
		var hint := issue.fix_hint.strip_edges()
		if not hint.is_empty():
			lines.append("  Fix: %s" % hint)
	return "\n".join(lines)


static func _validation_row_from_validator(rule_index: int, host: Node, scene_root: Node) -> String:
	if host == null or scene_root == null or not (host is Control):
		return "—"
	var owner := host as Control
	if not owner.is_inside_tree():
		return "—"
	var node_path := scene_root.get_path_to(owner)
	var component := UiReactScannerService.get_component_name_from_script(owner.get_script() as Script)
	var all := UiReactWiringValidator.validate_wire_rules(component, owner, node_path)
	var filtered: Array = filter_wire_rule_issues_by_index(all, rule_index)
	return format_wire_rule_diagnostic_issues(filtered)


static func _rule_class_name(r: UiReactWireRule) -> String:
	var sc: Script = r.get_script() as Script
	if sc == null:
		return "UiReactWireRule"
	var gn := String(sc.get_global_name())
	if not gn.is_empty():
		return gn
	return sc.resource_path.get_file().get_basename()


static func _trigger_label(t: int) -> String:
	match t:
		UiReactWireRule.TriggerKind.TEXT_CHANGED:
			return "TEXT_CHANGED — storage %d" % int(UiReactWireRule.TriggerKind.TEXT_CHANGED)
		UiReactWireRule.TriggerKind.SELECTION_CHANGED:
			return "SELECTION_CHANGED — storage %d" % int(UiReactWireRule.TriggerKind.SELECTION_CHANGED)
		UiReactWireRule.TriggerKind.TEXT_ENTERED:
			return "TEXT_ENTERED — storage %d" % int(UiReactWireRule.TriggerKind.TEXT_ENTERED)
		_:
			return str(t)


static func _state_ref_plain(st: Variant) -> String:
	if st == null:
		return "(missing)"
	if st is Resource:
		return "%s (set)" % _resource_type_name(st as Resource)
	return str(st)


static func _resource_ref_plain(res: Resource) -> String:
	if res == null:
		return "(missing)"
	var tn := _resource_type_name(res)
	var path := res.resource_path
	if not path.is_empty():
		return "%s · %s" % [tn, path.get_file()]
	return "%s (set)" % tn


static func _resource_type_name(res: Resource) -> String:
	var sc: Script = res.get_script() as Script
	if sc != null:
		var gn := String(sc.get_global_name())
		if not gn.is_empty():
			return gn
	return res.get_class()


static func _str_or_dash_plain(s: String) -> String:
	var t := s.strip_edges()
	if t.is_empty():
		return "—"
	return t


static func _dict_summary_plain(d: Dictionary, max_keys: int) -> String:
	if d.is_empty():
		return "— (empty)"
	var keys := d.keys()
	var n := mini(keys.size(), max_keys)
	var parts: PackedStringArray = []
	for i in range(n):
		parts.append("%s → %s" % [str(keys[i]), str(d[keys[i]])])
	var out := ", ".join(parts)
	if keys.size() > max_keys:
		out += " …"
	return out


static func _is_sort_array_by_key(rule: Variant) -> bool:
	if not (rule is UiReactWireRule):
		return false
	var sc: Script = (rule as UiReactWireRule).get_script() as Script
	return sc != null and sc.resource_path == _SCRIPT_SORT_ARRAY_BY_KEY

## Wire rules report for the dock details pane (static). Presentation matches [UiReactDockDetails] (bold label + value per line).
class_name UiReactDockWireDetails
extends Object

const _SCRIPT_SORT_ARRAY_BY_KEY := "res://addons/ui_react/scripts/api/models/ui_react_wire_sort_array_by_key.gd"


static func escape_bbcode_literal(s: String) -> String:
	return s.replace("[", "[lb]")


static func idle_placeholder_text() -> String:
	return "Select a rule above to view its wiring story: intent, states, runtime bindings, and validation."


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
	rows.append({&"label": &"Enabled", &"value": _val_enabled(rule)})
	rows.append({&"label": &"Trigger", &"value": _val_trigger(rule)})
	if host == null:
		rows.append({&"label": &"Node", &"value": "—"})
		rows.append({&"label": &"Path", &"value": "—"})
	else:
		rows.append({&"label": &"Node", &"value": str(host.name)})
		rows.append({&"label": &"Path", &"value": _val_host_path(host, scene_root)})
	rows.append({&"label": &"Intent", &"value": _val_intent(rule, host)})
	rows.append({&"label": &"Inputs", &"value": _val_inputs(rule)})
	rows.append({&"label": &"Outputs", &"value": _val_outputs(rule)})
	rows.append({&"label": &"Runtime notes", &"value": _val_runtime(rule, host)})
	rows.append({&"label": &"Validation warnings", &"value": _val_validation(rule)})
	return rows


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
		var hcls := host.get_class() if host else "—"
		return (
			"Map an integer source (tree/tab/option index) to a kind string and optional hint line. "
			+ "Host control: %s." % hcls
		)
	if rule is UiReactWireRefreshItemsFromCatalog:
		return "Rebuild item rows from catalog using filter text and optional category; normalize selection index."
	if rule is UiReactWireCopySelectionDetail:
		return "Format detail text from list/tab selection and row payloads; optional suffix line."
	if rule is UiReactWireSetStringOnBoolPulse:
		return "On bool pulse, write templated text using selected row placeholders."
	if rule is UiReactWireSyncBoolStateDebugLine:
		return "Mirror a bool into a debug string line (prefix + value)."
	if _is_sort_array_by_key(rule):
		return "Sort array rows by a dictionary key (or str compare for non-dict rows); optional descending."
	return "—"


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
		var hcls := host.get_class() if host else "—"
		lines.append(
			(
				"- Host class %s: helper binds selection signals when the control supports them "
				+ "(Tree / OptionButton / TabContainer) and source_int_state.changed."
			)
			% hcls
		)
		if r.trigger != UiReactWireRule.TriggerKind.SELECTION_CHANGED:
			lines.append("- Note: helper warns when trigger is not SELECTION_CHANGED for MapIntToString.")
	elif rule is UiReactWireRefreshItemsFromCatalog:
		lines.append(
			"- Helper binds trigger-appropriate host signals plus filter_text_state and category_kind_state changes."
		)
	elif _is_sort_array_by_key(rule):
		lines.append(
			"- State-driven only: items_state, sort_key_state, descending_state changed (trigger ignored for binding)."
		)
	elif rule is UiReactWireCopySelectionDetail:
		lines.append(
			"- On selection path, suffix may clear before recompute when clear_suffix_on_selection_change is true."
		)
		lines.append("- Also listens to items_state and suffix_note_state changes.")
	elif rule is UiReactWireSetStringOnBoolPulse:
		lines.append(
			"- Bound to pulse_bool value_changed; apply() is a no-op, work happens in apply_from_pulse()."
		)
	elif rule is UiReactWireSyncBoolStateDebugLine:
		lines.append("- Runs once at attach and on bool_state value_changed when bool_state is set.")
	else:
		return "—"
	if rule is UiReactWireRule:
		lines.append(
			"- Rule order in wire_rules matters (e.g. sort before copy-detail on the same host; see WIRING_LAYER.md §6)."
		)
	return "\n".join(lines)


static func _val_validation(rule: Variant) -> String:
	var warns: PackedStringArray = []
	if rule == null:
		return "Null slot: runner skips this index; remove or assign a UiReactWireRule resource."
	if not (rule is UiReactWireRule):
		return "Value is not a UiReactWireRule."
	var r := rule as UiReactWireRule
	if not r.enabled:
		warns.append("Rule is disabled; helper skips binding and apply.")
	if rule is UiReactWireMapIntToString:
		var m := rule as UiReactWireMapIntToString
		if m.source_int_state == null:
			warns.append("source_int_state is missing; apply() returns early.")
		if m.target_string_state == null:
			warns.append("target_string_state is missing; apply() returns early.")
	elif rule is UiReactWireRefreshItemsFromCatalog:
		var rr := rule as UiReactWireRefreshItemsFromCatalog
		if rr.items_state == null or rr.catalog == null:
			warns.append("items_state or catalog is missing; apply() returns early.")
	elif rule is UiReactWireCopySelectionDetail:
		var c := rule as UiReactWireCopySelectionDetail
		if c.detail_state == null or c.selected_state == null:
			warns.append("detail_state or selected_state is missing; apply() returns early.")
	elif rule is UiReactWireSetStringOnBoolPulse:
		var p := rule as UiReactWireSetStringOnBoolPulse
		if p.pulse_bool == null:
			warns.append("pulse_bool is missing; helper does not bind.")
		if p.target_string_state == null:
			warns.append("target_string_state is missing; apply_from_pulse() returns early.")
		var tr := p.template_rising.strip_edges()
		var tn := p.template_no_selection.strip_edges()
		if tr.is_empty() and tn.is_empty():
			warns.append("Both template strings are empty; output may be blank.")
	elif rule is UiReactWireSyncBoolStateDebugLine:
		var s := rule as UiReactWireSyncBoolStateDebugLine
		if s.target_string_state == null:
			warns.append("target_string_state is missing; apply() returns early.")
	elif _is_sort_array_by_key(rule):
		var srt := rule as UiReactWireSortArrayByKey
		if srt.items_state == null or srt.sort_key_state == null:
			warns.append("items_state or sort_key_state is missing; apply() returns early.")
		else:
			var key := srt.sort_key_state.get_string_value().strip_edges()
			if key.is_empty():
				warns.append("sort_key_state is empty after trim; apply() no-ops (no reorder).")
	if warns.is_empty():
		return "—"
	return "\n".join(warns)


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
			return "TEXT_CHANGED (5)"
		UiReactWireRule.TriggerKind.SELECTION_CHANGED:
			return "SELECTION_CHANGED (6)"
		UiReactWireRule.TriggerKind.TEXT_ENTERED:
			return "TEXT_ENTERED (13)"
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

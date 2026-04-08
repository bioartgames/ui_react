## Wire rules report BBCode for the dock details pane (static). Mirrors [UiReactDockDetails] role for diagnostics.
class_name UiReactDockWireDetails
extends Object

const _SCRIPT_SORT_ARRAY_BY_KEY := "res://addons/ui_react/scripts/api/models/ui_react_wire_sort_array_by_key.gd"


static func escape_bbcode_literal(s: String) -> String:
	return s.replace("[", "[lb]")


static func idle_placeholder_text() -> String:
	return "Select a rule above to view its wiring story: intent, states, runtime bindings, and validation."


## [param scene_root] Edited scene root (for a stable relative path); if null, Host path line is [code]—[/code].
static func build_details_bbcode(
	rule: Variant, rule_index: int, host: Node, scene_root: Node
) -> String:
	var body := ""
	body += _sec_rule(rule, rule_index)
	body += _sec_enabled_trigger(rule)
	body += _sec_host(host, scene_root)
	body += _sec_intent(rule, host)
	body += _sec_inputs(rule)
	body += _sec_outputs(rule)
	body += _sec_runtime(rule, host)
	body += _sec_validation(rule)
	return body


static func _sec_rule(rule: Variant, rule_index: int) -> String:
	var line := "—"
	if rule == null:
		line = "[i](null slot)[/i] at index %d" % rule_index
	elif rule is UiReactWireRule:
		var r := rule as UiReactWireRule
		var cls := _rule_class_name(r)
		var rid := r.rule_id.strip_edges()
		if rid.is_empty():
			rid = "—"
		line = "%s · index %d · [code]%s[/code]" % [cls, rule_index, escape_bbcode_literal(rid)]
	return "[b]Rule[/b]\n%s\n\n" % line


static func _sec_enabled_trigger(rule: Variant) -> String:
	var line := "—"
	if rule is UiReactWireRule:
		var r := rule as UiReactWireRule
		line = "%s · %s" % [str(r.enabled), _trigger_label(r.trigger)]
	return "[b]Enabled / Trigger[/b]\n%s\n\n" % line


static func _sec_host(host: Node, scene_root: Node) -> String:
	if host == null:
		return "[b]Host[/b]\n—\n\n"
	var name_part := host.name
	var path_part := "—"
	if scene_root != null:
		var rel := scene_root.get_path_to(host)
		var rs := String(rel)
		if rs == "." or rel.is_empty():
			path_part = "(scene root)"
		else:
			path_part = escape_bbcode_literal(rs)
	var line := "[b]%s[/b] · %s" % [escape_bbcode_literal(name_part), path_part]
	return "[b]Host[/b]\n%s\n\n" % line


static func _sec_intent(rule: Variant, host: Node) -> String:
	var line := "—"
	if rule == null:
		line = "—"
	elif rule is UiReactWireMapIntToString:
		var hcls := host.get_class() if host else "—"
		line = (
			"Map an integer source (tree/tab/option index) to a kind string and optional hint line. "
			+ "Host control: [code]%s[/code]."
			% escape_bbcode_literal(hcls)
		)
	elif rule is UiReactWireRefreshItemsFromCatalog:
		line = "Rebuild item rows from catalog using filter text and optional category; normalize selection index."
	elif rule is UiReactWireCopySelectionDetail:
		line = "Format detail text from list/tab selection and row payloads; optional suffix line."
	elif rule is UiReactWireSetStringOnBoolPulse:
		line = "On bool pulse, write templated text using selected row placeholders."
	elif rule is UiReactWireSyncBoolStateDebugLine:
		line = "Mirror a bool into a debug string line (prefix + value)."
	elif _is_sort_array_by_key(rule):
		line = "Sort array rows by a dictionary key (or str compare for non-dict rows); optional descending."
	else:
		line = "—"
	return "[b]Intent[/b]\n%s\n\n" % line


static func _sec_inputs(rule: Variant) -> String:
	var lines: PackedStringArray = []
	if rule == null:
		lines.append("—")
	elif rule is UiReactWireMapIntToString:
		var r := rule as UiReactWireMapIntToString
		lines.append("- source_int_state: %s" % _state_ref(r.source_int_state))
		lines.append(
			"- index_to_string: %s" % _dict_summary(r.index_to_string, 8)
		)
		lines.append(
			"- hint_labels_by_index: %s" % _dict_summary(r.hint_labels_by_index, 8)
		)
	elif rule is UiReactWireRefreshItemsFromCatalog:
		var r := rule as UiReactWireRefreshItemsFromCatalog
		lines.append("- filter_text_state: %s" % _state_ref(r.filter_text_state))
		lines.append("- category_kind_state: %s" % _state_ref(r.category_kind_state))
		lines.append("- catalog: %s" % _resource_ref(r.catalog))
		lines.append("- first_row_icon_path: %s" % _str_or_dash(r.first_row_icon_path))
	elif rule is UiReactWireCopySelectionDetail:
		var r := rule as UiReactWireCopySelectionDetail
		lines.append("- selected_state: %s" % _state_ref(r.selected_state))
		lines.append("- items_state: %s" % _state_ref(r.items_state))
		lines.append("- suffix_note_state: %s" % _state_ref(r.suffix_note_state))
		lines.append("- text_no_selection: %s" % _str_or_dash(r.text_no_selection))
		lines.append(
			"- clear_suffix_on_selection_change: %s" % str(r.clear_suffix_on_selection_change)
		)
	elif rule is UiReactWireSetStringOnBoolPulse:
		var r := rule as UiReactWireSetStringOnBoolPulse
		lines.append("- pulse_bool: %s" % _state_ref(r.pulse_bool))
		lines.append("- selected_state: %s" % _state_ref(r.selected_state))
		lines.append("- items_state: %s" % _state_ref(r.items_state))
		lines.append("- template_rising: %s" % _str_or_dash(r.template_rising))
		lines.append("- template_no_selection: %s" % _str_or_dash(r.template_no_selection))
		lines.append("- require_rising_edge: %s" % str(r.require_rising_edge))
	elif rule is UiReactWireSyncBoolStateDebugLine:
		var r := rule as UiReactWireSyncBoolStateDebugLine
		lines.append("- bool_state: %s" % _state_ref(r.bool_state))
		lines.append("- line_prefix: %s" % _str_or_dash(r.line_prefix))
	elif _is_sort_array_by_key(rule):
		var r_sort: UiReactWireSortArrayByKey = rule as UiReactWireSortArrayByKey
		lines.append("- items_state: %s" % _state_ref(r_sort.items_state))
		lines.append("- sort_key_state: %s" % _state_ref(r_sort.sort_key_state))
		lines.append("- descending_state: %s" % _state_ref(r_sort.descending_state))
	else:
		lines.append("—")
	return "[b]Inputs / States[/b]\n%s\n\n" % "\n".join(lines)


static func _sec_outputs(rule: Variant) -> String:
	var lines: PackedStringArray = []
	if rule == null:
		lines.append("—")
	elif rule is UiReactWireMapIntToString:
		var r := rule as UiReactWireMapIntToString
		lines.append("- target_string_state: %s" % _state_ref(r.target_string_state))
		lines.append("- hint_state: %s" % _state_ref(r.hint_state))
	elif rule is UiReactWireRefreshItemsFromCatalog:
		var r := rule as UiReactWireRefreshItemsFromCatalog
		lines.append("- items_state: %s" % _state_ref(r.items_state))
		lines.append("- selected_state: %s" % _state_ref(r.selected_state))
	elif rule is UiReactWireCopySelectionDetail:
		var r := rule as UiReactWireCopySelectionDetail
		lines.append("- detail_state: %s" % _state_ref(r.detail_state))
	elif rule is UiReactWireSetStringOnBoolPulse:
		var r := rule as UiReactWireSetStringOnBoolPulse
		lines.append("- target_string_state: %s" % _state_ref(r.target_string_state))
	elif rule is UiReactWireSyncBoolStateDebugLine:
		var r := rule as UiReactWireSyncBoolStateDebugLine
		lines.append("- target_string_state: %s" % _state_ref(r.target_string_state))
	elif _is_sort_array_by_key(rule):
		lines.append("- items_state (reordered in place): %s" % _state_ref((rule as UiReactWireSortArrayByKey).items_state))
	else:
		lines.append("—")
	return "[b]Outputs / Targets[/b]\n%s\n\n" % "\n".join(lines)


static func _sec_runtime(rule: Variant, host: Node) -> String:
	var lines: PackedStringArray = []
	if rule == null:
		lines.append("—")
	elif rule is UiReactWireMapIntToString:
		var r := rule as UiReactWireMapIntToString
		var hcls := host.get_class() if host else "—"
		lines.append(
			"- Host class [code]%s[/code]: helper binds selection signals when the control supports them (Tree / OptionButton / TabContainer) and source_int_state.changed."
			% escape_bbcode_literal(hcls)
		)
		if r.trigger != UiReactWireRule.TriggerKind.SELECTION_CHANGED:
			lines.append(
				"- [i]Note:[/i] Helper warns when trigger is not SELECTION_CHANGED for MapIntToString."
			)
	elif rule is UiReactWireRefreshItemsFromCatalog:
		lines.append("- Helper binds trigger-appropriate host signals plus filter_text_state and category_kind_state changes.")
	elif _is_sort_array_by_key(rule):
		lines.append(
			"- State-driven only: items_state, sort_key_state, descending_state [code]changed[/code] (trigger ignored for binding)."
		)
	elif rule is UiReactWireCopySelectionDetail:
		var r := rule as UiReactWireCopySelectionDetail
		lines.append(
			"- On selection path, suffix may clear before recompute when clear_suffix_on_selection_change is true."
		)
		lines.append("- Also listens to items_state and suffix_note_state changes.")
	elif rule is UiReactWireSetStringOnBoolPulse:
		lines.append(
			"- Bound to pulse_bool [code]value_changed[/code]; apply() is a no-op, work happens in apply_from_pulse()."
		)
	elif rule is UiReactWireSyncBoolStateDebugLine:
		lines.append(
			"- Runs once at attach and on bool_state value_changed when bool_state is set."
		)
	else:
		lines.append("—")
	if rule is UiReactWireRule and rule != null:
		lines.append(
			"- Rule order in [code]wire_rules[/code] matters (e.g. sort before copy-detail on the same host; see WIRING_LAYER.md §6)."
		)
	return "[b]Runtime notes[/b]\n%s\n\n" % "\n".join(lines)


static func _sec_validation(rule: Variant) -> String:
	var warns: PackedStringArray = []
	if rule == null:
		warns.append("Null slot: runner skips this index; remove or assign a UiReactWireRule resource.")
		return "[b]Validation warnings[/b]\n%s\n" % "\n".join(warns)
	if not (rule is UiReactWireRule):
		warns.append("Value is not a UiReactWireRule.")
		return "[b]Validation warnings[/b]\n%s\n" % "\n".join(warns)
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
		warns.append("—")
	return "[b]Validation warnings[/b]\n%s\n" % "\n".join(warns)


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


static func _state_ref(st: Variant) -> String:
	if st == null:
		return "[i](missing)[/i]"
	if st is Resource:
		return "%s [i](set)[/i]" % _resource_type_name(st as Resource)
	return str(st)


static func _resource_ref(res: Resource) -> String:
	if res == null:
		return "[i](missing)[/i]"
	var tn := _resource_type_name(res)
	var path := res.resource_path
	if not path.is_empty():
		return "%s · %s" % [tn, escape_bbcode_literal(path.get_file())]
	return "%s [i](set)[/i]" % tn


static func _resource_type_name(res: Resource) -> String:
	var sc: Script = res.get_script() as Script
	if sc != null:
		var gn := String(sc.get_global_name())
		if not gn.is_empty():
			return gn
	return res.get_class()


static func _str_or_dash(s: String) -> String:
	var t := s.strip_edges()
	if t.is_empty():
		return "—"
	return escape_bbcode_literal(t)


static func _dict_summary(d: Dictionary, max_keys: int) -> String:
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
	return escape_bbcode_literal(out)


static func _is_sort_array_by_key(rule: Variant) -> bool:
	if not (rule is UiReactWireRule):
		return false
	var sc: Script = (rule as UiReactWireRule).get_script() as Script
	return sc != null and sc.resource_path == _SCRIPT_SORT_ARRAY_BY_KEY

## Single switch for [UiReactWireRule] state references ([b]in[/b] / [b]out[/b]) — shared by collector and explain graph.
class_name UiReactWireRuleIntrospection
extends RefCounted

const _SCRIPT_WIRE_SORT_ARRAY_BY_KEY := "res://addons/ui_react/scripts/api/models/ui_react_wire_sort_array_by_key.gd"


## Returns [code]{ "role": "in"|"out", "state": UiState }[/code] dictionaries (state may be null; skip at call sites).
static func list_io(rule: UiReactWireRule) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if rule == null:
		return out
	if rule is UiReactWireMapIntToString:
		var r := rule as UiReactWireMapIntToString
		out.append(_pair(&"in", r.source_int_state))
		out.append(_pair(&"in", r.hint_state))
		out.append(_pair(&"out", r.target_string_state))
	elif rule is UiReactWireRefreshItemsFromCatalog:
		var r2 := rule as UiReactWireRefreshItemsFromCatalog
		out.append(_pair(&"in", r2.filter_text_state))
		out.append(_pair(&"in", r2.category_kind_state))
		out.append(_pair(&"in", r2.selected_state))
		out.append(_pair(&"out", r2.items_state))
	elif _is_wire_sort_array_by_key(rule):
		out.append(_pair(&"in", rule.get(&"items_state") as UiState))
		out.append(_pair(&"in", rule.get(&"sort_key_state") as UiState))
		out.append(_pair(&"in", rule.get(&"descending_state") as UiState))
		out.append(_pair(&"out", rule.get(&"items_state") as UiState))
	elif rule is UiReactWireCopySelectionDetail:
		var r3 := rule as UiReactWireCopySelectionDetail
		out.append(_pair(&"in", r3.selected_state))
		out.append(_pair(&"in", r3.items_state))
		out.append(_pair(&"out", r3.detail_state))
		out.append(_pair(&"out", r3.suffix_note_state))
	elif rule is UiReactWireSetStringOnBoolPulse:
		var r4 := rule as UiReactWireSetStringOnBoolPulse
		out.append(_pair(&"in", r4.pulse_bool))
		out.append(_pair(&"in", r4.selected_state))
		out.append(_pair(&"in", r4.items_state))
		out.append(_pair(&"out", r4.target_string_state))
	elif rule is UiReactWireSyncBoolStateDebugLine:
		var r5 := rule as UiReactWireSyncBoolStateDebugLine
		out.append(_pair(&"in", r5.bool_state))
		out.append(_pair(&"out", r5.target_string_state))
	return out


static func _pair(role: StringName, state: UiState) -> Dictionary:
	return {&"role": role, &"state": state}


static func _is_wire_sort_array_by_key(rule: UiReactWireRule) -> bool:
	var sc: Script = rule.get_script() as Script
	return sc != null and sc.resource_path == _SCRIPT_WIRE_SORT_ARRAY_BY_KEY

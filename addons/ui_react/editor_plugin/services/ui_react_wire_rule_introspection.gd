## Single switch for [UiReactWireRule] state references ([b]in[/b] / [b]out[/b]) — shared by collector and explain graph.
class_name UiReactWireRuleIntrospection
extends RefCounted


## Returns [code]{ "role": "in"|"out", "state": UiState, "property": StringName }[/code] dictionaries (state may be null; skip at call sites).
static func list_io(rule: UiReactWireRule) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if rule == null:
		return out
	if rule is UiReactWireMapIntToString:
		var r := rule as UiReactWireMapIntToString
		out.append(_entry(&"in", r.source_int_state, &"source_int_state"))
		out.append(_entry(&"in", r.hint_state, &"hint_state"))
		out.append(_entry(&"out", r.target_string_state, &"target_string_state"))
	elif rule is UiReactWireRefreshItemsFromCatalog:
		var r2 := rule as UiReactWireRefreshItemsFromCatalog
		out.append(_entry(&"in", r2.filter_text_state, &"filter_text_state"))
		out.append(_entry(&"in", r2.category_kind_state, &"category_kind_state"))
		out.append(_entry(&"in", r2.selected_state, &"selected_state"))
		out.append(_entry(&"out", r2.items_state, &"items_state"))
	elif rule is UiReactWireSortArrayByKey:
		out.append(_entry(&"in", rule.get(&"items_state") as UiState, &"items_state"))
		out.append(_entry(&"in", rule.get(&"sort_key_state") as UiState, &"sort_key_state"))
		out.append(_entry(&"in", rule.get(&"descending_state") as UiState, &"descending_state"))
		out.append(_entry(&"out", rule.get(&"items_state") as UiState, &"items_state"))
	elif rule is UiReactWireCopySelectionDetail:
		var r3 := rule as UiReactWireCopySelectionDetail
		out.append(_entry(&"in", r3.selected_state, &"selected_state"))
		out.append(_entry(&"in", r3.items_state, &"items_state"))
		out.append(_entry(&"out", r3.detail_state, &"detail_state"))
		out.append(_entry(&"out", r3.suffix_note_state, &"suffix_note_state"))
	elif rule is UiReactWireSetStringOnBoolPulse:
		var r4 := rule as UiReactWireSetStringOnBoolPulse
		out.append(_entry(&"in", r4.pulse_bool, &"pulse_bool"))
		out.append(_entry(&"in", r4.selected_state, &"selected_state"))
		out.append(_entry(&"in", r4.items_state, &"items_state"))
		out.append(_entry(&"out", r4.target_string_state, &"target_string_state"))
	elif rule is UiReactWireSyncBoolStateDebugLine:
		var r5 := rule as UiReactWireSyncBoolStateDebugLine
		out.append(_entry(&"in", r5.bool_state, &"bool_state"))
		out.append(_entry(&"out", r5.target_string_state, &"target_string_state"))
	return out


static func _entry(role: StringName, state: UiState, property: StringName) -> Dictionary:
	return {&"role": role, &"state": state, &"property": property}

## Maps an int (e.g. tree visible index) to a string payload ([code]docs/WIRING_LAYER.md[/code] §6.1).
class_name UiReactWireMapIntToString
extends UiReactWireRule

@export var source_int_state: UiIntState
@export var target_string_state: UiStringState
## Int keys -> kind string (empty string = no kind filter). Editor may store keys as [int] or stringified ints.
@export var index_to_string: Dictionary = {
	0: "",
	1: "weapon",
	2: "consumable",
	3: "material",
}
## Optional: fill a hint line (e.g. for a bound [UiReactLabel]).
@export var hint_state: UiStringState
## Labels for [member hint_state]; keys are tree indices ([int]).
@export var hint_labels_by_index: Dictionary = {
	0: "All items",
	1: "Weapons",
	2: "Consumables",
	3: "Materials",
}


func apply(_source: Node) -> void:
	if not enabled:
		return
	if source_int_state == null or target_string_state == null:
		return
	var idx: int = int(source_int_state.get_value())
	var mapped := ""
	for k in index_to_string.keys():
		if int(k) == idx:
			mapped = str(index_to_string[k])
			break
	target_string_state.set_value(mapped)
	if hint_state != null:
		var label: String = str(hint_labels_by_index.get(idx, "(pick a row)"))
		hint_state.set_value("Category: %s (tree index %d)." % [label, idx])

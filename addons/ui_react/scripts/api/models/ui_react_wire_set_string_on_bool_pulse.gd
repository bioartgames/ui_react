## On [signal UiBoolState.value_changed], optionally on rising edge to [code]true[/code], writes [UiStringState] using [code]{name}[/code], [code]{kind}[/code], [code]{qty}[/code] placeholders from the selected row ([code]docs/WIRING_LAYER.md[/code] §6).
class_name UiReactWireSetStringOnBoolPulse
extends UiReactWireRule

@export var pulse_bool: UiBoolState
@export var target_string_state: UiStringState
@export var selected_state: UiIntState
@export var items_state: UiArrayState
## Output when [member template_no_selection] is set and there is no valid selection row name (e.g. Use with no item).
@export var template_no_selection: String = ""
## Output template; placeholders [code]{name}[/code], [code]{kind}[/code], [code]{qty}[/code] come from the selected row dictionary.
@export var template_rising: String = ""
## If [code]true[/code], only runs when the new value is [code]true[/code] and the old value was [code]false[/code].
@export var require_rising_edge: bool = true


func apply(_source: Node) -> void:
	pass


func apply_from_pulse(_source: Node, new_val: Variant, old_val: Variant) -> void:
	if not enabled or target_string_state == null or pulse_bool == null:
		return
	if require_rising_edge:
		if not (bool(new_val) and not bool(old_val)):
			return
	elif not bool(new_val):
		return
	var idx := -1
	var items: Array = []
	if selected_state != null:
		idx = int(selected_state.get_value())
	if items_state != null:
		var v: Variant = items_state.get_value()
		items = v as Array if v is Array else []
	var row: Dictionary = UiReactWireTemplate.selected_row_dict(idx, items)
	var name := UiReactWireTemplate.row_display_name(row)
	var no_sel := template_no_selection.strip_edges()
	if not no_sel.is_empty():
		if idx < 0 or name.is_empty():
			target_string_state.set_value(no_sel)
			return
	var out := UiReactWireTemplate.substitute_row_placeholders(template_rising, row)
	target_string_state.set_value(out)

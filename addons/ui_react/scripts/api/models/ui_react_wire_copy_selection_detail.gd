## Writes a detail string when list selection / rows / optional suffix change ([code]docs/WIRING_LAYER.md[/code] §6.3).
class_name UiReactWireCopySelectionDetail
extends UiReactWireRule

@export var selected_state: UiIntState
@export var items_state: UiArrayState
@export var detail_state: UiStringState
## Optional second line (e.g. demo “Use” note); when it changes, runner re-runs this rule.
@export var suffix_note_state: UiStringState
@export var text_no_selection: String = "No selection."
## When [code]true[/code], the runner clears [member suffix_note_state] whenever [member selected_state] changes, before recomputing the detail line (avoids stale toasts).
@export var clear_suffix_on_selection_change: bool = true


func apply(_source: Node) -> void:
	if not enabled or detail_state == null or selected_state == null:
		return
	var idx: int = int(selected_state.get_value())
	var items: Array = items_state.get_value() if items_state != null else []
	var base := UiReactWireTemplate.selection_detail_base(idx, items, text_no_selection)
	if suffix_note_state != null:
		var note := str(suffix_note_state.get_value()).strip_edges()
		if not note.is_empty():
			base = "%s\n%s" % [base, note]
	detail_state.set_value(base)

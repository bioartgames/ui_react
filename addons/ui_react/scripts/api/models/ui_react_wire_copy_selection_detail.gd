## Writes a detail string when list selection / rows / optional suffix change ([code]docs/WIRING_LAYER.md[/code] §6.3).
class_name UiReactWireCopySelectionDetail
extends UiReactWireRule

@export var selected_state: UiIntState
@export var items_state: UiArrayState
@export var detail_state: UiStringState
## Optional second line (e.g. demo “Use” note); when it changes, runner re-runs this rule.
@export var suffix_note_state: UiStringState
@export var text_no_selection: String = "No selection."


func apply(_source: Node) -> void:
	if not enabled or detail_state == null or selected_state == null:
		return
	var idx: int = int(selected_state.get_value())
	var items: Array = items_state.get_value() if items_state != null else []
	var base := text_no_selection
	if idx >= 0 and idx < items.size():
		var entry: Variant = items[idx]
		if entry is Dictionary:
			var d: Dictionary = entry as Dictionary
			if d.has("name") or d.has("kind"):
				base = "Selected: %s — %s (qty %s)" % [
					str(d.get("name", "")),
					str(d.get("kind", "")),
					str(d.get("qty", 1)),
				]
			else:
				base = "Selected: %s" % str(d.get("label", d.get("text", str(entry))))
		else:
			base = "Selected: %s" % str(entry)
	if suffix_note_state != null:
		var note := str(suffix_note_state.get_value()).strip_edges()
		if not note.is_empty():
			base = "%s\n%s" % [base, note]
	detail_state.set_value(base)

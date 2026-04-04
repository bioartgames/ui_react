extends RefCounted
## Shared helpers for [UiReactWireCopySelectionDetail] and bool-pulse string rules ([code]docs/WIRING_LAYER.md[/code] §6).
class_name UiReactWireTemplate


static func selection_detail_base(idx: int, items: Array, text_no_selection: String) -> String:
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
	return base


static func substitute_row_placeholders(template: String, row: Dictionary) -> String:
	var s := template
	s = s.replace("{name}", str(row.get("name", "")))
	s = s.replace("{kind}", str(row.get("kind", "")))
	s = s.replace("{qty}", str(row.get("qty", 1)))
	return s


static func selected_row_dict(idx: int, items: Array) -> Dictionary:
	if idx < 0 or idx >= items.size():
		return {}
	var entry: Variant = items[idx]
	return entry as Dictionary if entry is Dictionary else {}


static func row_display_name(row: Dictionary) -> String:
	return str(row.get("name", "")).strip_edges()

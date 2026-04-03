## Rebuilds [member items_state] line payloads from a catalog + filter + optional category string ([code]docs/WIRING_LAYER.md[/code] §6.2).
class_name UiReactWireRefreshItemsFromCatalog
extends UiReactWireRule

@export var filter_text_state: UiStringState
## Kind string from [UiReactWireMapIntToString] (or leave unset for no category filter).
@export var category_kind_state: UiStringState
@export var catalog: UiReactWireCatalogData
@export var items_state: UiArrayState
@export var selected_state: UiIntState
## Optional icon for the **first row that passes filter** (not necessarily catalog row 0).
@export var first_row_icon_path: String = ""


func apply(_source: Node) -> void:
	if not enabled:
		return
	if items_state == null or catalog == null:
		return
	catalog.ensure_rows_loaded()
	var kind_filter := ""
	if category_kind_state != null:
		kind_filter = str(category_kind_state.get_value()).strip_edges()
	var needle := ""
	if filter_text_state != null:
		needle = str(filter_text_state.get_value()).strip_edges().to_lower()
	var lines: Array = []
	for i in range(catalog.rows.size()):
		var row: Dictionary = catalog.rows[i]
		var item_name := str(row.get("name", ""))
		var kind := str(row.get("kind", ""))
		if not kind_filter.is_empty() and kind != kind_filter:
			continue
		if (
			not needle.is_empty()
			and not item_name.to_lower().contains(needle)
			and not kind.to_lower().contains(needle)
		):
			continue
		var line_text := "%s (%s) × %s" % [item_name, kind, str(row.get("qty", 1))]
		var icon_stripped := first_row_icon_path.strip_edges()
		var use_icon := lines.is_empty() and not icon_stripped.is_empty()
		if use_icon:
			lines.append(
				{
					"label": line_text,
					"icon": icon_stripped,
					"name": row.get("name", ""),
					"kind": row.get("kind", ""),
					"qty": row.get("qty", 1),
				}
			)
		else:
			lines.append(
				{
					"label": line_text,
					"name": row.get("name", ""),
					"kind": row.get("kind", ""),
					"qty": row.get("qty", 1),
				}
			)
	items_state.set_value(lines)
	if selected_state != null:
		var idx := int(selected_state.get_value())
		if idx < 0 or idx >= lines.size():
			selected_state.set_value(-1)

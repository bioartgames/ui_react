extends Control
## P3 example: filter text drives [UiArrayState]; [UiReactItemList] rows are strings or { **label**, **icon** } dicts (see README **List patterns**).
## Catalog rows are dictionaries in code only; the first visible row uses the project icon for CB-008 demo.
## [member list_input_blocker_path]: full-rect overlay with [member Control.mouse_filter] STOP when [member list_locked_state] is [code]true[/code] (CB-015 workaround).

const _CATALOG: Array[Dictionary] = [
	{"id": &"iron_sword", "name": "Iron Sword", "kind": "weapon", "qty": 1},
	{"id": &"heal_pot", "name": "Health Potion", "kind": "consumable", "qty": 3},
	{"id": &"oak_wood", "name": "Oak Wood", "kind": "material", "qty": 12},
	{"id": &"leather", "name": "Leather Scraps", "kind": "material", "qty": 5},
	{"id": &"steel_dagger", "name": "Steel Dagger", "kind": "weapon", "qty": 1},
]

@export var filter_text_state: UiStringState
@export var items_state: UiArrayState
@export var selected_state: UiIntState
@export var detail_text_state: UiStringState
@export var list_locked_state: UiBoolState
@export var list_input_blocker_path: NodePath = NodePath("VBox/ListSlot/InputBlocker")

const _DEMO_ROW_ICON := "res://icon.svg"

var _input_blocker: Control
var _filtered_catalog_indices: Array[int] = []


func _ready() -> void:
	_input_blocker = get_node_or_null(list_input_blocker_path) as Control
	if filter_text_state:
		if not filter_text_state.value_changed.is_connected(_on_filter_value_changed):
			filter_text_state.value_changed.connect(_on_filter_value_changed)
		if not filter_text_state.changed.is_connected(_on_filter_resource_changed):
			filter_text_state.changed.connect(_on_filter_resource_changed)
	if selected_state:
		if not selected_state.value_changed.is_connected(_on_selected_state_changed):
			selected_state.value_changed.connect(_on_selected_state_changed)
	if list_locked_state:
		if not list_locked_state.value_changed.is_connected(_on_lock_changed):
			list_locked_state.value_changed.connect(_on_lock_changed)
	_apply_list_lock(bool(list_locked_state.get_value()) if list_locked_state else false)
	_refresh_list()


func _on_filter_value_changed(_nv: Variant, _ov: Variant) -> void:
	_refresh_list()


func _on_filter_resource_changed() -> void:
	_refresh_list()


func _on_selected_state_changed(_nv: Variant, _ov: Variant) -> void:
	_update_detail()


func _on_lock_changed(new_value: Variant, _old_value: Variant) -> void:
	_apply_list_lock(bool(new_value))


func _apply_list_lock(locked: bool) -> void:
	if _input_blocker == null:
		return
	_input_blocker.mouse_filter = (
		Control.MOUSE_FILTER_STOP if locked else Control.MOUSE_FILTER_IGNORE
	)


func _refresh_list() -> void:
	var needle := ""
	if filter_text_state:
		needle = str(filter_text_state.get_value()).strip_edges().to_lower()
	var lines: Array = []
	_filtered_catalog_indices.clear()
	for i in _CATALOG.size():
		var row: Dictionary = _CATALOG[i]
		var item_name := str(row.get("name", ""))
		var kind := str(row.get("kind", ""))
		if (
			needle.is_empty()
			or item_name.to_lower().contains(needle)
			or kind.to_lower().contains(needle)
		):
			var line_text := "%s (%s) × %s" % [item_name, kind, str(row.get("qty", 1))]
			if i == 0:
				lines.append({"label": line_text, "icon": _DEMO_ROW_ICON})
			else:
				lines.append(line_text)
			_filtered_catalog_indices.append(i)
	if items_state:
		items_state.set_value(lines)
	if selected_state:
		var idx := int(selected_state.get_value())
		if idx < 0 or idx >= lines.size():
			selected_state.set_value(-1)
	_update_detail()


func _update_detail() -> void:
	if detail_text_state == null or selected_state == null:
		return
	var idx := int(selected_state.get_value())
	if idx < 0 or idx >= _filtered_catalog_indices.size():
		detail_text_state.set_value("No selection.")
		return
	var cat_i: int = _filtered_catalog_indices[idx]
	var row: Dictionary = _CATALOG[cat_i]
	detail_text_state.set_value(
		"Selected: %s — %s (qty %s)" % [row.get("name", ""), row.get("kind", ""), str(row.get("qty", 1))]
	)

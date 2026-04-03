extends Control
## Combined inventory UI example: [UiReactTree] category filter + [UiReactItemList] (filter/detail/lock) + [UiReactTextureButton] actions.
## Catalog: [InventoryDemoCatalog] via [member _CATALOG_SCRIPT]. Tree uses visible pre-order indices with [code]hide_root = true[/code] (see [method _tree_index_to_kind]).

const _CATALOG_SCRIPT := preload("res://addons/ui_react/examples/inventory_demo_catalog.gd")
const _DEMO_ROW_ICON := "res://icon.svg"

@export var filter_text_state: UiStringState
@export var items_state: UiArrayState
@export var selected_state: UiIntState
@export var detail_text_state: UiStringState
@export var list_locked_state: UiBoolState
@export var tree_selected_state: UiIntState
@export var actions_disabled_state: UiBoolState
@export var use_pressed_state: UiBoolState
@export var sort_pressed_state: UiBoolState
@export var list_input_blocker_path: NodePath = NodePath("MainHBox/CenterColumn/ListSlot/InputBlocker")

@onready var _tree: Tree = $MainHBox/LeftColumn/CategoryTree
@onready var _category_hint: Label = $MainHBox/LeftColumn/CategoryHint
@onready var _texture_use: TextureButton = $MainHBox/RightColumn/ActionButtons/UseButton
@onready var _texture_sort: TextureButton = $MainHBox/RightColumn/ActionButtons/SortButton
@onready var _pressed_use_label: Label = $MainHBox/RightColumn/PressedUseLabel
@onready var _pressed_sort_label: Label = $MainHBox/RightColumn/PressedSortLabel
@onready var _disabled_actions_label: Label = $MainHBox/RightColumn/DisabledActionsLabel

var _input_blocker: Control
var _filtered_catalog_indices: Array[int] = []
var _last_action_note: String = ""


func _ready() -> void:
	_input_blocker = get_node_or_null(list_input_blocker_path) as Control
	_build_tree.call_deferred()
	if filter_text_state:
		if not filter_text_state.value_changed.is_connected(_on_filter_value_changed):
			filter_text_state.value_changed.connect(_on_filter_value_changed)
		if not filter_text_state.changed.is_connected(_on_filter_resource_changed):
			filter_text_state.changed.connect(_on_filter_resource_changed)
	if selected_state:
		if not selected_state.value_changed.is_connected(_on_selected_state_changed):
			selected_state.value_changed.connect(_on_selected_state_changed)
	if tree_selected_state:
		if not tree_selected_state.value_changed.is_connected(_on_tree_selection_changed):
			tree_selected_state.value_changed.connect(_on_tree_selection_changed)
	if list_locked_state:
		if not list_locked_state.value_changed.is_connected(_on_lock_changed):
			list_locked_state.value_changed.connect(_on_lock_changed)
	if use_pressed_state:
		if not use_pressed_state.value_changed.is_connected(_on_use_pressed_changed):
			use_pressed_state.value_changed.connect(_on_use_pressed_changed)
	if sort_pressed_state:
		if not sort_pressed_state.value_changed.is_connected(_on_sort_pressed_changed):
			sort_pressed_state.value_changed.connect(_on_sort_pressed_changed)
	if actions_disabled_state:
		if not actions_disabled_state.value_changed.is_connected(_on_actions_disabled_changed):
			actions_disabled_state.value_changed.connect(_on_actions_disabled_changed)
	_apply_list_lock(bool(list_locked_state.get_value()) if list_locked_state else false)
	_refresh_list()
	_refresh_action_labels()


func _build_tree() -> void:
	_tree.clear()
	_tree.hide_root = true
	var root: TreeItem = _tree.create_item()
	root.set_text(0, "Inventory")
	var all_items: TreeItem = _tree.create_item(root)
	all_items.set_text(0, "All items")
	var weapons: TreeItem = _tree.create_item(root)
	weapons.set_text(0, "Weapons")
	var consumables: TreeItem = _tree.create_item(root)
	consumables.set_text(0, "Consumables")
	var materials: TreeItem = _tree.create_item(root)
	materials.set_text(0, "Materials")
	var st: UiIntState = _tree.selected_state as UiIntState
	if st == null:
		return
	_on_tree_selection_changed(st.get_value(), st.get_value())


func _tree_index_to_kind(tree_index: int) -> String:
	match tree_index:
		1:
			return "weapon"
		2:
			return "consumable"
		3:
			return "material"
		_:
			return ""


func _on_tree_selection_changed(_new_val: Variant, _old_val: Variant) -> void:
	_refresh_list()


func _on_filter_value_changed(_nv: Variant, _ov: Variant) -> void:
	_refresh_list()


func _on_filter_resource_changed() -> void:
	_refresh_list()


func _on_selected_state_changed(_nv: Variant, _ov: Variant) -> void:
	_last_action_note = ""
	_update_detail()


func _on_lock_changed(new_value: Variant, _old_value: Variant) -> void:
	_apply_list_lock(bool(new_value))


func _apply_list_lock(locked: bool) -> void:
	if _input_blocker == null:
		return
	_input_blocker.mouse_filter = (
		Control.MOUSE_FILTER_STOP if locked else Control.MOUSE_FILTER_IGNORE
	)


func _current_category_kind() -> String:
	var idx := -1
	if tree_selected_state:
		idx = int(tree_selected_state.get_value())
	if idx < 0:
		idx = -1
	var hint := "Category: "
	match idx:
		0:
			hint += "All items"
		1:
			hint += "Weapons"
		2:
			hint += "Consumables"
		3:
			hint += "Materials"
		_:
			hint += "(pick a row)"
	if _category_hint:
		_category_hint.text = "%s (tree index %d)." % [hint, idx]
	return _tree_index_to_kind(idx)


func _refresh_list() -> void:
	var kind_filter := _current_category_kind()
	var needle := ""
	if filter_text_state:
		needle = str(filter_text_state.get_value()).strip_edges().to_lower()
	var lines: Array = []
	_filtered_catalog_indices.clear()
	var catalog: Array = _CATALOG_SCRIPT.CATALOG
	for i in catalog.size():
		var row: Dictionary = catalog[i]
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
	var base := ""
	if idx < 0 or idx >= _filtered_catalog_indices.size():
		base = "No selection."
	else:
		var cat_i: int = _filtered_catalog_indices[idx]
		var row: Dictionary = _CATALOG_SCRIPT.CATALOG[cat_i]
		base = "Selected: %s — %s (qty %s)" % [row.get("name", ""), row.get("kind", ""), str(row.get("qty", 1))]
	if not _last_action_note.is_empty():
		base = "%s\n%s" % [base, _last_action_note]
	detail_text_state.set_value(base)


func _on_use_pressed_changed(new_val: Variant, _old_val: Variant) -> void:
	if not bool(new_val):
		return
	var name_str := ""
	if selected_state and int(selected_state.get_value()) >= 0:
		var li := int(selected_state.get_value())
		if li >= 0 and li < _filtered_catalog_indices.size():
			var row: Dictionary = _CATALOG_SCRIPT.CATALOG[_filtered_catalog_indices[li]]
			name_str = str(row.get("name", ""))
	if name_str.is_empty():
		_last_action_note = "[Demo] Use — select an item first."
	else:
		_last_action_note = "[Demo] Use — queued for “%s”." % name_str
	_update_detail()
	_refresh_action_labels()


func _on_actions_disabled_changed(_new_val: Variant, _old_val: Variant) -> void:
	_refresh_action_labels()


func _on_sort_pressed_changed(new_val: Variant, _old_val: Variant) -> void:
	if not bool(new_val):
		return
	_last_action_note = "[Demo] Sort — no-op (shows texture button pressed_state)."
	_update_detail()
	_refresh_action_labels()


func _refresh_action_labels() -> void:
	var pu: UiBoolState = _texture_use.pressed_state as UiBoolState
	var ps: UiBoolState = _texture_sort.pressed_state as UiBoolState
	var ds: UiBoolState = _texture_use.disabled_state as UiBoolState
	if _pressed_use_label:
		_pressed_use_label.text = "use pressed_state: %s" % (str(pu.get_value()) if pu else "—")
	if _pressed_sort_label:
		_pressed_sort_label.text = "sort pressed_state: %s" % (str(ps.get_value()) if ps else "—")
	if _disabled_actions_label:
		_disabled_actions_label.text = "actions disabled_state: %s" % (str(ds.get_value()) if ds else "—")

## P5.2 dock tab: edit [member Node.wire_rules] with the same [UiReactWireRule] subresources as the Inspector ([code]CB-035[/code]). Rule script list: keep aligned with [code]docs/WIRING_LAYER.md[/code] §6.
class_name UiReactDockWireRulesPanel
extends MarginContainer

## Display label → script path (order = Add menu order). Full paths — GDScript const cannot concatenate here.
const _RULE_ENTRIES: Array[Dictionary] = [
	{&"label": &"MapIntToString", &"path": &"res://addons/ui_react/scripts/api/models/ui_react_wire_map_int_to_string.gd"},
	{&"label": &"RefreshItemsFromCatalog", &"path": &"res://addons/ui_react/scripts/api/models/ui_react_wire_refresh_items_from_catalog.gd"},
	{&"label": &"CopySelectionDetail", &"path": &"res://addons/ui_react/scripts/api/models/ui_react_wire_copy_selection_detail.gd"},
	{&"label": &"SetStringOnBoolPulse", &"path": &"res://addons/ui_react/scripts/api/models/ui_react_wire_set_string_on_bool_pulse.gd"},
	{&"label": &"SyncBoolStateDebugLine", &"path": &"res://addons/ui_react/scripts/api/models/ui_react_wire_sync_bool_state_debug_line.gd"},
	{&"label": &"SortArrayByKey", &"path": &"res://addons/ui_react/scripts/api/models/ui_react_wire_sort_array_by_key.gd"},
]

var _plugin: EditorPlugin
var _actions: UiReactActionController

var _hint: RichTextLabel
var _list: ItemList
var _btn_add: MenuButton
var _btn_remove: Button
var _btn_up: Button
var _btn_down: Button
var _btn_dup: Button
var _btn_inspect: Button
var _btn_refresh: Button

var _target: Node = null


func setup(plugin: EditorPlugin, actions: UiReactActionController) -> void:
	_plugin = plugin
	_actions = actions
	_build_ui()


func refresh() -> void:
	_target = null
	_list.clear()
	if _plugin == null or _actions == null:
		_set_hint("Plugin not ready.")
		_set_buttons(false)
		return
	var ei := _plugin.get_editor_interface()
	var root := ei.get_edited_scene_root()
	if root == null:
		_set_hint("Open a scene to edit [code]wire_rules[/code].")
		_set_buttons(false)
		return
	var sel: Array[Node] = ei.get_selection().get_selected_nodes()
	if sel.size() != 1:
		_set_hint(
			"Select exactly one node in the edited scene ([code]wire_rules[/code] is per [UiReact*] host; see [code]docs/WIRING_LAYER.md[/code] §5)."
		)
		_set_buttons(false)
		return
	var n: Node = sel[0]
	if not (&"wire_rules" in n):
		_set_hint(
			"No [code]wire_rules[/code] on this node. Use a §5 host (e.g. [UiReactItemList], [UiReactTree], [UiReactLineEdit])."
		)
		_set_buttons(false)
		return
	if not (n == root or root.is_ancestor_of(n)):
		_set_hint("Selection must be part of the current edited scene.")
		_set_buttons(false)
		return
	_target = n
	_set_hint(
		"Target: [b]%s[/b] — order matches [code]wire_rules[/code] ([code]WIRING_LAYER.md[/code] §3)."
		% str(n.get_path())
	)
	var wr: Variant = n.get(&"wire_rules")
	var arr: Array = wr as Array if wr is Array else []
	for i in range(arr.size()):
		var item: Variant = arr[i]
		_list.add_item(_format_rule_line(i, item))
	_set_buttons(true)


func _build_ui() -> void:
	add_theme_constant_override(&"margin_left", 2)
	add_theme_constant_override(&"margin_right", 2)
	add_theme_constant_override(&"margin_top", 4)
	add_theme_constant_override(&"margin_bottom", 4)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override(&"separation", 6)
	add_child(v)

	_hint = RichTextLabel.new()
	_hint.bbcode_enabled = true
	_hint.fit_content = true
	_hint.scroll_active = false
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hint.text = "Select one [UiReact*] node with [code]wire_rules[/code]."
	if _plugin:
		UiReactDockTheme.apply_richtext_content(_hint, _plugin)
	v.add_child(_hint)

	_list = ItemList.new()
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.custom_minimum_size = Vector2(0, 120)
	_list.allow_reselect = true
	v.add_child(_list)

	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override(&"separation", 6)
	v.add_child(row1)

	_btn_add = MenuButton.new()
	_btn_add.text = "Add rule…"
	var pop := _btn_add.get_popup()
	for e in _RULE_ENTRIES:
		pop.add_item(String(e[&"label"]))
	for i in range(_RULE_ENTRIES.size()):
		pop.set_item_id(i, i)
	if not pop.id_pressed.is_connected(_on_add_menu_id):
		pop.id_pressed.connect(_on_add_menu_id)
	row1.add_child(_btn_add)

	_btn_remove = Button.new()
	_btn_remove.text = "Remove"
	_btn_remove.tooltip_text = "Remove the selected rule row (Undo: Ctrl+Z)."
	_btn_remove.pressed.connect(_on_remove_pressed)
	row1.add_child(_btn_remove)

	_btn_dup = Button.new()
	_btn_dup.text = "Duplicate"
	_btn_dup.tooltip_text = "Duplicate the selected rule (deep duplicate)."
	_btn_dup.pressed.connect(_on_duplicate_pressed)
	row1.add_child(_btn_dup)

	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override(&"separation", 6)
	v.add_child(row2)

	_btn_up = Button.new()
	_btn_up.text = "Move up"
	_btn_up.pressed.connect(func(): _on_move(-1))
	row2.add_child(_btn_up)

	_btn_down = Button.new()
	_btn_down.text = "Move down"
	_btn_down.pressed.connect(func(): _on_move(1))
	row2.add_child(_btn_down)

	_btn_inspect = Button.new()
	_btn_inspect.text = "Inspect rule"
	_btn_inspect.tooltip_text = "Open the Inspector on this rule resource (assign states, catalog, templates)."
	_btn_inspect.pressed.connect(_on_inspect_pressed)
	row2.add_child(_btn_inspect)

	_btn_refresh = Button.new()
	_btn_refresh.text = "Refresh list"
	_btn_refresh.tooltip_text = "Resync from the scene after external edits or Undo."
	_btn_refresh.pressed.connect(refresh)
	row2.add_child(_btn_refresh)

	_set_buttons(false)


func _set_hint(bbcode: String) -> void:
	_hint.text = bbcode
	if _plugin:
		UiReactDockTheme.apply_richtext_content(_hint, _plugin)


func _set_buttons(enabled: bool) -> void:
	_btn_add.disabled = not enabled
	_btn_remove.disabled = not enabled
	_btn_dup.disabled = not enabled
	_btn_up.disabled = not enabled
	_btn_down.disabled = not enabled
	_btn_inspect.disabled = not enabled


func _format_rule_line(index: int, item: Variant) -> String:
	if item == null:
		return "[%d] (null)" % index
	var cls := "?"
	if item is Object and (item as Object).get_script() != null:
		var script: Script = (item as Object).get_script() as Script
		var gn: StringName = script.get_global_name()
		if String(gn) != "":
			cls = String(gn)
		else:
			cls = script.resource_path.get_file().get_basename()
	var rule_field := "—"
	if item is UiReactWireRule:
		var rid: String = (item as UiReactWireRule).rule_id
		if not rid.is_empty():
			rule_field = rid
	return "[%d] %s — %s" % [index, cls, rule_field]


func _get_wr_array_duplicate() -> Array[UiReactWireRule]:
	if _target == null:
		return []
	var wr: Variant = _target.get(&"wire_rules")
	if wr == null:
		return []
	## Typed export: duplicate preserves Array[UiReactWireRule].
	if wr is Array[UiReactWireRule]:
		return (wr as Array[UiReactWireRule]).duplicate()
	## Rare: untyped Array — keep only [UiReactWireRule] entries.
	var plain: Array = wr as Array
	var out: Array[UiReactWireRule] = []
	for it in plain:
		if it is UiReactWireRule:
			out.append(it as UiReactWireRule)
	return out


func _commit_wire_rules(next: Array[UiReactWireRule], action_label: String) -> void:
	if _target == null or _actions == null:
		return
	_actions.assign_property_variant(_target, &"wire_rules", next, action_label)
	refresh()


func _on_add_menu_id(menu_idx: int) -> void:
	if _target == null or menu_idx < 0 or menu_idx >= _RULE_ENTRIES.size():
		return
	var path: String = String(_RULE_ENTRIES[menu_idx][&"path"])
	var s: GDScript = load(path) as GDScript
	if s == null:
		push_warning("Ui React: could not load wire rule script %s" % path)
		return
	var inst: Variant = s.new()
	if inst == null or not (inst is UiReactWireRule):
		push_warning("Ui React: script did not instantiate a UiReactWireRule: %s" % path)
		return
	var rule := inst as UiReactWireRule
	var arr := _get_wr_array_duplicate()
	if rule.rule_id.is_empty():
		rule.rule_id = "rule_%d" % arr.size()
	arr.append(rule)
	_commit_wire_rules(arr, "Ui React: Add wire rule")


func _selected_index() -> int:
	var sel: PackedInt32Array = _list.get_selected_items()
	if sel.is_empty():
		return -1
	return int(sel[0])


func _on_remove_pressed() -> void:
	var i := _selected_index()
	if i < 0 or _target == null:
		return
	var arr := _get_wr_array_duplicate()
	if i >= arr.size():
		return
	arr.remove_at(i)
	_commit_wire_rules(arr, "Ui React: Remove wire rule")


func _on_duplicate_pressed() -> void:
	var i := _selected_index()
	if i < 0 or _target == null:
		return
	var arr := _get_wr_array_duplicate()
	if i >= arr.size():
		return
	var item: Variant = arr[i]
	if item is Resource:
		var dup := (item as Resource).duplicate(true)
		if dup is UiReactWireRule:
			arr.insert(i + 1, dup as UiReactWireRule)
			_commit_wire_rules(arr, "Ui React: Duplicate wire rule")


func _on_move(delta: int) -> void:
	var i := _selected_index()
	if i < 0 or _target == null:
		return
	var j := i + delta
	var arr := _get_wr_array_duplicate()
	if j < 0 or j >= arr.size():
		return
	var tmp: UiReactWireRule = arr[i]
	arr[i] = arr[j]
	arr[j] = tmp
	_actions.assign_property_variant(_target, &"wire_rules", arr, "Ui React: Reorder wire rule")
	refresh()
	if j >= 0 and j < _list.item_count:
		_list.select(j)


func _on_inspect_pressed() -> void:
	var i := _selected_index()
	if i < 0 or _target == null:
		return
	var arr := _get_wr_array_duplicate()
	if i >= arr.size():
		return
	var item: Variant = arr[i]
	if item is Resource:
		_plugin.get_editor_interface().edit_resource(item as Resource)

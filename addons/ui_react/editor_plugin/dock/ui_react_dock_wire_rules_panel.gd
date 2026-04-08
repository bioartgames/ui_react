## P5.2 dock tab: edit [member Node.wire_rules] with the same [UiReactWireRule] subresources as the Inspector ([code]CB-035[/code]). Rule script list: keep aligned with [code]docs/WIRING_LAYER.md[/code] §6.
class_name UiReactDockWireRulesPanel
extends MarginContainer

const _WireDetailsScript := preload("res://addons/ui_react/editor_plugin/dock/ui_react_dock_wire_details.gd")

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
var _split_main: VSplitContainer
var _rules_scroll: ScrollContainer
var _rules_container: VBoxContainer
var _details_scroll: ScrollContainer
var _details_label: RichTextLabel

var _btn_add: MenuButton
var _btn_refresh: Button

var _target: Node = null
var _edited_scene_root: Node = null
var _selected_rule_index: int = -1


func setup(plugin: EditorPlugin, actions: UiReactActionController) -> void:
	_plugin = plugin
	_actions = actions
	_build_ui()


func refresh() -> void:
	var preserved_idx := _selected_rule_index
	_target = null
	_edited_scene_root = null
	_selected_rule_index = -1
	_clear_rules_container()
	_set_details_idle()
	if _plugin == null or _actions == null:
		_set_hint("Plugin not ready.")
		_set_global_actions_enabled(false)
		return
	var ei := _plugin.get_editor_interface()
	var root := ei.get_edited_scene_root()
	if root == null:
		_set_hint("Open a scene to edit [code]wire_rules[/code].")
		_set_global_actions_enabled(false)
		return
	var sel: Array[Node] = ei.get_selection().get_selected_nodes()
	if sel.size() != 1:
		_set_hint(
			"Select exactly one node in the edited scene ([code]wire_rules[/code] is per [UiReact*] host; see [code]docs/WIRING_LAYER.md[/code] §5)."
		)
		_set_global_actions_enabled(false)
		return
	var n: Node = sel[0]
	if not (&"wire_rules" in n):
		_set_hint(
			"No [code]wire_rules[/code] on this node. Use a §5 host (e.g. [UiReactItemList], [UiReactTree], [UiReactLineEdit])."
		)
		_set_global_actions_enabled(false)
		return
	if not (n == root or root.is_ancestor_of(n)):
		_set_hint("Selection must be part of the current edited scene.")
		_set_global_actions_enabled(false)
		return
	_target = n
	_edited_scene_root = root
	_set_hint(_format_target_hint(n, root))
	var wr: Variant = n.get(&"wire_rules")
	var arr: Array = wr as Array if wr is Array else []
	if arr.is_empty():
		_selected_rule_index = -1
	else:
		if preserved_idx >= 0 and preserved_idx < arr.size():
			_selected_rule_index = preserved_idx
		else:
			_selected_rule_index = 0
	_rebuild_rule_rows(arr)
	_update_details_panel()
	_set_global_actions_enabled(true)


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

	_split_main = VSplitContainer.new()
	_split_main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_split_main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_split_main.add_theme_constant_override(&"autohide", 0)
	_split_main.add_theme_constant_override(&"minimum_grab_thickness", 10)
	if _plugin:
		UiReactDockTheme.apply_split_bar(_split_main, _plugin)
	_split_main.tooltip_text = "Drag to resize the rule list and the report below."
	v.add_child(_split_main)

	var rules_section := VBoxContainer.new()
	rules_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rules_section.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rules_section.add_theme_constant_override(&"separation", 4)
	_split_main.add_child(rules_section)

	var rules_panel := PanelContainer.new()
	rules_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rules_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rules_panel.custom_minimum_size = Vector2(0, 56)
	rules_panel.tooltip_text = "Wire rules for the selected host. Order matches wire_rules (WIRING_LAYER.md §3)."
	rules_section.add_child(rules_panel)
	if _plugin:
		UiReactDockTheme.apply_panelcontainer(rules_panel, _plugin)

	var rules_margin := MarginContainer.new()
	rules_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rules_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rules_margin.add_theme_constant_override(&"margin_left", 6)
	rules_margin.add_theme_constant_override(&"margin_right", 6)
	rules_margin.add_theme_constant_override(&"margin_top", 6)
	rules_margin.add_theme_constant_override(&"margin_bottom", 6)
	rules_panel.add_child(rules_margin)

	_rules_scroll = ScrollContainer.new()
	_rules_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rules_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_rules_scroll.tooltip_text = "Scroll the rule list."
	rules_margin.add_child(_rules_scroll)

	_rules_container = VBoxContainer.new()
	_rules_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rules_scroll.add_child(_rules_container)

	var report_section := VBoxContainer.new()
	report_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	report_section.size_flags_vertical = Control.SIZE_EXPAND_FILL
	report_section.add_theme_constant_override(&"separation", 4)
	_split_main.add_child(report_section)

	var report_panel := PanelContainer.new()
	report_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	report_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	report_panel.custom_minimum_size = Vector2(0, 56)
	report_panel.tooltip_text = "Report: intent, states, runtime bindings, validation for the selected rule."
	report_section.add_child(report_panel)
	if _plugin:
		UiReactDockTheme.apply_panelcontainer(report_panel, _plugin)

	var report_margin := MarginContainer.new()
	report_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	report_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	report_margin.add_theme_constant_override(&"margin_left", 6)
	report_margin.add_theme_constant_override(&"margin_right", 6)
	report_margin.add_theme_constant_override(&"margin_top", 6)
	report_margin.add_theme_constant_override(&"margin_bottom", 6)
	report_panel.add_child(report_margin)

	_details_scroll = ScrollContainer.new()
	_details_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_details_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_details_scroll.tooltip_text = "Rule story and fields for the selected row."
	report_margin.add_child(_details_scroll)

	_details_label = RichTextLabel.new()
	_details_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_details_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_details_label.bbcode_enabled = true
	_details_label.fit_content = true
	_details_label.scroll_active = false
	_details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details_scroll.add_child(_details_label)
	if _plugin:
		UiReactDockTheme.apply_richtext_content(_details_label, _plugin)

	_split_main.split_offset = 0

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override(&"separation", 6)
	v.add_child(btn_row)

	_btn_add = MenuButton.new()
	_btn_add.text = "Add rule…"
	var pop := _btn_add.get_popup()
	for e in _RULE_ENTRIES:
		pop.add_item(String(e[&"label"]))
	for i in range(_RULE_ENTRIES.size()):
		pop.set_item_id(i, i)
	if not pop.id_pressed.is_connected(_on_add_menu_id):
		pop.id_pressed.connect(_on_add_menu_id)
	_btn_add.flat = false
	_btn_add.theme_type_variation = &"Button"
	if _plugin:
		UiReactDockTheme.apply_basebutton_editor_panel_style(_btn_add, _plugin)
	btn_row.add_child(_btn_add)

	_btn_refresh = Button.new()
	_btn_refresh.text = "Refresh list"
	_btn_refresh.tooltip_text = "Resync from the scene after external edits or Undo."
	_btn_refresh.pressed.connect(refresh)
	btn_row.add_child(_btn_refresh)

	_set_global_actions_enabled(false)
	_set_details_idle()


func _clear_rules_container() -> void:
	for i in range(_rules_container.get_child_count() - 1, -1, -1):
		_rules_container.get_child(i).queue_free()


func _rebuild_rule_rows(arr: Array) -> void:
	_clear_rules_container()
	for i in range(arr.size()):
		var item: Variant = arr[i]
		_rules_container.add_child(_make_rule_row(i, item, arr.size()))


func _make_rule_row(index: int, item: Variant, arr_size: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 6)
	var sel_btn := Button.new()
	sel_btn.text = _format_rule_line(index, item)
	sel_btn.flat = false
	sel_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	sel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sel_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var fi := index
	sel_btn.pressed.connect(func(): _select_rule(fi))
	sel_btn.tooltip_text = "Select this rule; read the report below."
	if index == _selected_rule_index:
		var sel_style := StyleBoxFlat.new()
		sel_style.bg_color = Color(0.25, 0.45, 0.75, 0.28)
		sel_style.set_corner_radius_all(3)
		sel_style.set_content_margin_all(4)
		sel_btn.add_theme_stylebox_override(&"normal", sel_style)
		var sel_hover := StyleBoxFlat.new()
		sel_hover.bg_color = Color(0.3, 0.52, 0.82, 0.34)
		sel_hover.set_corner_radius_all(3)
		sel_hover.set_content_margin_all(4)
		sel_btn.add_theme_stylebox_override(&"hover", sel_hover)
		var sel_pressed := StyleBoxFlat.new()
		sel_pressed.bg_color = Color(0.22, 0.38, 0.62, 0.4)
		sel_pressed.set_corner_radius_all(3)
		sel_pressed.set_content_margin_all(4)
		sel_btn.add_theme_stylebox_override(&"pressed", sel_pressed)
	row.add_child(sel_btn)

	var btn_insp := Button.new()
	btn_insp.text = "Inspect"
	btn_insp.disabled = item == null or not (item is Resource)
	btn_insp.pressed.connect(func(): _inspect_at(fi))
	btn_insp.tooltip_text = "Open the Inspector on this rule resource."
	row.add_child(btn_insp)

	var btn_up := Button.new()
	btn_up.text = "Up"
	btn_up.disabled = index <= 0
	btn_up.pressed.connect(func(): _move_at(fi, -1))
	btn_up.tooltip_text = "Move this rule earlier in wire_rules (Undo: Ctrl+Z)."
	row.add_child(btn_up)

	var btn_dn := Button.new()
	btn_dn.text = "Down"
	btn_dn.disabled = index >= arr_size - 1
	btn_dn.pressed.connect(func(): _move_at(fi, 1))
	btn_dn.tooltip_text = "Move this rule later in wire_rules (Undo: Ctrl+Z)."
	row.add_child(btn_dn)

	var btn_dup := Button.new()
	btn_dup.text = "Dup"
	btn_dup.disabled = item == null or not (item is Resource)
	btn_dup.pressed.connect(func(): _duplicate_at(fi))
	btn_dup.tooltip_text = "Duplicate this rule (deep duplicate) below this row."
	row.add_child(btn_dup)

	var btn_rm := Button.new()
	btn_rm.text = "Remove"
	btn_rm.pressed.connect(func(): _remove_at(fi))
	btn_rm.tooltip_text = "Remove this rule from wire_rules (Undo: Ctrl+Z)."
	row.add_child(btn_rm)

	return row


func _select_rule(index: int) -> void:
	_selected_rule_index = index
	if _target == null:
		return
	var wr: Variant = _target.get(&"wire_rules")
	var arr: Array = wr as Array if wr is Array else []
	_rebuild_rule_rows(arr)
	_update_details_panel()


func _set_details_idle() -> void:
	_details_label.text = _WireDetailsScript.idle_placeholder_text()
	if _plugin:
		UiReactDockTheme.apply_richtext_content(_details_label, _plugin)


func _update_details_panel() -> void:
	if _target == null or _edited_scene_root == null:
		_set_details_idle()
		return
	var wr: Variant = _target.get(&"wire_rules")
	var arr: Array = wr as Array if wr is Array else []
	if _selected_rule_index < 0 or _selected_rule_index >= arr.size():
		_set_details_idle()
		return
	var item: Variant = arr[_selected_rule_index]
	_details_label.text = _WireDetailsScript.build_details_bbcode(
		item, _selected_rule_index, _target, _edited_scene_root
	)
	if _plugin:
		UiReactDockTheme.apply_richtext_content(_details_label, _plugin)


func _format_target_hint(n: Node, root: Node) -> String:
	var rel := root.get_path_to(n)
	var rel_str := String(rel)
	if rel_str == "." or rel.is_empty():
		return "Wire rules: [b]%s[/b] · (scene root)" % n.name
	return "Wire rules: [b]%s[/b] · [code]%s[/code]" % [n.name, rel_str]


func _set_hint(bbcode: String) -> void:
	_hint.text = bbcode
	if _plugin:
		UiReactDockTheme.apply_richtext_content(_hint, _plugin)


func _set_global_actions_enabled(enabled: bool) -> void:
	_btn_add.disabled = not enabled
	_btn_refresh.disabled = not enabled


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
	_selected_rule_index = arr.size() - 1
	_commit_wire_rules(arr, "Ui React: Add wire rule")


func _remove_at(index: int) -> void:
	if _target == null:
		return
	var arr := _get_wr_array_duplicate()
	if index < 0 or index >= arr.size():
		return
	arr.remove_at(index)
	if arr.is_empty():
		_selected_rule_index = -1
	else:
		_selected_rule_index = mini(index, arr.size() - 1)
	_commit_wire_rules(arr, "Ui React: Remove wire rule")


func _duplicate_at(index: int) -> void:
	if _target == null:
		return
	var arr := _get_wr_array_duplicate()
	if index < 0 or index >= arr.size():
		return
	var item: Variant = arr[index]
	if item is Resource:
		var dup := (item as Resource).duplicate(true)
		if dup is UiReactWireRule:
			arr.insert(index + 1, dup as UiReactWireRule)
			_selected_rule_index = index + 1
			_commit_wire_rules(arr, "Ui React: Duplicate wire rule")


func _move_at(index: int, delta: int) -> void:
	if _target == null:
		return
	var j := index + delta
	var arr := _get_wr_array_duplicate()
	if j < 0 or j >= arr.size():
		return
	var tmp: UiReactWireRule = arr[index]
	arr[index] = arr[j]
	arr[j] = tmp
	_selected_rule_index = j
	_actions.assign_property_variant(_target, &"wire_rules", arr, "Ui React: Reorder wire rule")
	refresh()


func _inspect_at(index: int) -> void:
	if _target == null:
		return
	var arr := _get_wr_array_duplicate()
	if index < 0 or index >= arr.size():
		return
	var item: Variant = arr[index]
	if item is Resource:
		_plugin.get_editor_interface().edit_resource(item as Resource)

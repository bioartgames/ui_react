## Embedded [code]wire_rules[/code] list + rule report under the Dependency Graph details ([code]CB-058[/code] RMB-first). Row actions: right-click.
class_name UiReactDockWireRulesSection
extends VBoxContainer

const _WireDetailsScript := preload("res://addons/ui_react/editor_plugin/dock/ui_react_dock_wire_details.gd")

const _ROW_MENU_MOVE_UP := 6001
const _ROW_MENU_MOVE_DOWN := 6002
const _ROW_MENU_DUPLICATE := 6003
const _ROW_MENU_REMOVE := 6004
const _ROW_MENU_COPY_REPORT := 6005
const _ROW_MENU_INSPECT := 6006

var _plugin: EditorPlugin
var _actions: UiReactActionController
var _after_wire_mutated: Callable = Callable()

var _hint: RichTextLabel
var _split_main: VSplitContainer
var _rules_scroll: ScrollContainer
var _rules_container: VBoxContainer
var _details_scroll: ScrollContainer
var _details_label: RichTextLabel
var _row_context_popup: PopupMenu

var _target: Node = null
var _edited_scene_root: Node = null
var _selected_rule_index: int = -1
var _row_menu_index: int = -1


func setup(
	plugin: EditorPlugin,
	actions: UiReactActionController,
	after_wire_mutated: Callable = Callable(),
) -> void:
	_plugin = plugin
	_actions = actions
	_after_wire_mutated = after_wire_mutated
	_build_ui()


func set_target_host(host: Control, root: Node) -> void:
	if host == null or root == null:
		_target = null
		_edited_scene_root = null
		_selected_rule_index = -1
		_clear_rules_container()
		_set_details_idle()
		visible = false
		return
	_target = host
	_edited_scene_root = root
	visible = true
	_set_hint(_format_target_hint(host, root))
	var wr: Variant = host.get(&"wire_rules")
	var arr: Array = wr as Array if wr is Array else []
	if arr.is_empty():
		_selected_rule_index = -1
	else:
		_selected_rule_index = clampi(_selected_rule_index, 0, arr.size() - 1)
	_rebuild_rule_rows(arr)
	_update_details_panel()


func focus_rule_index(idx: int) -> void:
	if _target == null:
		return
	var wr: Variant = _target.get(&"wire_rules")
	var arr: Array = wr as Array if wr is Array else []
	if idx < 0 or idx >= arr.size():
		return
	_selected_rule_index = idx
	_rebuild_rule_rows(arr)
	_update_details_panel()


func get_selected_rule_index() -> int:
	return _selected_rule_index


func copy_selected_report_to_clipboard() -> bool:
	if _target == null or _edited_scene_root == null:
		return false
	var wr: Variant = _target.get(&"wire_rules")
	var arr: Array = wr as Array if wr is Array else []
	if _selected_rule_index < 0 or _selected_rule_index >= arr.size():
		return false
	var item: Variant = arr[_selected_rule_index]
	var t: String = _WireDetailsScript.build_details_plain_text(
		item, _selected_rule_index, _target, _edited_scene_root
	)
	DisplayServer.clipboard_set(t)
	return true


func refresh_from_host() -> void:
	if _target == null or _edited_scene_root == null:
		return
	set_target_host(_target as Control, _edited_scene_root)


func append_rule_from_catalog_index(catalog_idx: int) -> void:
	if _target == null or _actions == null:
		return
	if catalog_idx < 0 or catalog_idx >= UiReactWireRuleCatalog.rule_script_entries().size():
		return
	var rule := UiReactWireRuleCatalog.instantiate_rule(catalog_idx)
	if rule == null:
		return
	var arr := _get_wr_array_duplicate()
	if rule.rule_id.is_empty():
		rule.rule_id = "rule_%d" % arr.size()
	arr.append(rule)
	_selected_rule_index = arr.size() - 1
	_commit_wire_rules(arr, "Ui React: Add wire rule")


func _build_ui() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override(&"separation", 6)

	_hint = RichTextLabel.new()
	_hint.bbcode_enabled = true
	_hint.fit_content = true
	_hint.scroll_active = false
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hint.text = "[b]Wire rules[/b] — right-click a row for reorder, duplicate, remove, copy report."
	if _plugin:
		UiReactDockTheme.apply_richtext_content(_hint, _plugin)
	add_child(_hint)

	_split_main = VSplitContainer.new()
	_split_main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_split_main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_split_main.custom_minimum_size = Vector2(0, 140)
	_split_main.add_theme_constant_override(&"autohide", 0)
	_split_main.add_theme_constant_override(&"minimum_grab_thickness", 10)
	if _plugin:
		UiReactDockTheme.apply_split_bar(_split_main, _plugin)
	_split_main.tooltip_text = "Drag to resize the rule list and the report."
	add_child(_split_main)

	var rules_section := VBoxContainer.new()
	rules_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rules_section.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rules_section.add_theme_constant_override(&"separation", 4)
	_split_main.add_child(rules_section)

	var rules_panel := PanelContainer.new()
	rules_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rules_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rules_panel.custom_minimum_size = Vector2(0, 56)
	rules_panel.tooltip_text = "Wire rules for the selected host; order matches wire_rules (see WIRING_LAYER.md)."
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
	report_panel.tooltip_text = "Rule story and fields for the selected row."
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

	if _plugin:
		var bc: Control = _plugin.get_editor_interface().get_base_control()
		_row_context_popup = PopupMenu.new()
		bc.add_child(_row_context_popup)
		_row_context_popup.id_pressed.connect(_on_row_menu_id)

	visible = false
	_set_details_idle()


func _clear_rules_container() -> void:
	for i: int in range(_rules_container.get_child_count() - 1, -1, -1):
		_rules_container.get_child(i).queue_free()


func _rebuild_rule_rows(arr: Array) -> void:
	_clear_rules_container()
	for i: int in range(arr.size()):
		var item: Variant = arr[i]
		_rules_container.add_child(_make_rule_row(i, item, arr.size()))


func _make_rule_row(index: int, item: Variant, arr_size: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	var sel_btn := Button.new()
	sel_btn.text = _format_rule_line(index, item)
	sel_btn.flat = false
	sel_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	sel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sel_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var fi := index
	sel_btn.pressed.connect(func() -> void: _select_rule(fi))
	sel_btn.tooltip_text = "Select this rule. Right-click the row for more actions."
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

	row.gui_input.connect(
		func(ev: InputEvent) -> void: _on_rule_row_gui_input(ev, row, fi, arr_size, item)
	)
	return row


func _on_rule_row_gui_input(ev: InputEvent, row_ctl: Control, index: int, arr_size: int, item: Variant) -> void:
	if _row_context_popup == null:
		return
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			row_ctl.accept_event()
			_selected_rule_index = index
			_row_menu_index = index
			if _target != null:
				var wr: Variant = _target.get(&"wire_rules")
				var arr: Array = wr as Array if wr is Array else []
				_rebuild_rule_rows(arr)
			_update_details_panel()
			_fill_row_context_menu(index, arr_size, item)
			_row_context_popup.position = DisplayServer.mouse_get_position()
			_row_context_popup.popup()


func _fill_row_context_menu(index: int, arr_size: int, item: Variant) -> void:
	var pop := _row_context_popup
	pop.clear()
	pop.add_item("Duplicate", _ROW_MENU_DUPLICATE)
	pop.set_item_disabled(pop.item_count - 1, item == null or not (item is Resource))
	pop.add_separator()
	pop.add_item("Move up", _ROW_MENU_MOVE_UP)
	pop.set_item_disabled(pop.item_count - 1, index <= 0)
	pop.add_item("Move down", _ROW_MENU_MOVE_DOWN)
	pop.set_item_disabled(pop.item_count - 1, index >= arr_size - 1)
	pop.add_separator()
	pop.add_item("Remove", _ROW_MENU_REMOVE)
	pop.add_separator()
	pop.add_item("Copy rule details", _ROW_MENU_COPY_REPORT)
	pop.add_item("Inspect rule", _ROW_MENU_INSPECT)
	pop.set_item_disabled(pop.item_count - 1, item == null or not (item is Resource))


func _on_row_menu_id(id: int) -> void:
	if _target == null:
		return
	var wr: Variant = _target.get(&"wire_rules")
	var arr: Array = wr as Array if wr is Array else []
	var idx := _row_menu_index
	if idx < 0 or idx >= arr.size():
		return
	match id:
		_ROW_MENU_MOVE_UP:
			_move_at(idx, -1)
		_ROW_MENU_MOVE_DOWN:
			_move_at(idx, 1)
		_ROW_MENU_DUPLICATE:
			_duplicate_at(idx)
		_ROW_MENU_REMOVE:
			_remove_at(idx)
		_ROW_MENU_COPY_REPORT:
			var item: Variant = arr[idx]
			var t: String = _WireDetailsScript.build_details_plain_text(
				item, idx, _target, _edited_scene_root
			)
			DisplayServer.clipboard_set(t)
		_ROW_MENU_INSPECT:
			_inspect_at(idx)
		_:
			pass


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
		return "[b]Wire rules[/b] — host [b]%s[/b] (scene root)" % n.name
	return "[b]Wire rules[/b] — host [b]%s[/b] · [code]%s[/code]" % [n.name, rel_str]


func _set_hint(bbcode: String) -> void:
	_hint.text = bbcode
	if _plugin:
		UiReactDockTheme.apply_richtext_content(_hint, _plugin)


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
	if wr is Array[UiReactWireRule]:
		return (wr as Array[UiReactWireRule]).duplicate()
	var plain: Array = wr as Array
	var out: Array[UiReactWireRule] = []
	for it: Variant in plain:
		if it is UiReactWireRule:
			out.append(it as UiReactWireRule)
	return out


func _commit_wire_rules(next: Array[UiReactWireRule], action_label: String) -> void:
	if _target == null or _actions == null:
		return
	_actions.assign_property_variant(_target, &"wire_rules", next, action_label)
	if _after_wire_mutated.is_valid():
		_after_wire_mutated.call()
	else:
		refresh_from_host()


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
	if _after_wire_mutated.is_valid():
		_after_wire_mutated.call()
	else:
		refresh_from_host()


func _inspect_at(index: int) -> void:
	if _target == null or _plugin == null:
		return
	var arr := _get_wr_array_duplicate()
	if index < 0 or index >= arr.size():
		return
	var item: Variant = arr[index]
	if item is Resource:
		_plugin.get_editor_interface().edit_resource(item as Resource)

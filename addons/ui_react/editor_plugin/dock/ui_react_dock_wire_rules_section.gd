## Embedded [code]wire_rules[/code] list under the Dependency Graph details ([code]CB-058[/code]); row actions stay inline.
class_name UiReactDockWireRulesSection
extends VBoxContainer

const _WireDetailsScript := preload("res://addons/ui_react/editor_plugin/dock/ui_react_dock_wire_details.gd")
const _WireGraphEditScript := preload("res://addons/ui_react/editor_plugin/services/ui_react_wire_graph_edit_service.gd")
const _WireShallowEditorScript := preload("res://addons/ui_react/editor_plugin/dock/ui_react_dock_wire_rule_shallow_editor.gd")

const _LIST_VISIBLE_RULE_ROWS := 3
const _RULE_ROW_EST_HEIGHT := 30
const _LIST_EXTRA_CHROME_HEIGHT := 12

signal rule_selection_changed(rule_index: int)

var _plugin: EditorPlugin
var _actions: UiReactActionController
var _after_wire_mutated: Callable = Callable()

var _rules_scroll: ScrollContainer
var _rules_container: VBoxContainer
var _shallow_editor = null

var _target: Node = null
var _edited_scene_root: Node = null
var _selected_rule_index: int = -1
var _last_emitted_rule_index: int = -2


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
		if _shallow_editor != null:
			_shallow_editor.clear()
		visible = false
		_emit_rule_selection_changed()
		return
	_target = host
	_edited_scene_root = root
	visible = true
	var wr: Variant = host.get(&"wire_rules")
	var arr: Array = wr as Array if wr is Array else []
	if arr.is_empty():
		_selected_rule_index = -1
	else:
		_selected_rule_index = clampi(_selected_rule_index, 0, arr.size() - 1)
	_rebuild_rule_rows(arr)
	_emit_rule_selection_changed()


# Graph-driven list sync only; do not open the Inspector (avoids stealing focus from graph work).
func focus_rule_index(idx: int) -> void:
	if _target == null:
		return
	var wr: Variant = _target.get(&"wire_rules")
	var arr: Array = wr as Array if wr is Array else []
	if idx < 0 or idx >= arr.size():
		return
	if _selected_rule_index == idx:
		_sync_shallow_editor_to_selection()
		return
	_selected_rule_index = idx
	_rebuild_rule_rows(arr)
	_emit_rule_selection_changed()


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
	add_theme_constant_override(&"separation", 4)
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	var rules_panel := PanelContainer.new()
	rules_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rules_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	rules_panel.custom_minimum_size = Vector2(0, 46)
	rules_panel.tooltip_text = "Wire rules for the selected host; order matches wire_rules (see WIRING_LAYER.md)."
	add_child(rules_panel)
	if _plugin:
		UiReactDockTheme.apply_panelcontainer(rules_panel, _plugin)

	var rules_margin := MarginContainer.new()
	rules_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rules_margin.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	rules_margin.add_theme_constant_override(&"margin_left", 6)
	rules_margin.add_theme_constant_override(&"margin_right", 6)
	rules_margin.add_theme_constant_override(&"margin_top", 6)
	rules_margin.add_theme_constant_override(&"margin_bottom", 6)
	rules_panel.add_child(rules_margin)

	var rules_outer := VBoxContainer.new()
	rules_outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rules_outer.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	rules_outer.add_theme_constant_override(&"separation", 6)
	rules_margin.add_child(rules_outer)

	_rules_scroll = ScrollContainer.new()
	_rules_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rules_scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_rules_scroll.custom_minimum_size = Vector2(0, _RULE_ROW_EST_HEIGHT + _LIST_EXTRA_CHROME_HEIGHT)
	rules_outer.add_child(_rules_scroll)

	_rules_container = VBoxContainer.new()
	_rules_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rules_container.add_theme_constant_override(&"separation", 4)
	_rules_scroll.add_child(_rules_container)

	_shallow_editor = _WireShallowEditorScript.new()
	_shallow_editor.setup(_actions, _after_wire_mutated)
	rules_outer.add_child(_shallow_editor)

	visible = false


func _clear_rules_container() -> void:
	for i: int in range(_rules_container.get_child_count() - 1, -1, -1):
		_rules_container.get_child(i).queue_free()
	_update_rules_scroll_height(0)


func _rebuild_rule_rows(arr: Array) -> void:
	_clear_rules_container()
	for i: int in range(arr.size()):
		var item: Variant = arr[i]
		_rules_container.add_child(_make_rule_row(i, item, arr.size()))
	_update_rules_scroll_height(arr.size())
	_sync_shallow_editor_to_selection()


func _sync_shallow_editor_to_selection() -> void:
	if _shallow_editor == null:
		return
	if _target == null:
		_shallow_editor.clear()
		return
	_shallow_editor.set_context(_target as Control, _edited_scene_root, _selected_rule_index)


## Sets list selection + highlight + shallow quick-edit; does not open the Inspector (use [code]_select_rule[/code] for that).
func _select_row_for_quick_edit(index: int) -> void:
	if _target == null:
		return
	var wr: Variant = _target.get(&"wire_rules")
	var arr: Array = wr as Array if wr is Array else []
	if index < 0 or index >= arr.size():
		return
	_selected_rule_index = index
	_rebuild_rule_rows(arr)
	_emit_rule_selection_changed()


func _update_rules_scroll_height(rule_count: int) -> void:
	if _rules_scroll == null:
		return
	var visible_rows := mini(maxi(rule_count, 1), _LIST_VISIBLE_RULE_ROWS)
	_rules_scroll.custom_minimum_size = Vector2(
		0,
		visible_rows * _RULE_ROW_EST_HEIGHT + _LIST_EXTRA_CHROME_HEIGHT
	)


func _make_rule_row(index: int, item: Variant, arr_size: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 4)
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fi := index

	var enabled_cb := CheckBox.new()
	enabled_cb.text = ""
	enabled_cb.tooltip_text = "Enable or pause this rule."
	enabled_cb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	enabled_cb.disabled = item == null or not (item is UiReactWireRule)
	if item is UiReactWireRule:
		enabled_cb.button_pressed = (item as UiReactWireRule).enabled
	enabled_cb.toggled.connect(func(on: bool) -> void: _on_row_enabled_toggled(fi, on))
	row.add_child(enabled_cb)

	var sel_btn := Button.new()
	sel_btn.text = _format_rule_line(index, item)
	sel_btn.flat = false
	sel_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	sel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sel_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	sel_btn.pressed.connect(func() -> void: _select_rule(fi))
	sel_btn.tooltip_text = (
		"Select this rule for quick edit below and open the rule resource in the Inspector. "
		+ "Row controls (enable, trigger, order) also move quick edit to that row without opening the Inspector."
	)
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

	var trig_opt := OptionButton.new()
	trig_opt.tooltip_text = "Choose when this rule fires."
	trig_opt.custom_minimum_size = Vector2(110, 0)
	var trig_ids: PackedInt32Array = _WireGraphEditScript.wire_trigger_kind_ordinals_in_ui_order()
	for k in range(trig_ids.size()):
		var tid := int(trig_ids[k])
		trig_opt.add_item(_WireGraphEditScript.wire_trigger_kind_label(tid), tid)
	trig_opt.disabled = item == null or not (item is UiReactWireRule)
	if item is UiReactWireRule:
		var trig_ord := int((item as UiReactWireRule).trigger)
		for k2 in range(trig_opt.item_count):
			if trig_opt.get_item_id(k2) == trig_ord:
				trig_opt.select(k2)
				break
	trig_opt.item_selected.connect(
		func(sel_idx: int) -> void: _on_row_trigger_selected(fi, trig_opt.get_item_id(sel_idx))
	)
	row.add_child(trig_opt)

	var order := SpinBox.new()
	order.tooltip_text = "Rule order (runtime evaluation order)."
	order.min_value = 1.0
	order.max_value = float(maxi(1, arr_size))
	order.step = 1.0
	order.rounded = true
	order.allow_greater = false
	order.allow_lesser = false
	order.value = float(fi + 1)
	order.custom_minimum_size = Vector2(56, 0)
	order.value_changed.connect(func(v: float) -> void: _on_row_order_changed(fi, int(round(v))))
	row.add_child(order)

	var dup_btn := Button.new()
	dup_btn.text = "Duplicate"
	dup_btn.tooltip_text = "Duplicate this rule."
	dup_btn.disabled = item == null or not (item is Resource)
	dup_btn.pressed.connect(func() -> void: _duplicate_at(fi))
	row.add_child(dup_btn)

	var del_btn := Button.new()
	del_btn.text = "Delete"
	del_btn.tooltip_text = "Delete this rule."
	del_btn.pressed.connect(func() -> void: _remove_at(fi))
	row.add_child(del_btn)

	var copy_btn := Button.new()
	copy_btn.text = "Copy details"
	copy_btn.tooltip_text = "Copy this rule's details."
	copy_btn.disabled = item == null or not (item is UiReactWireRule)
	copy_btn.pressed.connect(func() -> void: _copy_details_at(fi))
	row.add_child(copy_btn)

	return row


func _select_rule(index: int) -> void:
	_selected_rule_index = index
	if _target == null:
		return
	var wr: Variant = _target.get(&"wire_rules")
	var arr: Array = wr as Array if wr is Array else []
	_rebuild_rule_rows(arr)
	_emit_rule_selection_changed()
	_inspect_at(index)


func _format_rule_line(index: int, item: Variant) -> String:
	if item == null:
		return "[%d] (null)" % (index + 1)
	var cls := _rule_class_label(item)
	var rule_field := "—"
	if item is UiReactWireRule:
		var rid: String = (item as UiReactWireRule).rule_id
		if not rid.is_empty():
			rule_field = rid
	return "[%d] %s — %s" % [index + 1, cls, rule_field]


func _rule_class_label(item: Variant) -> String:
	var cls := "?"
	if item is Object and (item as Object).get_script() != null:
		var script: Script = (item as Object).get_script() as Script
		var gn: StringName = script.get_global_name()
		if String(gn) != "":
			cls = String(gn)
		else:
			cls = script.resource_path.get_file().get_basename()
	return cls


func _on_row_enabled_toggled(index: int, enabled: bool) -> void:
	if _target == null or _actions == null:
		return
	if not _WireGraphEditScript.try_commit_wire_rule_enabled(
		_target as Control,
		index,
		enabled,
		_actions
	):
		return
	_select_row_for_quick_edit(index)
	if _after_wire_mutated.is_valid():
		_after_wire_mutated.call()
	else:
		refresh_from_host()


func _on_row_trigger_selected(index: int, trigger_ordinal: int) -> void:
	if _target == null or _actions == null:
		return
	if not _WireGraphEditScript.try_commit_wire_rule_trigger(
		_target as Control,
		index,
		trigger_ordinal,
		_actions
	):
		return
	_select_row_for_quick_edit(index)
	if _after_wire_mutated.is_valid():
		_after_wire_mutated.call()
	else:
		refresh_from_host()


func _on_row_order_changed(from_index: int, target_1_based: int) -> void:
	var to_index := clampi(target_1_based - 1, 0, maxi(0, _get_wr_array_duplicate().size() - 1))
	_move_to_index(from_index, to_index)


func _emit_rule_selection_changed() -> void:
	if _selected_rule_index == _last_emitted_rule_index:
		return
	_last_emitted_rule_index = _selected_rule_index
	rule_selection_changed.emit(_selected_rule_index)


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
	_last_emitted_rule_index = -2
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
	_commit_wire_rules(arr, "Ui React: Delete wire rule")


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


func _move_to_index(index: int, target_index: int) -> void:
	if _target == null:
		return
	var arr := _get_wr_array_duplicate()
	if index < 0 or index >= arr.size():
		return
	if target_index < 0 or target_index >= arr.size():
		return
	if target_index == index:
		return
	var moving: UiReactWireRule = arr[index]
	arr.remove_at(index)
	arr.insert(target_index, moving)
	_selected_rule_index = target_index
	_actions.assign_property_variant(_target, &"wire_rules", arr, "Ui React: Reorder wire rule")
	_last_emitted_rule_index = -2
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


func _copy_details_at(index: int) -> void:
	if _target == null or _edited_scene_root == null:
		return
	var wr: Variant = _target.get(&"wire_rules")
	var arr: Array = wr as Array if wr is Array else []
	if index < 0 or index >= arr.size():
		return
	var item: Variant = arr[index]
	var t: String = _WireDetailsScript.build_details_plain_text(
		item,
		index,
		_target,
		_edited_scene_root
	)
	DisplayServer.clipboard_set(t)

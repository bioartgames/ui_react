extends CanvasLayer


var _panel: PanelContainer
var _list: ItemList
var _header: Label
var _click_through: CheckBox


func _ready() -> void:
	layer = 100

	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_panel)

	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_panel.add_child(vb)

	_header = Label.new()
	_header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(_header)

	_click_through = CheckBox.new()
	_click_through.button_pressed = false
	_click_through.text = "Click-through panel (mouse to game)"
	vb.add_child(_click_through)
	_click_through.toggled.connect(_on_click_through_toggled)

	_list = ItemList.new()
	_list.custom_minimum_size = Vector2(200, 80)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(_list)

	visible = false
	get_viewport().size_changed.connect(_update_layout_geometry)
	_update_layout_geometry()


func _update_layout_geometry() -> void:
	if _panel == null:
		return
	var vs := get_viewport().get_visible_rect().size
	_panel.custom_minimum_size = Vector2(maxf(vs.x * 0.96 - 24.0, 320.0), maxf(vs.y * 0.4, 160.0))
	_panel.global_position = Vector2(12, 12)


func set_header_text(txt: String) -> void:
	if _header:
		_header.text = txt


func toggle_visible() -> void:
	visible = not visible


func refresh_items(rows: Array) -> void:
	if _list == null:
		return
	_list.clear()
	for raw in rows:
		if raw is not Dictionary:
			continue
		_list.add_item(_format_row(raw as Dictionary))


func _on_click_through_toggled(pressed: bool) -> void:
	if _panel:
		_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE if pressed else Control.MOUSE_FILTER_STOP
	if _list:
		_list.mouse_filter = Control.MOUSE_FILTER_IGNORE if pressed else Control.MOUSE_FILTER_STOP
	if _header:
		_header.mouse_filter = Control.MOUSE_FILTER_IGNORE if pressed else Control.MOUSE_FILTER_STOP
	if _click_through:
		_click_through.mouse_filter = Control.MOUSE_FILTER_IGNORE if pressed else Control.MOUSE_FILTER_STOP


func _format_row(d: Dictionary) -> String:
	var kk := UiReactLiveDebugEventKinds
	var kt := int(d.get(kk.META_KIND, -1))
	var seq := str(d.get(kk.META_SEQ, "?"))
	match kt:
		int(kk.Kind.STATE_VALUE_CHANGED):
			return "[%s] state %s \"%s\"" % [
				seq,
				_trunc(str(d.get(kk.META_STATE_ID, "?"))),
				_trunc(str(d.get(kk.META_NEW_VALUE_STR, ""))),
			]
		int(kk.Kind.COMPUTED_RECOMPUTE):
			return "[%s] recompute %s" % [seq, _trunc(str(d.get(kk.META_STATE_ID, "?")))]
		int(kk.Kind.WIRE_RULE_APPLY):
			return "[%s] wire %s @ %s" % [
				seq,
				_trunc(str(d.get(kk.META_RULE_ID, "?"))),
				_trunc(str(d.get(kk.META_HOST_PATH, ""))),
			]
		int(kk.Kind.ACTION_APPLY):
			return "[%s] action row %s kind %s via %s @ %s" % [
				seq,
				str(d.get(kk.META_ROW_INDEX, "?")),
				str(d.get(kk.META_ACTION_KIND, "?")),
				str(d.get(kk.META_VIA, "")),
				_trunc(str(d.get(kk.META_HOST_PATH, ""))),
			]
		_:
			return "[%s] (?)" % seq


func _trunc(s: String) -> String:
	if s.length() <= 96:
		return s
	return s.substr(0, 93) + "..."

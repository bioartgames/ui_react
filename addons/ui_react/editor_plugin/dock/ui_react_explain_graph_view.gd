## Graph canvas for Dependency Graph visual mode ([code]CB-018A.1[/code]–[code]CB-018A.3[/code]); [b]Shift+drag[/b] reconnect + [b]Ctrl+Shift+drag[/b] new link (**[code]CB-058[/code]**).
class_name UiReactExplainGraphView
extends Control

signal node_selected(node_id: String)
signal edge_selected(from_id: String, to_id: String, kind: int, label: String, edge_index: int)
signal selection_cleared
## Fired when reconnect rubber-band drag crosses the movement threshold ([param edge_index] is [member _selected_edge_index]).
signal reconnect_drag_started(edge_index: int, origin_node_id: String)
## [param target_node_id] is empty if cancelled, released on canvas, or invalid; panel validates and commits.
signal reconnect_drag_ended(edge_index: int, origin_node_id: String, target_node_id: String)
signal newlink_drag_started(donor_node_id: String)
## [param target_node_id] empty if cancel / no hit; requires no edge selected when starting (**[code]CB-058[/code]** phase 2b).
signal newlink_drag_ended(donor_node_id: String, target_node_id: String)
## **Delete** / **Backspace** with an edge selected (**[code]CB-058[/code]** slice 1); panel decides if disconnect applies.
signal edge_disconnect_requested(edge_index: int)

const _Snap := preload("res://addons/ui_react/editor_plugin/models/ui_react_explain_graph_snapshot.gd")

const MIN_ZOOM := 0.55
const MAX_ZOOM := 1.75
const LABEL_ZOOM_MIN := 0.82
const NODE_W := 140.0
const NODE_H := 32.0
const NODE_FS := 12
const NODE_RADIUS := 6.0
const VIEW_PAD := 10.0

var _sb_fill: StyleBoxFlat
var _sb_sel: StyleBoxFlat
var _sb_hover: StyleBoxFlat
var _sb_valid: StyleBoxFlat
var _sb_valid_newlink: StyleBoxFlat

var _reconnect_can_start_cb: Callable = Callable()
var _reconnect_is_valid_target_cb: Callable = Callable()
var _shift_reconnect_pending := false
var _reconnect_active := false
var _reconnect_origin_node_id: String = ""
var _press_screen := Vector2.ZERO
var _reconnect_cursor_graph := Vector2.ZERO
const _RECONNECT_DRAG_THRESHOLD_PX := 6.0

var _newlink_can_start_cb: Callable = Callable()
var _newlink_is_valid_drop_cb: Callable = Callable()
var _newlink_pending := false
var _newlink_active := false
var _newlink_donor_id: String = ""
var _newlink_cursor_graph := Vector2.ZERO

var _layout: Dictionary = {}
var _pan := Vector2.ZERO
var _zoom := 1.0
var _dragging := false
var _last_mouse := Vector2.ZERO
var _selected_node_id: String = ""
var _selected_edge_index: int = -1
var _hover_node_id: String = ""
var _hover_edge_index: int = -1

var _show_binding: bool = true
var _show_computed: bool = true
var _show_wire: bool = true
var _show_all_edge_labels: bool = false

var _canvas_bg := Color(0.1, 0.11, 0.13, 1.0)
var _canvas_border := Color(0.38, 0.4, 0.46, 0.65)


func _ready() -> void:
	clip_contents = true
	focus_mode = Control.FOCUS_CLICK
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(200, 160)
	_sb_fill = StyleBoxFlat.new()
	_sb_fill.set_corner_radius_all(int(NODE_RADIUS))
	_sb_sel = StyleBoxFlat.new()
	_sb_sel.bg_color = Color(0, 0, 0, 0)
	_sb_sel.border_color = Color(1.0, 0.92, 0.35, 1.0)
	_sb_sel.set_border_width_all(2)
	_sb_sel.set_corner_radius_all(int(NODE_RADIUS) + 2)
	_sb_hover = StyleBoxFlat.new()
	_sb_hover.bg_color = Color(0, 0, 0, 0)
	_sb_hover.border_color = Color(1.0, 1.0, 0.85, 0.55)
	_sb_hover.set_border_width_all(1)
	_sb_hover.set_corner_radius_all(int(NODE_RADIUS) + 1)
	_sb_valid = StyleBoxFlat.new()
	_sb_valid.bg_color = Color(0, 0, 0, 0)
	_sb_valid.border_color = Color(0.35, 0.85, 0.45, 0.95)
	_sb_valid.set_border_width_all(2)
	_sb_valid.set_corner_radius_all(int(NODE_RADIUS) + 3)
	_sb_valid_newlink = StyleBoxFlat.new()
	_sb_valid_newlink.bg_color = Color(0, 0, 0, 0)
	_sb_valid_newlink.border_color = Color(0.95, 0.72, 0.35, 0.95)
	_sb_valid_newlink.set_border_width_all(2)
	_sb_valid_newlink.set_corner_radius_all(int(NODE_RADIUS) + 3)


## Panel supplies policy for [b]Shift+drag[/b] reconnect; call with empty Callables to disable.
func set_reconnect_handlers(can_start: Callable, is_valid_target: Callable) -> void:
	_reconnect_can_start_cb = can_start
	_reconnect_is_valid_target_cb = is_valid_target


## Panel supplies policy for [b]Ctrl+Shift+drag[/b] new link (no edge selected); empty Callables disable.
func set_newlink_handlers(can_start: Callable, is_valid_drop: Callable) -> void:
	_newlink_can_start_cb = can_start
	_newlink_is_valid_drop_cb = is_valid_drop


func set_edge_filters(show_binding: bool, show_computed: bool, show_wire: bool, show_all_edge_labels: bool) -> void:
	_show_binding = show_binding
	_show_computed = show_computed
	_show_wire = show_wire
	_show_all_edge_labels = show_all_edge_labels
	queue_redraw()


func clear_graph() -> void:
	_layout.clear()
	_selected_node_id = ""
	_selected_edge_index = -1
	_hover_node_id = ""
	_hover_edge_index = -1
	_pan = Vector2.ZERO
	_zoom = 1.0
	_clear_reconnect_drag_state()
	_clear_newlink_drag_state()
	queue_redraw()


func set_layout(layout: Dictionary) -> void:
	_layout = layout
	_selected_node_id = ""
	_selected_edge_index = -1
	_hover_node_id = ""
	_hover_edge_index = -1
	_clear_reconnect_drag_state()
	_clear_newlink_drag_state()
	reset_view()


## Programmatic node selection (e.g. auto-select graph center after layout). Emits [signal node_selected].
func select_node_by_id(node_id: String) -> void:
	if _layout.is_empty():
		return
	var node_by_id: Dictionary = _layout.get(&"node_by_id", {}) as Dictionary
	if not node_by_id.has(node_id):
		return
	_selected_node_id = node_id
	_selected_edge_index = -1
	queue_redraw()
	node_selected.emit(node_id)


func reset_view() -> void:
	var ir := _inner_rect()
	_pan = ir.position + ir.size * 0.5
	_zoom = 1.0
	queue_redraw()


func _inner_rect() -> Rect2:
	return Rect2(VIEW_PAD, VIEW_PAD, maxf(1.0, size.x - 2.0 * VIEW_PAD), maxf(1.0, size.y - 2.0 * VIEW_PAD))


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), _canvas_bg.darkened(0.12))
	var ir := _inner_rect()
	draw_rect(ir, _canvas_bg)
	draw_rect(ir, _canvas_border, false, 1.0)

	if _layout.is_empty():
		draw_string(ThemeDB.fallback_font, ir.position + Vector2(8, 22), "No graph data.", HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
		return

	draw_set_transform(_pan, 0.0, Vector2(_zoom, _zoom))

	var centers: Dictionary = _layout.get(&"node_centers", {}) as Dictionary
	var node_by_id: Dictionary = _layout.get(&"node_by_id", {}) as Dictionary
	var edges: Array = _layout.get(&"draw_edges", []) as Array
	var focus_id: String = str(_layout.get(&"focus_id", ""))

	var focus_active := _selection_or_hover_active()
	var ek := _Snap.EdgeKind

	var ei := 0
	for e: Variant in edges:
		if e is not Dictionary:
			ei += 1
			continue
		var ed: Dictionary = e as Dictionary
		if not _edge_visible(ed):
			ei += 1
			continue
		var fa := str(ed.get(&"from_id", ""))
		var ta := str(ed.get(&"to_id", ""))
		if not centers.has(fa) or not centers.has(ta):
			ei += 1
			continue
		var col := Color(0.55, 0.55, 0.6, 1.0)
		var width := 1.5
		var k := int(ed.get(&"kind", -1))
		if k == ek.WIRE_FLOW:
			col = Color(0.85, 0.45, 0.35, 1.0)
			width = 2.2
		elif k == ek.COMPUTED_SOURCE:
			col = Color(0.45, 0.65, 0.85, 1.0)
			width = 1.8
		if focus_active and not _edge_is_focused(ei):
			col.a = 0.16
			width *= 0.85
		var pts: Variant = ed.get(&"route_points", null)
		if pts is PackedVector2Array and (pts as PackedVector2Array).size() >= 2:
			_draw_polyline(pts as PackedVector2Array, col, width)
			if ei == _selected_edge_index:
				_draw_polyline(pts as PackedVector2Array, Color(1.0, 0.92, 0.35, 0.95), width + 2.2)
			elif ei == _hover_edge_index:
				_draw_polyline(pts as PackedVector2Array, Color(1.0, 1.0, 0.75, 0.55), width + 1.0)
			_draw_arrow_along_polyline(pts as PackedVector2Array, col, width + 0.5)
		else:
			var pa: Vector2 = centers[fa] as Vector2
			var pb: Vector2 = centers[ta] as Vector2
			draw_line(pa, pb, col, width, true)
			if ei == _selected_edge_index:
				draw_line(pa, pb, Color(1.0, 0.92, 0.35, 1.0), width + 2.0, true)
		ei += 1

	for nid: Variant in centers:
		var id := String(nid)
		var c: Vector2 = centers[nid] as Vector2
		var rect := Rect2(c - Vector2(NODE_W * 0.5, NODE_H * 0.5), Vector2(NODE_W, NODE_H))
		var nk := int((node_by_id.get(id, {}) as Dictionary).get(&"kind", 0))
		var fill := Color(0.22, 0.24, 0.3, 1.0)
		if nk == _Snap.NodeKind.UI_STATE:
			fill = Color(0.18, 0.28, 0.42, 1.0)
		elif nk == _Snap.NodeKind.UI_COMPUTED:
			fill = Color(0.28, 0.22, 0.4, 1.0)
		if id == focus_id:
			fill = Color(0.25, 0.42, 0.32, 1.0)
		if focus_active and not _node_is_focused(id):
			fill.a = 0.28
		_sb_fill.bg_color = fill
		draw_style_box(_sb_fill, rect)
		if (
			_reconnect_active
			and _selected_edge_index >= 0
			and _reconnect_is_valid_target_cb.is_valid()
			and _reconnect_is_valid_target_cb.call(_selected_edge_index, _reconnect_origin_node_id, id)
		):
			draw_style_box(_sb_valid, rect.grow(3.0))
		if (
			_newlink_active
			and _newlink_is_valid_drop_cb.is_valid()
			and _newlink_is_valid_drop_cb.call(_newlink_donor_id, id)
		):
			draw_style_box(_sb_valid_newlink, rect.grow(3.0))
		if id == _selected_node_id:
			draw_style_box(_sb_sel, rect.grow(2.0))
		elif id == _hover_node_id:
			draw_style_box(_sb_hover, rect.grow(1.0))
		var dct: Dictionary = node_by_id.get(id, {}) as Dictionary
		var lab2 := str(dct.get(&"short_label", dct.get(&"label", id)))
		if lab2.length() > 18:
			lab2 = lab2.substr(0, 16) + "…"
		_draw_centered_node_label(c, lab2, Color(0.92, 0.92, 0.95, 1.0))

	ei = 0
	for e2: Variant in edges:
		if e2 is not Dictionary:
			ei += 1
			continue
		var edl: Dictionary = e2 as Dictionary
		if not _edge_visible(edl):
			ei += 1
			continue
		var fa2 := str(edl.get(&"from_id", ""))
		var ta2 := str(edl.get(&"to_id", ""))
		if not centers.has(fa2) or not centers.has(ta2):
			ei += 1
			continue
		var pts2: Variant = edl.get(&"route_points", null)
		_draw_edge_label_if_needed(ei, edl, centers, pts2)
		ei += 1

	if _reconnect_active and not _reconnect_origin_node_id.is_empty():
		var oc: Variant = centers.get(_reconnect_origin_node_id, null)
		if oc is Vector2:
			draw_line(oc as Vector2, _reconnect_cursor_graph, Color(0.45, 0.92, 1.0, 0.92), 2.5, true)
	if _newlink_active and not _newlink_donor_id.is_empty():
		var ocn: Variant = centers.get(_newlink_donor_id, null)
		if ocn is Vector2:
			_draw_dashed_line(
				ocn as Vector2,
				_newlink_cursor_graph,
				Color(0.95, 0.78, 0.4, 0.92),
				2.2,
				7.0
			)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var gs: Variant = _layout.get(&"graph_stats", null)
	if gs is Dictionary:
		var gsd: Dictionary = gs as Dictionary
		var nc := int(gsd.get(&"node_count", 0))
		var ec := int(gsd.get(&"edge_count", 0))
		var tr := bool(gsd.get(&"truncated", false))
		var line := "Nodes: %d  Edges: %d" % [nc, ec]
		if tr:
			line += "  (truncated)"
		draw_string(ThemeDB.fallback_font, Vector2(VIEW_PAD + 4, size.y - 6), line, HORIZONTAL_ALIGNMENT_LEFT, int(size.x - 16), 10, Color(0.78, 0.8, 0.88, 0.95))


func _draw_centered_node_label(center: Vector2, text: String, modulate: Color) -> void:
	var font := ThemeDB.fallback_font
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, NODE_FS).x
	var baseline := center.y + font.get_ascent(NODE_FS) * 0.35
	draw_string(
		font,
		Vector2(center.x - tw * 0.5, baseline),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		NODE_FS,
		modulate
	)


func _draw_dashed_line(from: Vector2, to: Vector2, col: Color, width: float, dash_len: float) -> void:
	var seg := to - from
	var slen := seg.length()
	if slen < 0.001:
		return
	var dir := seg / slen
	var t := 0.0
	var draw_seg := true
	while t < slen:
		var t2 := minf(t + dash_len, slen)
		if draw_seg:
			draw_line(from + dir * t, from + dir * t2, col, width, true)
		t = t2
		draw_seg = not draw_seg


func _draw_polyline(pts: PackedVector2Array, col: Color, width: float) -> void:
	for i in range(pts.size() - 1):
		draw_line(pts[i], pts[i + 1], col, width, true)


func _draw_arrow_along_polyline(pts: PackedVector2Array, col: Color, width: float) -> void:
	if pts.size() < 2:
		return
	var a: Vector2 = pts[pts.size() - 2]
	var b: Vector2 = pts[pts.size() - 1]
	var dir := b - a
	if dir.length_squared() < 0.0001:
		return
	dir = dir.normalized()
	var head := 9.0
	var wing := 4.0
	var tip := b
	var base := b - dir * head
	var perp := Vector2(-dir.y, dir.x)
	var c := col
	c.a = minf(1.0, col.a + 0.15)
	draw_line(base + perp * wing, tip, c, maxf(1.0, width * 0.6), true)
	draw_line(base - perp * wing, tip, c, maxf(1.0, width * 0.6), true)


func _draw_edge_label_if_needed(ei: int, ed: Dictionary, centers: Dictionary, pts: Variant) -> void:
	var show_full := ei == _selected_edge_index or ei == _hover_edge_index
	if not show_full and not _show_all_edge_labels:
		return
	if _zoom < LABEL_ZOOM_MIN:
		return
	var text := str(ed.get(&"short_label", "?"))
	if show_full:
		text = str(ed.get(&"label", text))
	if text.length() > 40:
		text = text.substr(0, 38) + "…"
	var mid: Vector2
	if pts is PackedVector2Array and (pts as PackedVector2Array).size() >= 2:
		var arr := pts as PackedVector2Array
		var mid_i := arr.size() / 2
		mid = (arr[mid_i] + arr[mid_i - 1]) * 0.5 if mid_i > 0 else arr[0]
	else:
		var fa := str(ed.get(&"from_id", ""))
		var ta := str(ed.get(&"to_id", ""))
		mid = ((centers[fa] as Vector2) + (centers[ta] as Vector2)) * 0.5
	draw_string(ThemeDB.fallback_font, mid + Vector2(4, -5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.78, 0.78, 0.86, 0.92))


func _edge_visible(ed: Dictionary) -> bool:
	var k := int(ed.get(&"kind", -1))
	if k == _Snap.EdgeKind.BINDING:
		return _show_binding
	if k == _Snap.EdgeKind.COMPUTED_SOURCE:
		return _show_computed
	if k == _Snap.EdgeKind.WIRE_FLOW:
		return _show_wire
	return true


func _selection_or_hover_active() -> bool:
	return not _selected_node_id.is_empty() or _selected_edge_index >= 0 or not _hover_node_id.is_empty() or _hover_edge_index >= 0


func _node_is_focused(id: String) -> bool:
	if id == _selected_node_id or id == _hover_node_id:
		return true
	if _selected_edge_index >= 0:
		var ed: Variant = _edge_at_index(_selected_edge_index)
		if ed is Dictionary:
			var d: Dictionary = ed as Dictionary
			return id == str(d.get(&"from_id", "")) or id == str(d.get(&"to_id", ""))
	if _hover_edge_index >= 0:
		var ed2: Variant = _edge_at_index(_hover_edge_index)
		if ed2 is Dictionary:
			var d2: Dictionary = ed2 as Dictionary
			return id == str(d2.get(&"from_id", "")) or id == str(d2.get(&"to_id", ""))
	return false


func _edge_is_focused(ei: int) -> bool:
	if ei == _selected_edge_index or ei == _hover_edge_index:
		return true
	var ev: Variant = _edge_at_index(ei)
	if ev is Dictionary:
		var ed: Dictionary = ev as Dictionary
		var fa := str(ed.get(&"from_id", ""))
		var ta := str(ed.get(&"to_id", ""))
		if fa == _selected_node_id or ta == _selected_node_id:
			return true
		if fa == _hover_node_id or ta == _hover_node_id:
			return true
	return false


func _edge_at_index(i: int) -> Variant:
	var edges: Array = _layout.get(&"draw_edges", []) as Array
	if i < 0 or i >= edges.size():
		return null
	return edges[i]


func _clear_reconnect_drag_state() -> void:
	_shift_reconnect_pending = false
	_reconnect_active = false
	_reconnect_origin_node_id = ""


func _clear_newlink_drag_state() -> void:
	_newlink_pending = false
	_newlink_active = false
	_newlink_donor_id = ""


func _hit_test_node_id(screen_local: Vector2) -> String:
	if _layout.is_empty():
		return ""
	if not _inner_rect().has_point(screen_local):
		return ""
	var g := _screen_to_graph(screen_local, _zoom)
	var centers: Dictionary = _layout.get(&"node_centers", {}) as Dictionary
	var best_id := ""
	var best_d := 1e12
	for nid: Variant in centers:
		var c: Vector2 = centers[nid] as Vector2
		var rect := Rect2(c - Vector2(NODE_W * 0.5, NODE_H * 0.5), Vector2(NODE_W, NODE_H))
		if rect.has_point(g):
			var ds := g.distance_squared_to(c)
			if ds < best_d:
				best_d = ds
				best_id = String(nid)
	return best_id


func _try_begin_shift_reconnect(screen_local: Vector2, shift_pressed: bool) -> bool:
	if not shift_pressed or _selected_edge_index < 0:
		return false
	if not _reconnect_can_start_cb.is_valid():
		return false
	var nid := _hit_test_node_id(screen_local)
	if nid.is_empty():
		return false
	if not bool(_reconnect_can_start_cb.call(_selected_edge_index, nid)):
		return false
	_shift_reconnect_pending = true
	_reconnect_origin_node_id = nid
	_press_screen = screen_local
	return true


func _try_begin_ctrl_shift_newlink(screen_local: Vector2, ctrl: bool, shift: bool) -> bool:
	if not ctrl or not shift or _selected_edge_index >= 0:
		return false
	if not _newlink_can_start_cb.is_valid():
		return false
	var nid := _hit_test_node_id(screen_local)
	if nid.is_empty():
		return false
	if not bool(_newlink_can_start_cb.call(nid)):
		return false
	_newlink_pending = true
	_newlink_donor_id = nid
	_press_screen = screen_local
	return true


func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and (event.keycode == KEY_DELETE or event.keycode == KEY_BACKSPACE):
		if (
			_selected_edge_index >= 0
			and not _reconnect_active
			and not _shift_reconnect_pending
			and not _newlink_active
			and not _newlink_pending
		):
			edge_disconnect_requested.emit(_selected_edge_index)
			accept_event()
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if _reconnect_active or _shift_reconnect_pending:
			_clear_reconnect_drag_state()
			queue_redraw()
			accept_event()
		elif _newlink_active or _newlink_pending:
			_clear_newlink_drag_state()
			queue_redraw()
			accept_event()
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			var old_z := _zoom
			var lp := mb.position
			var graph_pt := _screen_to_graph(lp, old_z)
			_zoom = clampf(_zoom * 1.08, MIN_ZOOM, MAX_ZOOM)
			_pan = lp - graph_pt * _zoom
			queue_redraw()
			accept_event()
			return
		if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			var old_z2 := _zoom
			var lp2 := mb.position
			var gp := _screen_to_graph(lp2, old_z2)
			_zoom = clampf(_zoom / 1.08, MIN_ZOOM, MAX_ZOOM)
			_pan = lp2 - gp * _zoom
			queue_redraw()
			accept_event()
			return
		if mb.button_index == MOUSE_BUTTON_MIDDLE:
			_dragging = mb.pressed
			_last_mouse = mb.position
			if mb.pressed:
				accept_event()
			return
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if _try_begin_ctrl_shift_newlink(
					mb.position, mb.ctrl_pressed, mb.shift_pressed
				):
					accept_event()
					return
				if _try_begin_shift_reconnect(mb.position, mb.shift_pressed):
					accept_event()
					return
				_pick(mb.position)
				accept_event()
				return
			if _newlink_active:
				var tgt_n := _hit_test_node_id(mb.position)
				newlink_drag_ended.emit(_newlink_donor_id, tgt_n)
				_clear_newlink_drag_state()
				accept_event()
				queue_redraw()
				return
			if _reconnect_active:
				var tgt := _hit_test_node_id(mb.position)
				reconnect_drag_ended.emit(_selected_edge_index, _reconnect_origin_node_id, tgt)
				_clear_reconnect_drag_state()
				accept_event()
				queue_redraw()
				return
			if _newlink_pending:
				if not _newlink_active:
					_pick(_press_screen)
				_clear_newlink_drag_state()
				accept_event()
				queue_redraw()
				return
			if _shift_reconnect_pending:
				if not _reconnect_active:
					_pick(_press_screen)
				_clear_reconnect_drag_state()
				accept_event()
				queue_redraw()
				return
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _dragging:
			_pan += mm.relative
			queue_redraw()
			accept_event()
			return
		if _newlink_pending and (mm.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			if not _newlink_active and _press_screen.distance_to(mm.position) > _RECONNECT_DRAG_THRESHOLD_PX:
				_newlink_active = true
				newlink_drag_started.emit(_newlink_donor_id)
			if _newlink_active:
				_newlink_cursor_graph = _screen_to_graph(mm.position, _zoom)
				queue_redraw()
				accept_event()
				return
		if _shift_reconnect_pending and (mm.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			if not _reconnect_active and _press_screen.distance_to(mm.position) > _RECONNECT_DRAG_THRESHOLD_PX:
				_reconnect_active = true
				reconnect_drag_started.emit(_selected_edge_index, _reconnect_origin_node_id)
			if _reconnect_active:
				_reconnect_cursor_graph = _screen_to_graph(mm.position, _zoom)
				queue_redraw()
				accept_event()
				return
		_pick_hover(mm.position)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
	elif what == NOTIFICATION_MOUSE_EXIT:
		_clear_hover()


func _clear_hover() -> void:
	if not _hover_node_id.is_empty() or _hover_edge_index >= 0:
		_hover_node_id = ""
		_hover_edge_index = -1
		queue_redraw()


func _screen_to_graph(screen_local: Vector2, z: float) -> Vector2:
	return (screen_local - _pan) / z


func _dist_point_to_polyline_sq(g: Vector2, pts: PackedVector2Array) -> float:
	var best := 1e20
	for i in range(pts.size() - 1):
		var d := Geometry2D.get_closest_point_to_segment(g, pts[i], pts[i + 1]).distance_to(g)
		best = minf(best, d * d)
	return best


func _pick_hover(screen_local: Vector2) -> void:
	if _layout.is_empty():
		return
	if not _inner_rect().has_point(screen_local):
		_clear_hover()
		return
	var g := _screen_to_graph(screen_local, _zoom)
	var centers: Dictionary = _layout.get(&"node_centers", {}) as Dictionary
	var best_id := ""
	var best_d := 1e12
	for nid: Variant in centers:
		var c: Vector2 = centers[nid] as Vector2
		var rect := Rect2(c - Vector2(NODE_W * 0.5, NODE_H * 0.5), Vector2(NODE_W, NODE_H))
		if rect.has_point(g):
			var ds := g.distance_squared_to(c)
			if ds < best_d:
				best_d = ds
				best_id = String(nid)
	var prev_n := _hover_node_id
	var prev_e := _hover_edge_index
	if not best_id.is_empty():
		_hover_node_id = best_id
		_hover_edge_index = -1
	else:
		_hover_node_id = ""
		var edges: Array = _layout.get(&"draw_edges", []) as Array
		var best_i := -1
		var best_dist := 11.0 / _zoom
		var idx := 0
		for e: Variant in edges:
			if e is not Dictionary:
				idx += 1
				continue
			var ed: Dictionary = e as Dictionary
			if not _edge_visible(ed):
				idx += 1
				continue
			var fa := str(ed.get(&"from_id", ""))
			var ta := str(ed.get(&"to_id", ""))
			if not centers.has(fa) or not centers.has(ta):
				idx += 1
				continue
			var d2: float
			var pts_var: Variant = ed.get(&"route_points", null)
			if pts_var is PackedVector2Array and (pts_var as PackedVector2Array).size() >= 2:
				d2 = sqrt(_dist_point_to_polyline_sq(g, pts_var as PackedVector2Array))
			else:
				var pa: Vector2 = centers[fa] as Vector2
				var pb: Vector2 = centers[ta] as Vector2
				d2 = Geometry2D.get_closest_point_to_segment(g, pa, pb).distance_to(g)
			if d2 < best_dist:
				best_dist = d2
				best_i = idx
			idx += 1
		_hover_edge_index = best_i
	if prev_n != _hover_node_id or prev_e != _hover_edge_index:
		queue_redraw()


func _pick(screen_local: Vector2) -> void:
	if _layout.is_empty():
		return
	var g := _screen_to_graph(screen_local, _zoom)
	var centers: Dictionary = _layout.get(&"node_centers", {}) as Dictionary
	var best_id := ""
	var best_d := 1e12
	for nid: Variant in centers:
		var c: Vector2 = centers[nid] as Vector2
		var rect := Rect2(c - Vector2(NODE_W * 0.5, NODE_H * 0.5), Vector2(NODE_W, NODE_H))
		if rect.has_point(g):
			var d := g.distance_squared_to(c)
			if d < best_d:
				best_d = d
				best_id = String(nid)
	if not best_id.is_empty():
		_selected_node_id = best_id
		_selected_edge_index = -1
		node_selected.emit(best_id)
		queue_redraw()
		return

	var edges: Array = _layout.get(&"draw_edges", []) as Array
	var best_i := -1
	var best_dist := 12.0 / _zoom
	var idx := 0
	for e: Variant in edges:
		if e is not Dictionary:
			idx += 1
			continue
		var ed: Dictionary = e as Dictionary
		if not _edge_visible(ed):
			idx += 1
			continue
		var fa := str(ed.get(&"from_id", ""))
		var ta := str(ed.get(&"to_id", ""))
		if not centers.has(fa) or not centers.has(ta):
			idx += 1
			continue
		var d2: float
		var pts_var: Variant = ed.get(&"route_points", null)
		if pts_var is PackedVector2Array and (pts_var as PackedVector2Array).size() >= 2:
			d2 = sqrt(_dist_point_to_polyline_sq(g, pts_var as PackedVector2Array))
		else:
			var pa: Vector2 = centers[fa] as Vector2
			var pb: Vector2 = centers[ta] as Vector2
			d2 = Geometry2D.get_closest_point_to_segment(g, pa, pb).distance_to(g)
		if d2 < best_dist:
			best_dist = d2
			best_i = idx
		idx += 1

	if best_i >= 0:
		_selected_edge_index = best_i
		_selected_node_id = ""
		var ed2: Dictionary = edges[best_i] as Dictionary
		edge_selected.emit(
			str(ed2.get(&"from_id", "")),
			str(ed2.get(&"to_id", "")),
			int(ed2.get(&"kind", -1)),
			str(ed2.get(&"label", "")),
			best_i
		)
		queue_redraw()
	else:
		_selected_node_id = ""
		_selected_edge_index = -1
		selection_cleared.emit()
		queue_redraw()

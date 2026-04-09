## Read-only graph canvas for Explain visual mode ([code]CB-018A.1[/code]).
class_name UiReactExplainGraphView
extends Control

signal node_selected(node_id: String)
signal edge_selected(from_id: String, to_id: String, kind: int, label: String)
signal selection_cleared

const _Snap := preload("res://addons/ui_react/editor_plugin/models/ui_react_explain_graph_snapshot.gd")

const MIN_ZOOM := 0.55
const MAX_ZOOM := 1.75
const LABEL_ZOOM_MIN := 0.82
const NODE_W := 140.0
const NODE_H := 32.0

var _layout: Dictionary = {}
var _pan := Vector2.ZERO
var _zoom := 1.0
var _dragging := false
var _last_mouse := Vector2.ZERO
var _selected_node_id: String = ""
var _selected_edge_index: int = -1


func _ready() -> void:
	clip_contents = true
	focus_mode = Control.FOCUS_CLICK
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(200, 160)


func clear_graph() -> void:
	_layout.clear()
	_selected_node_id = ""
	_selected_edge_index = -1
	_pan = Vector2.ZERO
	_zoom = 1.0
	queue_redraw()


func set_layout(layout: Dictionary) -> void:
	_layout = layout
	_selected_node_id = ""
	_selected_edge_index = -1
	reset_view()


func reset_view() -> void:
	_pan = size * 0.5
	_zoom = 1.0
	queue_redraw()


func _draw() -> void:
	if _layout.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(8, 24), "No graph data.", HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
		return

	var centers: Dictionary = _layout.get(&"node_centers", {}) as Dictionary
	var node_by_id: Dictionary = _layout.get(&"node_by_id", {}) as Dictionary
	var edges: Array = _layout.get(&"draw_edges", []) as Array
	var focus_id: String = str(_layout.get(&"focus_id", ""))
	var note: String = str(_layout.get(&"note", ""))

	draw_set_transform(_pan, 0.0, Vector2(_zoom, _zoom))

	var ek := _Snap.EdgeKind
	var ei := 0
	for e: Variant in edges:
		if e is not Dictionary:
			ei += 1
			continue
		var ed: Dictionary = e as Dictionary
		var fa := str(ed.get(&"from_id", ""))
		var ta := str(ed.get(&"to_id", ""))
		if not centers.has(fa) or not centers.has(ta):
			ei += 1
			continue
		var pa: Vector2 = centers[fa] as Vector2
		var pb: Vector2 = centers[ta] as Vector2
		var k := int(ed.get(&"kind", -1))
		var col := Color(0.55, 0.55, 0.6, 1.0)
		var width := 1.5
		if k == ek.WIRE_FLOW:
			col = Color(0.85, 0.45, 0.35, 1.0)
			width = 2.2
		elif k == ek.COMPUTED_SOURCE:
			col = Color(0.45, 0.65, 0.85, 1.0)
			width = 1.8
		draw_line(pa, pb, col, width, true)
		if ei == _selected_edge_index:
			draw_line(pa, pb, Color(1.0, 0.92, 0.35, 1.0), width + 2.0, true)
		if _zoom >= LABEL_ZOOM_MIN:
			var mid := (pa + pb) * 0.5
			var lab := str(ed.get(&"label", ""))
			if lab.length() > 28:
				lab = lab.substr(0, 26) + "…"
			draw_string(ThemeDB.fallback_font, mid + Vector2(4, -4), lab, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.75, 0.75, 0.8, 1.0))
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
		draw_rect(rect, fill, true)
		if id == _selected_node_id:
			draw_rect(rect.grow(3), Color(1.0, 0.92, 0.35, 1.0), false, 2.0)
		var lab2 := str((node_by_id.get(id, {}) as Dictionary).get(&"label", id))
		if lab2.length() > 22:
			lab2 = lab2.substr(0, 20) + "…"
		draw_string(ThemeDB.fallback_font, c + Vector2(-NODE_W * 0.5 + 4, 4), lab2, HORIZONTAL_ALIGNMENT_LEFT, int(NODE_W - 8), 12, Color(0.92, 0.92, 0.95, 1.0))

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if not note.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(8, size.y - 8), note, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.95, 0.75, 0.45, 1.0))


func _gui_input(event: InputEvent) -> void:
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
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_pick(mb.position)
			accept_event()
			return
	if event is InputEventMouseMotion and _dragging:
		var mm := event as InputEventMouseMotion
		_pan += mm.relative
		queue_redraw()
		accept_event()


func _screen_to_graph(screen_local: Vector2, z: float) -> Vector2:
	return (screen_local - _pan) / z


func _pick(screen_local: Vector2) -> void:
	if _layout.is_empty():
		return
	var g := _screen_to_graph(screen_local, _zoom)
	var centers: Dictionary = _layout.get(&"node_centers", {}) as Dictionary
	var node_by_id: Dictionary = _layout.get(&"node_by_id", {}) as Dictionary
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
	var ek2 := _Snap.EdgeKind
	var best_i := -1
	var best_dist := 12.0 / _zoom
	var idx := 0
	for e: Variant in edges:
		if e is not Dictionary:
			idx += 1
			continue
		var ed: Dictionary = e as Dictionary
		var fa := str(ed.get(&"from_id", ""))
		var ta := str(ed.get(&"to_id", ""))
		if not centers.has(fa) or not centers.has(ta):
			idx += 1
			continue
		var pa: Vector2 = centers[fa] as Vector2
		var pb: Vector2 = centers[ta] as Vector2
		var d2 := Geometry2D.get_closest_point_to_segment(g, pa, pb).distance_to(g)
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
			str(ed2.get(&"label", ""))
		)
		queue_redraw()
	else:
		_selected_node_id = ""
		_selected_edge_index = -1
		selection_cleared.emit()
		queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

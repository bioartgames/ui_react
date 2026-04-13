## Deterministic focus-centric layout + orthogonal routing for Dependency Graph visual mode ([code]CB-018A[/code], [code]CB-018A.2[/code]).
class_name UiReactExplainGraphLayout
extends RefCounted

const _Snap := preload("res://addons/ui_react/editor_plugin/models/ui_react_explain_graph_snapshot.gd")

const DEFAULT_MAX_NODES := 200
const DEFAULT_MAX_EDGES := 400

const NODE_HALF_W := 70.0
const NODE_HALF_H := 16.0
## Moderate rounding for [enum UiReactExplainGraphSnapshot.NodeKind.CONTROL] nodes; must match graph view [code]_ready[/code] defaults.
const NODE_RADIUS_CONTROL := 6
## Nearly square [enum UiReactExplainGraphSnapshot.NodeKind.UI_COMPUTED] nodes.
const NODE_RADIUS_COMPUTED := 2

const LANE_SEP := 14.0


## Corner radius for dependency graph node fills (canvas + legend); pill radius derives from [member NODE_HALF_H].
static func fill_corner_radius_px(kind: int) -> int:
	match kind:
		_Snap.NodeKind.UI_STATE:
			return int(round(NODE_HALF_H))
		_Snap.NodeKind.UI_COMPUTED:
			return NODE_RADIUS_COMPUTED
		_:
			return NODE_RADIUS_CONTROL


## Returns node centers, enriched [code]node_by_id[/code] ([code]short_label[/code]), [code]draw_edges[/code] with [code]route_points[/code] and [code]short_label[/code], spacing metadata, truncation.
static func layout_snapshot(
	snap: Variant,
	focus_control_id: String,
	max_nodes: int = DEFAULT_MAX_NODES,
	max_edges: int = DEFAULT_MAX_EDGES,
	extra_scope_ids: PackedStringArray = PackedStringArray(),
) -> Dictionary:
	var snap_script: Object = snap
	var nodes_arr: Array = snap_script.get("nodes") as Array
	var edges_arr: Array = snap_script.get("edges") as Array
	var up_ids: PackedStringArray = snap_script.get("upstream_ids") as PackedStringArray
	var down_ids: PackedStringArray = snap_script.get("downstream_ids") as PackedStringArray

	var scope: Dictionary = {}
	scope[focus_control_id] = true
	for x: Variant in up_ids:
		scope[String(x)] = true
	for x: Variant in down_ids:
		scope[String(x)] = true
	for i in range(extra_scope_ids.size()):
		var px := String(extra_scope_ids[i]).strip_edges()
		if not px.is_empty():
			scope[px] = true

	var all_nodes_by_id: Dictionary = {}
	for nd: Variant in nodes_arr:
		if nd is Dictionary:
			var d0: Dictionary = nd as Dictionary
			var nid0 := str(d0.get(&"id", ""))
			if nid0.is_empty():
				continue
			all_nodes_by_id[nid0] = d0.duplicate(true)

	var node_by_id: Dictionary = {}
	for nid: Variant in scope:
		var ks := String(nid)
		if not all_nodes_by_id.has(ks):
			continue
		node_by_id[ks] = all_nodes_by_id[ks].duplicate(true)

	if not node_by_id.has(focus_control_id):
		node_by_id[focus_control_id] = {
			&"id": focus_control_id,
			&"kind": _Snap.NodeKind.CONTROL,
			&"label": "focus",
		}

	var scoped_edges: Array[Dictionary] = []
	var edges_capped := false
	for e: Variant in edges_arr:
		if e is not Dictionary:
			continue
		var ed: Dictionary = e as Dictionary
		var fr := str(ed.get(&"from_id", ""))
		var to := str(ed.get(&"to_id", ""))
		if not scope.has(fr) or not scope.has(to):
			continue
		scoped_edges.append(ed.duplicate(true))
		if scoped_edges.size() >= max_edges:
			edges_capped = true
			break

	var nodes_capped := false
	if node_by_id.size() > max_nodes:
		var kept: Dictionary = {}
		kept[focus_control_id] = node_by_id[focus_control_id]
		var rest: Array[String] = []
		for k: Variant in node_by_id:
			var ks := String(k)
			if ks == focus_control_id:
				continue
			rest.append(ks)
		rest.sort()
		for i in range(mini(rest.size(), max_nodes - 1)):
			kept[rest[i]] = node_by_id[rest[i]]
		node_by_id = kept
		nodes_capped = true

	var pred: Dictionary = {}
	var succ: Dictionary = {}
	for ed: Dictionary in scoped_edges:
		var fr := str(ed.get(&"from_id", ""))
		var to := str(ed.get(&"to_id", ""))
		if not pred.has(to):
			pred[to] = [] as Array[String]
		(pred[to] as Array[String]).append(fr)
		if not succ.has(fr):
			succ[fr] = [] as Array[String]
		(succ[fr] as Array[String]).append(to)

	var back_dist := _bfs_backward_from(focus_control_id, pred, node_by_id)
	var seeds := _binding_sources_to_focus(scoped_edges, focus_control_id)
	var seed_fwd := _bfs_forward_multisource(seeds, succ, node_by_id)
	var focus_fwd := _bfs_forward_from(focus_control_id, succ, node_by_id)
	var fwd_combined := _min_dist_merge(seed_fwd, focus_fwd)

	var layer: Dictionary = {}
	for nid: Variant in node_by_id:
		var id := String(nid)
		var bd: int = 999999
		var fd: int = 999999
		if back_dist.has(id):
			bd = int(back_dist[id])
		if fwd_combined.has(id):
			fd = int(fwd_combined[id])
		var L := 0
		if id == focus_control_id:
			L = 0
		elif bd < 999999 and fd < 999999:
			L = -bd if bd <= fd else fd
		elif bd < 999999:
			L = -bd
		elif fd < 999999:
			L = fd
		else:
			L = -512
		layer[id] = L

	var n_scoped := node_by_id.size()
	var gaps: Vector2 = _adaptive_gaps(n_scoped)
	var layer_gap: float = gaps.x
	var row_gap: float = gaps.y

	var by_layer: Dictionary = {}
	for id: Variant in layer:
		var L2: int = int(layer[id])
		if not by_layer.has(L2):
			by_layer[L2] = [] as Array[String]
		(by_layer[L2] as Array[String]).append(String(id))

	for L3: Variant in by_layer:
		var arr: Array[String] = by_layer[L3] as Array[String]
		arr.sort_custom(func(a: String, b: String) -> bool: return _sort_key(node_by_id, a) < _sort_key(node_by_id, b))

	var layers_sorted: Array[int] = []
	for L4: Variant in by_layer:
		layers_sorted.append(int(L4))
	layers_sorted.sort()

	var node_centers: Dictionary = {}
	var min_x := 0.0
	var max_x := 0.0
	var min_y := 0.0
	var max_y := 0.0
	for L5: int in layers_sorted:
		var row: Array[String] = by_layer[L5] as Array[String]
		var xi := float(L5) * layer_gap
		var ri := 0
		for nid2: String in row:
			var cy := float(ri) * row_gap
			var pos := Vector2(xi, cy)
			node_centers[nid2] = pos
			min_x = minf(min_x, pos.x - NODE_HALF_W)
			max_x = maxf(max_x, pos.x + NODE_HALF_W)
			min_y = minf(min_y, pos.y - NODE_HALF_H)
			max_y = maxf(max_y, pos.y + NODE_HALF_H)
			ri += 1

	var offset := Vector2(-(min_x + max_x) * 0.5, -(min_y + max_y) * 0.5)
	for k2: Variant in node_centers:
		node_centers[k2] = (node_centers[k2] as Vector2) + offset

	for nid3: Variant in node_by_id:
		var ids := String(nid3)
		var d0: Dictionary = node_by_id[ids] as Dictionary
		var full_lab := str(d0.get(&"label", ids))
		var kind0 := int(d0.get(&"kind", 0))
		d0[&"short_label"] = _short_node_label(ids, kind0, full_lab)
		node_by_id[ids] = d0

	var draw_edges: Array[Dictionary] = []
	for ed2: Dictionary in scoped_edges:
		var fa := str(ed2.get(&"from_id", ""))
		var ta := str(ed2.get(&"to_id", ""))
		if not node_centers.has(fa) or not node_centers.has(ta):
			continue
		var k := int(ed2.get(&"kind", -1))
		ed2[&"short_label"] = _short_edge_token(k)
		draw_edges.append(ed2)

	_assign_routes(draw_edges, node_centers, layer)

	var truncated := nodes_capped or edges_capped
	var n_draw_edges := draw_edges.size()

	var node_layer_out: Dictionary = {}
	for lk: Variant in layer:
		node_layer_out[String(lk)] = int(layer[lk])

	return {
		&"node_centers": node_centers,
		&"node_by_id": node_by_id,
		&"draw_edges": draw_edges,
		&"truncated": truncated,
		&"note": "",
		&"focus_id": focus_control_id,
		&"layer_gap": layer_gap,
		&"row_gap": row_gap,
		&"node_layer": node_layer_out,
		&"graph_stats": {
			&"node_count": node_by_id.size(),
			&"edge_count": n_draw_edges,
			&"truncated": truncated,
		},
	}


static func _adaptive_gaps(node_count: int) -> Vector2:
	if node_count <= 20:
		return Vector2(220.0, 56.0)
	if node_count <= 80:
		return Vector2(200.0, 48.0)
	return Vector2(180.0, 44.0)


static func _short_edge_token(kind: int) -> String:
	match kind:
		_Snap.EdgeKind.BINDING:
			return "bind"
		_Snap.EdgeKind.COMPUTED_SOURCE:
			return "computed"
		_Snap.EdgeKind.WIRE_FLOW:
			return "wire"
	return "edge"


static func _short_node_label(id: String, kind: int, full_label: String) -> String:
	if kind == _Snap.NodeKind.CONTROL:
		if full_label.contains(" @ "):
			return full_label.get_slice(" @ ", 0).strip_edges()
		if id.begins_with("ctrl:"):
			var p := id.substr(5)
			var slash := p.rfind("/")
			if slash >= 0:
				return p.substr(slash + 1)
			return p
		return full_label
	if kind == _Snap.NodeKind.UI_STATE:
		if full_label.begins_with("embedded "):
			var rest := full_label.substr(9)
			var at := rest.find(" @ ")
			if at > 0:
				return rest.substr(0, at).strip_edges()
			return rest.strip_edges()
		var f := full_label.get_file()
		if f.is_empty():
			return full_label
		return f.get_basename()
	if kind == _Snap.NodeKind.UI_COMPUTED:
		if full_label.begins_with("embedded "):
			var rest2 := full_label.substr(9)
			var at2 := rest2.find(" @ ")
			if at2 > 0:
				return rest2.substr(0, at2).strip_edges()
			return rest2.strip_edges()
		var f2 := full_label.get_file()
		if f2.is_empty():
			return full_label
		return f2.get_basename()
	return full_label


static func _assign_routes(
	draw_edges: Array[Dictionary],
	node_centers: Dictionary,
	layer: Dictionary,
) -> void:
	var bands: Dictionary = {}
	for ed: Dictionary in draw_edges:
		var fa := str(ed.get(&"from_id", ""))
		var ta := str(ed.get(&"to_id", ""))
		var la: int = int(layer.get(fa, 0))
		var lb: int = int(layer.get(ta, 0))
		var lo := mini(la, lb)
		var hi := maxi(la, lb)
		var key := "%d|%d" % [lo, hi]
		if not bands.has(key):
			bands[key] = [] as Array[Dictionary]
		(bands[key] as Array[Dictionary]).append(ed)

	for bkey: Variant in bands:
		var arr: Array[Dictionary] = bands[bkey] as Array[Dictionary]
		arr.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var fa := str(a.get(&"from_id", ""))
			var ta := str(a.get(&"to_id", ""))
			var fb := str(b.get(&"from_id", ""))
			var tb := str(b.get(&"to_id", ""))
			if fa != fb:
				return fa < fb
			if ta != tb:
				return ta < tb
			return int(a.get(&"kind", 0)) < int(b.get(&"kind", 0))
		)
		var n := arr.size()
		for i in range(n):
			var ed: Dictionary = arr[i]
			var lane_offset := (float(i) - float(n - 1) * 0.5) * LANE_SEP
			var pts: PackedVector2Array = _orthogonal_polyline(ed, node_centers, lane_offset)
			ed[&"route_points"] = pts


static func _orthogonal_polyline(ed: Dictionary, node_centers: Dictionary, lane_offset: float) -> PackedVector2Array:
	var fa := str(ed.get(&"from_id", ""))
	var ta := str(ed.get(&"to_id", ""))
	var sa: Vector2 = node_centers[fa] as Vector2
	var sb: Vector2 = node_centers[ta] as Vector2
	var exit_entry: Array = _exit_entry_ports(sa, sb)
	var exit_pt: Vector2 = exit_entry[0]
	var entry_pt: Vector2 = exit_entry[1]
	var mid_x := (exit_pt.x + entry_pt.x) * 0.5 + lane_offset
	var p1 := Vector2(mid_x, exit_pt.y)
	var p2 := Vector2(mid_x, entry_pt.y)
	var raw: PackedVector2Array = PackedVector2Array()
	raw.append(exit_pt)
	raw.append(p1)
	raw.append(p2)
	raw.append(entry_pt)
	return _dedupe_collinear(raw)


static func _dedupe_collinear(pts: PackedVector2Array) -> PackedVector2Array:
	if pts.size() <= 2:
		return pts
	var out: PackedVector2Array = PackedVector2Array()
	out.append(pts[0])
	for i in range(1, pts.size()):
		var cur: Vector2 = pts[i]
		if out[out.size() - 1].distance_to(cur) < 0.01:
			continue
		out.append(cur)
	if out.size() >= 3:
		var merged: PackedVector2Array = PackedVector2Array()
		merged.append(out[0])
		for j in range(1, out.size() - 1):
			var prev: Vector2 = merged[merged.size() - 1]
			var mid: Vector2 = out[j]
			var nxt: Vector2 = out[j + 1]
			var v1 := mid - prev
			var v2 := nxt - mid
			if absf(v1.x * v2.y - v1.y * v2.x) < 1e-3:
				continue
			merged.append(mid)
		merged.append(out[out.size() - 1])
		return merged
	return out


static func _exit_entry_ports(sa: Vector2, sb: Vector2) -> Array:
	var dx := sb.x - sa.x
	var half_w := NODE_HALF_W
	var half_h := NODE_HALF_H
	var exit_pt: Vector2
	var entry_pt: Vector2
	if absf(dx) < 1.0:
		var jog := 1.0
		if absf(sb.y - sa.y) > 0.01:
			jog = signf(sb.y - sa.y)
		exit_pt = Vector2(sa.x + half_w * jog, sa.y)
		entry_pt = Vector2(sb.x - half_w * jog, sb.y)
		if absf(exit_pt.x - entry_pt.x) < 1.0:
			exit_pt = Vector2(sa.x + half_w, sa.y - signf(sb.y - sa.y) * half_h)
			entry_pt = Vector2(sb.x - half_w, sb.y + signf(sb.y - sa.y) * half_h)
	else:
		var sx := signf(dx)
		exit_pt = Vector2(sa.x + sx * half_w, sa.y)
		entry_pt = Vector2(sb.x - sx * half_w, sb.y)
	return [exit_pt, entry_pt]


static func _bfs_backward_from(start: String, pred: Dictionary, allowed: Dictionary) -> Dictionary:
	var dist: Dictionary = {}
	var dq: Array[String] = []
	dist[start] = 0
	dq.append(start)
	var guard := 0
	while not dq.is_empty() and guard < 512:
		guard += 1
		var cur: String = dq.pop_front() as String
		for nb: Variant in pred.get(cur, []) as Array[String]:
			var nbs := String(nb)
			if not allowed.has(nbs):
				continue
			if not dist.has(nbs):
				dist[nbs] = int(dist[cur]) + 1
				dq.append(nbs)
	return dist


static func _bfs_forward_from(start: String, succ: Dictionary, allowed: Dictionary) -> Dictionary:
	var dist: Dictionary = {}
	var dq: Array[String] = []
	dist[start] = 0
	dq.append(start)
	var guard := 0
	while not dq.is_empty() and guard < 512:
		guard += 1
		var cur: String = dq.pop_front() as String
		for nb: Variant in succ.get(cur, []) as Array[String]:
			var nbs := String(nb)
			if not allowed.has(nbs):
				continue
			if not dist.has(nbs):
				dist[nbs] = int(dist[cur]) + 1
				dq.append(nbs)
	return dist


static func _binding_sources_to_focus(scoped_edges: Array[Dictionary], focus_id: String) -> Array[String]:
	var out: Array[String] = []
	var ek := _Snap.EdgeKind.BINDING
	for ed: Dictionary in scoped_edges:
		if int(ed.get(&"kind", -1)) != ek:
			continue
		if str(ed.get(&"to_id", "")) != focus_id:
			continue
		var fr := str(ed.get(&"from_id", ""))
		if not fr.is_empty():
			out.append(fr)
	return out


static func _bfs_forward_multisource(starters: Array[String], succ: Dictionary, allowed: Dictionary) -> Dictionary:
	var dist: Dictionary = {}
	var dq: Array[String] = []
	for s: String in starters:
		if allowed.has(s) and not dist.has(s):
			dist[s] = 0
			dq.append(s)
	var guard := 0
	while not dq.is_empty() and guard < 512:
		guard += 1
		var cur: String = dq.pop_front() as String
		for nb: Variant in succ.get(cur, []) as Array[String]:
			var nbs := String(nb)
			if not allowed.has(nbs):
				continue
			if not dist.has(nbs):
				dist[nbs] = int(dist[cur]) + 1
				dq.append(nbs)
	return dist


static func _min_dist_merge(a: Dictionary, b: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for k: Variant in a:
		out[String(k)] = int(a[k])
	for k2: Variant in b:
		var ks := String(k2)
		var v := int(b[k2])
		if not out.has(ks) or v < int(out[ks]):
			out[ks] = v
	return out


static func _sort_key(node_by_id: Dictionary, id: String) -> String:
	var d: Variant = node_by_id.get(id, null)
	if d is Dictionary:
		var dd: Dictionary = d as Dictionary
		var k := int(dd.get(&"kind", 0))
		var lab := str(dd.get(&"label", id))
		return "%04d|%s|%s" % [k, lab, id]
	return id

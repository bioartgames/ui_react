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
const PINNED_ISLAND_GAP_PX := 100.0

## Sentinel: no finite BFS distance yet in [method _layout_directed_spine_block].
const DIST_INF := 999999
## Temporary layer key for nodes outside both backward/forward reach; collapsed to 0 immediately after.
const LAYER_SENTINEL_UNREACHABLE := -512


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

	var pin_set := _to_id_set(extra_scope_ids)
	var comp_info := _compute_components(node_by_id, scoped_edges)
	var comp_of: Dictionary = comp_info.get(&"comp_of", {}) as Dictionary
	var nodes_by_comp: Dictionary = comp_info.get(&"nodes_by_comp", {}) as Dictionary
	var focus_comp: int = int(comp_of.get(focus_control_id, 0))

	var merged_node_ids: Dictionary = {}
	for id0: Variant in node_by_id:
		var ids0 := String(id0)
		var cid := int(comp_of.get(ids0, focus_comp))
		if cid == focus_comp or _component_has_pin(nodes_by_comp, cid, pin_set):
			merged_node_ids[ids0] = true

	var nodes_capped := false
	var n_final := _truncate_merged_ids(merged_node_ids, pin_set, focus_control_id, max_nodes)
	if n_final.size() < merged_node_ids.size():
		nodes_capped = true

	var merged_edges := _filter_edges_to_nodes(scoped_edges, n_final)
	var comp_final := _compute_components(_subset_nodes(node_by_id, n_final), merged_edges)
	var comp_of_final: Dictionary = comp_final.get(&"comp_of", {}) as Dictionary
	var nodes_by_comp_final: Dictionary = comp_final.get(&"nodes_by_comp", {}) as Dictionary
	var focus_comp_final: int = int(comp_of_final.get(focus_control_id, 0))

	var focus_ids: Dictionary = {}
	var island_ids_by_root: Dictionary = {}
	for id1: Variant in n_final:
		var ids1 := String(id1)
		var cid1 := int(comp_of_final.get(ids1, focus_comp_final))
		if cid1 == focus_comp_final:
			focus_ids[ids1] = true
			continue
		if not _component_has_pin(nodes_by_comp_final, cid1, pin_set):
			continue
		var root_id := _component_root_id(nodes_by_comp_final, cid1, pin_set)
		if root_id.is_empty():
			continue
		if not island_ids_by_root.has(root_id):
			island_ids_by_root[root_id] = {} as Dictionary
		var island_set: Dictionary = island_ids_by_root[root_id] as Dictionary
		island_set[ids1] = true
		island_ids_by_root[root_id] = island_set

	var focus_nodes := _subset_nodes(node_by_id, focus_ids)
	var focus_edges := _filter_edges_to_nodes(merged_edges, focus_ids)
	var focus_pack := _layout_directed_spine_block(focus_nodes, focus_edges, focus_control_id)

	var merged_centers: Dictionary = focus_pack.get(&"node_centers", {}) as Dictionary
	var merged_node_by_id: Dictionary = focus_pack.get(&"node_by_id", {}) as Dictionary
	var merged_draw_edges: Array[Dictionary] = focus_pack.get(&"draw_edges", []) as Array[Dictionary]
	var node_layer_out: Dictionary = {}
	var focus_layer: Dictionary = focus_pack.get(&"layer", {}) as Dictionary
	for lk: Variant in focus_layer:
		node_layer_out[String(lk)] = int(focus_layer[lk])

	var focus_bbox := _axis_aligned_bbox_from_centers(merged_centers)
	var cursor_x := focus_bbox.position.x + focus_bbox.size.x + PINNED_ISLAND_GAP_PX
	var roots: Array[String] = []
	for rk: Variant in island_ids_by_root:
		roots.append(String(rk))
	roots.sort()
	for root: String in roots:
		var island_ids: Dictionary = island_ids_by_root[root] as Dictionary
		var island_nodes := _subset_nodes(node_by_id, island_ids)
		var island_edges := _filter_edges_to_nodes(merged_edges, island_ids)
		var island_pack := _layout_directed_spine_block(island_nodes, island_edges, root)
		var island_centers: Dictionary = island_pack.get(&"node_centers", {}) as Dictionary
		var island_bbox := _axis_aligned_bbox_from_centers(island_centers)
		var dy_align := focus_bbox.get_center().y - island_bbox.get_center().y
		var shift := Vector2(cursor_x - island_bbox.position.x, dy_align)
		_translate_centers(island_centers, shift)
		var island_draw_edges: Array[Dictionary] = island_pack.get(&"draw_edges", []) as Array[Dictionary]
		_translate_edges(island_draw_edges, shift)
		var island_node_by_id: Dictionary = island_pack.get(&"node_by_id", {}) as Dictionary
		for nk: Variant in island_centers:
			merged_centers[String(nk)] = island_centers[nk]
		for nk2: Variant in island_node_by_id:
			merged_node_by_id[String(nk2)] = island_node_by_id[nk2]
		merged_draw_edges.append_array(island_draw_edges)
		var moved_bbox := _axis_aligned_bbox_from_centers(island_centers)
		cursor_x = moved_bbox.position.x + moved_bbox.size.x + PINNED_ISLAND_GAP_PX

	var n_scoped := merged_node_by_id.size()
	var gaps: Vector2 = _adaptive_gaps(n_scoped)
	var layer_gap: float = gaps.x
	var row_gap: float = gaps.y
	var truncated := nodes_capped or edges_capped
	var n_draw_edges := merged_draw_edges.size()

	return {
		&"node_centers": merged_centers,
		&"node_by_id": merged_node_by_id,
		&"draw_edges": merged_draw_edges,
		&"truncated": truncated,
		&"note": "",
		&"focus_id": focus_control_id,
		&"layer_gap": layer_gap,
		&"row_gap": row_gap,
		&"node_layer": node_layer_out,
		&"graph_stats": {
			&"node_count": merged_node_by_id.size(),
			&"edge_count": n_draw_edges,
			&"truncated": truncated,
		},
	}


static func _layout_directed_spine_block(nodes: Dictionary, edges: Array[Dictionary], layer_focus_id: String) -> Dictionary:
	var pred: Dictionary = {}
	var succ: Dictionary = {}
	for ed: Dictionary in edges:
		var fr := str(ed.get(&"from_id", ""))
		var to := str(ed.get(&"to_id", ""))
		if not pred.has(to):
			pred[to] = [] as Array[String]
		(pred[to] as Array[String]).append(fr)
		if not succ.has(fr):
			succ[fr] = [] as Array[String]
		(succ[fr] as Array[String]).append(to)

	var back_dist := _bfs_backward_from(layer_focus_id, pred, nodes)
	var seeds := _binding_sources_to_focus(edges, layer_focus_id)
	var seed_fwd := _bfs_forward_multisource(seeds, succ, nodes)
	var focus_fwd := _bfs_forward_from(layer_focus_id, succ, nodes)
	var fwd_combined := _min_dist_merge(seed_fwd, focus_fwd)

	var layer: Dictionary = {}
	for nid: Variant in nodes:
		var id := String(nid)
		var back_d: int = DIST_INF
		var forward_d: int = DIST_INF
		if back_dist.has(id):
			back_d = int(back_dist[id])
		if fwd_combined.has(id):
			forward_d = int(fwd_combined[id])
		var layer_key := 0
		if id == layer_focus_id:
			layer_key = 0
		elif back_d < DIST_INF and forward_d < DIST_INF:
			layer_key = -back_d if back_d <= forward_d else forward_d
		elif back_d < DIST_INF:
			layer_key = -back_d
		elif forward_d < DIST_INF:
			layer_key = forward_d
		else:
			layer_key = LAYER_SENTINEL_UNREACHABLE
		if layer_key == LAYER_SENTINEL_UNREACHABLE:
			layer_key = 0
		layer[id] = layer_key

	var gaps: Vector2 = _adaptive_gaps(nodes.size())
	var layer_gap: float = gaps.x
	var row_gap: float = gaps.y
	var by_layer: Dictionary = {}
	for id2: Variant in layer:
		var layer_key_row: int = int(layer[id2])
		if not by_layer.has(layer_key_row):
			by_layer[layer_key_row] = [] as Array[String]
		(by_layer[layer_key_row] as Array[String]).append(String(id2))
	for layer_key_bucket: Variant in by_layer:
		var arr: Array[String] = by_layer[layer_key_bucket] as Array[String]
		arr.sort_custom(func(a: String, b: String) -> bool: return _sort_key(nodes, a) < _sort_key(nodes, b))

	var layers_sorted: Array[int] = []
	for layer_key_sorted: Variant in by_layer:
		layers_sorted.append(int(layer_key_sorted))
	layers_sorted.sort()

	var node_centers: Dictionary = {}
	var min_x := 0.0
	var max_x := 0.0
	var min_y := 0.0
	var max_y := 0.0
	for layer_key_col: int in layers_sorted:
		var row: Array[String] = by_layer[layer_key_col] as Array[String]
		var xi := float(layer_key_col) * layer_gap
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

	var out_nodes: Dictionary = {}
	for nid3: Variant in nodes:
		var ids := String(nid3)
		var d0: Dictionary = (nodes[ids] as Dictionary).duplicate(true)
		var full_lab := str(d0.get(&"label", ids))
		var kind0 := int(d0.get(&"kind", 0))
		d0[&"short_label"] = _short_node_label(ids, kind0, full_lab)
		out_nodes[ids] = d0

	var draw_edges: Array[Dictionary] = []
	for ed2: Dictionary in edges:
		var fa := str(ed2.get(&"from_id", ""))
		var ta := str(ed2.get(&"to_id", ""))
		if not node_centers.has(fa) or not node_centers.has(ta):
			continue
		var copy := ed2.duplicate(true)
		var k := int(copy.get(&"kind", -1))
		copy[&"short_label"] = _short_edge_token(k)
		draw_edges.append(copy)
	_assign_routes(draw_edges, node_centers, layer)

	return {
		&"node_centers": node_centers,
		&"node_by_id": out_nodes,
		&"draw_edges": draw_edges,
		&"layer": layer,
	}


static func _to_id_set(ids: PackedStringArray) -> Dictionary:
	var out: Dictionary = {}
	for i in range(ids.size()):
		var id := String(ids[i]).strip_edges()
		if id.is_empty():
			continue
		out[id] = true
	return out


static func _compute_components(nodes: Dictionary, edges: Array[Dictionary]) -> Dictionary:
	var weak_adj: Dictionary = {}
	for id: Variant in nodes:
		weak_adj[String(id)] = {} as Dictionary
	for ed: Dictionary in edges:
		var fa := str(ed.get(&"from_id", ""))
		var ta := str(ed.get(&"to_id", ""))
		if not weak_adj.has(fa) or not weak_adj.has(ta):
			continue
		var a: Dictionary = weak_adj[fa] as Dictionary
		a[ta] = true
		weak_adj[fa] = a
		var b: Dictionary = weak_adj[ta] as Dictionary
		b[fa] = true
		weak_adj[ta] = b

	var sorted_ids: Array[String] = []
	for id2: Variant in nodes:
		sorted_ids.append(String(id2))
	sorted_ids.sort()
	var comp_of: Dictionary = {}
	var nodes_by_comp: Dictionary = {}
	var comp_index := 0
	for id3: String in sorted_ids:
		if comp_of.has(id3):
			continue
		var queue: Array[String] = [id3]
		comp_of[id3] = comp_index
		var members: Array[String] = []
		while not queue.is_empty():
			var cur: String = queue.pop_front() as String
			members.append(cur)
			var nbrs: Dictionary = weak_adj.get(cur, {}) as Dictionary
			for nb: Variant in nbrs:
				var nbs := String(nb)
				if comp_of.has(nbs):
					continue
				comp_of[nbs] = comp_index
				queue.append(nbs)
		members.sort()
		nodes_by_comp[comp_index] = members
		comp_index += 1
	return {
		&"comp_of": comp_of,
		&"nodes_by_comp": nodes_by_comp,
	}


static func _component_has_pin(nodes_by_comp: Dictionary, comp_id: int, pin_set: Dictionary) -> bool:
	var members: Array[String] = []
	var raw: Variant = nodes_by_comp.get(comp_id, [])
	if raw is Array:
		for item: Variant in raw:
			members.append(String(item))
	for id: String in members:
		if pin_set.has(id):
			return true
	return false


static func _component_root_id(nodes_by_comp: Dictionary, comp_id: int, pin_set: Dictionary) -> String:
	var members: Array[String] = []
	var raw: Variant = nodes_by_comp.get(comp_id, [])
	if raw is Array:
		for item: Variant in raw:
			members.append(String(item))
	if members.is_empty():
		return ""
	var pins: Array[String] = []
	for id: String in members:
		if pin_set.has(id):
			pins.append(id)
	if not pins.is_empty():
		pins.sort()
		return pins[0]
	var copy := members.duplicate()
	copy.sort()
	return copy[0]


static func _truncate_merged_ids(
	merged_ids: Dictionary,
	pin_set: Dictionary,
	focus_id: String,
	max_nodes: int,
) -> Dictionary:
	if merged_ids.size() <= max_nodes:
		return merged_ids.duplicate(true)
	var must: Dictionary = {}
	must[focus_id] = true
	for id: Variant in merged_ids:
		var ids := String(id)
		if pin_set.has(ids):
			must[ids] = true
	var keep: Dictionary = {}
	keep[focus_id] = true
	if must.size() > max_nodes:
		var pin_ids: Array[String] = []
		for id2: Variant in must:
			var s2 := String(id2)
			if s2 == focus_id:
				continue
			pin_ids.append(s2)
		pin_ids.sort()
		for i in range(mini(pin_ids.size(), maxi(0, max_nodes - 1))):
			keep[pin_ids[i]] = true
		return keep
	for id3: Variant in must:
		keep[String(id3)] = true
	var rest: Array[String] = []
	for id4: Variant in merged_ids:
		var s4 := String(id4)
		if keep.has(s4):
			continue
		rest.append(s4)
	rest.sort()
	var room := maxi(0, max_nodes - keep.size())
	for i2 in range(mini(rest.size(), room)):
		keep[rest[i2]] = true
	return keep


static func _subset_nodes(nodes: Dictionary, include_ids: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for id: Variant in include_ids:
		var ids := String(id)
		if nodes.has(ids):
			out[ids] = (nodes[ids] as Dictionary).duplicate(true)
	return out


static func _filter_edges_to_nodes(edges: Array[Dictionary], include_ids: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for ed: Dictionary in edges:
		var fa := str(ed.get(&"from_id", ""))
		var ta := str(ed.get(&"to_id", ""))
		if not include_ids.has(fa) or not include_ids.has(ta):
			continue
		out.append(ed.duplicate(true))
	return out


static func _axis_aligned_bbox_from_centers(node_centers: Dictionary) -> Rect2:
	if node_centers.is_empty():
		return Rect2(-NODE_HALF_W, -NODE_HALF_H, NODE_HALF_W * 2.0, NODE_HALF_H * 2.0)
	var first := true
	var min_x := 0.0
	var max_x := 0.0
	var min_y := 0.0
	var max_y := 0.0
	for v: Variant in node_centers.values():
		var p := v as Vector2
		if first:
			min_x = p.x - NODE_HALF_W
			max_x = p.x + NODE_HALF_W
			min_y = p.y - NODE_HALF_H
			max_y = p.y + NODE_HALF_H
			first = false
			continue
		min_x = minf(min_x, p.x - NODE_HALF_W)
		max_x = maxf(max_x, p.x + NODE_HALF_W)
		min_y = minf(min_y, p.y - NODE_HALF_H)
		max_y = maxf(max_y, p.y + NODE_HALF_H)
	return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))


static func _translate_centers(node_centers: Dictionary, shift: Vector2) -> void:
	for id: Variant in node_centers:
		node_centers[id] = (node_centers[id] as Vector2) + shift


static func _translate_edges(edges: Array[Dictionary], shift: Vector2) -> void:
	for i in range(edges.size()):
		var ed: Dictionary = edges[i]
		var pts := ed.get(&"route_points", PackedVector2Array()) as PackedVector2Array
		var moved := PackedVector2Array()
		for p: Vector2 in pts:
			moved.append(p + shift)
		ed[&"route_points"] = moved
		edges[i] = ed


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

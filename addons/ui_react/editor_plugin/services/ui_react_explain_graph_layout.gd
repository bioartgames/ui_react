## Deterministic focus-centric layout for Explain visual graph ([code]CB-018A.1[/code]).
class_name UiReactExplainGraphLayout
extends RefCounted

const _Snap := preload("res://addons/ui_react/editor_plugin/models/ui_react_explain_graph_snapshot.gd")

const DEFAULT_MAX_NODES := 200
const DEFAULT_MAX_EDGES := 400
const LAYER_GAP := 180.0
const ROW_GAP := 44.0
const NODE_HALF_W := 70.0
const NODE_HALF_H := 16.0


## Returns [code]{ "node_centers": Dictionary id->Vector2, "draw_edges": Array[Dictionary], "truncated": bool, "note": String }[/code]
static func layout_snapshot(
	snap: Variant,
	focus_control_id: String,
	max_nodes: int = DEFAULT_MAX_NODES,
	max_edges: int = DEFAULT_MAX_EDGES,
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

	var node_by_id: Dictionary = {}
	for nd: Variant in nodes_arr:
		if nd is Dictionary:
			var d: Dictionary = nd as Dictionary
			var nid := str(d.get(&"id", ""))
			if nid.is_empty() or not scope.has(nid):
				continue
			node_by_id[nid] = d

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
		scoped_edges.append(ed)
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
		var xi := float(L5) * LAYER_GAP
		var yi := 0.0
		var ri := 0
		for nid2: String in row:
			var cy := float(ri) * ROW_GAP
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

	var draw_edges: Array[Dictionary] = []
	for ed2: Dictionary in scoped_edges:
		var fa := str(ed2.get(&"from_id", ""))
		var ta := str(ed2.get(&"to_id", ""))
		if not node_centers.has(fa) or not node_centers.has(ta):
			continue
		draw_edges.append(ed2)

	var truncated := nodes_capped or edges_capped
	var note := ""
	if truncated:
		note = "Graph truncated (nodes=%s, edges=%s)." % [nodes_capped, edges_capped]

	return {
		&"node_centers": node_centers,
		&"node_by_id": node_by_id,
		&"draw_edges": draw_edges,
		&"truncated": truncated,
		&"note": note,
		&"focus_id": focus_control_id,
	}


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

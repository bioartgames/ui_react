## Builds a declarative dependency snapshot for the Dependency Graph dock tab ([code]CB-018A[/code]).
class_name UiReactExplainGraphBuilder
extends RefCounted

const _SnapshotScript := preload("res://addons/ui_react/editor_plugin/models/ui_react_explain_graph_snapshot.gd")
const _ExplainNarrativeScript := preload("res://addons/ui_react/editor_plugin/models/ui_react_explain_graph_narrative.gd")
const _WireRuleIntrospectionScript := preload("res://addons/ui_react/editor_plugin/services/ui_react_wire_rule_introspection.gd")

## Set [code]true[/code] briefly to print graph metrics to the editor Output (declarative graph only).
const EXPLAIN_GRAPH_DEBUG := false

const MAX_CYCLE_CANDIDATES := 32
const MAX_CYCLE_START_NODES := 64
const MAX_CYCLE_DFS_DEPTH := 24
const MAX_GRAPH_WALK := 4096
const MAX_BINDING_LINES := 32


static func build(root: Node, focus: Control):
	var snap = _SnapshotScript.new()
	if root == null or focus == null:
		return snap
	if not (focus is Control):
		return snap
	if not UiReactScannerService.is_react_node(focus):
		return snap

	var ctx := _BuildContext.new(root)
	for host in UiReactScannerService.collect_react_nodes(root):
		if not (host is Control):
			continue
		var ctl := host as Control
		var component := UiReactScannerService.get_component_name_from_script(ctl.get_script() as Script)
		if component.is_empty():
			continue
		var hp := _host_path_from_root(root, ctl)
		ctx._index_host(component, ctl, hp)

	ctx._finalize_wire_product_edges()
	ctx._copy_nodes_and_edges(snap)
	ctx._find_cycle_candidates(snap)
	var focus_path := _host_path_from_root(root, focus)
	var focus_id := _control_id(focus_path)
	ctx._apply_layout_scope_for_host(snap, focus_id)
	snap.bound_state_lines.clear()
	snap.upstream_lines.clear()
	snap.downstream_lines.clear()
	if EXPLAIN_GRAPH_DEBUG:
		push_warning(
			"UiReactExplainGraphBuilder: nodes=%d edges=%d cycles=%d layout_upstream=%d layout_downstream=%d"
			% [snap.nodes.size(), snap.edges.size(), snap.cycle_candidates.size(), snap.upstream_ids.size(), snap.downstream_ids.size()]
		)
	return snap


## Stable host path for [param root] + [param node]: avoids [code]is_inside_tree()[/code] split that can diverge from [method Node.get_path_to].
static func _host_path_from_root(root: Node, node: Node) -> NodePath:
	if root == null or node == null:
		return NodePath()
	if node == root:
		return NodePath()
	if root.is_ancestor_of(node):
		return root.get_path_to(node)
	return NodePath(String(node.get_path()))


static func _control_id(path: NodePath) -> String:
	return "ctrl:%s" % str(path)


static func _state_id(
	ctx: _BuildContext,
	host_path: NodePath,
	context_seg: String,
	st: UiState,
) -> String:
	if st == null:
		return ""
	var rp := st.resource_path
	var sid: String
	var disp: String
	if not rp.is_empty():
		sid = "state:%s" % rp
		disp = rp.get_file()
	else:
		sid = "state:emb:%s#%s#%d" % [str(host_path), context_seg, st.get_instance_id()]
		disp = "embedded %s @ %s" % [context_seg, str(host_path)]

	var kind := _SnapshotScript.NodeKind.UI_STATE
	if st is UiComputedStringState or st is UiComputedBoolState:
		kind = _SnapshotScript.NodeKind.UI_COMPUTED
	var extra: Dictionary = {}
	if not rp.is_empty():
		extra[&"state_file_path"] = rp
	else:
		extra[&"embedded_host_path"] = str(host_path)
		extra[&"embedded_context"] = context_seg
	ctx.ensure_node(sid, kind, disp, extra)
	return sid


class _BuildContext extends RefCounted:
	var root: Node
	var node_by_id: Dictionary = {}
	var edges: Array[Dictionary] = []
	var _wire_pairs: Array[Dictionary] = []

	func _init(p_root: Node) -> void:
		root = p_root

	func ensure_node(p_id: String, kind: int, p_label: String, extra: Dictionary = {}) -> void:
		if node_by_id.has(p_id):
			return
		var d: Dictionary = {&"id": p_id, &"kind": kind, &"label": p_label}
		for k: Variant in extra:
			d[k] = extra[k]
		node_by_id[p_id] = d

	func add_edge(from_id: String, to_id: String, kind: int, label: String, meta: Dictionary = {}) -> void:
		if from_id.is_empty() or to_id.is_empty() or from_id == to_id:
			return
		var e: Dictionary = {&"from_id": from_id, &"to_id": to_id, &"kind": kind, &"label": label}
		for k: Variant in meta:
			e[k] = meta[k]
		edges.append(e)

	func _index_host(component: String, ctl: Control, host_path: NodePath) -> void:
		var cid := UiReactExplainGraphBuilder._control_id(host_path)
		ensure_node(
			cid,
			_SnapshotScript.NodeKind.CONTROL,
			"%s @ %s" % [String(ctl.name), str(host_path)],
			{&"control_path": str(host_path)}
		)

		var bindings: Array = UiReactComponentRegistry.BINDINGS_BY_COMPONENT.get(component, [])
		for b in bindings:
			var prop: StringName = b.get("property", &"")
			if prop == &"" or not prop in ctl:
				continue
			var property_value: Variant = ctl.get(prop)
			if property_value is UiState:
				var sid := state_id(host_path, str(prop), property_value as UiState)
				add_edge(
					sid,
					cid,
					_SnapshotScript.EdgeKind.BINDING,
					str(prop),
					{&"host_path": str(host_path), &"binding_property": str(prop)}
				)
				_walk_for_computed(host_path, "bind:" + str(prop), property_value)

		if component == "UiReactTabContainer" and &"tab_config" in ctl:
			var cfg: Variant = ctl.get(&"tab_config")
			if cfg is UiTabContainerCfg:
				_walk_tab_cfg(host_path, cfg as UiTabContainerCfg)

		if &"wire_rules" in ctl:
			var wr_variant: Variant = ctl.get(&"wire_rules")
			if wr_variant is Array:
				var idx := 0
				for item in wr_variant as Array:
					if item is UiReactWireRule:
						var rule := item as UiReactWireRule
						var sc: Script = rule.get_script() as Script
						var short := "WireRule"
						if sc != null and not sc.resource_path.is_empty():
							short = sc.resource_path.get_file().get_basename()
						queue_wire_rule_edges(host_path, idx, rule, short)
						for ref in _WireRuleIntrospectionScript.list_io(rule):
							var st: Variant = ref.get(&"state", null)
							if st is UiState:
								var wp: Variant = ref.get(&"property", &"")
								var wprop: StringName = wp if wp is StringName else StringName(str(wp))
								_walk_for_computed(
									host_path,
									"wire[%d].%s" % [idx, str(wprop)],
									st
								)
					idx += 1

		for extra in [&"animation_targets", &"action_targets"]:
			if extra in ctl:
				_walk_for_computed(host_path, str(extra), ctl.get(extra))

	func _walk_tab_cfg(host_path: NodePath, cfg: UiTabContainerCfg) -> void:
		_walk_for_computed(host_path, "tab_config.tabs", cfg.tabs_state)
		_walk_for_computed(host_path, "tab_config.disabled", cfg.disabled_tabs_state)
		_walk_for_computed(host_path, "tab_config.visible", cfg.visible_tabs_state)
		var ti := 0
		for s in cfg.tab_content_states:
			if s is UiState:
				_walk_for_computed(host_path, "tab_config.content[%d]" % ti, s as UiState)
			ti += 1

	func state_id(host_path: NodePath, context_seg: String, st: UiState) -> String:
		return UiReactExplainGraphBuilder._state_id(self, host_path, context_seg, st)

	func _walk_for_computed(host_path: NodePath, ctx_seg: String, v: Variant) -> void:
		_variant_nested(v, host_path, ctx_seg)

	func _variant_nested(v: Variant, host_path: NodePath, base_ctx: String) -> void:
		if v == null:
			return
		if v is UiComputedStringState or v is UiComputedBoolState:
			var c := v as UiState
			var cid_node := state_id(host_path, base_ctx, c)
			var raw: Variant = c.get(&"sources")
			if typeof(raw) == TYPE_ARRAY:
				var si := 0
				for it in raw as Array:
					if it is UiState:
						var src := it as UiState
						var src_id := state_id(host_path, "%s.src[%d]" % [base_ctx, si], src)
						add_edge(
							src_id,
							cid_node,
							_SnapshotScript.EdgeKind.COMPUTED_SOURCE,
							"sources[%d]" % si,
							{
								&"host_path": str(host_path),
								&"computed_source_index": si,
								&"computed_context": base_ctx,
							}
						)
						_variant_nested(it, host_path, base_ctx + ".src[%d]" % si)
					si += 1
			return
		if v is Array:
			var i := 0
			for el in v:
				_variant_nested(el, host_path, "%s[%d]" % [base_ctx, i])
				i += 1
			return
		if v is Dictionary:
			for k in v:
				_variant_nested(v[k], host_path, "%s.%s" % [base_ctx, str(k)])
			return

	func queue_wire_rule_edges(host_path: NodePath, rule_index: int, rule: UiReactWireRule, type_name: String) -> void:
		var ins: Array = []
		var outs: Array = []
		for ref in _WireRuleIntrospectionScript.list_io(rule):
			var role: StringName = ref.get(&"role", &"")
			var st: Variant = ref.get(&"state", null)
			if not (st is UiState):
				continue
			var prop: Variant = ref.get(&"property", &"")
			var prop_sn: StringName = prop if prop is StringName else StringName(str(prop))
			var u := st as UiState
			var entry: Dictionary = {&"state": u, &"property": prop_sn}
			if role == &"in":
				ins.append(entry)
			elif role == &"out":
				outs.append(entry)
		_wire_pairs.append({
			&"host_path": host_path,
			&"index": rule_index,
			&"type": type_name,
			&"ins": ins,
			&"outs": outs,
		})

	func _finalize_wire_product_edges() -> void:
		for pack in _wire_pairs:
			var hp: NodePath = pack[&"host_path"]
			var ri: int = int(pack[&"index"])
			var tname: String = str(pack[&"type"])
			var ins: Array = pack[&"ins"] as Array
			var outs: Array = pack[&"outs"] as Array
			var label := "wire_rules[%d] (%s)" % [ri, tname]
			for in_ev in ins:
				if in_ev is not Dictionary:
					continue
				var in_ent: Dictionary = in_ev as Dictionary
				var in_st: Variant = in_ent.get(&"state", null)
				if not (in_st is UiState):
					continue
				var in_prop_v: Variant = in_ent.get(&"property", &"")
				var in_prop: StringName = in_prop_v if in_prop_v is StringName else StringName(str(in_prop_v))
				var in_id := state_id(hp, "wire.in", in_st as UiState)
				if in_id.is_empty():
					continue
				for out_ev in outs:
					if out_ev is not Dictionary:
						continue
					var out_ent: Dictionary = out_ev as Dictionary
					var out_st: Variant = out_ent.get(&"state", null)
					if not (out_st is UiState):
						continue
					var out_prop_v: Variant = out_ent.get(&"property", &"")
					var out_prop: StringName = (
						out_prop_v if out_prop_v is StringName else StringName(str(out_prop_v))
					)
					var out_id := state_id(hp, "wire.out", out_st as UiState)
					if out_id.is_empty() or in_id == out_id:
						continue
					add_edge(
						in_id,
						out_id,
						_SnapshotScript.EdgeKind.WIRE_FLOW,
						label,
						{
							&"wire_host_path": str(hp),
							&"wire_rule_index": ri,
							&"wire_in_property": str(in_prop),
							&"wire_out_property": str(out_prop),
						}
					)

	func _copy_nodes_and_edges(snap: Variant) -> void:
		for k in node_by_id:
			snap.nodes.append(node_by_id[k])
		for e in edges:
			snap.edges.append(e)

	func _find_cycle_candidates(snap: Variant) -> void:
		var sc_nodes: Dictionary = {}
		for nid: Variant in node_by_id:
			var n: Dictionary = node_by_id[nid]
			var kk: int = int(n.get(&"kind", -1))
			if kk == _SnapshotScript.NodeKind.UI_STATE or kk == _SnapshotScript.NodeKind.UI_COMPUTED:
				sc_nodes[String(nid)] = true

		var adj: Dictionary = {}
		for e: Dictionary in edges:
			var fk: String = str(e.get(&"from_id", ""))
			var tk: String = str(e.get(&"to_id", ""))
			if not sc_nodes.has(fk) or not sc_nodes.has(tk):
				continue
			if not adj.has(fk):
				adj[fk] = [] as Array[String]
			(adj[fk] as Array[String]).append(tk)

		var found: Array[Dictionary] = []
		var seen_sig: Dictionary = {}
		var starts: PackedStringArray = PackedStringArray()
		for k: Variant in sc_nodes:
			starts.append(String(k))

		var n_starts: int = mini(starts.size(), MAX_CYCLE_START_NODES)
		for si in range(n_starts):
			var s_start: String = String(starts[si])
			var path0: Array[String] = []
			path0.append(s_start)
			_dfs_cycles(s_start, s_start, adj, path0, seen_sig, found)
			if found.size() >= MAX_CYCLE_CANDIDATES:
				break

		for c in found:
			snap.cycle_candidates.append(c)

	func _dfs_cycles(
		start: String,
		current: String,
		adj: Dictionary,
		path: Array[String],
		seen_sig: Dictionary,
		found: Array[Dictionary],
	) -> void:
		if found.size() >= MAX_CYCLE_CANDIDATES:
			return
		if path.size() > MAX_CYCLE_DFS_DEPTH:
			return
		var nbrs: Variant = adj.get(current, [] as Array[String])
		for raw: Variant in nbrs as Array[String]:
			var nb := String(raw)
			if nb == start:
				if path.size() >= 2:
					var sig_parts := PackedStringArray()
					for p in path:
						sig_parts.append(p)
					var sig := "|".join(sig_parts)
					if not seen_sig.has(sig):
						seen_sig[sig] = true
						var ids := PackedStringArray()
						for p in path:
							ids.append(p)
						var parts: PackedStringArray = PackedStringArray()
						for p in path:
							parts.append(p)
						parts.append(start)
						found.append({&"node_ids": ids, &"summary": " -> ".join(parts)})
				continue
			if path.has(nb):
				continue
			var next_path: Array[String] = (path.duplicate() as Array[String])
			next_path.append(nb)
			_dfs_cycles(start, nb, adj, next_path, seen_sig, found)

	## Fills [code]snap.upstream_ids[/code] / [code]downstream_ids[/code] only (layout scope for graph center).
	func _apply_layout_scope_for_host(snap: Variant, focus_control_id: String) -> void:
		snap.upstream_ids.clear()
		snap.downstream_ids.clear()
		var ad := UiReactExplainGraphBuilder._adjacency_from_edges(edges)
		var rev: Dictionary = ad[&"rev"]
		var fwd: Dictionary = ad[&"fwd"]

		var seed_states: Dictionary = {}
		for e2: Dictionary in edges:
			if int(e2.get(&"kind", -1)) != _SnapshotScript.EdgeKind.BINDING:
				continue
			if str(e2.get(&"to_id", "")) != focus_control_id:
				continue
			var fs := str(e2.get(&"from_id", ""))
			if not fs.is_empty():
				seed_states[fs] = true

		var up: Dictionary = {}
		var dq: Array[String] = []
		for s: Variant in seed_states:
			var ss := String(s)
			up[ss] = true
			dq.append(ss)
		var guard := 0
		while not dq.is_empty() and guard < MAX_GRAPH_WALK:
			guard += 1
			var cur: String = dq.pop_front() as String
			var pr: Variant = rev.get(cur, [] as Array[String])
			for p: Variant in pr as Array[String]:
				var ps := String(p)
				if up.has(ps):
					continue
				up[ps] = true
				dq.append(ps)

		var down: Dictionary = {}
		var q2: Array[String] = []
		for s: Variant in seed_states:
			var s2 := String(s)
			down[s2] = true
			q2.append(s2)
		guard = 0
		while not q2.is_empty() and guard < MAX_GRAPH_WALK:
			guard += 1
			var c2: String = q2.pop_front() as String
			var nx: Variant = fwd.get(c2, [] as Array[String])
			for nxt: Variant in nx as Array[String]:
				var ns := String(nxt)
				if down.has(ns):
					continue
				down[ns] = true
				q2.append(ns)

		for k: Variant in up:
			snap.upstream_ids.append(String(k))
		for k: Variant in down:
			snap.downstream_ids.append(String(k))


static func _adjacency_from_edges(edge_list: Array) -> Dictionary:
	var rev: Dictionary = {}
	var fwd: Dictionary = {}
	for e: Variant in edge_list:
		if e is not Dictionary:
			continue
		var ed: Dictionary = e as Dictionary
		var f: String = str(ed.get(&"from_id", ""))
		var t: String = str(ed.get(&"to_id", ""))
		if f.is_empty() or t.is_empty():
			continue
		if not rev.has(t):
			rev[t] = [] as Array[String]
		(rev[t] as Array[String]).append(f)
		if not fwd.has(f):
			fwd[f] = [] as Array[String]
		(fwd[f] as Array[String]).append(t)
	return {&"rev": rev, &"fwd": fwd}


static func _node_by_id_from_snap(snap: UiReactExplainGraphSnapshot) -> Dictionary:
	var nb: Dictionary = {}
	for nd: Variant in snap.nodes:
		if nd is not Dictionary:
			continue
		var d: Dictionary = nd as Dictionary
		var id := str(d.get(&"id", ""))
		if not id.is_empty():
			nb[id] = d
	return nb


static func _fill_lines_into(
	out_arr: PackedStringArray,
	id_set: Dictionary,
	node_by_id: Dictionary,
	max_visible: int,
) -> void:
	var n := mini(id_set.size(), max_visible)
	var i := 0
	for k: Variant in id_set:
		if i >= n:
			break
		var idstr := String(k)
		var nl: Dictionary = node_by_id.get(idstr, {}) as Dictionary
		var lab := str(nl.get(&"label", idstr))
		out_arr.append("• %s — [code]%s[/code]\n" % [lab, idstr])
		i += 1
	if id_set.size() > n:
		out_arr.append("• … (%d more)\n" % (id_set.size() - n))


static func _sorted_id_keys(id_set: Dictionary) -> Array[String]:
	var keys: Array[String] = []
	for k: Variant in id_set:
		keys.append(String(k))
	keys.sort()
	return keys


## Display-only: remove ids from a reachability dict before human bullets (full [member UiReactExplainGraphNarrative.upstream_node_ids] unchanged).
static func _dict_minus_ids(d: Dictionary, exclude: PackedStringArray) -> Dictionary:
	if exclude.is_empty():
		return d
	var out: Dictionary = {}
	for k: Variant in d:
		var ks := String(k)
		var skip := false
		for i in exclude.size():
			if String(exclude[i]) == ks:
				skip = true
				break
		if not skip:
			out[ks] = true
	return out


## Human-only bullets for details pane (no technical ids); keys iterated in sorted order.
static func _append_human_bullets_for_ids(
	out_arr: PackedStringArray,
	id_set: Dictionary,
	node_by_id: Dictionary,
	max_visible: int,
) -> void:
	var keys := _sorted_id_keys(id_set)
	var n := mini(keys.size(), max_visible)
	for i in range(n):
		var idstr := keys[i]
		var nl: Dictionary = node_by_id.get(idstr, {}) as Dictionary
		var lab := str(nl.get(&"label", idstr)).strip_edges()
		out_arr.append("• %s\n" % lab)
	if keys.size() > n:
		out_arr.append("• … (%d more)\n" % (keys.size() - n))


static func _pack_ids_from_set(id_set: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	for k: Variant in id_set:
		out.append(String(k))
	return out


static func _partition_down_by_kind(down: Dictionary, node_by_id: Dictionary) -> Array:
	var down_states: Dictionary = {}
	var down_ctrls: Dictionary = {}
	for k: Variant in down:
		var idstr := String(k)
		var nl: Dictionary = node_by_id.get(idstr, {}) as Dictionary
		var dkind := int(nl.get(&"kind", -1))
		if dkind == _SnapshotScript.NodeKind.CONTROL:
			down_ctrls[idstr] = true
		else:
			down_states[idstr] = true
	return [down_states, down_ctrls]


static func compute_narrative(
	root: Node,
	snap: UiReactExplainGraphSnapshot,
	anchor_id: String,
	show_full: bool = false,
	upstream_display_exclude_ids: PackedStringArray = PackedStringArray(),
	downstream_display_exclude_ids: PackedStringArray = PackedStringArray(),
) -> RefCounted:
	var out: RefCounted = _ExplainNarrativeScript.new() as RefCounted
	out.anchor_id = anchor_id
	if anchor_id.is_empty() or root == null:
		out.bound_state_lines.append("[i]No anchor.[/i]\n")
		return out

	var node_by_id := _node_by_id_from_snap(snap)
	if not node_by_id.has(anchor_id):
		out.bound_state_lines.append("[i]Unknown node id in snapshot.[/i]\n")
		return out

	var nk := int((node_by_id[anchor_id] as Dictionary).get(&"kind", -1))
	var edges_arr: Array = snap.edges
	var ad := _adjacency_from_edges(edges_arr)
	var rev: Dictionary = ad[&"rev"]
	var fwd: Dictionary = ad[&"fwd"]

	var max_vis := 999999 if show_full else 96

	var up: Dictionary = {}
	var down: Dictionary = {}
	var seed_states_meta: Dictionary = {}

	if nk == _SnapshotScript.NodeKind.CONTROL:
		var seed_states: Dictionary = {}
		for e2: Variant in edges_arr:
			if e2 is not Dictionary:
				continue
			var ed2: Dictionary = e2 as Dictionary
			if int(ed2.get(&"kind", -1)) != _SnapshotScript.EdgeKind.BINDING:
				continue
			if str(ed2.get(&"to_id", "")) != anchor_id:
				continue
			var fs := str(ed2.get(&"from_id", ""))
			if not fs.is_empty():
				seed_states[fs] = true
		seed_states_meta = seed_states

		var dq: Array[String] = []
		for s: Variant in seed_states:
			var ss := String(s)
			up[ss] = true
			dq.append(ss)
		var guard := 0
		while not dq.is_empty() and guard < MAX_GRAPH_WALK:
			guard += 1
			var cur: String = dq.pop_front() as String
			var pr: Variant = rev.get(cur, [] as Array[String])
			for p: Variant in pr as Array[String]:
				var ps := String(p)
				if up.has(ps):
					continue
				up[ps] = true
				dq.append(ps)

		(out as UiReactExplainGraphNarrative).omit_upstream_in_details = false

		var q2: Array[String] = []
		for s: Variant in seed_states:
			var s2 := String(s)
			down[s2] = true
			q2.append(s2)
		guard = 0
		while not q2.is_empty() and guard < MAX_GRAPH_WALK:
			guard += 1
			var c2: String = q2.pop_front() as String
			var nx: Variant = fwd.get(c2, [] as Array[String])
			for nxt: Variant in nx as Array[String]:
				var ns := String(nxt)
				if down.has(ns):
					continue
				down[ns] = true
				q2.append(ns)

		if anchor_id.begins_with("ctrl:"):
			var path_str := anchor_id.substr(5)
			var np := NodePath(path_str)
			if root.has_node(np):
				var n: Node = root.get_node(np)
				if n is Control and UiReactScannerService.is_react_node(n as Control):
					var ctl := n as Control
					var focus_path := _host_path_from_root(root, ctl)
					var comp := UiReactScannerService.get_component_name_from_script(ctl.get_script() as Script)
					out.bound_state_lines.append(
						"[b]Focus[/b]: [code]%s[/code]  path [code]%s[/code]  component [code]%s[/code]\n" % [ctl.name, str(focus_path), comp]
					)
				else:
					out.bound_state_lines.append("[i]Control anchor is not a UiReact* host in this scene.[/i]\n")
			else:
				out.bound_state_lines.append("[i]Control path not found under edited scene root.[/i]\n")
		else:
			out.bound_state_lines.append("[i]Invalid control id.[/i]\n")

	elif nk == _SnapshotScript.NodeKind.UI_STATE or nk == _SnapshotScript.NodeKind.UI_COMPUTED:
		# v1: full edge-wise reachability from this anchor (all edge kinds in snapshot).
		up[anchor_id] = true
		var dq2: Array[String] = [anchor_id]
		var guard2 := 0
		while not dq2.is_empty() and guard2 < MAX_GRAPH_WALK:
			guard2 += 1
			var cur2: String = dq2.pop_front() as String
			var pr2: Variant = rev.get(cur2, [] as Array[String])
			for p: Variant in pr2 as Array[String]:
				var ps := String(p)
				if up.has(ps):
					continue
				up[ps] = true
				dq2.append(ps)

		down[anchor_id] = true
		var q3: Array[String] = [anchor_id]
		guard2 = 0
		while not q3.is_empty() and guard2 < MAX_GRAPH_WALK:
			guard2 += 1
			var c3: String = q3.pop_front() as String
			var nx3: Variant = fwd.get(c3, [] as Array[String])
			for nxt: Variant in nx3 as Array[String]:
				var ns3 := String(nxt)
				if down.has(ns3):
					continue
				down[ns3] = true
				q3.append(ns3)

		out.bound_state_lines.append(
			"[i]Anchor is not a UiReact* host — no binding export list. Upstream/downstream follow all declarative edges in this snapshot.[/i]\n"
		)
	else:
		out.bound_state_lines.append("[i]Unknown node kind for narrative.[/i]\n")

	var narr_cast := out as UiReactExplainGraphNarrative
	if nk == _SnapshotScript.NodeKind.CONTROL:
		for sk: Variant in _sorted_id_keys(seed_states_meta):
			narr_cast.seed_state_ids.append(String(sk))
		var upstream_extra: Dictionary = {}
		for k: Variant in up:
			var ku := String(k)
			if not seed_states_meta.has(ku):
				upstream_extra[ku] = true
		_append_human_bullets_for_ids(
			narr_cast.upstream_display_lines,
			_dict_minus_ids(upstream_extra, upstream_display_exclude_ids),
			node_by_id,
			max_vis
		)
		var down_disp: Dictionary = {}
		for k2: Variant in down:
			var kd := String(k2)
			if seed_states_meta.has(kd):
				continue
			if kd == anchor_id:
				continue
			down_disp[kd] = true
		var down_parts_c: Array = _partition_down_by_kind(
			_dict_minus_ids(down_disp, downstream_display_exclude_ids), node_by_id
		)
		_append_human_bullets_for_ids(
			narr_cast.downstream_state_display_lines, down_parts_c[0] as Dictionary, node_by_id, max_vis
		)
		_append_human_bullets_for_ids(
			narr_cast.downstream_control_display_lines, down_parts_c[1] as Dictionary, node_by_id, max_vis
		)
	elif nk == _SnapshotScript.NodeKind.UI_STATE or nk == _SnapshotScript.NodeKind.UI_COMPUTED:
		var up_disp: Dictionary = {}
		for k3: Variant in up:
			var ku2 := String(k3)
			if ku2 == anchor_id:
				continue
			up_disp[ku2] = true
		_append_human_bullets_for_ids(
			narr_cast.upstream_display_lines,
			_dict_minus_ids(up_disp, upstream_display_exclude_ids),
			node_by_id,
			max_vis
		)
		var down_disp2: Dictionary = {}
		for k4: Variant in down:
			var kd2 := String(k4)
			if kd2 == anchor_id:
				continue
			down_disp2[kd2] = true
		var down_parts_s: Array = _partition_down_by_kind(
			_dict_minus_ids(down_disp2, downstream_display_exclude_ids), node_by_id
		)
		_append_human_bullets_for_ids(
			narr_cast.downstream_state_display_lines, down_parts_s[0] as Dictionary, node_by_id, max_vis
		)
		_append_human_bullets_for_ids(
			narr_cast.downstream_control_display_lines, down_parts_s[1] as Dictionary, node_by_id, max_vis
		)

	narr_cast.upstream_node_ids = _pack_ids_from_set(up)
	narr_cast.downstream_node_ids = _pack_ids_from_set(down)
	return out

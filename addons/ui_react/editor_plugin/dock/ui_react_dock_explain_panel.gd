## Editor dock tab: declarative dependency graph ([code]CB-018A[/code]) + visual graph ([code]CB-018A.1[/code]–[code]CB-018A.3[/code]).
class_name UiReactDockExplainPanel
extends MarginContainer

const _ExplainBuilderScript := preload("res://addons/ui_react/editor_plugin/services/ui_react_explain_graph_builder.gd")
const _ExplainLayoutScript := preload("res://addons/ui_react/editor_plugin/services/ui_react_explain_graph_layout.gd")
const _ExplainGraphViewScript := preload("res://addons/ui_react/editor_plugin/dock/ui_react_explain_graph_view.gd")
const _SnapScript := preload("res://addons/ui_react/editor_plugin/models/ui_react_explain_graph_snapshot.gd")

const MODE_TEXT := 0
const MODE_VISUAL := 1

const _SEL_NONE := 0
const _SEL_NODE := 1
const _SEL_EDGE := 2

var _plugin: EditorPlugin

var _hint: RichTextLabel
var _btn_refresh: Button
var _mode_option: OptionButton
var _btn_fit: Button
var _stack: TabContainer
var _scroll_text: ScrollContainer
var _body: RichTextLabel
var _visual_host: VBoxContainer
var _visual_toolbar: HBoxContainer
var _legend_row: HBoxContainer
var _cb_bind: CheckBox
var _cb_computed: CheckBox
var _cb_wire: CheckBox
var _cb_edge_labels: CheckBox
var _graph_view: Control
var _details_scroll: ScrollContainer
var _details: RichTextLabel
var _details_buttons: HBoxContainer
var _btn_focus_inspector: Button
var _btn_copy_details: Button

var _auto_refresh_timer: Timer

var _mode: int = MODE_TEXT
var _last_snap: Variant = null
var _last_focus_id: String = ""
var _last_layout: Dictionary = {}

var _selection_kind: int = _SEL_NONE
var _graph_selected_node_id: String = ""
var _graph_selected_edge_index: int = -1
var _last_details_plain: String = ""


func setup(plugin: EditorPlugin) -> void:
	_plugin = plugin
	_build_ui()
	var ei := _plugin.get_editor_interface()
	if not ei.get_selection().selection_changed.is_connected(_on_editor_selection_changed):
		ei.get_selection().selection_changed.connect(_on_editor_selection_changed)


func refresh() -> void:
	if _body == null:
		return
	_set_idle()
	if _plugin == null:
		_set_hint_visible(true)
		_set_hint("Plugin not ready.")
		_clear_stale_snapshot()
		return
	var ei := _plugin.get_editor_interface()
	var root := ei.get_edited_scene_root()
	if root == null:
		_set_hint_visible(true)
		_set_hint("Open a scene to build the dependency graph.")
		_clear_stale_snapshot()
		return
	var sel: Array[Node] = ei.get_selection().get_selected_nodes()
	if sel.size() != 1:
		_set_hint_visible(true)
		_set_hint("Select exactly one [code]UiReact*[/code] node in the edited scene.")
		_clear_stale_snapshot()
		return
	var n: Node = sel[0]
	if not (n is Control):
		_set_hint_visible(true)
		_set_hint("Selection must be a [code]Control[/code] ([code]UiReact*[/code]).")
		_clear_stale_snapshot()
		return
	if not UiReactScannerService.is_react_node(n):
		_set_hint_visible(true)
		_set_hint("Selection is not a [code]UiReact*[/code] host (no ui_react_* script stem).")
		_clear_stale_snapshot()
		return
	if not (n == root or root.is_ancestor_of(n)):
		_set_hint_visible(true)
		_set_hint("Selection must be part of the current edited scene.")
		_clear_stale_snapshot()
		return

	_set_hint_visible(false)
	var snap = _ExplainBuilderScript.build(root, n as Control)
	_last_snap = snap
	var hp: NodePath = _ExplainBuilderScript._host_path_from_root(root, n as Control)
	_last_focus_id = _ExplainBuilderScript._control_id(hp)

	_render_text_report(snap)
	_apply_visual_from_snap_safe(snap, _last_focus_id)
	_apply_mode_visibility()


func _on_editor_selection_changed() -> void:
	if _auto_refresh_timer == null:
		return
	_auto_refresh_timer.stop()
	_auto_refresh_timer.start()


func _on_debounced_auto_refresh() -> void:
	if not is_visible_in_tree():
		return
	refresh()


func _render_text_report(snap: Variant) -> void:
	var bbf := "[font_size=12]"
	for line in snap.bound_state_lines:
		bbf += line
	bbf += "\n[b]Upstream[/b] (state/computed that flow into this control’s bindings):\n"
	if snap.upstream_lines.is_empty():
		bbf += "(none)\n"
	else:
		for line in snap.upstream_lines:
			bbf += line
	bbf += "\n[b]Downstream[/b] (nodes reachable from bound states):\n"
	if snap.downstream_lines.is_empty():
		bbf += "(none)\n"
	else:
		for line in snap.downstream_lines:
			bbf += line
	bbf += "\n[b]Cycle candidates[/b] (static, state/computed edges only):\n"
	if snap.cycle_candidates.is_empty():
		bbf += "(none)\n"
	else:
		for c: Variant in snap.cycle_candidates:
			if c is Dictionary:
				bbf += "• %s\n" % str((c as Dictionary).get(&"summary", "?"))
	bbf += "\n[i]Declarative graph only — not a runtime causality trace.[/i]\n"
	bbf += "[/font_size]"
	_body.text = bbf


func _apply_visual_from_snap_safe(snap: Variant, focus_id: String) -> void:
	if _graph_view == null:
		return
	var layout: Dictionary = _ExplainLayoutScript.layout_snapshot(snap, focus_id)
	_last_layout = layout
	var centers: Dictionary = layout.get(&"node_centers", {}) as Dictionary
	if centers.is_empty():
		_graph_view.clear_graph()
		_set_details_empty()
		_set_hint_visible(true)
		_set_hint("No nodes in scope for this layout. Use Text mode for the full report.")
		return
	(_graph_view as Object).call(&"set_layout", layout)
	_push_visual_filters()
	_set_details_placeholder()
	_graph_selected_node_id = ""
	_graph_selected_edge_index = -1
	_selection_kind = _SEL_NONE
	_update_focus_button_state()


func _push_visual_filters() -> void:
	if _graph_view == null:
		return
	var b := _cb_bind == null or _cb_bind.button_pressed
	var c := _cb_computed == null or _cb_computed.button_pressed
	var w := _cb_wire == null or _cb_wire.button_pressed
	var lbl := _cb_edge_labels != null and _cb_edge_labels.button_pressed
	(_graph_view as Object).call(&"set_edge_filters", b, c, w, lbl)


func _apply_mode_visibility() -> void:
	if _stack == null:
		return
	_stack.current_tab = 0 if _mode == MODE_TEXT else 1
	if _visual_toolbar:
		_visual_toolbar.visible = _mode == MODE_VISUAL
	if _legend_row:
		_legend_row.visible = _mode == MODE_VISUAL
	if _btn_fit:
		_btn_fit.visible = _mode == MODE_VISUAL


func _on_mode_changed(index: int) -> void:
	_mode = _mode_option.get_item_id(index)
	if _stack:
		_stack.current_tab = 0 if _mode == MODE_TEXT else 1
	_apply_mode_visibility()
	if _mode == MODE_VISUAL and _last_snap != null:
		_apply_visual_from_snap_safe(_last_snap, _last_focus_id)


func _on_fit_pressed() -> void:
	if _graph_view and _graph_view.has_method(&"reset_view"):
		_graph_view.call(&"reset_view")


func _on_graph_node(id: String) -> void:
	_graph_selected_node_id = id
	_graph_selected_edge_index = -1
	_selection_kind = _SEL_NODE
	_update_focus_button_state()
	_fill_node_details(id)


func _on_graph_edge(from_id: String, to_id: String, kind: int, label: String, edge_index: int) -> void:
	_graph_selected_node_id = ""
	_graph_selected_edge_index = edge_index
	_selection_kind = _SEL_EDGE
	_update_focus_button_state()
	_fill_edge_details(from_id, to_id, kind, label, edge_index)


func _on_graph_cleared() -> void:
	_graph_selected_node_id = ""
	_graph_selected_edge_index = -1
	_selection_kind = _SEL_NONE
	_update_focus_button_state()
	_set_details_placeholder()


func _update_focus_button_state() -> void:
	if _btn_focus_inspector == null:
		return
	_btn_focus_inspector.disabled = _selection_kind == _SEL_NONE


func _set_details_placeholder() -> void:
	_set_details_both(
		"[i]Select a node or edge in the graph to see details.[/i]",
		"Select a node or edge in the graph to see details."
	)


func _set_details_empty() -> void:
	_set_details_both(
		"[i]No graph in scope. Try Text mode or Refresh after changing bindings.[/i]",
		"No graph in scope. Try Text mode or Refresh after changing bindings."
	)


func _set_details_both(bb: String, plain: String) -> void:
	if _details:
		_details.text = bb
	_last_details_plain = plain


const _INCIDENT_EDGE_CAP := 8
const _ORPHAN_LAYER := -512
const _CYCLE_SUMMARY_CAP := 2


func _id_in_packed(ids: PackedStringArray, needle: String) -> bool:
	for i in ids.size():
		if String(ids[i]) == needle:
			return true
	return false


func _format_incident_edge_bb_plain(ed: Dictionary) -> PackedStringArray:
	var fa := str(ed.get(&"from_id", ""))
	var ta := str(ed.get(&"to_id", ""))
	var k := int(ed.get(&"kind", -1))
	var lab := str(ed.get(&"label", ""))
	var tag := _edge_short_token(k)
	var s_from := _short_label_for_node_id(fa)
	var s_to := _short_label_for_node_id(ta)
	var bb := "• [code][%s][/code] %s → %s" % [tag, s_from, s_to]
	var plain := "• [%s] %s → %s" % [tag, s_from, s_to]
	if not lab.is_empty():
		bb += "  ([code]%s[/code])" % lab
		plain += " (%s)" % lab
	return PackedStringArray([bb, plain])


func _focus_relation_blurb_bb_plain(node_id: String, focus_id: String, node_layer: Dictionary) -> PackedStringArray:
	var bb := "[b]Relative to focus[/b]\n"
	var plain := "Relative to focus\n"
	if node_id == focus_id:
		bb += "At layout center — this is the focus control column in this layout.\n\n"
		plain += "At layout center — this is the focus control column in this layout.\n\n"
	else:
		if not node_layer.has(node_id):
			bb += "Weakly connected in this layout — present in scope but not on the main upstream/downstream spine used for layering.\n\n"
			plain += "Weakly connected in this layout — present in scope but not on the main upstream/downstream spine used for layering.\n\n"
		else:
			var L := int(node_layer[node_id])
			if L == _ORPHAN_LAYER:
				bb += "Weakly connected in this layout — present in scope but not on the main upstream/downstream spine used for layering.\n\n"
				plain += "Weakly connected in this layout — present in scope but not on the main upstream/downstream spine used for layering.\n\n"
			elif L < 0:
				bb += "Upstream side — closer to sources that feed the focus control's bindings (left side of this layout).\n\n"
				plain += "Upstream side — closer to sources that feed the focus control's bindings (left side of this layout).\n\n"
			elif L > 0:
				bb += "Downstream side — reachable from states bound to the focus (right side of this layout).\n\n"
				plain += "Downstream side — reachable from states bound to the focus (right side of this layout).\n\n"
			else:
				bb += "Same layout tier as the focus column — neighbors in this horizontal band.\n\n"
				plain += "Same layout tier as the focus column — neighbors in this horizontal band.\n\n"
	if _last_snap != null:
		var snap: UiReactExplainGraphSnapshot = _last_snap as UiReactExplainGraphSnapshot
		if _id_in_packed(snap.upstream_ids, node_id):
			bb += "Also listed as upstream of the focus in the full snapshot (state/computed walk).\n\n"
			plain += "Also listed as upstream of the focus in the full snapshot (state/computed walk).\n\n"
		if _id_in_packed(snap.downstream_ids, node_id):
			bb += "Also listed as downstream of the focus in the full snapshot (state/computed walk).\n\n"
			plain += "Also listed as downstream of the focus in the full snapshot (state/computed walk).\n\n"
	return PackedStringArray([bb, plain])


func _cycle_summaries_bb_plain(node_id: String) -> PackedStringArray:
	if _last_snap == null:
		return PackedStringArray(["", ""])
	var snap: UiReactExplainGraphSnapshot = _last_snap as UiReactExplainGraphSnapshot
	var collected: PackedStringArray = PackedStringArray()
	var total_matching := 0
	for c: Variant in snap.cycle_candidates:
		if c is not Dictionary:
			continue
		var cd: Dictionary = c as Dictionary
		var ids := cd.get(&"node_ids", PackedStringArray()) as PackedStringArray
		if not _id_in_packed(ids, node_id):
			continue
		total_matching += 1
		if collected.size() >= _CYCLE_SUMMARY_CAP:
			continue
		var sm := str(cd.get(&"summary", "")).strip_edges()
		if sm.is_empty():
			continue
		collected.append(sm)
	if collected.is_empty():
		return PackedStringArray(["", ""])
	var bb := "[b]Cycle hints[/b]\n"
	var plain := "Cycle hints\n"
	for i in collected.size():
		bb += "• [code]%s[/code]\n" % collected[i]
		plain += "• %s\n" % collected[i]
	var more := total_matching - collected.size()
	if more > 0:
		bb += "• [i]+%d more[/i]\n" % more
		plain += "• +%d more\n" % more
	bb += "Static candidate (declarative edges only).\n\n"
	plain += "Static candidate (declarative edges only).\n\n"
	return PackedStringArray([bb, plain])


func _node_headline_bb_plain(node_id: String, d: Dictionary, focus_id: String) -> PackedStringArray:
	if node_id == focus_id:
		var bb := "[b]Focus control[/b]\n"
		bb += "This is the [code]UiReact*[/code] host you selected when building this graph. Relationships are [i]declarative[/i] (Inspector wiring), not a live runtime trace.\n\n"
		var plain := "Focus control\n"
		plain += "This is the UiReact* host you selected when building this graph. Relationships are declarative (Inspector wiring), not a live runtime trace.\n\n"
		return PackedStringArray([bb, plain])
	var nk := int(d.get(&"kind", -1))
	var short_l := str(d.get(&"short_label", ""))
	var label_disp := short_l if not short_l.is_empty() else node_id
	var bb2 := "[b]%s[/b] — " % label_disp
	var plain2 := "%s — " % label_disp
	match nk:
		_SnapScript.NodeKind.CONTROL:
			bb2 += "Control ([code]UiReact*[/code] host) in this scoped graph.\n\n"
			plain2 += "Control (UiReact* host) in this scoped graph.\n\n"
		_SnapScript.NodeKind.UI_STATE:
			bb2 += "[code]UiState[/code] resource node (bindings, wires, or computed inputs).\n\n"
			plain2 += "UiState resource node (bindings, wires, or computed inputs).\n\n"
		_SnapScript.NodeKind.UI_COMPUTED:
			bb2 += "[code]UiComputed*[/code] resource node (aggregates [code]sources[/code]).\n\n"
			plain2 += "UiComputed* resource node (aggregates sources).\n\n"
		_:
			bb2 += "Node in this scoped graph.\n\n"
			plain2 += "Node in this scoped graph.\n\n"
	return PackedStringArray([bb2, plain2])


func _fill_node_details(node_id: String) -> void:
	if node_id.is_empty():
		return
	var nb: Dictionary = _last_layout.get(&"node_by_id", {}) as Dictionary
	var d: Dictionary = nb.get(node_id, {}) as Dictionary
	var edges: Array = _last_layout.get(&"draw_edges", []) as Array
	var focus_id := str(_last_layout.get(&"focus_id", ""))
	var node_layer: Dictionary = _last_layout.get(&"node_layer", {}) as Dictionary
	var stats: Dictionary = _last_layout.get(&"graph_stats", {}) as Dictionary
	var truncated := bool(stats.get(&"truncated", false))

	var hl := _node_headline_bb_plain(node_id, d, focus_id)
	var bb := hl[0]
	var plain := hl[1]

	var rel := _focus_relation_blurb_bb_plain(node_id, focus_id, node_layer)
	bb += rel[0]
	plain += rel[1]

	var incident: Array[Dictionary] = []
	for e: Variant in edges:
		if e is not Dictionary:
			continue
		var ed: Dictionary = e as Dictionary
		if str(ed.get(&"from_id", "")) == node_id or str(ed.get(&"to_id", "")) == node_id:
			incident.append(ed)
	incident.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			var ka := int(a.get(&"kind", -1))
			var kb := int(b.get(&"kind", -1))
			if ka != kb:
				return ka < kb
			var fa := str(a.get(&"from_id", ""))
			var fb := str(b.get(&"from_id", ""))
			if fa != fb:
				return fa < fb
			return str(a.get(&"to_id", "")) < str(b.get(&"to_id", ""))
	)

	bb += "[b]Incident edges[/b]\n"
	plain += "Incident edges\n"
	if incident.is_empty():
		bb += "No edges touch this node in the scoped graph (or it is isolated after filters).\n\n"
		plain += "No edges touch this node in the scoped graph (or it is isolated after filters).\n\n"
	else:
		var n_show := mini(incident.size(), _INCIDENT_EDGE_CAP)
		for i in n_show:
			var pair := _format_incident_edge_bb_plain(incident[i])
			bb += pair[0] + "\n"
			plain += pair[1] + "\n"
		bb += "\n"
		plain += "\n"
		var overflow := incident.size() - n_show
		if overflow > 0:
			bb += "[i]+%d more in this graph[/i]\n\n" % overflow
			plain += "+%d more in this graph\n\n" % overflow

	var cyc := _cycle_summaries_bb_plain(node_id)
	if not cyc[0].is_empty():
		bb += cyc[0]
		plain += cyc[1]

	bb += "[b]Full detail[/b]\n"
	plain += "Full detail\n"
	bb += "Switch to [b]Text[/b] mode for full upstream/downstream narratives, binding lists, and the complete cycle section"
	plain += "Switch to Text mode for full upstream/downstream narratives, binding lists, and the complete cycle section"
	if truncated:
		bb += " (this graph is truncated)"
		plain += " (this graph is truncated)"
	bb += ".\n\n"
	plain += ".\n\n"

	bb += "[b]Technical[/b]\n"
	plain += "Technical\n"
	var nk := int(d.get(&"kind", -1))
	var short_l := str(d.get(&"short_label", ""))
	var full_l := str(d.get(&"label", ""))
	if not short_l.is_empty():
		bb += "Short label: [code]%s[/code]\n" % short_l
		plain += "Short label: %s\n" % short_l
	if nk == _SnapScript.NodeKind.CONTROL:
		var cp := str(d.get(&"control_path", ""))
		if not cp.is_empty():
			bb += "Scene path: [code]%s[/code]\n" % cp
			plain += "Scene path: %s\n" % cp
	elif nk == _SnapScript.NodeKind.UI_STATE or nk == _SnapScript.NodeKind.UI_COMPUTED:
		var fp := str(d.get(&"state_file_path", ""))
		if not fp.is_empty():
			bb += "Resource: [code]%s[/code]\n" % fp
			plain += "Resource: %s\n" % fp
		else:
			var eh := str(d.get(&"embedded_host_path", ""))
			var ec := str(d.get(&"embedded_context", ""))
			if not eh.is_empty():
				bb += "Embedded — host: [code]%s[/code] context: [code]%s[/code]\n" % [eh, ec]
				plain += "Embedded — host: %s context: %s\n" % [eh, ec]
	if not full_l.is_empty():
		bb += "Full label: %s\n" % full_l
		plain += "Full label: %s\n" % full_l
	bb += "Technical id: [code]%s[/code]\n" % node_id
	plain += "Technical id: %s\n" % node_id

	_set_details_both(bb, plain)


func _fill_edge_details(from_id: String, to_id: String, kind: int, label: String, edge_index: int) -> void:
	var token := _edge_short_token(kind)
	var edges: Array = _last_layout.get(&"draw_edges", []) as Array
	var ed: Dictionary = {}
	if edge_index >= 0 and edge_index < edges.size():
		var ev: Variant = edges[edge_index]
		if ev is Dictionary:
			ed = ev as Dictionary

	var from_short := _short_label_for_node_id(from_id)
	var to_short := _short_label_for_node_id(to_id)

	var bb := ""
	var plain := ""

	match kind:
		_SnapScript.EdgeKind.BINDING:
			var bp := str(ed.get(&"binding_property", label))
			bb = "[b]Property binding[/b]\n"
			bb += "[code]%s[/code] feeds the [code]UiReact*[/code] control [code]%s[/code]'s [code]%s[/code] export.\n\n" % [
				from_short,
				to_short,
				bp,
			]
			plain = "Property binding\n"
			plain += "%s feeds the UiReact* control %s's %s export.\n\n" % [from_short, to_short, bp]
		_SnapScript.EdgeKind.COMPUTED_SOURCE:
			bb = "[b]Computed source[/b]\n"
			bb += "Upstream state [code]%s[/code] feeds an entry in the computed resource [code]%s[/code]'s [code]sources[/code] array.\n\n" % [
				from_short,
				to_short,
			]
			plain = "Computed source\n"
			plain += "Upstream state %s feeds an entry in the computed resource %s's sources array.\n\n" % [from_short, to_short]
		_SnapScript.EdgeKind.WIRE_FLOW:
			bb = "[b]Wire flow[/b]\n"
			bb += "A [code]wire_rules[/code] row connects input state [code]%s[/code] to output state [code]%s[/code].\n\n" % [
				from_short,
				to_short,
			]
			plain = "Wire flow\n"
			plain += "A wire_rules row connects input state %s to output state %s.\n\n" % [from_short, to_short]
		_:
			bb = "[b]Edge[/b]\nDeclarative dependency between two snapshot nodes.\n\n"
			plain = "Edge\nDeclarative dependency between two snapshot nodes.\n\n"

	bb += "[b]Endpoints[/b]\n"
	bb += "From: [code]%s[/code]  →  To: [code]%s[/code]\n" % [from_short, to_short]
	if not label.is_empty():
		bb += "Detail: [code]%s[/code]\n" % label
	bb += "\n"
	plain += "Endpoints\n"
	plain += "From: %s  →  To: %s\n" % [from_short, to_short]
	if not label.is_empty():
		plain += "Detail: %s\n" % label
	plain += "\n"

	if kind == _SnapScript.EdgeKind.BINDING:
		var hp := str(ed.get(&"host_path", ""))
		var bp := str(ed.get(&"binding_property", ""))
		if not hp.is_empty():
			bb += "[b]Where to edit[/b]\nInspector on host [code]%s[/code], export [code]%s[/code].\n\n" % [hp, bp]
			plain += "Where to edit\nInspector on host %s, export %s.\n\n" % [hp, bp]
	elif kind == _SnapScript.EdgeKind.COMPUTED_SOURCE:
		var hp2 := str(ed.get(&"host_path", ""))
		var si := int(ed.get(&"computed_source_index", -1))
		bb += "[b]Where to edit[/b]\nComputed [code]sources[/code]"
		var plain_w := "Where to edit\nComputed sources"
		if si >= 0:
			bb += " (index [code]%d[/code])" % si
			plain_w += " (index %d)" % si
		bb += " on the owning host"
		plain_w += " on the owning host"
		if not hp2.is_empty():
			bb += " [code]%s[/code]" % hp2
			plain_w += " %s" % hp2
		bb += ".\n\n"
		plain += plain_w + ".\n\n"
	elif kind == _SnapScript.EdgeKind.WIRE_FLOW:
		var wh := str(ed.get(&"wire_host_path", ""))
		var wi := int(ed.get(&"wire_rule_index", -1))
		bb += "[b]Where to edit[/b]\n"
		var plain_w2 := "Where to edit\n"
		if not wh.is_empty():
			bb += "Host [code]%s[/code], [code]wire_rules[/code]" % wh
			plain_w2 += "Host %s, wire_rules" % wh
			if wi >= 0:
				bb += " row [code]%d[/code]" % wi
				plain_w2 += " row %d" % wi
			bb += ".\n\n"
			plain_w2 += ".\n\n"
			plain += plain_w2

	if from_id == _last_focus_id or to_id == _last_focus_id:
		bb += "[b]Relation to focus[/b]\nTouches the focus control directly.\n\n"
		plain += "Relation to focus\nTouches the focus control directly.\n\n"

	bb += "[b]Technical[/b]\nKind token: [code]%s[/code]\nFrom id: [code]%s[/code]\nTo id: [code]%s[/code]\n" % [token, from_id, to_id]
	plain += "Technical\nKind token: %s\nFrom id: %s\nTo id: %s\n" % [token, from_id, to_id]

	_set_details_both(bb, plain)


func _edge_short_token(kind: int) -> String:
	match kind:
		_SnapScript.EdgeKind.BINDING:
			return "bind"
		_SnapScript.EdgeKind.COMPUTED_SOURCE:
			return "computed"
		_SnapScript.EdgeKind.WIRE_FLOW:
			return "wire"
	return "edge"


func _short_label_for_node_id(node_id: String) -> String:
	var nb: Dictionary = _last_layout.get(&"node_by_id", {}) as Dictionary
	var d: Dictionary = nb.get(node_id, {}) as Dictionary
	if d.is_empty():
		return node_id
	return str(d.get(&"short_label", d.get(&"label", node_id)))


func _on_focus_inspector_pressed() -> void:
	if _plugin == null:
		return
	var ei := _plugin.get_editor_interface()
	var root := ei.get_edited_scene_root()
	if root == null:
		return
	if _selection_kind == _SEL_NODE and not _graph_selected_node_id.is_empty():
		_focus_node_in_editor(_graph_selected_node_id, ei, root)
	elif _selection_kind == _SEL_EDGE and _graph_selected_edge_index >= 0:
		_focus_edge_in_editor(_graph_selected_edge_index, ei, root)


func _focus_node_in_editor(node_id: String, ei: EditorInterface, root: Node) -> void:
	if node_id.begins_with("ctrl:"):
		var path_str := node_id.substr(5)
		var np := NodePath(path_str)
		if root.has_node(np):
			var n: Node = root.get_node(np)
			if n is Control:
				ei.get_selection().clear()
				ei.get_selection().add_node(n)
				if ei.has_method(&"edit_node"):
					ei.call(&"edit_node", n as Node)
				return
	elif node_id.begins_with("state:"):
		var nb: Dictionary = _last_layout.get(&"node_by_id", {}) as Dictionary
		var d: Dictionary = nb.get(node_id, {}) as Dictionary
		var fp := str(d.get(&"state_file_path", ""))
		if fp.is_empty():
			_set_details_both(
				"[i]Embedded state has no resource file — select the owning [code]UiReact*[/code] control in the Scene tree, then open its state in the Inspector.[/i]",
				"Embedded state has no resource file — select the owning UiReact* control in the Scene tree."
			)
			return
		if ResourceLoader.exists(fp):
			var res: Resource = load(fp)
			if res != null and ei.has_method(&"edit_resource"):
				ei.call(&"edit_resource", res)
				return
	_set_details_both(
		"[i]Could not open this resource in the Inspector.[/i]",
		"Could not open this resource in the Inspector."
	)


func _focus_edge_in_editor(edge_index: int, ei: EditorInterface, root: Node) -> void:
	var edges: Array = _last_layout.get(&"draw_edges", []) as Array
	if edge_index < 0 or edge_index >= edges.size():
		return
	var ev: Variant = edges[edge_index]
	if ev is not Dictionary:
		return
	var ed: Dictionary = ev as Dictionary
	var kind := int(ed.get(&"kind", -1))
	if kind == _SnapScript.EdgeKind.BINDING:
		var hp := str(ed.get(&"host_path", ""))
		if not hp.is_empty() and root.has_node(NodePath(hp)):
			var n: Node = root.get_node(NodePath(hp))
			if n is Control:
				ei.get_selection().clear()
				ei.get_selection().add_node(n)
				if ei.has_method(&"edit_node"):
					ei.call(&"edit_node", n)
				return
	elif kind == _SnapScript.EdgeKind.WIRE_FLOW:
		var wh := str(ed.get(&"wire_host_path", ""))
		if not wh.is_empty() and root.has_node(NodePath(wh)):
			var n2: Node = root.get_node(NodePath(wh))
			if n2 is Control:
				ei.get_selection().clear()
				ei.get_selection().add_node(n2)
				if ei.has_method(&"edit_node"):
					ei.call(&"edit_node", n2)
				return
	elif kind == _SnapScript.EdgeKind.COMPUTED_SOURCE:
		var to_id := str(ed.get(&"to_id", ""))
		if not to_id.is_empty():
			_focus_node_in_editor(to_id, ei, root)
			return


func _on_copy_details_pressed() -> void:
	if not _last_details_plain.is_empty():
		DisplayServer.clipboard_set(_last_details_plain)


func _add_legend_swatch(row: HBoxContainer, col: Color, text: String) -> void:
	var sw := ColorRect.new()
	sw.custom_minimum_size = Vector2(12, 12)
	sw.color = col
	sw.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(sw)
	var lab := Label.new()
	lab.text = text
	lab.add_theme_font_size_override(&"font_size", 11)
	row.add_child(lab)


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_theme_constant_override(&"margin_left", 8)
	add_theme_constant_override(&"margin_right", 8)
	add_theme_constant_override(&"margin_top", 8)
	add_theme_constant_override(&"margin_bottom", 8)

	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(v)

	_hint = RichTextLabel.new()
	_hint.bbcode_enabled = true
	_hint.fit_content = false
	_hint.scroll_active = false
	_hint.custom_minimum_size = Vector2(0, 36)
	_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hint.visible = false
	v.add_child(_hint)

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(row)

	_btn_refresh = Button.new()
	_btn_refresh.text = "Refresh"
	_btn_refresh.tooltip_text = "Rebuild the dependency graph from the current selection and edited scene."
	_btn_refresh.pressed.connect(refresh)
	row.add_child(_btn_refresh)

	_mode_option = OptionButton.new()
	_mode_option.add_item("Text", MODE_TEXT)
	_mode_option.add_item("Visual", MODE_VISUAL)
	_mode_option.tooltip_text = "Text: full BBCode report. Visual: scoped dependency graph (read-only)."
	_mode_option.item_selected.connect(_on_mode_changed)
	row.add_child(_mode_option)

	_btn_fit = Button.new()
	_btn_fit.text = "Fit view"
	_btn_fit.tooltip_text = "Reset pan/zoom on the graph."
	_btn_fit.pressed.connect(_on_fit_pressed)
	row.add_child(_btn_fit)

	_auto_refresh_timer = Timer.new()
	_auto_refresh_timer.wait_time = 0.15
	_auto_refresh_timer.one_shot = true
	_auto_refresh_timer.timeout.connect(_on_debounced_auto_refresh)
	add_child(_auto_refresh_timer)

	_stack = TabContainer.new()
	_stack.tabs_visible = false
	_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stack.custom_minimum_size = Vector2(0, 220)
	v.add_child(_stack)

	_scroll_text = ScrollContainer.new()
	_scroll_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll_text.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_stack.add_child(_scroll_text)
	_stack.set_tab_title(0, "text")

	_body = RichTextLabel.new()
	_body.bbcode_enabled = true
	_body.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.scroll_active = false
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.fit_content = true
	_body.custom_minimum_size = Vector2(400, 0)
	_scroll_text.add_child(_body)

	_visual_host = VBoxContainer.new()
	_visual_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_visual_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stack.add_child(_visual_host)
	_stack.set_tab_title(1, "visual")

	_visual_toolbar = HBoxContainer.new()
	_visual_toolbar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_visual_host.add_child(_visual_toolbar)

	var leg := Label.new()
	leg.text = "Show:"
	_visual_toolbar.add_child(leg)

	_cb_bind = CheckBox.new()
	_cb_bind.text = "Binding"
	_cb_bind.button_pressed = true
	_cb_bind.tooltip_text = "Toggle binding edges (state → control property)."
	_cb_bind.toggled.connect(func(_on: bool) -> void: _push_visual_filters())
	_visual_toolbar.add_child(_cb_bind)

	_cb_computed = CheckBox.new()
	_cb_computed.text = "Computed"
	_cb_computed.button_pressed = true
	_cb_computed.tooltip_text = "Toggle computed-source edges."
	_cb_computed.toggled.connect(func(_on2: bool) -> void: _push_visual_filters())
	_visual_toolbar.add_child(_cb_computed)

	_cb_wire = CheckBox.new()
	_cb_wire.text = "Wire"
	_cb_wire.button_pressed = true
	_cb_wire.tooltip_text = "Toggle wire-rule flow edges."
	_cb_wire.toggled.connect(func(_on3: bool) -> void: _push_visual_filters())
	_visual_toolbar.add_child(_cb_wire)

	_cb_edge_labels = CheckBox.new()
	_cb_edge_labels.text = "All edge labels"
	_cb_edge_labels.button_pressed = false
	_cb_edge_labels.tooltip_text = "Show short edge tokens on all edges. Selection still shows full detail below."
	_cb_edge_labels.toggled.connect(func(_on4: bool) -> void: _push_visual_filters())
	_visual_toolbar.add_child(_cb_edge_labels)

	_legend_row = HBoxContainer.new()
	_legend_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_visual_host.add_child(_legend_row)
	var leg_title := Label.new()
	leg_title.text = "Key:"
	leg_title.add_theme_font_size_override(&"font_size", 11)
	_legend_row.add_child(leg_title)
	_add_legend_swatch(_legend_row, Color(0.25, 0.42, 0.32, 1.0), "Focus control")
	_add_legend_swatch(_legend_row, Color(0.22, 0.24, 0.3, 1.0), "Control")
	_add_legend_swatch(_legend_row, Color(0.18, 0.28, 0.42, 1.0), "State")
	_add_legend_swatch(_legend_row, Color(0.28, 0.22, 0.4, 1.0), "Computed")
	var leg_sp := Label.new()
	leg_sp.text = "  |  Edges:"
	leg_sp.add_theme_font_size_override(&"font_size", 11)
	_legend_row.add_child(leg_sp)
	_add_legend_swatch(_legend_row, Color(0.55, 0.55, 0.6, 1.0), "Binding")
	_add_legend_swatch(_legend_row, Color(0.45, 0.65, 0.85, 1.0), "Computed src")
	_add_legend_swatch(_legend_row, Color(0.85, 0.45, 0.35, 1.0), "Wire")

	_graph_view = _ExplainGraphViewScript.new()
	_graph_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_graph_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_graph_view.custom_minimum_size = Vector2(280, 200)
	_graph_view.node_selected.connect(_on_graph_node)
	_graph_view.edge_selected.connect(_on_graph_edge)
	_graph_view.selection_cleared.connect(_on_graph_cleared)
	_visual_host.add_child(_graph_view)

	_details_scroll = ScrollContainer.new()
	_details_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_details_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_details_scroll.custom_minimum_size = Vector2(0, 120)
	_details_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_details_scroll.tooltip_text = "Details for the selected graph item."
	_visual_host.add_child(_details_scroll)

	_details = RichTextLabel.new()
	_details.bbcode_enabled = true
	_details.scroll_active = false
	_details.fit_content = true
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_details.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_details.text = "[i]Select a node or edge in the graph to see details.[/i]"
	_details_scroll.add_child(_details)
	_last_details_plain = "Select a node or edge in the graph to see details."

	_details_buttons = HBoxContainer.new()
	_details_buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_visual_host.add_child(_details_buttons)

	_btn_focus_inspector = Button.new()
	_btn_focus_inspector.text = "Focus in Inspector"
	_btn_focus_inspector.tooltip_text = "Open the related scene node or resource in the Inspector when possible."
	_btn_focus_inspector.disabled = true
	_btn_focus_inspector.pressed.connect(_on_focus_inspector_pressed)
	_details_buttons.add_child(_btn_focus_inspector)

	_btn_copy_details = Button.new()
	_btn_copy_details.text = "Copy details"
	_btn_copy_details.tooltip_text = "Copy the plain-text details to the clipboard."
	_btn_copy_details.pressed.connect(_on_copy_details_pressed)
	_details_buttons.add_child(_btn_copy_details)

	_mode = MODE_TEXT
	_mode_option.select(_mode_option.get_item_index(MODE_TEXT))
	_stack.current_tab = MODE_TEXT
	_apply_mode_visibility()


func _set_hint_visible(on: bool) -> void:
	if _hint:
		_hint.visible = on
		var h := 36 if on else 0
		_hint.custom_minimum_size = Vector2(0, h)


func _clear_stale_snapshot() -> void:
	_last_snap = null
	_last_layout.clear()
	_last_focus_id = ""
	_graph_selected_node_id = ""
	_graph_selected_edge_index = -1
	_selection_kind = _SEL_NONE
	_update_focus_button_state()
	if _graph_view:
		_graph_view.clear_graph()


func _set_hint(t: String) -> void:
	if _hint:
		_hint.text = "[font_size=12]%s[/font_size]" % t


func _set_idle() -> void:
	if _body:
		_body.clear()

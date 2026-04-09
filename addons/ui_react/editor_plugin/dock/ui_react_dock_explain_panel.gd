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


func _fill_node_details(node_id: String) -> void:
	if node_id.is_empty():
		return
	var nb: Dictionary = _last_layout.get(&"node_by_id", {}) as Dictionary
	var d: Dictionary = nb.get(node_id, {}) as Dictionary
	var deg_in := 0
	var deg_out := 0
	var edges: Array = _last_layout.get(&"draw_edges", []) as Array
	for e: Variant in edges:
		if e is not Dictionary:
			continue
		var ed: Dictionary = e as Dictionary
		if str(ed.get(&"to_id", "")) == node_id:
			deg_in += 1
		if str(ed.get(&"from_id", "")) == node_id:
			deg_out += 1

	var nk := int(d.get(&"kind", 0))
	var type_user := "Control (UiReact host)"
	if nk == _SnapScript.NodeKind.UI_STATE:
		type_user = "UiState resource"
	elif nk == _SnapScript.NodeKind.UI_COMPUTED:
		type_user = "UiComputed* resource"

	var short_l := str(d.get(&"short_label", ""))
	var full_l := str(d.get(&"label", ""))

	var bb := "[b]What this is[/b]\n"
	bb += "A [b]%s[/b] node in the static dependency graph" % type_user
	bb += " — relationships are [i]declarative[/i] (Inspector wiring), not a live runtime trace.\n\n"

	bb += "[b]Display name[/b]\n[code]%s[/code]\n\n" % short_l

	if nk == _SnapScript.NodeKind.CONTROL:
		var cp := str(d.get(&"control_path", ""))
		if not cp.is_empty():
			bb += "[b]Scene location[/b]\n[code]%s[/code]\n\n" % cp
	elif nk == _SnapScript.NodeKind.UI_STATE or nk == _SnapScript.NodeKind.UI_COMPUTED:
		var fp := str(d.get(&"state_file_path", ""))
		if not fp.is_empty():
			bb += "[b]Resource[/b]\n[code]%s[/code]\n\n" % fp
		else:
			var eh := str(d.get(&"embedded_host_path", ""))
			var ec := str(d.get(&"embedded_context", ""))
			if not eh.is_empty():
				bb += "[b]Embedded state[/b] (no standalone .tres file)\n"
				bb += "Host: [code]%s[/code]\nContext: [code]%s[/code]\n\n" % [eh, ec]

	bb += "[b]Connections in this graph[/b]\n"
	bb += "Incoming: [b]%d[/b]  Outgoing: [b]%d[/b]\n\n" % [deg_in, deg_out]

	bb += "[b]Full label[/b] (from builder)\n%s\n\n" % full_l
	bb += "[b]Technical id[/b] (stable in this snapshot)\n[code]%s[/code]\n" % node_id

	var plain := "What this is\n"
	plain += "A %s node in the static dependency graph (declarative / Inspector wiring).\n\n" % type_user
	plain += "Display name\n%s\n\n" % short_l
	if nk == _SnapScript.NodeKind.CONTROL:
		var cp2 := str(d.get(&"control_path", ""))
		if not cp2.is_empty():
			plain += "Scene location\n%s\n\n" % cp2
	elif nk == _SnapScript.NodeKind.UI_STATE or nk == _SnapScript.NodeKind.UI_COMPUTED:
		var fp2 := str(d.get(&"state_file_path", ""))
		if not fp2.is_empty():
			plain += "Resource\n%s\n\n" % fp2
		else:
			plain += "Embedded state — Host: %s  Context: %s\n\n" % [
				str(d.get(&"embedded_host_path", "")),
				str(d.get(&"embedded_context", "")),
			]
	plain += "Connections in this graph — Incoming: %d  Outgoing: %d\n\n" % [deg_in, deg_out]
	plain += "Full label\n%s\n\nTechnical id\n%s\n" % [full_l, node_id]

	if d.is_empty():
		_set_details_both(
			"[b]Node[/b]\n[code]%s[/code]\n\nIncoming: %d  Outgoing: %d" % [node_id, deg_in, deg_out],
			"Node %s\nIncoming: %d Outgoing: %d" % [node_id, deg_in, deg_out]
		)
		return

	_set_details_both(bb, plain)


func _fill_edge_details(from_id: String, to_id: String, kind: int, label: String, edge_index: int) -> void:
	var token := _edge_short_token(kind)
	var kname := "?"
	match kind:
		_SnapScript.EdgeKind.BINDING:
			kname = "Property binding"
		_SnapScript.EdgeKind.COMPUTED_SOURCE:
			kname = "Computed source"
		_SnapScript.EdgeKind.WIRE_FLOW:
			kname = "Wire rule flow"

	var edges: Array = _last_layout.get(&"draw_edges", []) as Array
	var ed: Dictionary = {}
	if edge_index >= 0 and edge_index < edges.size():
		var ev: Variant = edges[edge_index]
		if ev is Dictionary:
			ed = ev as Dictionary

	var bb := "[b]What this is[/b]\n"
	bb += "A [b]%s[/b] edge: data/flow dependency between two snapshot nodes (declarative).\n\n" % kname
	bb += "[b]Summary[/b]\n"
	bb += "From [code]%s[/code] → to [code]%s[/code]\n" % [_short_label_for_node_id(from_id), _short_label_for_node_id(to_id)]
	bb += "Detail: [code]%s[/code]\n\n" % label

	if kind == _SnapScript.EdgeKind.BINDING:
		var hp := str(ed.get(&"host_path", ""))
		var bp := str(ed.get(&"binding_property", ""))
		if not hp.is_empty():
			bb += "[b]Where to edit[/b]\nInspector on host [code]%s[/code], export [code]%s[/code].\n\n" % [hp, bp]
	elif kind == _SnapScript.EdgeKind.COMPUTED_SOURCE:
		var hp2 := str(ed.get(&"host_path", ""))
		var si := ed.get(&"computed_source_index", -1)
		bb += "[b]Where to edit[/b]\nComputed [code]sources[/code]"
		if int(si) >= 0:
			bb += " (index [code]%d[/code])" % int(si)
		bb += " on the owning host"
		if not hp2.is_empty():
			bb += " [code]%s[/code]" % hp2
		bb += ".\n\n"
	elif kind == _SnapScript.EdgeKind.WIRE_FLOW:
		var wh := str(ed.get(&"wire_host_path", ""))
		var wi := int(ed.get(&"wire_rule_index", -1))
		bb += "[b]Where to edit[/b]\n"
		if not wh.is_empty():
			bb += "Host [code]%s[/code], [code]wire_rules[/code]" % wh
			if wi >= 0:
				bb += " row [code]%d[/code]" % wi
			bb += ".\n\n"

	bb += "[b]Technical[/b]\nKind token: [code]%s[/code]\nFrom id: [code]%s[/code]\nTo id: [code]%s[/code]\n" % [token, from_id, to_id]

	var plain := "What this is\n%s edge (declarative).\n\n" % kname
	plain += "From %s → to %s\nDetail: %s\n\n" % [_short_label_for_node_id(from_id), _short_label_for_node_id(to_id), label]
	if kind == _SnapScript.EdgeKind.BINDING:
		var hp := str(ed.get(&"host_path", ""))
		var bp := str(ed.get(&"binding_property", ""))
		if not hp.is_empty():
			plain += "Where to edit — Host %s, export %s.\n\n" % [hp, bp]
	elif kind == _SnapScript.EdgeKind.WIRE_FLOW:
		var wh := str(ed.get(&"wire_host_path", ""))
		var wi := int(ed.get(&"wire_rule_index", -1))
		if not wh.is_empty():
			plain += "Where to edit — Host %s, wire_rules row %d.\n\n" % [wh, wi]

	plain += "Technical — %s\nFrom: %s\nTo: %s\n" % [token, from_id, to_id]

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

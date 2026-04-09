## Editor dock tab: declarative dependency explain graph ([code]CB-018A[/code]) + visual graph ([code]CB-018A.1[/code], [code]CB-018A.2[/code]).
class_name UiReactDockExplainPanel
extends MarginContainer

const _ExplainBuilderScript := preload("res://addons/ui_react/editor_plugin/services/ui_react_explain_graph_builder.gd")
const _ExplainLayoutScript := preload("res://addons/ui_react/editor_plugin/services/ui_react_explain_graph_layout.gd")
const _ExplainGraphViewScript := preload("res://addons/ui_react/editor_plugin/dock/ui_react_explain_graph_view.gd")
const _SnapScript := preload("res://addons/ui_react/editor_plugin/models/ui_react_explain_graph_snapshot.gd")

const MODE_TEXT := 0
const MODE_VISUAL := 1

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
var _cb_bind: CheckBox
var _cb_computed: CheckBox
var _cb_wire: CheckBox
var _cb_edge_labels: CheckBox
var _graph_view: Control
var _breadcrumb: Label
var _details_scroll: ScrollContainer
var _details: RichTextLabel

var _mode: int = MODE_TEXT
var _last_snap: Variant = null
var _last_focus_id: String = ""
var _last_layout: Dictionary = {}


func setup(plugin: EditorPlugin) -> void:
	_plugin = plugin
	_build_ui()


func refresh() -> void:
	if _body == null:
		return
	_set_idle()
	if _plugin == null:
		_set_hint("Plugin not ready.")
		_clear_stale_snapshot()
		return
	var ei := _plugin.get_editor_interface()
	var root := ei.get_edited_scene_root()
	if root == null:
		_set_hint("Open a scene to run Explain graph.")
		_clear_stale_snapshot()
		return
	var sel: Array[Node] = ei.get_selection().get_selected_nodes()
	if sel.size() != 1:
		_set_hint("Select exactly one [code]UiReact*[/code] node in the edited scene.")
		_clear_stale_snapshot()
		return
	var n: Node = sel[0]
	if not (n is Control):
		_set_hint("Selection must be a [code]Control[/code] ([code]UiReact*[/code]).")
		_clear_stale_snapshot()
		return
	if not UiReactScannerService.is_react_node(n):
		_set_hint("Selection is not a [code]UiReact*[/code] host (no ui_react_* script stem).")
		_clear_stale_snapshot()
		return
	if not (n == root or root.is_ancestor_of(n)):
		_set_hint("Selection must be part of the current edited scene.")
		_clear_stale_snapshot()
		return

	_set_hint("Focus: [code]%s[/code]  (%s)" % [n.name, str(root.get_path_to(n))])
	var snap = _ExplainBuilderScript.build(root, n as Control)
	_last_snap = snap
	var hp: NodePath = _ExplainBuilderScript._host_path_from_root(root, n as Control)
	_last_focus_id = _ExplainBuilderScript._control_id(hp)

	_render_text_report(snap)
	_apply_visual_from_snap_safe(snap, _last_focus_id)
	_apply_mode_visibility()


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
		_details.text = "[i]No nodes in scope for visual layout. Use Text mode for full report.[/i]"
		_set_breadcrumb("Selection: none")
		return
	(_graph_view as Object).call(&"set_layout", layout)
	_push_visual_filters()
	_details.text = "[i]Click a node or edge in the graph.[/i]"
	_set_breadcrumb("Selection: none")


func _push_visual_filters() -> void:
	if _graph_view == null:
		return
	var b := _cb_bind == null or _cb_bind.button_pressed
	var c := _cb_computed == null or _cb_computed.button_pressed
	var w := _cb_wire == null or _cb_wire.button_pressed
	var lbl := _cb_edge_labels != null and _cb_edge_labels.button_pressed
	(_graph_view as Object).call(&"set_edge_filters", b, c, w, lbl)


func _set_breadcrumb(t: String) -> void:
	if _breadcrumb:
		_breadcrumb.text = t


func _apply_mode_visibility() -> void:
	if _stack == null:
		return
	_stack.current_tab = 0 if _mode == MODE_TEXT else 1
	if _visual_toolbar:
		_visual_toolbar.visible = _mode == MODE_VISUAL
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
	var sl := _short_label_for_node_id(id)
	_set_breadcrumb("Selection: Node > %s" % sl)
	_fill_node_details(id)


func _on_graph_edge(from_id: String, to_id: String, kind: int, label: String) -> void:
	var token := _edge_short_token(kind)
	_set_breadcrumb("Selection: Edge > %s" % token)
	var kname := "?"
	match kind:
		_SnapScript.EdgeKind.BINDING:
			kname = "BINDING"
		_SnapScript.EdgeKind.COMPUTED_SOURCE:
			kname = "COMPUTED_SOURCE"
		_SnapScript.EdgeKind.WIRE_FLOW:
			kname = "WIRE_FLOW"
	_details.text = (
		"[b]Edge[/b]\n"
		+ "Kind: [code]%s[/code]\n" % kname
		+ "Short: [code]%s[/code]\n" % token
		+ "Label: [code]%s[/code]\n" % label
		+ "From: [code]%s[/code]\n" % from_id
		+ "To: [code]%s[/code]\n" % to_id
	)


func _edge_short_token(kind: int) -> String:
	match kind:
		_SnapScript.EdgeKind.BINDING:
			return "bind"
		_SnapScript.EdgeKind.COMPUTED_SOURCE:
			return "computed"
		_SnapScript.EdgeKind.WIRE_FLOW:
			return "wire"
	return "edge"


func _on_graph_cleared() -> void:
	_details.text = "[i]Click a node or edge in the graph.[/i]"
	_set_breadcrumb("Selection: none")


func _short_label_for_node_id(node_id: String) -> String:
	var nb: Dictionary = _last_layout.get(&"node_by_id", {}) as Dictionary
	var d: Dictionary = nb.get(node_id, {}) as Dictionary
	if d.is_empty():
		return node_id
	return str(d.get(&"short_label", d.get(&"label", node_id)))


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
	if d.is_empty():
		_details.text = "[code]%s[/code]\nIn degree: %d  Out degree: %d" % [node_id, deg_in, deg_out]
		return
	var nk := int(d.get(&"kind", 0))
	var kn := "CONTROL"
	if nk == _SnapScript.NodeKind.UI_STATE:
		kn = "UI_STATE"
	elif nk == _SnapScript.NodeKind.UI_COMPUTED:
		kn = "UI_COMPUTED"
	_details.text = (
		"[b]Node[/b]\n"
		+ "Kind: [code]%s[/code]\n" % kn
		+ "Short label: [code]%s[/code]\n" % str(d.get(&"short_label", ""))
		+ "Full label: %s\n" % str(d.get(&"label", ""))
		+ "Id: [code]%s[/code]\n" % node_id
		+ "Degree: in %d / out %d\n" % [deg_in, deg_out]
	)


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
	v.add_child(_hint)

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(row)

	_btn_refresh = Button.new()
	_btn_refresh.text = "Refresh explain"
	_btn_refresh.tooltip_text = "Rebuild the explain graph from the current selection and edited scene."
	_btn_refresh.pressed.connect(refresh)
	row.add_child(_btn_refresh)

	_mode_option = OptionButton.new()
	_mode_option.add_item("Text", MODE_TEXT)
	_mode_option.add_item("Visual", MODE_VISUAL)
	_mode_option.tooltip_text = "Text: full BBCode report. Visual: scoped node graph (read-only)."
	_mode_option.item_selected.connect(_on_mode_changed)
	row.add_child(_mode_option)

	_btn_fit = Button.new()
	_btn_fit.text = "Fit view"
	_btn_fit.tooltip_text = "Reset pan/zoom on the visual graph."
	_btn_fit.pressed.connect(_on_fit_pressed)
	row.add_child(_btn_fit)

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
	_cb_bind.tooltip_text = "Toggle binding edges (state/control property binds)."
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
	_cb_edge_labels.tooltip_text = "Show short edge tokens on all edges (busy). Hover/selection always shows detail in the pane."
	_cb_edge_labels.toggled.connect(func(_on4: bool) -> void: _push_visual_filters())
	_visual_toolbar.add_child(_cb_edge_labels)

	_graph_view = _ExplainGraphViewScript.new()
	_graph_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_graph_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_graph_view.custom_minimum_size = Vector2(280, 200)
	_graph_view.node_selected.connect(_on_graph_node)
	_graph_view.edge_selected.connect(_on_graph_edge)
	_graph_view.selection_cleared.connect(_on_graph_cleared)
	_visual_host.add_child(_graph_view)

	_breadcrumb = Label.new()
	_breadcrumb.text = "Selection: none"
	_breadcrumb.add_theme_font_size_override(&"font_size", 12)
	_breadcrumb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_breadcrumb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_visual_host.add_child(_breadcrumb)

	_details_scroll = ScrollContainer.new()
	_details_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_details_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_details_scroll.custom_minimum_size = Vector2(0, 120)
	_details_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_details_scroll.tooltip_text = "Details for the selected node or edge."
	_visual_host.add_child(_details_scroll)

	_details = RichTextLabel.new()
	_details.bbcode_enabled = true
	_details.scroll_active = false
	_details.fit_content = true
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_details.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_details.text = "[i]Click a node or edge in the graph.[/i]"
	_details_scroll.add_child(_details)

	_mode = MODE_TEXT
	_mode_option.select(_mode_option.get_item_index(MODE_TEXT))
	_stack.current_tab = MODE_TEXT
	_apply_mode_visibility()


func _clear_stale_snapshot() -> void:
	_last_snap = null
	_last_layout.clear()
	_last_focus_id = ""
	_set_breadcrumb("Selection: none")
	if _graph_view:
		_graph_view.clear_graph()


func _set_hint(t: String) -> void:
	if _hint:
		_hint.text = "[font_size=12]%s[/font_size]" % t


func _set_idle() -> void:
	if _body:
		_body.clear()

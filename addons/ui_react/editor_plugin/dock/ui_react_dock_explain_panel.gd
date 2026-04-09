## Editor dock tab: declarative dependency explain graph ([code]CB-018A[/code]).
class_name UiReactDockExplainPanel
extends MarginContainer

const _ExplainBuilderScript := preload("res://addons/ui_react/editor_plugin/services/ui_react_explain_graph_builder.gd")

var _plugin: EditorPlugin

var _hint: RichTextLabel
var _btn_refresh: Button
var _body: RichTextLabel


func setup(plugin: EditorPlugin) -> void:
	_plugin = plugin
	_build_ui()


func refresh() -> void:
	if _body == null:
		return
	_set_idle()
	if _plugin == null:
		_set_hint("Plugin not ready.")
		return
	var ei := _plugin.get_editor_interface()
	var root := ei.get_edited_scene_root()
	if root == null:
		_set_hint("Open a scene to run Explain graph.")
		return
	var sel: Array[Node] = ei.get_selection().get_selected_nodes()
	if sel.size() != 1:
		_set_hint("Select exactly one [code]UiReact*[/code] node in the edited scene.")
		return
	var n: Node = sel[0]
	if not (n is Control):
		_set_hint("Selection must be a [code]Control[/code] ([code]UiReact*[/code]).")
		return
	if not UiReactScannerService.is_react_node(n):
		_set_hint("Selection is not a [code]UiReact*[/code] host (no ui_react_* script stem).")
		return
	if not (n == root or root.is_ancestor_of(n)):
		_set_hint("Selection must be part of the current edited scene.")
		return

	_set_hint("Focus: [code]%s[/code]  (%s)" % [n.name, str(root.get_path_to(n))])
	var snap = _ExplainBuilderScript.build(root, n as Control)
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
	bbf += "[/font_size]"
	_body.text = bbf


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

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 200)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)

	_body = RichTextLabel.new()
	_body.bbcode_enabled = true
	_body.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.scroll_active = false
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.fit_content = true
	_body.custom_minimum_size = Vector2(400, 0)
	scroll.add_child(_body)


func _set_hint(t: String) -> void:
	if _hint:
		_hint.text = "[font_size=12]%s[/font_size]" % t


func _set_idle() -> void:
	if _body:
		_body.clear()

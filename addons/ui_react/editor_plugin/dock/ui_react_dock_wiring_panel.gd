extends MarginContainer
class_name UiReactDockWiringPanel

const _ExplainPanelScript := preload("res://addons/ui_react/editor_plugin/dock/ui_react_dock_explain_panel.gd")
const _WireRulesPanelScript := preload("res://addons/ui_react/editor_plugin/dock/ui_react_dock_wire_rules_panel.gd")

var _plugin: EditorPlugin
var _actions: UiReactActionController

## [UiReactDockExplainPanel]
var _explain: Variant = null
## [UiReactDockWireRulesPanel]
var _wire_rules: Variant = null


func setup(plugin: EditorPlugin, actions: UiReactActionController, request_dock_refresh: Callable = Callable()) -> void:
	_plugin = plugin
	_actions = actions
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_theme_constant_override(&"margin_left", 0)
	add_theme_constant_override(&"margin_right", 0)
	add_theme_constant_override(&"margin_top", 0)
	add_theme_constant_override(&"margin_bottom", 0)

	var hsplit := HSplitContainer.new()
	hsplit.set_anchors_preset(Control.PRESET_FULL_RECT)
	hsplit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hsplit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hsplit.add_theme_constant_override(&"autohide", 0)
	hsplit.add_theme_constant_override(&"minimum_grab_thickness", 10)
	if _plugin:
		UiReactDockTheme.apply_split_bar(hsplit, _plugin)
	hsplit.tooltip_text = "Drag to resize the dependency graph and wire rules list."
	add_child(hsplit)

	var ex = _ExplainPanelScript.new()
	ex.callv(
		&"setup",
		[_plugin, _actions, request_dock_refresh, func(idx: int) -> void: _focus_wire_rule_row(idx)]
	)
	_explain = ex
	ex.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ex.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hsplit.add_child(ex)

	var wr = _WireRulesPanelScript.new()
	wr.setup(_plugin, _actions)
	_wire_rules = wr
	wr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wr.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hsplit.add_child(wr)

	hsplit.split_offset = 0


func _focus_wire_rule_row(idx: int) -> void:
	if _wire_rules != null and _wire_rules.has_method(&"focus_rule_index"):
		_wire_rules.call(&"focus_rule_index", idx)


func refresh() -> void:
	if _explain != null and _explain.has_method(&"refresh"):
		_explain.call(&"refresh")
	if _wire_rules != null and _wire_rules.has_method(&"refresh"):
		_wire_rules.call(&"refresh")

extends MarginContainer
class_name UiReactDockWiringPanel

const _ExplainPanelScript := preload("res://addons/ui_react/editor_plugin/dock/ui_react_dock_explain_panel.gd")

var _plugin: EditorPlugin
var _actions: UiReactActionController

## [UiReactDockExplainPanel]
var _explain: Variant = null


func setup(plugin: EditorPlugin, actions: UiReactActionController, request_dock_refresh: Callable = Callable()) -> void:
	_plugin = plugin
	_actions = actions
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_theme_constant_override(&"margin_left", 0)
	add_theme_constant_override(&"margin_right", 0)
	add_theme_constant_override(&"margin_top", 0)
	add_theme_constant_override(&"margin_bottom", 0)

	var ex = _ExplainPanelScript.new()
	ex.callv(&"setup", [_plugin, _actions, request_dock_refresh])
	_explain = ex
	ex.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ex.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(ex)


func refresh() -> void:
	if _explain != null and _explain.has_method(&"refresh"):
		_explain.call(&"refresh")

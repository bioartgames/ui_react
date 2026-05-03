extends MarginContainer
class_name UiReactDockWiringPanel

const _ExplainPanelScript := preload("res://addons/ui_react/editor_plugin/dock/ui_react_dock_explain_panel.gd")

var _plugin: EditorPlugin
var _actions: UiReactActionController

var _cb_runtime_trace: CheckBox

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

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var toolbar := HBoxContainer.new()
	toolbar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(toolbar)

	var cb_trace := CheckBox.new()
	cb_trace.text = "Print runtime trace to Output (debug builds only)"
	cb_trace.tooltip_text = "Trace wire, computed, and action rows to Output in debug builds; persists per project and applies on the next run."
	cb_trace.button_pressed = bool(
		ProjectSettings.get_setting(UiReactDockConfig.KEY_RUNTIME_CONSOLE_DEBUG_ENABLED, false)
	)
	cb_trace.toggled.connect(_on_runtime_console_trace_toggled)
	toolbar.add_child(cb_trace)
	_cb_runtime_trace = cb_trace

	var ex := _ExplainPanelScript.new()
	ex.callv(&"setup", [_plugin, _actions, request_dock_refresh])
	_explain = ex
	ex.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ex.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(ex)

	add_child(root)


func _on_runtime_console_trace_toggled(toggled_on: bool) -> void:
	UiReactDockConfig.save_ui_preference(
		UiReactDockConfig.KEY_RUNTIME_CONSOLE_DEBUG_ENABLED, toggled_on
	)


func refresh() -> void:
	if _explain != null and _explain.has_method(&"refresh"):
		_explain.call(&"refresh")


func capture_session_for_persist() -> void:
	if _explain != null and _explain.has_method(&"capture_wiring_session_for_persist"):
		_explain.call(&"capture_wiring_session_for_persist")


func restore_session_from_settings() -> bool:
	var got := false
	if _explain != null and _explain.has_method(&"restore_wiring_session_from_project_settings"):
		got = (_explain.call(&"restore_wiring_session_from_project_settings") as bool)
	if _cb_runtime_trace != null:
		_cb_runtime_trace.button_pressed = bool(
			ProjectSettings.get_setting(UiReactDockConfig.KEY_RUNTIME_CONSOLE_DEBUG_ENABLED, false)
		)
	return got

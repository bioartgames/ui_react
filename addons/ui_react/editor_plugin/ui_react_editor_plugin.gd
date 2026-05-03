@tool
extends EditorPlugin

const _DOCK_SCENE_PATH := "res://addons/ui_react/editor_plugin/dock/ui_react_dock.tscn"
const _BottomShortcut := preload(
	"res://addons/ui_react/editor_plugin/services/ui_react_editor_bottom_panel_shortcut.gd"
)

var _dock: Control
var _bottom_panel_tab_button: Button = null
var _open_diagnostics_shortcut: Variant = null
var _open_wiring_shortcut: Variant = null
static var _shortcut_property_info_registered_global: bool = false


func _enter_tree() -> void:
	UiReactDockConfig.migrate_project_settings_to_v2_clean_break()
	UiReactDockConfig.register_default_project_settings()
	var dock_scene := load(_DOCK_SCENE_PATH) as PackedScene
	if dock_scene == null:
		push_error(
			"Ui React: dock scene is missing at %s. Restore the addon files or reinstall ui_react from the repo." % _DOCK_SCENE_PATH
		)
		return
	_dock = dock_scene.instantiate() as Control
	_dock.setup(self)
	_dock.set_plugin_owner(self)
	_register_project_settings_property_info_v2()
	_register_bottom_panel_tab()
	_reload_action_shortcuts()
	if not ProjectSettings.settings_changed.is_connected(_on_project_settings_changed):
		ProjectSettings.settings_changed.connect(_on_project_settings_changed)
	set_process_input(true)
	scene_changed.connect(_on_editor_scene_changed)


func _exit_tree() -> void:
	if ProjectSettings.settings_changed.is_connected(_on_project_settings_changed):
		ProjectSettings.settings_changed.disconnect(_on_project_settings_changed)
	if scene_changed.is_connected(_on_editor_scene_changed):
		scene_changed.disconnect(_on_editor_scene_changed)
	if _dock:
		remove_control_from_bottom_panel(_dock)
		_dock.queue_free()
		_dock = null
	_bottom_panel_tab_button = null


func _register_project_settings_property_info_v2() -> void:
	if _shortcut_property_info_registered_global:
		return
	_shortcut_property_info_registered_global = true
	# Dock/plugin keys stay internal (advanced-only). Runtime live debug (**CB-018C**) is user-facing:
	# visible under Project Settings → `ui_react`, searchable as “live debug”.
	for key in [
		UiReactDockConfig.KEY_SCAN_MODE,
		UiReactDockConfig.KEY_GROUP_MODE,
		UiReactDockConfig.KEY_SHOW_ERRORS,
		UiReactDockConfig.KEY_SHOW_WARNINGS,
		UiReactDockConfig.KEY_SHOW_INFO,
		UiReactDockConfig.KEY_AUTO_REFRESH,
		UiReactDockConfig.KEY_STATE_OUTPUT_PATH,
		UiReactDockConfig.KEY_GRAPH_LEGEND_VISIBLE,
		UiReactDockConfig.KEY_SETTINGS_SCHEMA_VERSION,
		UiReactDockConfig.KEY_IGNORED_UNUSED_STATE_PATHS,
		UiReactDockConfig.KEY_OPEN_DIAGNOSTICS_SHORTCUT_JSON,
		UiReactDockConfig.KEY_OPEN_WIRING_SHORTCUT_JSON,
	]:
		ProjectSettings.set_as_internal(key, true)

	ProjectSettings.set_as_internal(UiReactDockConfig.KEY_RUNTIME_LIVE_DEBUG_ENABLED, false)
	ProjectSettings.set_as_internal(UiReactDockConfig.KEY_RUNTIME_LIVE_DEBUG_BUFFER_CAP, false)
	ProjectSettings.add_property_info(
		{
			"name": UiReactDockConfig.KEY_RUNTIME_LIVE_DEBUG_ENABLED,
			"type": TYPE_BOOL,
		}
	)
	ProjectSettings.add_property_info(
		{
			"name": UiReactDockConfig.KEY_RUNTIME_LIVE_DEBUG_BUFFER_CAP,
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "%d,%d,1"
			% [
				UiReactDockConfig.LIVE_DEBUG_BUFFER_CAP_MIN,
				UiReactDockConfig.LIVE_DEBUG_BUFFER_CAP_MAX,
			],
		}
	)


func _register_bottom_panel_tab() -> void:
	if _dock == null:
		return
	if _bottom_panel_tab_button != null:
		remove_control_from_bottom_panel(_dock)
		_bottom_panel_tab_button = null

	_bottom_panel_tab_button = add_control_to_bottom_panel(_dock, "Ui React", null)
	if _bottom_panel_tab_button:
		_bottom_panel_tab_button.shortcut_in_tooltip = false


func _on_project_settings_changed() -> void:
	_reload_action_shortcuts()


func _get_window_layout(configuration: ConfigFile) -> void:
	if _dock and _dock.has_method(&"capture_session_for_layout_persist"):
		_dock.call(&"capture_session_for_layout_persist")
	var state: Dictionary = UiReactDockConfig.export_session_state()
	for k in state.keys():
		configuration.set_value("UiReactDock", String(k), state[k])


func _set_window_layout(configuration: ConfigFile) -> void:
	var out: Dictionary = {
		UiReactDockConfig.SESSION_LAST_TAB: configuration.get_value(
			"UiReactDock", UiReactDockConfig.SESSION_LAST_TAB, UiReactDockConfig.DEF_DOCK_LAST_TAB
		),
		UiReactDockConfig.SESSION_WIRING_LAST_SCENE_PATH: configuration.get_value(
			"UiReactDock", UiReactDockConfig.SESSION_WIRING_LAST_SCENE_PATH, ""
		),
		UiReactDockConfig.SESSION_WIRING_LAST_SCOPE_NODE_PATH: configuration.get_value(
			"UiReactDock", UiReactDockConfig.SESSION_WIRING_LAST_SCOPE_NODE_PATH, ""
		),
		UiReactDockConfig.SESSION_WIRING_LAST_GRAPH_NODE_ID: configuration.get_value(
			"UiReactDock", UiReactDockConfig.SESSION_WIRING_LAST_GRAPH_NODE_ID, ""
		),
		UiReactDockConfig.SESSION_GRAPH_BODY_VSPLIT_OFFSET: configuration.get_value(
			"UiReactDock", UiReactDockConfig.SESSION_GRAPH_BODY_VSPLIT_OFFSET, -1
		),
		UiReactDockConfig.SESSION_GRAPH_SCOPE_PRESETS_JSON: configuration.get_value(
			"UiReactDock", UiReactDockConfig.SESSION_GRAPH_SCOPE_PRESETS_JSON, "[]"
		),
		UiReactDockConfig.SESSION_GRAPH_ACTIVE_SCOPE_PRESET_NAME: configuration.get_value(
			"UiReactDock", UiReactDockConfig.SESSION_GRAPH_ACTIVE_SCOPE_PRESET_NAME, ""
		),
	}
	UiReactDockConfig.import_session_state(out)


func _on_editor_scene_changed(_scene_root: Node) -> void:
	if _dock and _dock.has_method(&"notify_edited_scene_changed"):
		_dock.notify_edited_scene_changed()


func _reload_action_shortcuts() -> void:
	var diagnostics_raw := UiReactDockConfig.get_open_diagnostics_shortcut_json()
	var wiring_raw := UiReactDockConfig.get_open_wiring_shortcut_json()
	_open_diagnostics_shortcut = _BottomShortcut.open_shortcut_from_json_string(
		diagnostics_raw, _BottomShortcut.default_open_diagnostics_spec()
	)
	_open_wiring_shortcut = _BottomShortcut.open_shortcut_from_json_string(
		wiring_raw, _BottomShortcut.default_open_wiring_spec()
	)
	_refresh_bottom_tab_tooltip()


func _refresh_bottom_tab_tooltip() -> void:
	if _bottom_panel_tab_button == null:
		return
	_bottom_panel_tab_button.tooltip_text = _BottomShortcut.format_bottom_panel_tab_tooltip(
		_open_diagnostics_shortcut, _open_wiring_shortcut
	)


func _input(event: InputEvent) -> void:
	if event is not InputEventKey:
		return
	var ek := event as InputEventKey
	if not ek.pressed or ek.echo:
		return
	var diagnostics_hit := _event_matches_shortcut(event, _open_diagnostics_shortcut)
	if diagnostics_hit:
		_open_and_focus_tab(UiReactDock.TAB_DIAGNOSTICS)
		get_viewport().set_input_as_handled()
		return
	var wiring_hit := _event_matches_shortcut(event, _open_wiring_shortcut)
	if wiring_hit:
		_open_and_focus_tab(UiReactDock.TAB_WIRING)
		get_viewport().set_input_as_handled()


func _event_matches_shortcut(event: InputEvent, shortcut: Variant) -> bool:
	if shortcut == null or shortcut is not Shortcut:
		return false
	var sc := shortcut as Shortcut
	if sc.events.is_empty():
		return false
	return sc.matches_event(event)


func _should_dismiss_bottom_panel_for_tab(tab_idx: int) -> bool:
	if _bottom_panel_tab_button == null:
		return false
	if not _bottom_panel_tab_button.button_pressed:
		return false
	if _dock == null or not _dock.has_method(&"get_current_editor_tab"):
		return false
	return int(_dock.call(&"get_current_editor_tab")) == tab_idx


func _open_and_focus_tab(tab_idx: int) -> void:
	if _should_dismiss_bottom_panel_for_tab(tab_idx):
		hide_bottom_panel()
		return
	if _bottom_panel_tab_button:
		_bottom_panel_tab_button.button_pressed = true
	if _dock == null:
		return
	if tab_idx == UiReactDock.TAB_DIAGNOSTICS and _dock.has_method(&"open_and_focus_diagnostics"):
		_dock.call(&"open_and_focus_diagnostics")
	elif tab_idx == UiReactDock.TAB_WIRING and _dock.has_method(&"open_and_focus_wiring"):
		_dock.call(&"open_and_focus_wiring")

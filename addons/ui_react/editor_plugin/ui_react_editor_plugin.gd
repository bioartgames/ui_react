@tool
extends EditorPlugin

const _DOCK_SCENE_PATH := "res://addons/ui_react/editor_plugin/dock/ui_react_dock.tscn"
const _BottomShortcut := preload(
	"res://addons/ui_react/editor_plugin/services/ui_react_editor_bottom_panel_shortcut.gd"
)

var _dock: Control
var _bottom_panel_tab_button: Button = null
var _bottom_panel_shortcut_json_applied: String = ""
var _bottom_panel_register_queued: bool = false
static var _shortcut_property_info_registered_global: bool = false


func _enter_tree() -> void:
	var dock_scene := load(_DOCK_SCENE_PATH) as PackedScene
	if dock_scene == null:
		push_error(
			"Ui React: dock scene is missing at %s. Restore the addon files or reinstall ui_react from the repo." % _DOCK_SCENE_PATH
		)
		return
	_dock = dock_scene.instantiate() as Control
	_dock.setup(self)
	_ensure_shortcut_property_info()
	_register_bottom_panel_tab()
	if not ProjectSettings.settings_changed.is_connected(_on_project_settings_changed):
		ProjectSettings.settings_changed.connect(_on_project_settings_changed)
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
	_bottom_panel_shortcut_json_applied = ""


func _ensure_shortcut_property_info() -> void:
	if _shortcut_property_info_registered_global:
		return
	_shortcut_property_info_registered_global = true
	ProjectSettings.add_property_info(
		{
			"name": UiReactDockConfig.KEY_EDITOR_BOTTOM_PANEL_SHORTCUT_JSON,
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_MULTILINE_TEXT,
			"hint_string": (
				"Ui React bottom panel shortcut (JSON). Schema v1: "
				+ '{"v":1,"enabled":true,"keycode":85,"alt":true,"shift":false,"ctrl":false,"meta":false} '
				+ "(85 = KEY_U). Use enabled:false or {} to disable. Invalid JSON falls back to Alt+U."
			),
		}
	)


func _register_bottom_panel_tab() -> void:
	if _dock == null:
		return
	var raw := String(
		ProjectSettings.get_setting(UiReactDockConfig.KEY_EDITOR_BOTTOM_PANEL_SHORTCUT_JSON, "")
	)
	if _bottom_panel_tab_button != null:
		remove_control_from_bottom_panel(_dock)
		_bottom_panel_tab_button = null

	var sc_variant: Variant = _BottomShortcut.shortcut_from_json_string(raw)

	_bottom_panel_tab_button = add_control_to_bottom_panel(_dock, "Ui React", sc_variant)
	if _bottom_panel_tab_button:
		# We render one complete tooltip line ourselves (avoid engine-added shortcut header/newline).
		_bottom_panel_tab_button.shortcut_in_tooltip = false
		_bottom_panel_tab_button.tooltip_text = _BottomShortcut.format_tab_tooltip(sc_variant)
	_bottom_panel_shortcut_json_applied = raw


func _on_project_settings_changed() -> void:
	if _bottom_panel_register_queued:
		return
	var raw := String(
		ProjectSettings.get_setting(UiReactDockConfig.KEY_EDITOR_BOTTOM_PANEL_SHORTCUT_JSON, "")
	)
	if raw == _bottom_panel_shortcut_json_applied:
		return
	_bottom_panel_register_queued = true
	call_deferred(&"_deferred_reregister_bottom_panel_tab")


func _deferred_reregister_bottom_panel_tab() -> void:
	_bottom_panel_register_queued = false
	_register_bottom_panel_tab()


func _on_editor_scene_changed(_scene_root: Node) -> void:
	if _dock and _dock.has_method(&"notify_edited_scene_changed"):
		_dock.notify_edited_scene_changed()

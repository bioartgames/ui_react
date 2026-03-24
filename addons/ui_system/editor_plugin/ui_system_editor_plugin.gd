@tool
extends EditorPlugin

const _DOCK_SCENE_PATH := "res://addons/ui_system/editor_plugin/ui_system_dock.tscn"

var _dock: Control
var _bottom_panel_button: Button


func _enter_tree() -> void:
	var dock_scene := load(_DOCK_SCENE_PATH) as PackedScene
	if dock_scene == null:
		push_error("UI System Tools: missing dock scene at %s" % _DOCK_SCENE_PATH)
		return
	_dock = dock_scene.instantiate() as Control
	_dock.setup(self)
	_bottom_panel_button = add_control_to_bottom_panel(_dock, "UI System Tools")


func _exit_tree() -> void:
	if _dock:
		remove_control_from_bottom_panel(_dock)
		_dock.queue_free()
		_dock = null
		_bottom_panel_button = null

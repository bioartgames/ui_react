@tool
extends EditorPlugin

const _DOCK_SCENE_PATH := "res://addons/ui_react/editor_plugin/dock/ui_react_dock.tscn"

var _dock: Control


func _enter_tree() -> void:
	var dock_scene := load(_DOCK_SCENE_PATH) as PackedScene
	if dock_scene == null:
		push_error(
			"Ui React: dock scene is missing at %s. Restore the addon files or reinstall ui_react from the repo." % _DOCK_SCENE_PATH
		)
		return
	_dock = dock_scene.instantiate() as Control
	_dock.setup(self)
	add_control_to_bottom_panel(_dock, "Ui React")
	scene_changed.connect(_on_editor_scene_changed)


func _exit_tree() -> void:
	if scene_changed.is_connected(_on_editor_scene_changed):
		scene_changed.disconnect(_on_editor_scene_changed)
	if _dock:
		remove_control_from_bottom_panel(_dock)
		_dock.queue_free()
		_dock = null


func _on_editor_scene_changed(_scene_root: Node) -> void:
	if _dock and _dock.has_method(&"notify_edited_scene_changed"):
		_dock.notify_edited_scene_changed()

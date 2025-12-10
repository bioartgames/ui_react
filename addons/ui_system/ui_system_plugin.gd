## Main editor plugin for Reactive UI System.
## Registers custom inspector plugins for enhanced designer workflow.
@tool
extends EditorPlugin

## Inspector plugins to register.
var _inspector_plugins: Array[EditorInspectorPlugin] = []

func _enter_tree() -> void:
	# Register inspector plugins
	_add_inspector_plugin(load("res://ui_system/editor/inspector_plugins/reactive_value_picker.gd").new())
	_add_inspector_plugin(load("res://ui_system/editor/inspector_plugins/binding_editor.gd").new())
	_add_inspector_plugin(load("res://ui_system/editor/inspector_plugins/action_configurator.gd").new())
	_add_inspector_plugin(load("res://ui_system/editor/inspector_plugins/text_builder_editor.gd").new())
	_add_inspector_plugin(load("res://ui_system/editor/inspector_plugins/animation_editor.gd").new())
	_add_inspector_plugin(load("res://ui_system/editor/inspector_plugins/navigation_group_editor.gd").new())

func _exit_tree() -> void:
	# Remove all inspector plugins
	for plugin in _inspector_plugins:
		remove_inspector_plugin(plugin)
	_inspector_plugins.clear()
	
	# Clear ControlInspector cache
	ControlInspector.clear_cache()

## Adds an inspector plugin and registers it.
func _add_inspector_plugin(plugin: EditorInspectorPlugin) -> void:
	add_inspector_plugin(plugin)
	_inspector_plugins.append(plugin)


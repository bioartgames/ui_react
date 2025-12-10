## Custom inspector plugin for action configuration.
## Provides visual interface with validation warnings.
@tool
extends EditorInspectorPlugin

func _can_handle(object: Variant) -> bool:
	return object is ReactiveActionBinding

func _parse_property(object: Variant, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: PropertyUsageFlags, wide: bool) -> bool:
	# Add custom editor for validation warnings
	if name == "action" or name == "target":
		var editor = ActionConfiguratorEditor.new()
		editor.setup(name)
		add_property_editor(name, editor)
		return true
	return false

## Custom property editor for action configuration.
class ActionConfiguratorEditor:
	extends EditorProperty
	
	var _action_binding: ReactiveActionBinding = null
	var _container: VBoxContainer
	var _warning_label: Label
	var _property_name: String = ""
	
	func setup(property_name: String) -> void:
		_property_name = property_name
	
	func _init() -> void:
		_container = VBoxContainer.new()
		add_child(_container)
		
		_warning_label = Label.new()
		_warning_label.add_theme_color_override("font_color", Color.YELLOW)
		_warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_container.add_child(_warning_label)
	
	func _update_property() -> void:
		_action_binding = get_edited_object() as ReactiveActionBinding
		if _action_binding == null:
			return
		
		_update_validation_warnings()
	
	func _update_validation_warnings() -> void:
		if _action_binding == null:
			return
		
		var warnings: Array[String] = []
		
		# Check if action is set
		if _action_binding.action == null:
			warnings.append("No action assigned")
		
		# Check if target is set (unless it's an ActionGroup)
		if _action_binding.target == null and not (_action_binding.action is ActionGroup):
			warnings.append("No target ReactiveValue assigned")
		
		# Check if params match action type
		if _action_binding.action != null and _action_binding.params != null:
			# Basic validation - can be enhanced
			pass
		
		if warnings.is_empty():
			_warning_label.text = ""
			_warning_label.visible = false
		else:
			_warning_label.text = "Warning: " + ", ".join(warnings)
			_warning_label.visible = true


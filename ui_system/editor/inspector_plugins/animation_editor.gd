## Custom inspector plugin for animation configuration.
## Provides step-by-step animation builder with preview.
@tool
extends EditorInspectorPlugin

func _can_handle(object: Variant) -> bool:
	return object is ReactiveAnimation

func _parse_property(object: Variant, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: PropertyUsageFlags, wide: bool) -> bool:
	if name == "steps":
		# Use custom editor for steps array
		var editor = AnimationEditor.new()
		editor.setup(name)
		add_property_editor(name, editor)
		return true
	return false

## Custom property editor for animation steps.
class AnimationEditor:
	extends EditorProperty
	
	var _animation: ReactiveAnimation = null
	var _container: VBoxContainer
	var _info_label: Label
	var _property_name: String = ""
	
	func setup(property_name: String) -> void:
		_property_name = property_name
	
	func _init() -> void:
		_container = VBoxContainer.new()
		add_child(_container)
		
		_info_label = Label.new()
		_info_label.add_theme_color_override("font_color", Color.CYAN)
		_container.add_child(_info_label)
	
	func _update_property() -> void:
		_animation = get_edited_object() as ReactiveAnimation
		if _animation == null:
			return
		
		_update_info()
	
	func _update_info() -> void:
		if _animation == null:
			_info_label.text = ""
			return
		
		var step_count = _animation.steps.size()
		var total_duration = 0.0
		for step in _animation.steps:
			if step != null:
				total_duration += step.duration + step.delay
		
		_info_label.text = "Steps: %d | Total Duration: %.2fs" % [step_count, total_duration]


## Custom inspector plugin for text builder configuration.
## Provides visual segment builder with live preview.
@tool
extends EditorInspectorPlugin

func _can_handle(object: Variant) -> bool:
	return object is TextBuilder

func _parse_property(object: Variant, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: PropertyUsageFlags, wide: bool) -> bool:
	if name == "segments":
		# Use custom editor for segments array
		var editor = TextBuilderEditor.new()
		editor.setup(name)
		add_property_editor(name, editor)
		return true
	return false

## Custom property editor for text builder segments.
class TextBuilderEditor:
	extends EditorProperty
	
	var _text_builder: TextBuilder = null
	var _container: VBoxContainer
	var _preview_label: Label
	var _property_name: String = ""
	
	func setup(property_name: String) -> void:
		_property_name = property_name
	
	func _init() -> void:
		_container = VBoxContainer.new()
		add_child(_container)
		
		var preview_container = HBoxContainer.new()
		_container.add_child(preview_container)
		
		var preview_title = Label.new()
		preview_title.text = "Preview: "
		preview_container.add_child(preview_title)
		
		_preview_label = Label.new()
		_preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_preview_label.add_theme_color_override("font_color", Color.CYAN)
		preview_container.add_child(_preview_label)
	
	func _update_property() -> void:
		_text_builder = get_edited_object() as TextBuilder
		if _text_builder == null:
			return
		
		_update_preview()
	
	func _update_preview() -> void:
		if _text_builder == null:
			_preview_label.text = ""
			return
		
		# Build preview text
		var preview_text = _text_builder.build()
		_preview_label.text = preview_text if not preview_text.is_empty() else "(empty)"


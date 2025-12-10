## Custom inspector plugin for navigation group selection.
## Provides dropdown for selecting navigation groups.
@tool
extends EditorInspectorPlugin

func _can_handle(object: Variant) -> bool:
	return object is ReactiveControl

func _parse_property(object: Variant, _type: Variant.Type, name: String, _hint_type: PropertyHint, _hint_string: String, _usage_flags: PropertyUsageFlags, _wide: bool) -> bool:
	if name == "navigation_group":
		var editor = NavigationGroupEditor.new()
		editor.setup(name, object as ReactiveControl)
		add_property_editor(name, editor)
		return true
	return false

## Custom property editor for navigation group dropdown.
class NavigationGroupEditor:
	extends EditorProperty
	
	var _control: ReactiveControl = null
	var _picker: OptionButton
	var _property_name: String = ""
	
	func setup(property_name: String, control: ReactiveControl) -> void:
		_property_name = property_name
		_control = control
	
	func _init() -> void:
		_picker = OptionButton.new()
		_picker.add_item("(None)")
		add_child(_picker)
		add_focusable(_picker)
		_picker.item_selected.connect(_on_item_selected)
		_refresh_groups()
	
	func _refresh_groups() -> void:
		_picker.clear()
		_picker.add_item("(None)")
		
		# Get navigation groups from ReactiveNavigation singleton
		var nav = _get_navigation_singleton()
		if nav == null:
			return
		
		# Get registered group names
		var group_names = nav.get_group_names()
		for group_name in group_names:
			_picker.add_item(group_name)
		
		# Select current group if set
		if _control != null and not _control.navigation_group.is_empty():
			for i in range(1, _picker.get_item_count()):
				if _picker.get_item_text(i) == _control.navigation_group:
					_picker.selected = i
					break
	
	func _get_navigation_singleton() -> ReactiveNavigation:
		# Try to get from autoload
		if Engine.has_singleton("ReactiveNavigation"):
			return Engine.get_singleton("ReactiveNavigation") as ReactiveNavigation
		
		# Try to find in edited scene
		var edited_scene = EditorInterface.get_edited_scene_root()
		if edited_scene != null:
			return edited_scene.find_child("ReactiveNavigation", true, false) as ReactiveNavigation
		
		return null
	
	func _update_property() -> void:
		_control = get_edited_object() as ReactiveControl
		if _control == null:
			return
		_refresh_groups()
	
	func _on_item_selected(index: int) -> void:
		if index == 0:
			emit_changed(_property_name, "")
		else:
			var selected_group = _picker.get_item_text(index)
			emit_changed(_property_name, selected_group)


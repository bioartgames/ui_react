## Custom inspector plugin for ReactiveValue resource picker.
## Provides filtered dropdown by type and shows current value.
@tool
extends EditorInspectorPlugin

func _can_handle(object: Variant) -> bool:
	# Handle ReactiveValue properties
	if object is Resource:
		var property_list = object.get_property_list()
		for prop in property_list:
			if prop["type"] == TYPE_OBJECT and prop.has("class_name"):
				var class_type = prop["class_name"] as String
				if class_type == "ReactiveValue":
					return true
	return false

func _parse_property(object: Variant, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: PropertyUsageFlags, wide: bool) -> bool:
	# Check if this is a ReactiveValue property
	if type == TYPE_OBJECT:
		var property_info = object.get_property_list()
		for prop in property_info:
			if prop["name"] == name and prop.has("class_name"):
				var class_type = prop["class_name"] as String
				if class_type == "ReactiveValue":
					var editor = ReactiveValuePickerEditor.new()
					editor.setup(name)
					add_property_editor(name, editor)
					return true
	return false

## Custom property editor for ReactiveValue picker.
class ReactiveValuePickerEditor:
	extends EditorProperty
	
	var _picker: OptionButton
	var _current_value: ReactiveValue = null
	var _all_resources: Array[Resource] = []
	var _property_name: String = ""
	
	func setup(property_name: String) -> void:
		_property_name = property_name
	
	func _init() -> void:
		_picker = OptionButton.new()
		_picker.add_item("(None)")
		_picker.selected = 0
		add_child(_picker)
		add_focusable(_picker)
		_picker.item_selected.connect(_on_item_selected)
		_refresh_resources()
	
	func _refresh_resources() -> void:
		_picker.clear()
		_picker.add_item("(None)")
		_all_resources.clear()
		
		# Use ReactiveUtils helper if available, otherwise use DirAccess
		var resource_paths = ReactiveUtils.find_all_reactive_values()
		if not resource_paths.is_empty():
			for path in resource_paths:
				var resource = load(path)
				if resource is ReactiveValue:
					_all_resources.append(resource)
					var display_name = path.get_file().get_basename()
					if resource.has_method("_get_value"):
						var value = resource.value
						if value != null:
							display_name += " (" + str(value) + ")"
					_picker.add_item(display_name)
		else:
			# Fallback: use DirAccess
			var dir = DirAccess.open("res://")
			if dir != null:
				_collect_resources_recursive(dir, "res://")
	
	func _collect_resources_recursive(dir: DirAccess, path: String) -> void:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			var full_path = path + "/" + file_name if path != "res://" else "res://" + file_name
			
			if dir.current_is_dir():
				if file_name != "." and file_name != "..":
					var sub_dir = DirAccess.open(full_path)
					if sub_dir != null:
						_collect_resources_recursive(sub_dir, full_path)
			else:
				if file_name.ends_with(".tres") or file_name.ends_with(".res"):
					var resource = load(full_path)
					if resource is ReactiveValue:
						_all_resources.append(resource)
						var display_name = file_name.get_basename()
						if resource.has_method("_get_value"):
							var value = resource.value
							if value != null:
								display_name += " (" + str(value) + ")"
						_picker.add_item(display_name)
			
			file_name = dir.get_next()
	
	func _update_property() -> void:
		var edited_object = get_edited_object()
		if edited_object == null:
			return
		
		var new_value = edited_object.get(_property_name)
		if new_value != _current_value:
			_current_value = new_value as ReactiveValue
			_update_picker_selection()
	
	func _update_picker_selection() -> void:
		if _current_value == null:
			_picker.selected = 0
			return
		
		# Find matching resource
		for i in range(_all_resources.size()):
			if _all_resources[i] == _current_value:
				_picker.selected = i + 1  # +1 for "(None)" option
				return
		
		_picker.selected = 0
	
	func _on_item_selected(index: int) -> void:
		if index == 0:
			emit_changed(_property_name, null)
		else:
			var selected_resource = _all_resources[index - 1]
			emit_changed(_property_name, selected_resource)


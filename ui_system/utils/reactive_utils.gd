## Utility functions for reactive UI system.
## Common helper functions used across the system.
class_name ReactiveUtils
extends RefCounted

## Gets a logger instance for ReactiveUI system.
## Uses Godot 4.5's Logger API.
static func get_logger() -> Logger:
	# Try to get logger using Godot 4.5 API
	# Note: Logging API may not be available in all versions
	# For now, return null - logger functionality can be added when API is confirmed
	# In Godot 4.5, you would use: Logging.get_logger("ReactiveUI")
	return null

## Formats a value for display in editor/debug.
## Returns a string representation suitable for UI display.
static func format_value_for_display(value: Variant) -> String:
	if value == null:
		return "(null)"
	
	if value is String:
		return '"' + value + '"'
	elif value is bool:
		return "true" if value else "false"
	elif value is int or value is float:
		return str(value)
	elif value is Vector2:
		return "Vector2(%s, %s)" % [value.x, value.y]
	elif value is Vector3:
		return "Vector3(%s, %s, %s)" % [value.x, value.y, value.z]
	elif value is Color:
		return "Color(%s, %s, %s, %s)" % [value.r, value.g, value.b, value.a]
	elif value is Resource:
		return value.resource_path if value.resource_path else value.get_class()
	else:
		return str(value)

## Gets a human-readable name for a ReactiveValue type.
static func get_reactive_value_type_name(reactive_value: ReactiveValue) -> String:
	if reactive_value == null:
		return "None"
	
	var class_type = reactive_value.get_class()
	match class_type:
		"ReactiveString":
			return "String"
		"ReactiveInt":
			return "Int"
		"ReactiveFloat":
			return "Float"
		"ReactiveBool":
			return "Bool"
		"ReactiveArray":
			return "Array"
		"ReactiveObject":
			return "Object"
		"ReactiveReference":
			return "Reference"
		_:
			return class_type

## Checks if a value type is compatible with a ReactiveValue type.
static func is_type_compatible(reactive_value: ReactiveValue, value_type: Variant.Type) -> bool:
	if reactive_value == null:
		return false
	
	var reactive_type_name = get_reactive_value_type_name(reactive_value)
	
	match reactive_type_name:
		"String":
			return value_type == TYPE_STRING
		"Int":
			return value_type == TYPE_INT
		"Float":
			return value_type == TYPE_FLOAT
		"Bool":
			return value_type == TYPE_BOOL
		"Array":
			return value_type == TYPE_ARRAY
		"Object":
			return value_type == TYPE_DICTIONARY
		_:
			return false

## Gets all ReactiveValue resources in the project.
## Returns an array of Resource paths.
static func find_all_reactive_values() -> Array[String]:
	var resources: Array[String] = []
	var dir = DirAccess.open("res://")
	if dir == null:
		return resources
	
	_collect_resources_recursive(dir, "res://", resources)
	return resources

## Recursively collects ReactiveValue resources.
static func _collect_resources_recursive(dir: DirAccess, path: String, resources: Array[String]) -> void:
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		var full_path = path + "/" + file_name if path != "res://" else "res://" + file_name
		
		if dir.current_is_dir():
			if file_name != "." and file_name != "..":
				var sub_dir = DirAccess.open(full_path)
				if sub_dir != null:
					_collect_resources_recursive(sub_dir, full_path, resources)
		else:
			if file_name.ends_with(".tres") or file_name.ends_with(".res"):
				var resource = load(full_path)
				if resource is ReactiveValue:
					resources.append(full_path)
		
		file_name = dir.get_next()


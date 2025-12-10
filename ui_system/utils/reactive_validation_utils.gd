## Static utility class for shared validation patterns.
## Common validation logic used by Value Validation, Binding Validation, and Action Validation.
class_name ReactiveValidationUtils

## Checks if a type is compatible with another type (allowing Variant flexibility).
static func is_type_compatible(value_type: Variant.Type, target_type: Variant.Type) -> bool:
	# Same type is always compatible
	if value_type == target_type:
		return true
	
	# Variant accepts anything (TYPE_NIL means untyped/any)
	if target_type == TYPE_NIL:
		return true
	
	# Numeric types are compatible with each other
	if value_type in [TYPE_INT, TYPE_FLOAT] and target_type in [TYPE_INT, TYPE_FLOAT]:
		return true
	
	# String can be converted to most types
	if value_type == TYPE_STRING:
		return true
	
	# Bool can be converted to int/float
	if value_type == TYPE_BOOL and target_type in [TYPE_INT, TYPE_FLOAT]:
		return true
	
	return false

## Validates that a node path exists in the scene tree.
static func validate_node_path(owner: Node, path: NodePath) -> bool:
	if path == null or path.is_empty():
		return false
	
	var target = owner.get_node_or_null(path)
	return target != null

## Gets the type of a property on an object.
static func get_property_type(obj: Object, property_name: String) -> Variant.Type:
	if obj == null:
		return TYPE_NIL
	
	var property_list = obj.get_property_list()
	for prop in property_list:
		if prop.name == property_name:
			return prop.type as Variant.Type
	
	return TYPE_NIL

## Checks if a signal exists on an object.
static func check_has_signal(obj: Object, signal_name: StringName) -> bool:
	if obj == null:
		return false
	
	return obj.has_signal(signal_name)


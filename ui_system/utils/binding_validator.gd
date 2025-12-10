## Binding validation utility.
## Validates binding configuration and sets binding status.
class_name BindingValidator

## Validates a binding and returns its status.
static func validate_binding(owner: Control, binding: ReactiveBinding) -> BindingStatus.Status:
	if binding.reactive_value == null:
		return BindingStatus.Status.DISCONNECTED
	
	# Determine target control
	var target_path = binding.control_path
	if target_path == null or target_path.is_empty():
		target_path = NodePath(".")
	
	var target = owner.get_node_or_null(target_path)
	if target == null:
		return BindingStatus.Status.ERROR_INVALID_PATH
	
	# Validate property exists
	if not target.has_method("get") and not (target is Object and target.get_script() != null):
		# Try to get property type
		var prop_type = ReactiveValidationUtils.get_property_type(target, binding.control_property)
		if prop_type == TYPE_NIL:
			return BindingStatus.Status.ERROR_INVALID_PROPERTY
	
	# For TWO_WAY binding, validate signal exists
	if binding.mode == ReactiveBinding.BindingMode.TWO_WAY:
		if binding.control_signal.is_empty():
			return BindingStatus.Status.ERROR_INVALID_SIGNAL
		
		if not ReactiveValidationUtils.check_has_signal(target, binding.control_signal as StringName):
			return BindingStatus.Status.ERROR_INVALID_SIGNAL
	
	# Validate type compatibility (if converter not provided)
	if binding.value_converter == null:
		# Get reactive value type (approximate)
		var reactive_type = _get_reactive_value_type(binding.reactive_value)
		var property_type = ReactiveValidationUtils.get_property_type(target, binding.control_property)
		
		if property_type != TYPE_NIL and not ReactiveValidationUtils.is_type_compatible(reactive_type, property_type):
			return BindingStatus.Status.ERROR_TYPE_MISMATCH
	
	return BindingStatus.Status.CONNECTED

## Gets the approximate type of a ReactiveValue.
static func _get_reactive_value_type(reactive_value: ReactiveValue) -> Variant.Type:
	if reactive_value is ReactiveString:
		return TYPE_STRING
	elif reactive_value is ReactiveInt:
		return TYPE_INT
	elif reactive_value is ReactiveFloat:
		return TYPE_FLOAT
	elif reactive_value is ReactiveBool:
		return TYPE_BOOL
	else:
		# Return TYPE_NIL for unknown types (will be treated as compatible)
		return TYPE_NIL


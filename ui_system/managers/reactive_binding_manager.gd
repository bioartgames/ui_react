## Binding system manager (RefCounted).
## Handles all binding logic, signal connections, validation, and cleanup.
class_name ReactiveBindingManager
extends RefCounted

## The owner Control that this manager manages bindings for.
var _owner: Control = null

## Array of bindings to manage.
var _bindings: Array[ReactiveBinding] = []

## Signal connections tracked for cleanup.
var _signal_connections: Array[SignalConnection] = []

## Flag to prevent circular updates when updating from reactive value.
var _updating_from_reactive: bool = false

## Flag to prevent circular updates when updating from control.
var _updating_from_control: bool = false

## Sets up the binding manager with owner and bindings.
func setup(owner: Control, bindings: Array[ReactiveBinding]) -> void:
	_owner = owner
	_bindings = bindings
	
	# Validate and connect all bindings
	for binding in _bindings:
		if binding == null:
			continue
		
		# Validate binding
		binding.status = BindingValidator.validate_binding(_owner, binding)
		
		if binding.status == BindingStatus.Status.CONNECTED:
			_connect_binding(binding)
	
	# Sync initial values after all bindings are connected
	sync_initial_values()

## Syncs initial values from ReactiveValues to Control properties.
func sync_initial_values() -> void:
	for binding in _bindings:
		if binding == null or binding.status != BindingStatus.Status.CONNECTED:
			continue
		
		if binding.reactive_value == null:
			continue
		
		_update_control_from_reactive(binding)

## Connects a binding based on its mode.
func _connect_binding(binding: ReactiveBinding) -> void:
	if binding.reactive_value == null:
		return
	
	# Always connect reactive value changed signal (for ONE_WAY and TWO_WAY)
	var callable_reactive = Callable(self, "_on_reactive_value_changed").bind(binding)
	binding.reactive_value.value_changed.connect(callable_reactive)
	_signal_connections.append(SignalConnection.create(binding.reactive_value.value_changed, callable_reactive))
	
	# For TWO_WAY, also connect control signal
	if binding.mode == ReactiveBinding.BindingMode.TWO_WAY:
		var target = _get_target_control(binding)
		if target != null and not binding.control_signal.is_empty():
			if target.has_signal(binding.control_signal):
				var callable_control = Callable(self, "_on_control_signal").bind(binding)
				target.connect(binding.control_signal, callable_control)
				_signal_connections.append(SignalConnection.create_from_node(target, binding.control_signal, callable_control))

## Gets the target control for a binding.
func _get_target_control(binding: ReactiveBinding) -> Control:
	var target_path = binding.control_path
	if target_path == null or target_path.is_empty() or target_path == NodePath("."):
		return _owner
	
	return _owner.get_node_or_null(target_path) as Control

## Called when reactive value changes.
func _on_reactive_value_changed(_new_value: Variant, _old_value: Variant, binding: ReactiveBinding) -> void:
	# Prevent circular updates
	if _updating_from_control:
		return
	
	_updating_from_reactive = true
	_update_control_from_reactive(binding)
	_updating_from_reactive = false

## Updates control property from reactive value.
func _update_control_from_reactive(binding: ReactiveBinding) -> void:
	if binding.reactive_value == null:
		return
	
	var target = _get_target_control(binding)
	if target == null:
		return
	
	var value = binding.reactive_value.value
	
	# Apply converter if present
	if binding.value_converter != null:
		value = binding.value_converter.convert(value)
	
	# Set the property using set_indexed for nested properties (e.g., "modulate:a")
	target.set_indexed(binding.control_property, value)

## Called when control signal fires (TWO_WAY only).
func _on_control_signal(binding: ReactiveBinding) -> void:
	# Prevent circular updates
	if _updating_from_reactive:
		return
	
	_updating_from_control = true
	_update_reactive_from_control(binding)
	_updating_from_control = false

## Updates reactive value from control property.
func _update_reactive_from_control(binding: ReactiveBinding) -> void:
	if binding.reactive_value == null:
		return
	
	var target = _get_target_control(binding)
	if target == null:
		return
	
	# Get the property value using get_indexed for nested properties
	var value = target.get_indexed(binding.control_property)
	
	# Note: Converters are typically one-way. For TWO_WAY bindings,
	# converters should be bidirectional or omitted to avoid data loss.
	# If a converter is provided, we skip reverse conversion for now.
	
	# Set the reactive value
	binding.reactive_value.set_value(value)

## Cleans up all signal connections.
func cleanup() -> void:
	ReactiveLifecycleManager.cleanup_signal_connections(_signal_connections)
	_signal_connections.clear()
	_bindings.clear()
	_owner = null

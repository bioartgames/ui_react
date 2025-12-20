@tool
extends State
class_name ComputedState

@export_group("Computation")
## The function to call to compute the value.
## Set this to a Callable that takes no parameters and returns the computed value.
## Example: func(): return health.value / max_health.value * 100
@export var computation: Callable

@export_group("Dependencies")
## List of State objects that this computation depends on.
## When any dependency changes, the computation will be re-evaluated automatically.
@export var dependencies: Array[State] = []

## Internal fields
## Flag indicating if a recomputation is currently in progress (prevents infinite loops).
var _is_recomputing: bool = false
## Tracks whether dependencies have been connected and initial computation performed.
var _initialized: bool = false
## Maps dependency State objects to their value_changed signal connections.
var _dependency_connections: Dictionary = {}

## Static computation stack for circular dependency detection
static var _computation_stack: Array[ComputedState] = []
static var _max_computation_depth: int = 10

## Sets the computation function and dependencies for this computed state.
## This method should be called after creating the ComputedState, either in script
## or automatically when properties are set in the Inspector.
##
## [param compute_func]: The function to call for computation (signature: func() -> Variant).
## [param deps]: Array of State objects this computation depends on.
func set_computation(compute_func: Callable, deps: Array[State] = []) -> void:
	computation = compute_func
	dependencies = deps
	_reconnect_dependencies()
	_recompute()

## Reconnects to all dependency signals, disconnecting from old ones first.
func _reconnect_dependencies() -> void:
	# Validate dependencies first
	if not _validate_dependencies():
		return

	# Disconnect from old dependencies
	for dep in _dependency_connections.keys():
		if is_instance_valid(dep):
			var conn = _dependency_connections[dep]
			if dep.value_changed.is_connected(conn):
				dep.value_changed.disconnect(conn)
	_dependency_connections.clear()

	# Connect to new dependencies
	for dep in dependencies:
		if not is_instance_valid(dep):
			continue
		var callable = _on_dependency_changed.bind(dep)
		dep.value_changed.connect(callable)
		_dependency_connections[dep] = callable

	_initialized = true

## Handles changes to dependency states.
## [param dep]: The dependency State that changed (for logging/debugging).
func _on_dependency_changed(_new_value: Variant, _old_value: Variant, _dep: State) -> void:
	if _is_recomputing:
		return
	_recompute()

## Recomputes the value by calling the computation function.
func _recompute() -> void:
	# Check for circular dependencies
	if _computation_stack.has(self):
		push_error("ComputedState: Circular dependency detected! Computation chain: " + _format_computation_chain())
		return

	if _computation_stack.size() >= _max_computation_depth:
		push_error("ComputedState: Maximum computation depth reached. Possible circular dependency or excessive nesting.")
		return

	_computation_stack.append(self)

	if not computation.is_valid():
		# No computation function set - keep current value or set to null
		if not _initialized:
			value = null
			emit_changed()
		_computation_stack.pop_back()
		return

	if _is_recomputing:
		push_warning("ComputedState: Circular dependency detected or computation triggered during recomputation. Skipping.")
		_computation_stack.pop_back()
		return

	_is_recomputing = true

	var old_value = value
	var new_value: Variant

	# Attempt computation
	# Note: We already validated computation.is_valid() earlier, so we can safely call it
	new_value = computation.call()

	# Update value if changed (using parent's set_value to trigger signals)
	if new_value != old_value:
		# Manually update value and emit signal to maintain signal contract
		value = new_value
		emit_signal("value_changed", new_value, old_value)
		emit_changed()

	_is_recomputing = false
	_computation_stack.pop_back()

## Returns a human-readable description of the current computation chain for debugging.
func _format_computation_chain() -> String:
	var names: Array[String] = []
	for cs in _computation_stack:
		names.append(cs.resource_name if cs.resource_name else "Unnamed")
	names.append(self.resource_name if self.resource_name else "Unnamed")
	return " -> ".join(names)

## Override set_value to warn that manual changes will be overwritten.
func set_value(new_value: Variant) -> void:
	if _is_recomputing:
		# Allow internal updates during recomputation
		super.set_value(new_value)
		return

	push_warning("ComputedState: Manual set_value() call detected. This value will be overwritten when dependencies change. Consider modifying dependencies instead.")
	super.set_value(new_value)

func _ready() -> void:
	# In editor, validate configuration
	if Engine.is_editor_hint():
		_validate_configuration()
		return

	# At runtime, set up dependencies if not already done
	if not _initialized:
		# Wait for dependencies to be ready
		if not _all_dependencies_ready():
			# Defer initialization until next frame
			call_deferred("_initialize_if_ready")
			return

		_reconnect_dependencies()
		_recompute()

## Checks if all dependencies are ready for connection.
func _all_dependencies_ready() -> bool:
	for dep in dependencies:
		if not is_instance_valid(dep):
			return false
	return true

## Deferred initialization for when dependencies weren't ready in _ready.
func _initialize_if_ready() -> void:
	if _all_dependencies_ready() and not _initialized:
		_reconnect_dependencies()
		_recompute()

## Validates configuration in the editor.
func _validate_configuration() -> void:
	if dependencies.is_empty() and computation.is_valid():
		push_warning("ComputedState: Computation function is set but no dependencies are configured. Value will be computed once and never update.")
	elif not dependencies.is_empty() and not computation.is_valid():
		push_warning("ComputedState: Dependencies are set but no computation function is configured. Value will remain null.")

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		# Disconnect from all dependencies when the resource is about to be freed
		for dep in _dependency_connections.keys():
			if is_instance_valid(dep):
				var conn = _dependency_connections[dep]
				if dep.value_changed.is_connected(conn):
					dep.value_changed.disconnect(conn)
		_dependency_connections.clear()

## Creates a computed state that formats a string with values from dependency states.
## Example: create_formatted_string("Level {level} {class}", [level_state, class_state])
static func create_formatted_string(format: String, deps: Array[State]) -> ComputedState:
	var cs = ComputedState.new()
	var format_func = func() -> String:
		var args: Array = []
		for dep in deps:
			args.append(dep.value if dep else "")
		return format.format(args)
	cs.set_computation(format_func, deps)
	return cs

## Creates a computed state that performs a mathematical operation on dependencies.
## Example: create_math_operation([a, b], func(x, y): return x + y)
static func create_math_operation(deps: Array[State], op: Callable) -> ComputedState:
	var cs = ComputedState.new()
	var compute_func = func() -> Variant:
		var values: Array = []
		for dep in deps:
			values.append(dep.value if dep else 0)
		return op.callv(values)
	cs.set_computation(compute_func, deps)
	return cs

## Creates a computed state that calculates a percentage.
## Example: create_percentage(current_health, max_health)
static func create_percentage(numerator: State, denominator: State) -> ComputedState:
	var cs = ComputedState.new()
	var compute_func = func() -> float:
		if not is_instance_valid(denominator) or denominator.value == 0:
			return 0.0
		var num = numerator.value if is_instance_valid(numerator) else 0
		var den = denominator.value
		return (float(num) / float(den)) * 100.0
	cs.set_computation(compute_func, [numerator, denominator])
	return cs

## Returns a human-readable description of this computed state's configuration.
func get_debug_info() -> String:
	var info: Array[String] = []
	info.append("ComputedState: " + (resource_name if resource_name else "Unnamed"))
	info.append("  Computation: " + ("Valid" if computation.is_valid() else "Invalid/Not Set"))
	info.append("  Dependencies: " + str(dependencies.size()))
	for i in range(dependencies.size()):
		var dep = dependencies[i]
		if is_instance_valid(dep):
			info.append("    [%d] %s = %s" % [i, dep.resource_name if dep.resource_name else "Unnamed", str(dep.value)])
		else:
			info.append("    [%d] <invalid>" % i)
	info.append("  Current Value: " + str(value))
	info.append("  Initialized: " + str(_initialized))
	return "\n".join(info)

## Prints debug information to the console.
func print_debug_info() -> void:
	print(get_debug_info())

## Validates that all dependencies are valid State objects.
func _validate_dependencies() -> bool:
	var invalid_deps: Array = []
	for i in range(dependencies.size()):
		var dep = dependencies[i]
		if not is_instance_valid(dep):
			invalid_deps.append(i)
		elif not dep is State:
			invalid_deps.append(i)
			push_warning("ComputedState: Dependency at index %d is not a State object." % i)

	if not invalid_deps.is_empty():
		# Remove invalid dependencies
		for i in range(invalid_deps.size() - 1, -1, -1):
			dependencies.remove_at(invalid_deps[i])
		return false

	return true

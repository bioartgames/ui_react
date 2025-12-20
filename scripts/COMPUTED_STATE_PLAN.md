## ComputedState – Design & Implementation Plan

This document defines a **concrete, phased plan** for adding `ComputedState` support to the reactive UI system, enabling automatic derivation of values from multiple `State` dependencies.

The plan follows existing patterns used by `State`, reactive controls, and the animation/navigation systems.

---

## Phase 0 – Scope, Goals, and Constraints

### 0.1 Goals

- **Add** a `ComputedState` class that:
  - Extends or is compatible with `State` (reactive controls can bind to it seamlessly).
  - Automatically computes a value from one or more dependency `State` objects.
  - Recomputes automatically when any dependency changes.
  - Integrates with:
    - The **reactive state system** (works as a drop-in replacement for `State`).
    - All existing **reactive controls** (no changes needed to reactive controls).
    - The **animation system** (triggers `value_changed` like regular `State`).
  - Supports **editor configuration** (designers can set up computations in Inspector).
  - Prevents **circular dependencies** and handles **error cases** gracefully.

### 0.2 Non‑Goals

- **No runtime script evaluation**: Computation functions are defined via `Callable`, not as strings to be evaluated.
- **No automatic dependency detection**: Dependencies must be explicitly declared (no magic introspection).
- **No lazy evaluation optimization**: ComputedState always computes eagerly when dependencies change (no memoization beyond equality checks).
- **No async computation**: All computations are synchronous (no coroutines or await support).
- **No type safety enforcement**: Like `State`, `ComputedState` uses `Variant` for flexibility.

### 0.3 Design Principles

- **Liskov Substitution Principle**: `ComputedState` should be usable anywhere `State` is expected.
- **Single Responsibility**: `ComputedState` only handles computation and dependency tracking; reactive controls remain unchanged.
- **Open/Closed Principle**: Existing reactive controls don't need modification to support `ComputedState`.
- **Dependency Inversion**: Reactive controls depend on the `State` interface (signals), not concrete implementations.

### 0.4 Files and Types to Introduce

The following new scripts/resources will be introduced:

- **Computed state resource**:
  - `scripts/reactive/computed_state.gd`
    - `extends State`
    - `class_name ComputedState`
    - Handles dependency tracking, computation, and automatic updates.

No changes to existing reactive controls are required; `ComputedState` extends `State` and maintains the same interface.

---

## Phase 1 – Core ComputedState Implementation

**Objective**: Implement the core `ComputedState` class that extends `State` and handles dependency tracking and automatic recomputation.

### 1.1 `ComputedState` Class Structure

Create `ComputedState` as an extension of `State`:

- File: `scripts/reactive/computed_state.gd`
- Base:

```gdscript
extends State
class_name ComputedState
```

### 1.2 Core Properties

Exported properties for Inspector configuration:

- `@export var computation: Callable`
  - The function to call to compute the value.
  - Must be a `Callable` (can be set in Inspector or via script).
  - Signature: `func() -> Variant` (no parameters, returns computed value).
- `@export var dependencies: Array[State] = []`
  - List of `State` objects that this computed state depends on.
  - When any dependency's `value_changed` signal fires, recomputation is triggered.
  - Can be empty (computed state will have a static value until dependencies are set).

Internal fields:

- `var _is_recomputing: bool = false`
  - Prevents infinite loops if computation triggers dependency changes.
- `var _dependency_connections: Dictionary = {}`
  - Maps dependency `State` objects to their `value_changed` signal connections.
  - Used for cleanup when dependencies change.
- `var _initialized: bool = false`
  - Tracks whether dependencies have been connected and initial computation performed.

### 1.3 Core Methods

**Initialization and setup**:

```gdscript
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
func _on_dependency_changed(_new_value: Variant, _old_value: Variant, dep: State) -> void:
	if _is_recomputing:
		return
	_recompute()

## Recomputes the value by calling the computation function.
func _recompute() -> void:
	if not computation.is_valid():
		# No computation function set - keep current value or set to null
		if not _initialized:
			value = null
			emit_changed()
		return
	
	if _is_recomputing:
		push_warning("ComputedState: Circular dependency detected or computation triggered during recomputation. Skipping.")
		return
	
	_is_recomputing = true
	
	var old_value = value
	var new_value: Variant
	
	# Call computation function with error handling
	if computation.get_bound_object() == null and computation.get_method() == "":
		push_warning("ComputedState: Invalid computation Callable. Value will remain unchanged.")
		_is_recomputing = false
		return
	
	# Attempt computation
	# Note: GDScript doesn't have try-catch, so we rely on the computation function
	# being well-behaved. If it throws, the error will propagate up.
	new_value = computation.call()
	
	# Update value if changed (using parent's set_value to trigger signals)
	if new_value != old_value:
		# Use set_silent to avoid triggering value_changed during recomputation,
		# then manually emit to maintain signal contract
		var temp = value
		value = new_value
		emit_signal("value_changed", new_value, old_value)
		emit_changed()
	
	_is_recomputing = false
```

**Editor support**:

```gdscript
func _ready() -> void:
	# In editor, validate configuration
	if Engine.is_editor_hint():
		_validate_configuration()
		return
	
	# At runtime, set up dependencies if not already done
	if not _initialized:
		_reconnect_dependencies()
		_recompute()

## Validates configuration in the editor.
func _validate_configuration() -> void:
	if dependencies.is_empty() and computation.is_valid():
		push_warning("ComputedState: Computation function is set but no dependencies are configured. Value will be computed once and never update.")
	elif not dependencies.is_empty() and not computation.is_valid():
		push_warning("ComputedState: Dependencies are set but no computation function is configured. Value will remain null.")
```

**Cleanup**:

```gdscript
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		# Disconnect from all dependencies when the resource is about to be freed
		for dep in _dependency_connections.keys():
			if is_instance_valid(dep):
				var conn = _dependency_connections[dep]
				if dep.value_changed.is_connected(conn):
					dep.value_changed.disconnect(conn)
		_dependency_connections.clear()
```

**Note**: Resources in Godot use `_notification(NOTIFICATION_PREDELETE)` for cleanup, not `_exit_tree()` (which is for Nodes).

### 1.4 Integration with State

`ComputedState` extends `State`, so it inherits:
- `value: Variant` property
- `value_changed(new_value, old_value)` signal
- `set_value(new_value)` method (should be used with caution - see Phase 2)
- `set_silent(new_value)` method

**Important**: `ComputedState` should override `set_value()` to warn users that manually setting a computed value will be overwritten on the next dependency change:

```gdscript
## Override set_value to warn that manual changes will be overwritten.
func set_value(new_value: Variant) -> void:
	if _is_recomputing:
		# Allow internal updates during recomputation
		super.set_value(new_value)
		return
	
	push_warning("ComputedState: Manual set_value() call detected. This value will be overwritten when dependencies change. Consider modifying dependencies instead.")
	super.set_value(new_value)
```

---

## Phase 2 – Advanced Features & Safety

**Objective**: Add circular dependency detection, error handling, and edge case management.

### 2.1 Circular Dependency Detection

Implement detection to prevent infinite loops:

```gdscript
var _computation_stack: Array[ComputedState] = []
var _max_computation_depth: int = 10

func _recompute() -> void:
	# Check for circular dependencies
	if _computation_stack.has(self):
		push_error("ComputedState: Circular dependency detected! Computation chain: " + _format_computation_chain())
		return
	
	if _computation_stack.size() >= _max_computation_depth:
		push_error("ComputedState: Maximum computation depth reached. Possible circular dependency or excessive nesting.")
		return
	
	_computation_stack.append(self)
	
	# ... existing recomputation logic ...
	
	_computation_stack.pop_back()

func _format_computation_chain() -> String:
	var names: Array[String] = []
	for cs in _computation_stack:
		names.append(cs.resource_name if cs.resource_name else "Unnamed")
	names.append(self.resource_name if self.resource_name else "Unnamed")
	return " -> ".join(names)
```

**Note**: This requires a static/global computation stack or passing it through the call chain. For simplicity in v1, we can use a simpler approach with `_is_recomputing` flag and depth tracking.

### 2.2 Dependency Validation

Add validation to ensure dependencies are valid:

```gdscript
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
```

### 2.3 Error Handling in Computation

**Note**: GDScript doesn't have try-catch exception handling. Computation functions should be written to handle errors internally and return valid values. If a computation function throws an error or returns an invalid value, it will propagate up and may cause issues.

For robust error handling, computation functions should validate their inputs:

```gdscript
# Example: Safe percentage computation
var safe_percentage_func = func() -> float:
	if not is_instance_valid(denominator) or denominator.value == 0:
		return 0.0  # Return safe default instead of throwing
	var num = numerator.value if is_instance_valid(numerator) else 0
	var den = denominator.value
	return (float(num) / float(den)) * 100.0
```

The `_recompute()` method already validates that the computation Callable is valid before calling it. Additional error handling can be added in Phase 2 if needed, but for v1, we rely on well-behaved computation functions.

### 2.4 Initialization Order Handling

Ensure `ComputedState` handles initialization correctly when dependencies aren't ready:

```gdscript
func _ready() -> void:
	if Engine.is_editor_hint():
		_validate_configuration()
		return
	
	# Wait for dependencies to be ready
	if not _all_dependencies_ready():
		# Defer initialization until next frame
		call_deferred("_initialize_if_ready")
		return
	
	_reconnect_dependencies()
	_recompute()

func _all_dependencies_ready() -> bool:
	for dep in dependencies:
		if not is_instance_valid(dep):
			return false
	return true

func _initialize_if_ready() -> void:
	if _all_dependencies_ready() and not _initialized:
		_reconnect_dependencies()
		_recompute()
```

---

## Phase 3 – Editor Integration & Usability

**Objective**: Make `ComputedState` easy to configure in the Godot Inspector and provide helpful tooling.

### 3.1 Inspector Property Hints

Add property hints to make the Inspector more user-friendly:

```gdscript
@export_group("Computation")
## The function to call to compute the value.
## Set this to a Callable that takes no parameters and returns the computed value.
## Example: func(): return health.value / max_health.value * 100
@export var computation: Callable

@export_group("Dependencies")
## List of State objects that this computation depends on.
## When any dependency changes, the computation will be re-evaluated automatically.
@export var dependencies: Array[State] = []
```

**Note**: Godot's Inspector has limited support for `Callable` editing. For v1, we'll rely on script-based setup or provide a helper method. Future phases could add a custom property editor.

### 3.2 Helper Methods for Common Patterns

Add convenience methods for common computation patterns:

```gdscript
## Creates a computed state that formats a string with values from dependency states.
## Example: format_string("Level {level} {class}", [level_state, class_state])
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
```

### 3.3 Debug Visualization

Add methods to help debug computation chains:

```gdscript
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
```

---

## Phase 4 – Testing & Verification

**Objective**: Verify correctness, edge cases, and integration with reactive controls.

### 4.1 Test Scenes

Create test scenes to verify functionality:

1. **ComputedStateBasic.tscn**
   - Simple computed state: `health_percentage = (current_health / max_health) * 100`
   - Two `State` resources for dependencies
   - `ReactiveLabel` bound to the `ComputedState`
   - Verify label updates when dependencies change

2. **ComputedStateChained.tscn**
   - Chain of computed states: `base_damage` → `modified_damage` → `final_damage`
   - Verify changes propagate through the chain correctly

3. **ComputedStateMultipleDeps.tscn**
   - Computed state with 3+ dependencies
   - Example: `status_text = "Level {level} {class} - {health}/{max_health} HP"`
   - Verify all dependencies trigger recomputation

4. **ComputedStateCircular.tscn**
   - Attempt to create circular dependencies
   - Verify error handling and prevention

5. **ComputedStateReactiveControls.tscn**
   - Test `ComputedState` with various reactive controls:
     - `ReactiveLabel` (text binding)
     - `ReactiveProgressBar` (value binding)
     - `ReactiveButton` (disabled_state binding)
   - Verify all controls work seamlessly

### 4.2 Edge Cases to Test

Explicitly test:

- **Empty dependencies**: Computed state with no dependencies (static value)
- **Null dependencies**: Dependencies array contains `null` entries
- **Invalid computation**: Computation function returns `Error` or throws
- **Dependency changes during computation**: Dependency changes while recomputing
- **Rapid dependency changes**: Multiple dependencies change in the same frame
- **Resource lifecycle**: Computed state freed before/after dependencies
- **Editor vs Runtime**: Behavior differences in editor vs running game

### 4.3 Integration Tests

Verify integration with existing systems:

- **Animation system**: `ComputedState` triggers `VALUE_CHANGED` animations correctly
- **Navigation system**: `ComputedState` can be used in `NavigationStateBundle` (if applicable)
- **State persistence**: `ComputedState` serializes/deserializes correctly in scenes

---

## Phase 5 – Documentation & Examples

**Objective**: Provide clear documentation and practical examples for users.

### 5.1 Documentation File

Create `docs/COMPUTED_STATE.md` with:

- Quick start guide
- Common use cases with code examples
- Best practices
- Troubleshooting guide
- API reference

### 5.2 Example Use Cases

Document common patterns:

1. **Health Percentage**
   ```gdscript
   var health_pct = ComputedState.create_percentage(current_health, max_health)
   reactive_label.text_state = health_pct
   ```

2. **Formatted Status Text**
   ```gdscript
   var status = ComputedState.create_formatted_string(
       "Level {0} {1}",
       [level_state, class_state]
   )
   ```

3. **Conditional UI State**
   ```gdscript
   var can_afford = ComputedState.new()
   can_afford.set_computation(
       func(): return gold.value >= item_cost.value,
       [gold, item_cost]
   )
   reactive_button.disabled_state = can_afford  # Inverted logic needed
   ```

4. **Mathematical Operations**
   ```gdscript
   var total_weight = ComputedState.create_math_operation(
       item_weights,
       func(weights: Array) -> float:
           var sum = 0.0
           for w in weights:
               sum += float(w)
           return sum
   )
   ```

### 5.3 Migration Guide

If users have existing manual computation code, provide guidance on migrating to `ComputedState`.

---

## Phase 6 – Future Extensions (Non-blocking)

The design should allow, but does not initially implement:

1. **Custom Inspector Editor**: Visual editor for setting up computations in the Inspector
2. **Memoization**: Cache computation results when dependencies haven't changed
3. **Async Computation**: Support for async/await in computation functions
4. **Dependency Auto-Detection**: Automatically detect dependencies from computation function (requires reflection/analysis)
5. **ComputedState Groups**: Batch update multiple computed states together
6. **Computation Profiling**: Debug tools to identify slow computations

These can be added in later phases without breaking the initial API if the above plan is followed.

---

## Implementation Notes

### Design Decisions

1. **Extends State**: `ComputedState` extends `State` rather than being a separate class to ensure Liskov Substitution and seamless integration.

2. **Explicit Dependencies**: Dependencies must be explicitly declared rather than auto-detected for clarity and performance.

3. **Eager Computation**: Values are computed immediately when dependencies change, not lazily. This ensures UI is always up-to-date.

4. **Callable-based**: Computation uses `Callable` rather than string evaluation for type safety and performance.

5. **No Breaking Changes**: Existing reactive controls require no modifications, maintaining backward compatibility.

### SOLID Principles

- **Single Responsibility**: `ComputedState` only handles computation; reactive controls handle UI binding.
- **Open/Closed**: Reactive controls are open for extension (via `ComputedState`) but closed for modification.
- **Liskov Substitution**: `ComputedState` can be used anywhere `State` is expected.
- **Interface Segregation**: `ComputedState` maintains the same interface as `State` (no additional methods required by consumers).
- **Dependency Inversion**: Reactive controls depend on the `State` interface (signals), not concrete implementations.

### DRY Principles

- Reuses existing `State` infrastructure (signals, value storage)
- Reuses existing reactive control patterns (no new binding logic needed)
- Helper methods reduce code duplication for common patterns

---

This plan provides a complete, phased approach to adding `ComputedState` support while maintaining consistency with existing patterns and design principles.


## Shared helpers for reactive [UiState] <-> control synchronization.
class_name UiReactStateBindingHelper
extends RefCounted

## Standard setup warning: [code]ComponentClass 'NodeName': issue. Fix: hint[/code].
static func warn_setup(component_class: String, owner: Node, issue: String, fix: String) -> void:
	var node_name := "?" if owner == null else str(owner.name)
	push_warning("%s '%s': %s Fix: %s" % [component_class, node_name, issue, fix])

## Invokes [param sync_fn] with current and previous value equal (typical init path).
static func initial_sync(state: UiState, sync_fn: Callable) -> void:
	if state:
		sync_fn.call(state.value, state.value)

## Schedules [method _finish_initialization] after the current frame (shared reactive pattern).
static func deferred_finish_initialization(controller: Node, method: StringName = &"_finish_initialization") -> void:
	controller.call_deferred(method)

## Coerces a [UiState] value to [code]bool[/code] (same semantics as [code]bool()[/code]).
static func coerce_bool(value: Variant) -> bool:
	return bool(value)

## Coerces to [code]float[/code]; [code]null[/code] maps to [param default_if_null].
static func coerce_float(value: Variant, default_if_null: float = 0.0) -> float:
	if value == null:
		return default_if_null
	return float(value)

## Approximate float equality. Negative [param epsilon] uses [method @GlobalScope.is_equal_approx].
static func approx_equal_float(a: float, b: float, epsilon: float = -1.0) -> bool:
	if epsilon < 0.0:
		return is_equal_approx(a, b)
	return abs(a - b) <= epsilon

## Returns [param value] if it is an [Array], else warns and returns [code]null[/code].
static func expect_array_state(component_class: String, owner_name: String, field_name: String, value: Variant) -> Variant:
	if value is Array:
		return value
	var issue := "%s must be an Array (got type %s)." % [field_name, typeof(value)]
	var fix := "Set this UiState's value to an Array in the Inspector or from code (e.g. [\"Tab A\", \"Tab B\"])."
	# Owner may be unavailable; use name for context.
	push_warning("%s '%s': %s Fix: %s" % [component_class, owner_name, issue, fix])
	return null

## Flat text: [Array] elements use [method @GlobalScope.str] (no nested [UiState] expansion).
static func as_text_flat(value: Variant) -> String:
	if value is Array:
		var parts: Array[String] = []
		for v in value:
			parts.append(str(v))
		return "".join(parts)
	return str(value)

## Recursive text: unwraps [UiState] and concatenates nested arrays (label-style).
static func as_text_recursive(value: Variant) -> String:
	if value is UiState:
		return as_text_recursive(value.value)
	if value is Array:
		var parts: Array[String] = []
		for v in value:
			parts.append(as_text_recursive(v))
		return "".join(parts)
	return str(value)

## Shared helpers for reactive [State] ↔ control synchronization.
class_name ReactiveStateBindingHelper
extends RefCounted

## Invokes [param sync_fn] with current and previous value equal (typical init path).
static func initial_sync(state: State, sync_fn: Callable) -> void:
	if state:
		sync_fn.call(state.value, state.value)

## Schedules [method _finish_initialization] after the current frame (shared reactive pattern).
static func deferred_finish_initialization(controller: Node, method: StringName = &"_finish_initialization") -> void:
	controller.call_deferred(method)

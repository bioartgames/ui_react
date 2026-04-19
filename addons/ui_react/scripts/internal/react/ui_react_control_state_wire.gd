## Shared [signal UiState.value_changed] plus optional [UiReactComputedService] hook_bind / hook_unbind for [UiReact*] controls.
## Order matches existing controls: connect → initial [param on_changed] → hook_bind when [param use_computed_hook].
class_name UiReactControlStateWire
extends RefCounted


static func bind_value_changed(
	owner: Node,
	state: UiState,
	binding: StringName,
	on_changed: Callable,
	use_computed_hook: bool = true,
) -> void:
	if state == null or owner == null:
		return
	if not state.value_changed.is_connected(on_changed):
		state.value_changed.connect(on_changed)
	on_changed.call(state.get_value(), state.get_value())
	if use_computed_hook:
		UiReactComputedService.hook_bind(state, owner, binding)


static func unbind_value_changed(
	owner: Node,
	state: UiState,
	binding: StringName,
	on_changed: Callable,
	use_computed_hook: bool = true,
) -> void:
	if state == null or owner == null:
		return
	if use_computed_hook:
		UiReactComputedService.hook_unbind(state, owner, binding)
	if state.value_changed.is_connected(on_changed):
		state.value_changed.disconnect(on_changed)

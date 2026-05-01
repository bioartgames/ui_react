## Shared [signal UiState.value_changed] plus optional [UiReactComputedService] hook_bind / hook_unbind for [UiReact*] controls.
## Order matches existing controls: connect → initial [param on_changed] → hook_bind when the effective hook is true.
## [param use_computed_hook]: when [code]false[/code], dependency wiring is skipped for non-computed [UiState]s only; [UiComputed*] resources always use [UiReactComputedService] (see [method UiReactComputedService.supports_computed_wiring]).
class_name UiReactControlStateWire
extends RefCounted


static func _effective_computed_hook(state: UiState, use_computed_hook: bool) -> bool:
	return use_computed_hook or UiReactComputedService.supports_computed_wiring(state)


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
	var hook := _effective_computed_hook(state, use_computed_hook)
	if hook:
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
	var hook := _effective_computed_hook(state, use_computed_hook)
	if hook:
		UiReactComputedService.hook_unbind(state, owner, binding)
	if state.value_changed.is_connected(on_changed):
		state.value_changed.disconnect(on_changed)

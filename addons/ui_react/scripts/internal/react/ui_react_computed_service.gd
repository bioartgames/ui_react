## Owns [code]sources[/code] → [method UiComputedStringState.recompute] / [method UiComputedBoolState.recompute] wiring for [UiComputed*] resources bound to [UiReact*] controls.
## Static facade delegates mutable runtime state to [UiReactRuntimeSession].
class_name UiReactComputedService
extends RefCounted

static var _default_session: UiReactRuntimeSession = null


static func _session() -> UiReactRuntimeSession:
	if _default_session == null:
		_default_session = UiReactRuntimeSession.new()
		_default_session.start()
	return _default_session


static func hook_bind(state: UiState, consumer: Node, binding: StringName) -> void:
	ensure_wired(state, consumer, binding)


static func hook_unbind(state: UiState, consumer: Node, binding: StringName) -> void:
	release_wired(state, consumer, binding)


static func ensure_wired(computed: UiState, consumer: Node, binding: StringName) -> void:
	_session().ensure_wired(computed, consumer, binding)


static func release_wired(computed: UiState, consumer: Node, binding: StringName) -> void:
	_session().release_wired(computed, consumer, binding)


## Runtime/session lifecycle hard-stop: releases all listeners even when callers missed unbind.
static func stop_default_session() -> void:
	if _default_session == null:
		return
	_default_session.stop()
	_default_session = null


## Test-only reset helper retained for compatibility with existing GUT suite.
static func reset_internal_state_for_tests() -> void:
	stop_default_session()

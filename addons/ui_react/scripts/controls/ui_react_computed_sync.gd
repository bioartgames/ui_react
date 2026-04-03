@tool
## Subscribes to [member UiComputedStringState.sources] / [member UiComputedBoolState.sources] on [member computed] and calls [method UiComputedStringState.recompute] / [method UiComputedBoolState.recompute] when any dependency emits [signal Resource.changed] (all concrete [UiState] mutations call [method Resource.emit_changed]).
## Owns connection lifetime only; keep [member sources] on the computed resource (do not duplicate dep lists here).
class_name UiReactComputedSync
extends Control

const _MAX_SOURCES: int = 32

@export var computed: UiState

var _deps: Array[UiState] = []


func _ready() -> void:
	_wire()


func _exit_tree() -> void:
	_unwire()


func _wire() -> void:
	_unwire()
	if computed == null:
		return
	if not _is_supported_computed(computed):
		push_warning(
			"UiReactComputedSync '%s': computed must be UiComputedStringState or UiComputedBoolState (or a subclass)."
			% name
		)
		return
	var raw: Array[UiState] = _read_sources(computed)
	if raw.size() > _MAX_SOURCES:
		push_warning(
			"UiReactComputedSync '%s': sources count %d exceeds cap %d; extra entries are ignored."
			% [name, raw.size(), _MAX_SOURCES]
		)
	var cb := Callable(self, &"_on_dep_changed")
	for i in mini(raw.size(), _MAX_SOURCES):
		var dep: UiState = raw[i]
		if dep == null:
			continue
		if not dep.changed.is_connected(cb):
			dep.changed.connect(cb)
		_deps.append(dep)
	_trigger_recompute()


func _unwire() -> void:
	var cb := Callable(self, &"_on_dep_changed")
	for dep in _deps:
		if dep != null and is_instance_valid(dep):
			if dep.changed.is_connected(cb):
				dep.changed.disconnect(cb)
	_deps.clear()


func _is_supported_computed(state: UiState) -> bool:
	return state.has_method(&"recompute") and (
		state.has_method(&"compute_string") or state.has_method(&"compute_bool")
	)


func _read_sources(state: UiState) -> Array[UiState]:
	var out: Array[UiState] = []
	var raw: Variant = state.get(&"sources")
	if typeof(raw) != TYPE_ARRAY:
		return out
	for it in raw as Array:
		if it is UiState:
			out.append(it)
	return out


func _on_dep_changed(_arg0: Variant = null, _arg1: Variant = null) -> void:
	_trigger_recompute()


func _trigger_recompute() -> void:
	if computed == null or not computed.has_method(&"recompute"):
		return
	computed.call(&"recompute")

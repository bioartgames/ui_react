## Session-owned mutable state for computed dependency wiring.
## A session can be torn down to release all listeners even when callers miss explicit unbind.
class_name UiReactRuntimeSession
extends RefCounted

const MAX_SOURCES: int = 32

var _site_keys: Dictionary = {}
var _refcount_by_computed: Dictionary = {}
var _wired: Dictionary = {}
var _dirty_computed_ids: Dictionary = {}
var _flush_scheduled: bool = false
var _reenter_depth: Dictionary = {}
var _stopped: bool = false

class WiredEntry:
	var computed: UiState
	var deps: Array[UiState] = []
	var dep_callable: Callable
	var nested_to_release: Array = []


func start() -> void:
	_stopped = false


func stop() -> void:
	if _stopped:
		return
	_stopped = true
	while not _wired.is_empty():
		var k: Variant = _wired.keys()[0]
		var entry: WiredEntry = _wired[k] as WiredEntry
		if entry != null and entry.computed != null:
			_unwire_computed(entry.computed)
		else:
			_wired.erase(k)
	_site_keys.clear()
	_refcount_by_computed.clear()
	_wired.clear()
	_dirty_computed_ids.clear()
	_flush_scheduled = false
	_reenter_depth.clear()


func ensure_wired(computed: UiState, consumer: Node, binding: StringName) -> void:
	if _stopped or Engine.is_editor_hint() or computed == null or consumer == null:
		return
	if not _is_supported_computed(computed):
		return
	var key := _site_key(computed, consumer, binding)
	if _site_keys.has(key):
		return
	_site_keys[key] = true
	var cid := computed.get_instance_id()
	_refcount_by_computed[cid] = int(_refcount_by_computed.get(cid, 0)) + 1
	if int(_refcount_by_computed.get(cid, 0)) == 1:
		_wire_computed(computed, consumer)


func release_wired(computed: UiState, consumer: Node, binding: StringName) -> void:
	if _stopped or Engine.is_editor_hint() or computed == null or consumer == null:
		return
	var key := _site_key(computed, consumer, binding)
	if not _site_keys.has(key):
		return
	_site_keys.erase(key)
	var cid := computed.get_instance_id()
	var n := int(_refcount_by_computed.get(cid, 0)) - 1
	if n <= 0:
		_refcount_by_computed.erase(cid)
		_unwire_computed(computed)
	else:
		_refcount_by_computed[cid] = n


func _site_key(computed: UiState, consumer: Node, binding: StringName) -> String:
	return "%d|%d|%s" % [computed.get_instance_id(), consumer.get_instance_id(), String(binding)]


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


func _chain_binding(parent: UiState, dep_computed: UiState) -> StringName:
	return &"chain:%d:%d" % [parent.get_instance_id(), dep_computed.get_instance_id()]


func _wire_computed(computed: UiState, consumer: Node) -> void:
	var cid := computed.get_instance_id()
	if _wired.has(cid):
		return
	var raw: Array[UiState] = _read_sources(computed)
	if raw.size() > MAX_SOURCES:
		push_warning("UiReactComputedService: sources count %d exceeds cap %d; extra entries are ignored." % [raw.size(), MAX_SOURCES])
	var entry := WiredEntry.new()
	entry.computed = computed
	var wiring_cid: int = cid
	var cb: Callable = func(_a = null) -> void: _on_dep_changed(wiring_cid)
	entry.dep_callable = cb
	for i in mini(raw.size(), MAX_SOURCES):
		var dep: UiState = raw[i]
		if dep == null:
			continue
		if _is_supported_computed(dep):
			var nb := _chain_binding(computed, dep)
			ensure_wired(dep, consumer, nb)
			entry.nested_to_release.append([dep, consumer, nb])
		dep.changed.connect(cb)
		entry.deps.append(dep)
	_wired[cid] = entry
	_trigger_recompute_safe(computed)


func _unwire_computed(computed: UiState) -> void:
	var cid := computed.get_instance_id()
	if not _wired.has(cid):
		return
	var entry: WiredEntry = _wired[cid]
	var cb: Callable = entry.dep_callable
	for dep in entry.deps:
		if dep != null and is_instance_valid(dep) and dep.changed.is_connected(cb):
			dep.changed.disconnect(cb)
	for triple in entry.nested_to_release:
		if triple is Array and (triple as Array).size() >= 3:
			var t: Array = triple as Array
			var dep_c: UiState = t[0] as UiState
			var cons: Node = t[1] as Node
			var nb: StringName = t[2] as StringName
			if dep_c != null and cons != null:
				release_wired(dep_c, cons, nb)
	_wired.erase(cid)
	_dirty_computed_ids.erase(cid)


func _on_dep_changed(cid: int, _a = null, _b = null) -> void:
	if _stopped:
		return
	_dirty_computed_ids[cid] = true
	_schedule_flush()


func _schedule_flush() -> void:
	if _flush_scheduled or _stopped:
		return
	_flush_scheduled = true
	var st := Engine.get_main_loop() as SceneTree
	if st == null:
		_flush_scheduled = false
		return
	st.process_frame.connect(func() -> void: _flush_dirty_deferred(), CONNECT_ONE_SHOT)


func _flush_dirty_deferred() -> void:
	_flush_scheduled = false
	if _stopped:
		return
	var ids: Array = _dirty_computed_ids.keys()
	_dirty_computed_ids.clear()
	for cid in ids:
		if not _wired.has(cid):
			continue
		var entry: WiredEntry = _wired[cid]
		if entry.computed == null or not is_instance_valid(entry.computed):
			continue
		_trigger_recompute_safe(entry.computed)


func _trigger_recompute_safe(computed: UiState) -> void:
	if _stopped or computed == null or not computed.has_method(&"recompute"):
		return
	var cid := computed.get_instance_id()
	var d := int(_reenter_depth.get(cid, 0))
	if d > 0:
		push_warning("UiReactComputedService: reentrant recompute on computed instance %d; skipped (cycles unsupported)." % cid)
		return
	_reenter_depth[cid] = d + 1
	computed.call(&"recompute")
	var after := int(_reenter_depth.get(cid, 1)) - 1
	if after <= 0:
		_reenter_depth.erase(cid)
	else:
		_reenter_depth[cid] = after

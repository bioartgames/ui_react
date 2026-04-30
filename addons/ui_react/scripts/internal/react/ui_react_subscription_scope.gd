## Owns signal subscriptions for a single lifecycle scope.
## Use [method connect_signal] for deterministic teardown via [method dispose].
class_name UiReactSubscriptionScope
extends RefCounted

var _entries: Array[Dictionary] = []
var _disposed: bool = false


func connect_signal(sig: Signal, cb: Callable, flags: int = 0) -> void:
	if _disposed:
		return
	if not cb.is_valid():
		return
	if sig.is_connected(cb):
		return
	# Compact entries before appending to remove stale/disconnected callbacks
	_compact_entries()
	sig.connect(cb, flags)
	_entries.append({"signal": sig, "callable": cb})


func _compact_entries() -> void:
	var compacted: Array[Dictionary] = []
	for e in _entries:
		var sig: Signal = e.get("signal", null)
		var cb: Callable = e.get("callable", Callable())
		if sig is Signal and cb.is_valid() and sig.is_connected(cb):
			compacted.append(e)
	_entries = compacted


func dispose() -> void:
	for e in _entries:
		var sig: Signal = e.get("signal", null)
		var cb: Callable = e.get("callable", Callable())
		if sig is Signal and cb.is_valid() and sig.is_connected(cb):
			sig.disconnect(cb)
	_entries.clear()
	_disposed = false

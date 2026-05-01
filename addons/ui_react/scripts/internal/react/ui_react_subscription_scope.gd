## Tracks [Signal] → [Callable] pairs for a single owner ([UiReact*] control, [UiReactBaseButtonReactive], or editor UI).
## Call [method connect_bound] instead of raw [method Signal.connect]; call [method dispose] from the same teardown path
## as prior [code]_disconnect_local_control_signals[/code] helpers. Idempotent [method dispose]; duplicate [method connect_bound]
## for the same pair does not add a second record.
class_name UiReactSubscriptionScope
extends RefCounted

var _disposed: bool = false
var _records: Array[Dictionary] = []


## Connects [param cb] to [param sig] with optional [param flags] if not already connected; records for [method dispose].
func connect_bound(sig: Signal, cb: Callable, flags: int = 0) -> void:
	if _disposed:
		return
	if not cb.is_valid():
		return
	if sig.is_connected(cb):
		return
	sig.connect(cb, flags)
	_records.append({&"sig": sig, &"cb": cb})


## Disconnects all recorded pairs that are still connected. Safe to call multiple times.
func dispose() -> void:
	if _disposed:
		return
	_disposed = true
	for rec in _records:
		var s: Variant = rec.get(&"sig", null)
		var c: Callable = rec.get(&"cb", Callable()) as Callable
		if s is Signal and c.is_valid():
			var sig: Signal = s as Signal
			if sig.is_connected(c):
				sig.disconnect(c)
	_records.clear()


func is_disposed() -> bool:
	return _disposed


## Test-only: number of pairs recorded before [method dispose] drains them. After dispose, returns [code]0[/code].
func debug_tracked_count_for_tests() -> int:
	return _records.size()

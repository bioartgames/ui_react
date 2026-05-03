extends RefCounted
class_name UiReactLiveDebugBuffer

var _capacity: int
var _entries: Array[Dictionary] = []


func _init(capacity_p: int) -> void:
	_capacity = capacity_p if capacity_p > 0 else 384


func set_capacity(cap: int, clear: bool = true) -> void:
	_capacity = maxi(cap, 1)
	if clear:
		clear_buffer()


func clear_buffer() -> void:
	_entries.clear()


## Oldest at index zero.
func snapshot_oldest_first() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in _entries:
		out.append(e.duplicate(true))
	return out


func snapshot_newest_first() -> Array[Dictionary]:
	var out := snapshot_oldest_first()
	out.reverse()
	return out


func push(row: Dictionary) -> void:
	_entries.append(row.duplicate(true))
	while _entries.size() > _capacity:
		_entries.pop_front()

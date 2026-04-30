## Coalesces [method UiReactDock.refresh] into one deferred flush per burst; manual requests preserve unused-cache invalidation until the flush runs.
extends RefCounted

var _invalidate_unused_on_next_flush: bool = false
var _flush_scheduled: bool = false
var _dock: Control = null


func setup(dock: Control) -> void:
	_dock = dock


func request_refresh(reason_is_manual: bool) -> void:
	if reason_is_manual:
		_invalidate_unused_on_next_flush = true
	if _flush_scheduled or _dock == null:
		return
	_flush_scheduled = true
	_dock.call_deferred(&"_dock_coalescer_flush")


func take_invalidate_unused_for_flush() -> bool:
	var clear := _invalidate_unused_on_next_flush
	_invalidate_unused_on_next_flush = false
	return clear


func acknowledge_flush_started() -> void:
	_flush_scheduled = false

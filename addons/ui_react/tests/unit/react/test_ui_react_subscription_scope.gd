extends GutTest

const _Scope := preload("res://addons/ui_react/scripts/internal/react/ui_react_subscription_scope.gd")

var _hit_count: int = 0


func _line_hits(_t: String) -> void:
	_hit_count += 1


func test_dispose_idempotent() -> void:
	var scope = _Scope.new()
	scope.dispose()
	scope.dispose()
	assert_true(scope.is_disposed())


func test_duplicate_connect_bound_single_record() -> void:
	var scope = _Scope.new()
	var le := LineEdit.new()
	add_child_autofree(le)
	await wait_process_frames(1)
	_hit_count = 0
	var cb := Callable(self, "_line_hits")
	scope.connect_bound(le.text_changed, cb)
	scope.connect_bound(le.text_changed, cb)
	assert_eq(scope.debug_tracked_count_for_tests(), 1)
	scope.dispose()
	assert_eq(scope.debug_tracked_count_for_tests(), 0)


func test_dispose_disconnects_signal() -> void:
	var scope = _Scope.new()
	var le := LineEdit.new()
	add_child_autofree(le)
	await wait_process_frames(1)
	_hit_count = 0
	var cb := Callable(self, "_line_hits")
	scope.connect_bound(le.text_changed, cb)
	le.text_changed.emit("a")
	assert_eq(_hit_count, 1)
	scope.dispose()
	le.text_changed.emit("b")
	assert_eq(_hit_count, 1)


func test_connect_after_dispose_warns_and_ignores() -> void:
	var scope = _Scope.new()
	var le := LineEdit.new()
	add_child_autofree(le)
	await wait_process_frames(1)
	scope.dispose()
	scope.connect_bound(le.text_changed, Callable(self, "_line_hits"))
	assert_eq(scope.debug_tracked_count_for_tests(), 0)


func test_one_shot_dispose_safe() -> void:
	var scope = _Scope.new()
	var le := LineEdit.new()
	add_child_autofree(le)
	await wait_process_frames(1)
	var cb := Callable(self, "_line_hits")
	scope.connect_bound(le.text_changed, cb, CONNECT_ONE_SHOT)
	_hit_count = 0
	le.text_changed.emit("x")
	scope.dispose()
	assert_true(true, "one-shot + dispose completes without error")

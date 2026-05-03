extends GutTest


const Buffer := preload("res://addons/ui_react/scripts/runtime/ui_react_live_debug_buffer.gd")
const Ek := preload("res://addons/ui_react/scripts/runtime/ui_react_live_debug_event_kinds.gd")
const BR: Variant = preload("res://addons/ui_react/scripts/runtime/ui_react_live_debug_bridge.gd")


func test_ring_buffer_truncates_fifo() -> void:
	var buf := Buffer.new(3)
	buf.push({&"order": &"a"})
	buf.push({&"order": &"b"})
	buf.push({&"order": &"c"})
	buf.push({&"order": &"d"})
	var rows := buf.snapshot_oldest_first()
	assert_eq(rows.size(), 3)
	assert_eq(str(rows[0].get(&"order", "")), "b")
	assert_eq(str(rows[2].get(&"order", "")), "d")


func test_snapshot_newest_first_orders() -> void:
	var buf := Buffer.new(8)
	buf.push(Ek.make_row(1, Ek.Kind.STATE_VALUE_CHANGED, {Ek.META_STATE_ID: "first"}))
	buf.push(Ek.make_row(2, Ek.Kind.STATE_VALUE_CHANGED, {Ek.META_STATE_ID: "second"}))
	var rows := buf.snapshot_newest_first()
	assert_eq(rows.size(), 2)
	assert_eq(int(rows[0].get(Ek.META_SEQ, -1)), 2)
	assert_eq(int(rows[1].get(Ek.META_SEQ, -1)), 1)


func test_live_debug_facade_force_flag_smoke() -> void:
	var buf := Buffer.new(16)
	BR.call(&"register_buffer", buf)
	var prev := bool(BR.call(&"get_force_enabled_for_tests"))
	BR.call(&"set_force_enabled_for_tests", true)
	BR.call(&"reset_sequence_for_tests")
	var st := UiBoolState.new(false)
	BR.call(&"maybe_state_value_changed", st, true, false, "HBox/Ctrl", "bind:test")
	assert_eq(buf.snapshot_oldest_first().size(), 1)
	BR.call(&"set_force_enabled_for_tests", prev)
	BR.call(&"unregister_buffer", buf)

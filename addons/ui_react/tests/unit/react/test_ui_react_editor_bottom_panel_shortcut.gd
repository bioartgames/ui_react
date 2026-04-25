extends GutTest

const _S := preload(
	"res://addons/ui_react/editor_plugin/services/ui_react_editor_bottom_panel_shortcut.gd"
)


func test_default_spec_round_trips_json() -> void:
	var spec: Dictionary = _S.default_shortcut_spec()
	var json := _S.spec_to_json(spec)
	var sc_variant: Variant = _S.shortcut_from_json_string(json)
	assert_not_null(sc_variant)
	var sc := sc_variant as Shortcut
	assert_eq(sc.events.size(), 1)
	var ev := sc.events[0] as InputEventKey
	assert_eq(ev.keycode, KEY_U)
	assert_true(ev.alt_pressed)
	assert_false(ev.shift_pressed)
	assert_false(ev.ctrl_pressed)
	assert_false(ev.meta_pressed)


func test_empty_string_uses_default_alt_u() -> void:
	var sc_variant: Variant = _S.shortcut_from_json_string("")
	assert_not_null(sc_variant)
	var ev := (sc_variant as Shortcut).events[0] as InputEventKey
	assert_eq(ev.keycode, KEY_U)
	assert_true(ev.alt_pressed)


func test_invalid_json_uses_default_alt_u() -> void:
	var sc_variant: Variant = _S.shortcut_from_json_string("not json {{{")
	assert_engine_error(1)
	assert_not_null(sc_variant)
	var ev := (sc_variant as Shortcut).events[0] as InputEventKey
	assert_eq(ev.keycode, KEY_U)
	assert_true(ev.alt_pressed)


func test_disabled_spec_returns_null_shortcut() -> void:
	assert_null(_S.shortcut_from_json_string('{"v":1,"enabled":false}'))
	assert_null(_S.shortcut_from_json_string("{}"))


func test_unknown_version_falls_back_to_default() -> void:
	var sc_variant: Variant = _S.shortcut_from_json_string(
		'{"v":99,"enabled":true,"keycode":4194338,"alt":false}'
	)
	assert_engine_error(1)
	assert_not_null(sc_variant)
	var ev := (sc_variant as Shortcut).events[0] as InputEventKey
	assert_eq(ev.keycode, KEY_U)
	assert_true(ev.alt_pressed)


func test_format_tab_tooltip_default_matches_toggle_line() -> void:
	var sc_variant: Variant = _S.shortcut_from_json_string(_S.spec_to_json(_S.default_shortcut_spec()))
	var tip := _S.format_tab_tooltip(sc_variant)
	assert_eq(tip, "Toggle Ui React Bottom Panel (Alt+U)")


func test_format_tab_tooltip_no_shortcut_when_null() -> void:
	var tip := _S.format_tab_tooltip(null)
	assert_eq(tip, "Toggle Ui React Bottom Panel")

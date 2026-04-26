extends GutTest

const _S := preload(
	"res://addons/ui_react/editor_plugin/services/ui_react_editor_bottom_panel_shortcut.gd"
)


func test_default_open_specs_round_trip_json() -> void:
	var dspec: Dictionary = _S.default_open_diagnostics_spec()
	var wspec: Dictionary = _S.default_open_wiring_spec()
	var djson := _S.spec_to_json(dspec)
	var wjson := _S.spec_to_json(wspec)
	var dsc: Variant = _S.open_shortcut_from_json_string(djson, dspec)
	var wsc: Variant = _S.open_shortcut_from_json_string(wjson, wspec)
	assert_not_null(dsc)
	assert_not_null(wsc)
	var dev := (dsc as Shortcut).events[0] as InputEventKey
	var wev := (wsc as Shortcut).events[0] as InputEventKey
	assert_eq(dev.keycode, KEY_1)
	assert_true(dev.alt_pressed)
	assert_eq(wev.keycode, KEY_2)
	assert_true(wev.alt_pressed)


func test_empty_string_uses_fallback_spec() -> void:
	var fb := _S.default_open_diagnostics_spec()
	var sc_variant: Variant = _S.open_shortcut_from_json_string("", fb)
	assert_not_null(sc_variant)
	var ev := (sc_variant as Shortcut).events[0] as InputEventKey
	assert_eq(ev.keycode, KEY_1)
	assert_true(ev.alt_pressed)


func test_invalid_json_uses_fallback_and_warns() -> void:
	var fb := _S.default_open_wiring_spec()
	var sc_variant: Variant = _S.open_shortcut_from_json_string("not json {{{", fb)
	assert_engine_error(1)
	assert_not_null(sc_variant)
	var ev := (sc_variant as Shortcut).events[0] as InputEventKey
	assert_eq(ev.keycode, KEY_2)


func test_disabled_spec_returns_null_shortcut() -> void:
	var fb := _S.default_open_diagnostics_spec()
	assert_null(_S.open_shortcut_from_json_string('{"v":1,"enabled":false}', fb))
	assert_null(_S.open_shortcut_from_json_string("{}", fb))


func test_unknown_version_falls_back_to_fallback() -> void:
	var fb := _S.default_open_diagnostics_spec()
	var sc_variant: Variant = _S.open_shortcut_from_json_string(
		'{"v":99,"enabled":true,"keycode":4194338,"alt":false}', fb
	)
	assert_engine_error(1)
	assert_not_null(sc_variant)
	var ev := (sc_variant as Shortcut).events[0] as InputEventKey
	assert_eq(ev.keycode, KEY_1)


func test_format_bottom_panel_tab_tooltip_two_shortcuts() -> void:
	var d := _S.build_shortcut_from_spec(_S.default_open_diagnostics_spec())
	var w := _S.build_shortcut_from_spec(_S.default_open_wiring_spec())
	var tip := _S.format_bottom_panel_tab_tooltip(d, w)
	assert_eq(tip, "Toggle Ui React Bottom Panel (Alt+1, Alt+2)")


func test_format_bottom_panel_tab_tooltip_both_disabled() -> void:
	var tip := _S.format_bottom_panel_tab_tooltip(null, null)
	assert_eq(tip, "Toggle Ui React Bottom Panel (disabled, disabled)")

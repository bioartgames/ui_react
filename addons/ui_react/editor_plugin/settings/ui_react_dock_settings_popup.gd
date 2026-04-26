@tool
extends PopupPanel

const _BottomShortcut := preload(
	"res://addons/ui_react/editor_plugin/services/ui_react_editor_bottom_panel_shortcut.gd"
)

var _active_capture_key: String = ""
var _pending_specs: Dictionary = {}
var _value_labels: Dictionary = {}
var _assign_buttons: Dictionary = {}

func _ready() -> void:
	if get_child_count() == 0:
		_build_ui()
	reload_from_project_settings()
	hide()


func open_popup() -> void:
	reload_from_project_settings()
	popup_centered(Vector2i(640, 360))


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	var title := Label.new()
	title.text = "Ui React Settings"
	title.add_theme_font_size_override("font_size", 18)
	root.add_child(title)

	root.add_child(_build_shortcut_row(
		"diagnostics",
		"Open Diagnostics",
		"Open the Ui React bottom panel and focus the Diagnostics tab."
	))
	root.add_child(_build_shortcut_row(
		"wiring",
		"Open Wiring Graph",
		"Open the Ui React bottom panel and focus the Wiring tab."
	))

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	var apply_btn := Button.new()
	apply_btn.text = "Apply"
	apply_btn.tooltip_text = "Save Ui React shortcut settings."
	apply_btn.pressed.connect(_on_apply_pressed)
	actions.add_child(apply_btn)
	var revert_btn := Button.new()
	revert_btn.text = "Revert"
	revert_btn.tooltip_text = "Discard unsaved edits."
	revert_btn.pressed.connect(reload_from_project_settings)
	actions.add_child(revert_btn)
	var reset_btn := Button.new()
	reset_btn.text = "Reset defaults"
	reset_btn.tooltip_text = "Reset both shortcuts to Alt+1 and Alt+2."
	reset_btn.pressed.connect(_on_reset_defaults_pressed)
	actions.add_child(reset_btn)
	root.add_child(actions)


func _build_shortcut_row(key: String, label_text: String, help_text: String) -> VBoxContainer:
	var sec := VBoxContainer.new()
	sec.add_theme_constant_override("separation", 6)
	var label := Label.new()
	label.text = label_text
	label.tooltip_text = help_text
	sec.add_child(label)
	var value := Label.new()
	value.text = "Current: Disabled"
	value.tooltip_text = "Current assigned shortcut."
	sec.add_child(value)
	_value_labels[key] = value
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var assign := Button.new()
	assign.text = "Assign..."
	assign.tooltip_text = "Capture the next keypress. Esc cancels."
	assign.pressed.connect(func() -> void: _start_capture(key, assign))
	row.add_child(assign)
	_assign_buttons[key] = assign
	var clear_btn := Button.new()
	clear_btn.text = "Clear"
	clear_btn.tooltip_text = "Disable this shortcut."
	clear_btn.pressed.connect(func() -> void: _clear_shortcut(key))
	row.add_child(clear_btn)
	var reset_btn := Button.new()
	reset_btn.text = "Reset Default"
	reset_btn.tooltip_text = "Restore default shortcut."
	reset_btn.pressed.connect(func() -> void: _reset_shortcut(key))
	row.add_child(reset_btn)
	sec.add_child(row)
	return sec


func reload_from_project_settings() -> void:
	_active_capture_key = ""
	set_process_unhandled_key_input(false)
	_pending_specs["diagnostics"] = _read_spec("diagnostics", UiReactDockConfig.get_open_diagnostics_shortcut_json())
	_pending_specs["wiring"] = _read_spec("wiring", UiReactDockConfig.get_open_wiring_shortcut_json())
	_sync_labels()


func _on_apply_pressed() -> void:
	UiReactDockConfig.save_ui_preference(
		UiReactDockConfig.KEY_OPEN_DIAGNOSTICS_SHORTCUT_JSON,
		_BottomShortcut.spec_to_json(_pending_specs.get("diagnostics", _default_spec_for("diagnostics")))
	)
	UiReactDockConfig.save_ui_preference(
		UiReactDockConfig.KEY_OPEN_WIRING_SHORTCUT_JSON,
		_BottomShortcut.spec_to_json(_pending_specs.get("wiring", _default_spec_for("wiring")))
	)
	hide()


func _on_reset_defaults_pressed() -> void:
	_pending_specs["diagnostics"] = _default_spec_for("diagnostics")
	_pending_specs["wiring"] = _default_spec_for("wiring")
	_sync_labels()


func _start_capture(key: String, button: Button) -> void:
	_active_capture_key = key
	set_process_unhandled_key_input(true)
	button.text = "Press keys..."
	button.disabled = true
	for k in _value_labels.keys():
		if String(k) == key:
			(_value_labels[k] as Label).text = "Current: capturing input..."


func _clear_shortcut(key: String) -> void:
	_pending_specs[key] = {"v": _BottomShortcut.SCHEMA_VERSION, "enabled": false}
	_sync_labels()


func _reset_shortcut(key: String) -> void:
	_pending_specs[key] = _default_spec_for(key)
	_sync_labels()


func _unhandled_key_input(event: InputEvent) -> void:
	if _active_capture_key.is_empty() or event is not InputEventKey:
		return
	var ek := event as InputEventKey
	if not ek.pressed or ek.echo:
		return
	if ek.keycode == KEY_ESCAPE:
		_active_capture_key = ""
		set_process_unhandled_key_input(false)
		_sync_labels()
		_mark_input_handled()
		return
	if ek.keycode == KEY_SHIFT or ek.keycode == KEY_CTRL or ek.keycode == KEY_ALT or ek.keycode == KEY_META:
		_mark_input_handled()
		return
	_pending_specs[_active_capture_key] = {
		"v": _BottomShortcut.SCHEMA_VERSION,
		"enabled": true,
		"keycode": int(ek.keycode),
		"alt": ek.alt_pressed,
		"shift": ek.shift_pressed,
		"ctrl": ek.ctrl_pressed,
		"meta": ek.meta_pressed,
	}
	_active_capture_key = ""
	set_process_unhandled_key_input(false)
	_sync_labels()
	_mark_input_handled()


func _sync_labels() -> void:
	for key in ["diagnostics", "wiring"]:
		var assign_btn := _assign_buttons.get(key, null) as Button
		if assign_btn != null:
			assign_btn.text = "Assign..."
			assign_btn.disabled = false
		var label := _value_labels.get(key, null) as Label
		if label == null:
			continue
		var sc := _BottomShortcut.build_shortcut_from_spec(_pending_specs.get(key, _default_spec_for(key)))
		var text := "Disabled"
		if bool((_pending_specs.get(key, {}) as Dictionary).get("enabled", true)) and sc != null and not sc.events.is_empty():
			var st := sc.get_as_text().strip_edges()
			if not st.is_empty():
				text = st
		label.text = "Current: " + text


func _read_spec(key: String, raw: String) -> Dictionary:
	var fallback := _default_spec_for(key)
	var data := raw.strip_edges()
	if data.is_empty():
		return fallback
	var j := JSON.new()
	if j.parse(data) != OK or j.data is not Dictionary:
		return fallback
	var d := j.data as Dictionary
	if d.is_empty():
		return {"v": _BottomShortcut.SCHEMA_VERSION, "enabled": false}
	return {
		"v": int(d.get("v", d.get(&"v", _BottomShortcut.SCHEMA_VERSION))),
		"enabled": bool(d.get("enabled", d.get(&"enabled", true))),
		"keycode": int(d.get("keycode", d.get(&"keycode", 0))),
		"alt": bool(d.get("alt", d.get(&"alt", false))),
		"shift": bool(d.get("shift", d.get(&"shift", false))),
		"ctrl": bool(d.get("ctrl", d.get(&"ctrl", false))),
		"meta": bool(d.get("meta", d.get(&"meta", false))),
	}


func _default_spec_for(key: String) -> Dictionary:
	if key == "wiring":
		return _BottomShortcut.default_open_wiring_spec()
	return _BottomShortcut.default_open_diagnostics_spec()


func _mark_input_handled() -> void:
	var vp := get_viewport()
	if vp != null:
		vp.set_input_as_handled()

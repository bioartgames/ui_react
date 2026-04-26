## JSON ([ProjectSettings]) to [Shortcut] for Ui React editor “open tab” shortcuts and tab tooltips.
## The bottom-panel tab no longer registers a [Shortcut]; Alt+KEY_1 / Alt+KEY_2 open Diagnostics / Wiring.
class_name UiReactEditorBottomPanelShortcut
extends RefCounted

const SCHEMA_VERSION := 1


static func default_open_diagnostics_spec() -> Dictionary:
	return {
		"v": SCHEMA_VERSION,
		"enabled": true,
		"keycode": KEY_1,
		"alt": true,
		"shift": false,
		"ctrl": false,
		"meta": false,
	}


static func default_open_wiring_spec() -> Dictionary:
	return {
		"v": SCHEMA_VERSION,
		"enabled": true,
		"keycode": KEY_2,
		"alt": true,
		"shift": false,
		"ctrl": false,
		"meta": false,
	}


static func spec_to_json(spec: Dictionary) -> String:
	return JSON.stringify(spec)


static func build_shortcut_from_spec(spec: Dictionary) -> Shortcut:
	var sc := Shortcut.new()
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.echo = false
	ev.keycode = int(spec.get("keycode", KEY_NONE))
	ev.alt_pressed = bool(spec.get("alt", false))
	ev.shift_pressed = bool(spec.get("shift", false))
	ev.ctrl_pressed = bool(spec.get("ctrl", false))
	ev.meta_pressed = bool(spec.get("meta", false))
	sc.events.append(ev)
	return sc


## Returns [code]null[/code] when the binding is disabled or cleared ([code]{}[/code] / [code]enabled: false[/code]).
## On empty/invalid JSON, returns a [Shortcut] built from [param fallback_spec].
static func open_shortcut_from_json_string(raw: String, fallback_spec: Dictionary) -> Variant:
	var s := raw.strip_edges()
	if s.is_empty():
		return build_shortcut_from_spec(fallback_spec)

	var j := JSON.new()
	if j.parse(s) != OK:
		push_warning("Ui React: invalid open shortcut JSON; using fallback.")
		return build_shortcut_from_spec(fallback_spec)

	var root: Variant = j.data
	if root is not Dictionary:
		push_warning("Ui React: open shortcut JSON must be an object; using fallback.")
		return build_shortcut_from_spec(fallback_spec)

	var d: Dictionary = root as Dictionary
	if d.is_empty():
		return null

	if d.has("enabled") and bool(d["enabled"]) == false:
		return null

	var ver: int = int(d.get("v", 0))
	if ver != SCHEMA_VERSION:
		push_warning("Ui React: open shortcut schema v%s is unsupported; using fallback." % str(ver))
		return build_shortcut_from_spec(fallback_spec)

	var kc: int = int(d.get("keycode", KEY_NONE))
	if kc == KEY_NONE:
		push_warning("Ui React: open shortcut keycode missing or KEY_NONE; using fallback.")
		return build_shortcut_from_spec(fallback_spec)

	var spec := {
		"v": SCHEMA_VERSION,
		"enabled": true,
		"keycode": kc,
		"alt": bool(d.get("alt", false)),
		"shift": bool(d.get("shift", false)),
		"ctrl": bool(d.get("ctrl", false)),
		"meta": bool(d.get("meta", false)),
	}
	return build_shortcut_from_spec(spec)


static func _shortcut_as_parenthesis_token(shortcut: Variant) -> String:
	if shortcut == null or not shortcut is Shortcut:
		return "disabled"
	var sc := shortcut as Shortcut
	if sc.events.is_empty():
		return "disabled"
	var st := sc.get_as_text().strip_edges()
	if st.is_empty():
		var ev0: Variant = sc.events[0]
		if ev0 is InputEventKey:
			var ek := ev0 as InputEventKey
			st = OS.get_keycode_string(ek.get_keycode_with_modifiers())
		else:
			return "disabled"
	# Godot often appends " (Physical)"; keep tooltip as "Alt+1, Alt+2" style.
	var phys := " (Physical)"
	if st.ends_with(phys):
		st = st.substr(0, st.length() - phys.length()).strip_edges()
	return st


## Single-line tooltip for the Ui React bottom-panel tab ([member BaseButton.tooltip_text] only).
## Defaults read as [code]Toggle Ui React Bottom Panel (Alt+1, Alt+2)[/code]; tokens follow parsed shortcuts.
static func format_bottom_panel_tab_tooltip(diagnostics_shortcut: Variant, wiring_shortcut: Variant) -> String:
	var a := _shortcut_as_parenthesis_token(diagnostics_shortcut)
	var b := _shortcut_as_parenthesis_token(wiring_shortcut)
	return "Toggle Ui React Bottom Panel (%s, %s)" % [a, b]

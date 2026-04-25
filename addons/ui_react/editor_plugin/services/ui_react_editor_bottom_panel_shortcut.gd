## JSON (Project Settings) to [Shortcut] for the Ui React editor bottom panel tab.
## See [member UiReactDockConfig.KEY_EDITOR_BOTTOM_PANEL_SHORTCUT_JSON].
class_name UiReactEditorBottomPanelShortcut
extends RefCounted

const SCHEMA_VERSION := 1

## Hover text for the bottom-panel tab [Button] ([member BaseButton.tooltip_text] only).
## Shortcut text is appended by the engine when [member BaseButton.shortcut_in_tooltip] is [code]true[/code] (default).
const TAB_TOOLTIP_TEXT := "Toggle Ui React Bottom Panel"


static func default_shortcut_spec() -> Dictionary:
	return {
		"v": SCHEMA_VERSION,
		"enabled": true,
		"keycode": KEY_U,
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
## Returns a [Shortcut] (default Alt+U) when JSON is missing, invalid, or wrong version.
static func shortcut_from_json_string(s: String) -> Variant:
	var raw := s.strip_edges()
	if raw.is_empty():
		return build_shortcut_from_spec(default_shortcut_spec())

	var j := JSON.new()
	if j.parse(raw) != OK:
		push_warning("Ui React: invalid bottom panel shortcut JSON; using default Alt+U.")
		return build_shortcut_from_spec(default_shortcut_spec())

	var root: Variant = j.data
	if root is not Dictionary:
		push_warning("Ui React: bottom panel shortcut JSON must be an object; using default Alt+U.")
		return build_shortcut_from_spec(default_shortcut_spec())

	var d: Dictionary = root as Dictionary
	if d.is_empty():
		return null

	if d.has("enabled") and bool(d["enabled"]) == false:
		return null

	var ver: int = int(d.get("v", 0))
	if ver != SCHEMA_VERSION:
		push_warning(
			"Ui React: bottom panel shortcut schema v%s is unsupported; using default Alt+U." % str(ver)
		)
		return build_shortcut_from_spec(default_shortcut_spec())

	var kc: int = int(d.get("keycode", KEY_NONE))
	if kc == KEY_NONE:
		push_warning("Ui React: bottom panel shortcut keycode missing or KEY_NONE; using default Alt+U.")
		return build_shortcut_from_spec(default_shortcut_spec())

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


static func format_tab_tooltip(shortcut: Variant) -> String:
	if shortcut == null or not shortcut is Shortcut:
		return TAB_TOOLTIP_TEXT
	var sc := shortcut as Shortcut
	if sc.events.is_empty():
		return TAB_TOOLTIP_TEXT
	var st := sc.get_as_text()
	if st.is_empty():
		var ev0: Variant = sc.events[0]
		if ev0 is InputEventKey:
			var ek := ev0 as InputEventKey
			st = OS.get_keycode_string(ek.get_keycode_with_modifiers())
		else:
			return TAB_TOOLTIP_TEXT
	return TAB_TOOLTIP_TEXT + " (" + st + ")"

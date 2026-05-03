extends Node
## Autoload (**CB-018C**). Project Settings → Autoload → UiReactLiveDebug → `res://addons/ui_react/scripts/runtime/ui_react_live_debug.gd`. Toggle overlay: **Alt+3** (main row **3**, not numpad).

const _BufferScript := preload("res://addons/ui_react/scripts/runtime/ui_react_live_debug_buffer.gd")
const _OverlayScript := preload("res://addons/ui_react/scripts/runtime/ui_react_live_debug_overlay.gd")
const _HarvesterScript := preload("res://addons/ui_react/scripts/runtime/ui_react_live_debug_harvester.gd")
const BR: Variant = preload("res://addons/ui_react/scripts/runtime/ui_react_live_debug_bridge.gd")


const _BUFFER_CAP_KEY := &"ui_react/settings/runtime/live_debug_buffer_cap"
const _BUFFER_CAP_DEFAULT := 384
const _BUFFER_CAP_MIN := 64
const _BUFFER_CAP_MAX := 2048


func _live_debug_cap_effective() -> int:
	## Mirrors [method UiReactDockConfig.live_debug_buffer_cap_effective] — keep clamp defaults in sync.
	var raw := int(ProjectSettings.get_setting(_BUFFER_CAP_KEY, _BUFFER_CAP_DEFAULT))
	return clampi(raw, _BUFFER_CAP_MIN, _BUFFER_CAP_MAX)


func is_active() -> bool:
	return bool(BR.call(&"is_effective_enabled"))


var _buffer: RefCounted
var _harvester: RefCounted
var _debounce: Timer
var _poll: Timer
var _overlay: CanvasLayer = null


func _ready() -> void:
	var cap := _live_debug_cap_effective()
	_buffer = _BufferScript.new(cap) as RefCounted
	BR.call(&"register_buffer", _buffer)
	_harvester = _HarvesterScript.new() as RefCounted

	_debounce = Timer.new()
	_debounce.one_shot = true
	_debounce.wait_time = 0.15
	add_child(_debounce)
	_debounce.timeout.connect(_on_debounce_rescan)

	_poll = Timer.new()
	_poll.wait_time = 0.1
	add_child(_poll)
	_poll.timeout.connect(_on_poll_refresh)

	var st := get_tree()
	st.node_added.connect(_schedule_rescan_any)
	st.node_removed.connect(_schedule_rescan_any)

	call_deferred(&"_initial_scan")


func _exit_tree() -> void:
	_poll.stop()
	if _buffer != null:
		BR.call(&"unregister_buffer", _buffer)
	if _harvester != null:
		_harvester.call(&"clear_subscriptions")


func _initial_scan() -> void:
	_schedule_rescan_any(null)


func _schedule_rescan_any(_ignored: Node) -> void:
	if not is_active():
		if _harvester != null:
			_harvester.call(&"clear_subscriptions")
		return
	_debounce.stop()
	_debounce.start(0.15)


func _on_debounce_rescan() -> void:
	if not is_active():
		if _harvester != null:
			_harvester.call(&"clear_subscriptions")
		return
	var st := get_tree()
	var r: Node = st.current_scene
	if r == null:
		r = st.root
	if r == null:
		return
	_harvester.call(&"rebuild", r)


func _unhandled_input(event: InputEvent) -> void:
	if not is_active():
		return
	if event is InputEventKey:
		var ik := event as InputEventKey
		if ik.pressed and not ik.echo and ik.alt_pressed and ik.physical_keycode == KEY_3:
			var vp := get_viewport()
			if vp != null:
				vp.set_input_as_handled()
			_toggle_overlay()


func _toggle_overlay() -> void:
	var layer := _ensure_overlay(true)
	if layer == null:
		return
	layer.toggle_visible()
	if bool(layer.visible):
		_poll.start()
		_refresh_overlay_body()
	else:
		_poll.stop()


func _ensure_overlay(create: bool) -> CanvasLayer:
	if _overlay != null:
		return _overlay
	if not create:
		return null
	var layer := _OverlayScript.new()
	add_child(layer)
	_overlay = layer
	return layer


func _on_poll_refresh() -> void:
	if _overlay == null or not bool(_overlay.visible):
		_poll.stop()
		return
	_refresh_overlay_body()


func _refresh_overlay_body() -> void:
	if _overlay == null:
		return
	var cap := _live_debug_cap_effective()
	_overlay.set_header_text("Ui React live debug | buffer %d | Alt+3 hide | active" % cap)
	var rows: Variant = BR.call(&"get_buffer_snapshot_newest_first")
	_overlay.refresh_items(rows if typeof(rows) == TYPE_ARRAY else [])

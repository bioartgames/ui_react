## Input handling (RefCounted).
## Processes input and translates to navigation commands.
class_name ReactiveInputHandler
extends RefCounted

## The focus manager to delegate navigation to.
var _focus_manager: ReactiveFocusManager = null

## Signal connections for cleanup.
var _signal_connections: Array[SignalConnection] = []

## Sets up the input handler with a focus manager.
func setup(focus_manager: ReactiveFocusManager) -> void:
	_focus_manager = focus_manager
	_setup_input_connections()

## Sets up input connections.
func _setup_input_connections() -> void:
	# Connect to Input singleton signals if available
	# Note: In Godot 4, we process input in _process or via Input events
	# For now, we'll process input manually via process_input() method
	pass

## Processes input and translates to navigation commands.
## Should be called from _process() or _input() in the owner node.
func process_input() -> void:
	if _focus_manager == null:
		return
	
	# Check for navigation input
	if Input.is_action_just_pressed("ui_up"):
		_focus_manager.move_focus("up")
	elif Input.is_action_just_pressed("ui_down"):
		_focus_manager.move_focus("down")
	elif Input.is_action_just_pressed("ui_left"):
		_focus_manager.move_focus("left")
	elif Input.is_action_just_pressed("ui_right"):
		_focus_manager.move_focus("right")
	elif Input.is_action_just_pressed("ui_accept"):
		# Trigger accept action on focused control
		_handle_accept()
	elif Input.is_action_just_pressed("ui_cancel"):
		# Trigger cancel action on focused control
		_handle_cancel()
	
	# Tab navigation is handled automatically by Godot's Control system
	# Our focus order will be respected by the built-in Tab navigation

## Handles accept action (Enter/Space/A button).
func _handle_accept() -> void:
	if _focus_manager == null:
		return
	
	var focused = _get_focused_control()
	if focused == null:
		return
	
	# If it's a ReactiveControl, execute actions
	if focused is ReactiveControl:
		var reactive_control = focused as ReactiveControl
		reactive_control.execute_actions()
	
	# If it's a Button, press it
	if focused.has_method("_pressed"):
		focused._pressed()
	elif focused.has_signal("pressed"):
		focused.emit_signal("pressed")

## Handles cancel action (Escape/B button).
func _handle_cancel() -> void:
	if _focus_manager == null:
		return
	
	var focused = _get_focused_control()
	if focused == null:
		return
	
	# If it has a cancel signal, emit it
	if focused.has_signal("cancel"):
		focused.emit_signal("cancel")

## Gets the currently focused control.
func _get_focused_control() -> Control:
	if _focus_manager == null:
		return null
	
	# Use focus manager's method to get focused control
	return _focus_manager.get_focused_control()

## Cleans up the input handler.
func cleanup() -> void:
	# Cleanup signal connections
	ReactiveLifecycleManager.cleanup_signal_connections(_signal_connections)
	
	# Clear references
	_focus_manager = null


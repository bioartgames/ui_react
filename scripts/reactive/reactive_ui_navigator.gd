@tool
extends Node
class_name ReactiveUINavigator

## A designer-friendly navigation controller for reactive UI systems.
##
## This node provides keyboard/controller/mouse navigation for UI controls without requiring
## custom scripting. It supports multiple input modes and can be configured entirely
## through the Inspector.
##
## ## Usage:
## 1. Add this node to your scene
## 2. Set the navigation mode (INPUT_MAP for standard controls, STATE_DRIVEN for custom input)
## 3. Configure NavigationConfig to define which UI elements to control
## 4. Set up input sources (NavigationInputProfile or NavigationStateBundle)
##
## ## Navigation Modes:
## - INPUT_MAP: Uses Godot's InputMap for standard keyboard/controller input
## - STATE_DRIVEN: Reads navigation commands from State resources (for custom input systems)
## - BOTH: Reserved for advanced combined input handling
##
## ## Signals:
## Emits various signals when navigation events occur, allowing you to connect
## scene-specific behavior without subclassing.

## Emitted when focus actually moves from one control to another.
signal focus_changed(old_focus: Control, new_focus: Control)
## Emitted when user intends to move focus in a direction (may not result in actual focus change).
signal navigation_moved(direction: Vector2)
## Emitted when submit action is fired.
signal submit_fired(focus_owner: Control)
## Emitted when cancel action is fired.
signal cancel_fired(focus_owner: Control)
## Emitted when page navigation occurs (delta: +1 for next, -1 for previous).
signal page_changed(delta: int, focus_owner: Control)

enum NavigationMode {
	NONE,           ## Navigation disabled
	INPUT_MAP,      ## Uses NavigationInputProfile + Godot InputMap
	STATE_DRIVEN,   ## Uses NavigationStateBundle only
	BOTH            ## Reserved for the combined bridge mode described in the advanced features phase
}

var mode: NavigationMode = NavigationMode.INPUT_MAP:
	set(value):
		mode = value
		update_configuration()
		notify_property_list_changed()

var nav_config: NavigationConfig:
	set(value):
		nav_config = value
		update_configuration()

var input_profile: NavigationInputProfile
var nav_states: NavigationStateBundle

var _current_focus_owner: Control = null
var _is_ready: bool = false
var _repeat_state := {}  # internal structure for key repeat
var _prev_submit_value: bool = false
var _prev_cancel_value: bool = false
var _prev_page_next_value: bool = false
var _prev_page_prev_value: bool = false

@export var debug_navigation: bool = false

func _ready() -> void:
	if Engine.is_editor_hint():
		# Editor validation and preview
		update_configuration()
		return

	# Resolve nav_config.root_control and nav_config.default_focus
	var root_control: Control = null
	if nav_config and nav_config.root_control:
		root_control = get_node(nav_config.root_control) as Control
		if not root_control:
			push_warning("ReactiveUINavigator '%s': root_control path '%s' is invalid" % [name, nav_config.root_control])

	# Optionally apply auto_disable_child_focus
	if nav_config and nav_config.auto_disable_child_focus and root_control:
		UIAnimationUtils.disable_focus_on_children(root_control)

	# If focus_on_ready is true, set initial focus
	if nav_config and nav_config.focus_on_ready:
		var initial_focus: Control = null
		if nav_config.default_focus:
			initial_focus = get_node(nav_config.default_focus) as Control
		if not initial_focus and root_control:
			# Fallback to first focusable control
			initial_focus = _find_first_focusable_control(root_control)

		if initial_focus:
			initial_focus.grab_focus()
			_update_current_focus_owner(initial_focus)

	_is_ready = true

## Validates configuration and updates editor state.
func update_configuration() -> void:
	if not Engine.is_editor_hint():
		return

	# Validate nav_config
	if nav_config:
		_validate_nav_config()
	else:
		# Clear any previous warnings if config is removed
		pass

	# Update property visibility based on mode
	notify_property_list_changed()

## Validates the NavigationConfig and shows warnings in editor.
func _validate_nav_config() -> void:
	if not nav_config:
		return

	# Check root_control path
	if nav_config.root_control:
		var root_node = get_node_or_null(nav_config.root_control)
		if not root_node:
			push_warning("ReactiveUINavigator: root_control path '%s' does not exist" % nav_config.root_control)
		elif not (root_node is Control):
			push_warning("ReactiveUINavigator: root_control must point to a Control node, got %s" % root_node.get_class())

	# Check default_focus path
	if nav_config.default_focus:
		var focus_node = get_node_or_null(nav_config.default_focus)
		if not focus_node:
			push_warning("ReactiveUINavigator: default_focus path '%s' does not exist" % nav_config.default_focus)
		elif not (focus_node is Control):
			push_warning("ReactiveUINavigator: default_focus must point to a Control node, got %s" % focus_node.get_class())

	# Check ordered_controls paths
	for i in range(nav_config.ordered_controls.size()):
		var path = nav_config.ordered_controls[i]
		if path and not get_node_or_null(path):
			push_warning("ReactiveUINavigator: ordered_controls[%d] path '%s' does not exist" % [i, path])

	# Check auto_disable_child_focus requires root_control
	if nav_config.auto_disable_child_focus:
		if not nav_config.root_control or nav_config.root_control.is_empty():
			push_warning("ReactiveUINavigator: auto_disable_child_focus requires root_control to be set")

	# Validate custom neighbors if enabled
	if nav_config.respect_custom_neighbors:
		# Check if root_control has custom neighbors (if it's a Control)
		if nav_config.root_control:
			var root_node = get_node_or_null(nav_config.root_control)
			if root_node is Control:
				var root_control = root_node as Control
				if NavigationUtils.has_custom_focus_neighbors(root_control):
					# Validate each neighbor exists and is a Control
					var neighbors = {
						"top": root_control.focus_neighbor_top,
						"bottom": root_control.focus_neighbor_bottom,
						"left": root_control.focus_neighbor_left,
						"right": root_control.focus_neighbor_right
					}

					for dir_name in neighbors:
						var neighbor_path: NodePath = neighbors[dir_name]
						if neighbor_path and not neighbor_path.is_empty():
							var neighbor = root_control.get_node_or_null(neighbor_path)
							if not neighbor:
								push_warning("ReactiveUINavigator: focus_neighbor_%s path '%s' does not exist" % [
									dir_name, neighbor_path
								])
							elif not (neighbor is Control):
								push_warning("ReactiveUINavigator: focus_neighbor_%s must point to a Control node, got %s" % [
									dir_name, neighbor.get_class()
								])

		# Also check default_focus if it's a Control with custom neighbors
		if nav_config.default_focus:
			var default_node = get_node_or_null(nav_config.default_focus)
			if default_node is Control:
				var default_control = default_node as Control
				if NavigationUtils.has_custom_focus_neighbors(default_control):
					var neighbors = {
						"top": default_control.focus_neighbor_top,
						"bottom": default_control.focus_neighbor_bottom,
						"left": default_control.focus_neighbor_left,
						"right": default_control.focus_neighbor_right
					}

					for dir_name in neighbors:
						var neighbor_path: NodePath = neighbors[dir_name]
						if neighbor_path and not neighbor_path.is_empty():
							var neighbor = default_control.get_node_or_null(neighbor_path)
							if not neighbor:
								push_warning("ReactiveUINavigator: default_focus has invalid focus_neighbor_%s path '%s'" % [
									dir_name, neighbor_path
								])
							elif not (neighbor is Control):
								push_warning("ReactiveUINavigator: default_focus has invalid focus_neighbor_%s type (got %s)" % [
									dir_name, neighbor.get_class()
								])


## Custom property list to show/hide properties based on mode.
func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []

	# Mode - always shown, at the top
	properties.append({
		"name": "mode",
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_STORAGE,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "None,Input Map,State-driven,Both"
	})

	# Input Profile - conditional, right after mode
	if mode == NavigationMode.INPUT_MAP or mode == NavigationMode.BOTH:
		properties.append({
			"name": "input_profile",
			"type": TYPE_OBJECT,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string": "NavigationInputProfile"
		})

	# Nav Config - always shown, after input_profile
	properties.append({
		"name": "nav_config",
		"type": TYPE_OBJECT,
		"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_STORAGE,
		"hint": PROPERTY_HINT_RESOURCE_TYPE,
		"hint_string": "NavigationConfig"
	})

	# Nav States - conditional, at the end
	if mode == NavigationMode.STATE_DRIVEN or mode == NavigationMode.BOTH:
		properties.append({
			"name": "nav_states",
			"type": TYPE_OBJECT,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string": "NavigationStateBundle"
	})

	return properties

func _unhandled_input(event: InputEvent) -> void:
	if not _is_ready or mode == NavigationMode.NONE:
		return

	# Handle INPUT_MAP and BOTH modes (BOTH mode bridges InputMap to State bundle)
	if (mode == NavigationMode.INPUT_MAP or mode == NavigationMode.BOTH) and input_profile:
		_handle_input_map_navigation(event)

func _process(_delta: float) -> void:
	if not _is_ready or mode == NavigationMode.NONE:
		return

	# Check if current focus owner became invisible and re-home focus if needed
	_check_focus_visibility()

	# Handle STATE_DRIVEN and BOTH modes
	if mode == NavigationMode.STATE_DRIVEN or mode == NavigationMode.BOTH:
		_process_state_navigation()

## Handles InputMap-based navigation input.
func _handle_input_map_navigation(event: InputEvent) -> void:
	if not input_profile:
		return

	# Handle digital actions first
	var action_pressed := ""
	var is_just_pressed := false

	# Check if this event corresponds to any configured navigation action
	for action in [input_profile.action_up, input_profile.action_down,
				   input_profile.action_left, input_profile.action_right,
				   input_profile.action_accept, input_profile.action_cancel]:
		if event.is_action(action):
			action_pressed = action
			is_just_pressed = event.is_pressed() and not event.is_echo()
			break

	if not action_pressed.is_empty():
		# Handle repeat logic for directional inputs
		if action_pressed in [input_profile.action_up, input_profile.action_down,
							 input_profile.action_left, input_profile.action_right]:
			_handle_directional_input(action_pressed, is_just_pressed)
		# Handle instant actions (submit/cancel)
		elif action_pressed == input_profile.action_accept and is_just_pressed:
			_queue_submit()
			submit_fired.emit(_current_focus_owner)
			# Mirror to state bundle in BOTH mode
			if mode == NavigationMode.BOTH and nav_states and nav_states.submit:
				nav_states.submit.value = true
				# Reset after brief delay to simulate button press
				await get_tree().create_timer(0.1).timeout
				if nav_states.submit:  # Check still exists
					nav_states.submit.value = false
		elif action_pressed == input_profile.action_cancel and is_just_pressed:
			_queue_cancel()
			cancel_fired.emit(_current_focus_owner)
			# Mirror to state bundle in BOTH mode
			if mode == NavigationMode.BOTH and nav_states and nav_states.cancel:
				nav_states.cancel.value = true
				# Reset after brief delay to simulate button press
				await get_tree().create_timer(0.1).timeout
				if nav_states.cancel:  # Check still exists
					nav_states.cancel.value = false
		return

	# Handle analog input (gamepad sticks)
	if event is InputEventJoypadMotion:
		var joy_event = event as InputEventJoypadMotion
		_handle_analog_input(joy_event)

## Handles directional input with repeat logic.
func _handle_directional_input(action: StringName, just_pressed: bool) -> void:
	var current_time := Time.get_ticks_msec() / 1000.0

	if not _repeat_state.has(action):
		_repeat_state[action] = {"pressed": false, "last_time": 0.0}

	var state = _repeat_state[action]

	if just_pressed:
		# First press - execute immediately
		state.pressed = true
		state.last_time = current_time
		_execute_directional_action(action)
		navigation_moved.emit(_get_direction_from_action(action))
	else:
		# Handle repeat while held
		if state.pressed:
			var time_since_last = current_time - state.last_time
			var threshold = input_profile.repeat_delay if state.last_time == current_time else input_profile.repeat_interval

			if time_since_last >= threshold:
				state.last_time = current_time
				_execute_directional_action(action)
				navigation_moved.emit(_get_direction_from_action(action))

## Executes the actual directional navigation action.
func _execute_directional_action(action: StringName) -> void:
	var direction := _get_direction_from_action(action)
	_queue_move(direction)

	# Mirror to state bundle in BOTH mode
	if mode == NavigationMode.BOTH and nav_states:
		if direction.x != 0 and nav_states.move_x:
			nav_states.move_x.value = sign(direction.x)
		if direction.y != 0 and nav_states.move_y:
			nav_states.move_y.value = sign(direction.y)

## Handles analog input from gamepad sticks.
func _handle_analog_input(event: InputEventJoypadMotion) -> void:
	# Map common gamepad axes to navigation directions
	var axis_value := event.axis_value
	var direction := Vector2.ZERO

	# Left stick horizontal (usually axis 0)
	if event.axis == JOY_AXIS_LEFT_X:
		if abs(axis_value) > input_profile.analog_deadzone:
			direction.x = sign(axis_value)
	# Left stick vertical (usually axis 1)
	elif event.axis == JOY_AXIS_LEFT_Y:
		if abs(axis_value) > input_profile.analog_deadzone:
			direction.y = sign(axis_value)

	# Right stick could be used for alternative navigation if desired
	# elif event.axis == JOY_AXIS_RIGHT_X:
	#     direction.x = sign(axis_value) if abs(axis_value) > input_profile.analog_deadzone else 0
	# elif event.axis == JOY_AXIS_RIGHT_Y:
	#     direction.y = sign(axis_value) if abs(axis_value) > input_profile.analog_deadzone else 0

	# Only process if we have a direction
	if direction != Vector2.ZERO:
		# Handle diagonals based on profile setting
		if not input_profile.allow_diagonals:
			# Clamp to single axis (prioritize larger magnitude)
			if abs(direction.x) > abs(direction.y):
				direction.y = 0
			else:
				direction.x = 0

		# Apply repeat logic to analog input
		_handle_analog_directional_input(direction)

## Handles directional input from analog sticks with repeat logic.
func _handle_analog_directional_input(direction: Vector2) -> void:
	var current_time := Time.get_ticks_msec() / 1000.0
	var axis_key := "analog_%s" % direction

	if not _repeat_state.has(axis_key):
		_repeat_state[axis_key] = {"pressed": false, "last_time": 0.0, "direction": direction}

	var state = _repeat_state[axis_key]

	# Check if direction changed
	if state.direction != direction:
		state.direction = direction
		state.pressed = true
		state.last_time = current_time
		_execute_analog_directional_action(direction)
		navigation_moved.emit(direction)
		return

	# Handle repeat while stick is held
	if state.pressed:
		var time_since_last = current_time - state.last_time
		var threshold = input_profile.repeat_delay if state.last_time == current_time else input_profile.repeat_interval

		if time_since_last >= threshold:
			state.last_time = current_time
			_execute_analog_directional_action(direction)
			navigation_moved.emit(direction)

## Executes analog directional navigation action.
func _execute_analog_directional_action(direction: Vector2) -> void:
	_queue_move(direction)

	# Mirror to state bundle in BOTH mode
	if mode == NavigationMode.BOTH and nav_states:
		if direction.x != 0 and nav_states.move_x:
			nav_states.move_x.value = sign(direction.x)
		if direction.y != 0 and nav_states.move_y:
			nav_states.move_y.value = sign(direction.y)

## Converts action name to direction vector.
func _get_direction_from_action(action: StringName) -> Vector2:
	if action == input_profile.action_up:
		return Vector2.UP
	elif action == input_profile.action_down:
		return Vector2.DOWN
	elif action == input_profile.action_left:
		return Vector2.LEFT
	elif action == input_profile.action_right:
		return Vector2.RIGHT
	return Vector2.ZERO

## Handles State-driven navigation input.
func _process_state_navigation() -> void:
	if not nav_states:
		return

	# Handle movement
	var move_x = nav_states.move_x.value if nav_states.move_x else 0
	var move_y = nav_states.move_y.value if nav_states.move_y else 0
	var current_move = Vector2(move_x, move_y)

	if current_move != Vector2.ZERO:
		_queue_move(current_move)
		navigation_moved.emit(current_move)

	# Handle submit/cancel with edge detection
	var submit_value = nav_states.submit.value if nav_states.submit else false
	var cancel_value = nav_states.cancel.value if nav_states.cancel else false

	if submit_value and not _prev_submit_value:
		_queue_submit()
		submit_fired.emit(_current_focus_owner)

	if cancel_value and not _prev_cancel_value:
		_queue_cancel()
		cancel_fired.emit(_current_focus_owner)

	# Handle page navigation with edge detection
	var page_next_value = nav_states.page_next.value if nav_states.page_next else false
	var page_prev_value = nav_states.page_prev.value if nav_states.page_prev else false

	if page_next_value and not _prev_page_next_value:
		_queue_page(1)
		page_changed.emit(1, _current_focus_owner)

	if page_prev_value and not _prev_page_prev_value:
		_queue_page(-1)
		page_changed.emit(-1, _current_focus_owner)

	_prev_submit_value = submit_value
	_prev_cancel_value = cancel_value
	_prev_page_next_value = page_next_value
	_prev_page_prev_value = page_prev_value

## Checks if the current focus owner is still visible and re-homes focus if not.
func _check_focus_visibility() -> void:
	if not _current_focus_owner:
		return

	# If current focus owner became invisible, find a new focus target
	if not _is_control_visible(_current_focus_owner):
		var new_focus = _find_replacement_focus()
		if new_focus:
			new_focus.grab_focus()
			_update_current_focus_owner(new_focus)
		else:
			# No suitable replacement found, clear focus
			_current_focus_owner = null

## Finds a replacement focus target when current focus becomes invalid.
func _find_replacement_focus() -> Control:
	# First try default focus from config
	if nav_config and nav_config.default_focus:
		var default_control = get_node_or_null(nav_config.default_focus) as Control
		if default_control and _is_control_visible(default_control) and default_control.focus_mode != Control.FOCUS_NONE:
			return default_control

	# Then try first focusable control in scope
	var candidates = _get_focusable_candidates()
	if not candidates.is_empty():
		return candidates[0]

	return null

## Updates the current focus owner and emits focus_changed signal.
func _update_current_focus_owner(new_focus: Control) -> void:
	var old_focus = _current_focus_owner
	_current_focus_owner = new_focus
	if old_focus != new_focus:
		focus_changed.emit(old_focus, new_focus)

## Queues a movement command.
func _queue_move(direction: Vector2) -> void:
	_process_move_command(direction)

## Queues a submit command.
func _queue_submit() -> void:
	_process_submit_command()

## Queues a cancel command.
func _queue_cancel() -> void:
	_process_cancel_command()

## Queues a page command (delta: +1 for next, -1 for previous).
func _queue_page(delta: int) -> void:
	_process_page_command(delta)

## Processes a movement command.
func _process_move_command(direction: Vector2) -> void:
	if debug_navigation:
		var direction_name = ""
		if direction.y < 0:
			direction_name = "UP"
		elif direction.y > 0:
			direction_name = "DOWN"
		elif direction.x < 0:
			direction_name = "LEFT"
		elif direction.x > 0:
			direction_name = "RIGHT"
		print("\n[NAV DEBUG] ========================================")
		print("[NAV DEBUG] MOVE COMMAND: %s" % direction_name)
		print("[NAV DEBUG] Current focus: %s" % _get_control_name(_current_focus_owner))
		print("[NAV DEBUG] ========================================\n")
	
	var next_control = _find_next_focusable_control(direction)
	
	if debug_navigation:
		print("[NAV DEBUG] Result from _find_next_focusable_control: %s" % _get_control_name(next_control))
	
	if next_control and next_control != _current_focus_owner:
		# Safety check: ensure control can actually receive focus (defensive programming)
		if next_control.focus_mode != Control.FOCUS_NONE:
			if debug_navigation:
				print("[NAV DEBUG] ✓ Moving focus to: %s" % _get_control_name(next_control))
		next_control.grab_focus()
		_update_current_focus_owner(next_control)
	else:
		if debug_navigation:
			print("[NAV DEBUG] ✗ Cannot move focus: target has FOCUS_NONE")
		else:
			if debug_navigation:
				if not next_control:
					print("[NAV DEBUG] ✗ No next control found")
				else:
					print("[NAV DEBUG] ✗ Next control is same as current, no movement")

## Processes a submit command.
func _process_submit_command() -> void:
	if not _current_focus_owner:
		return

	# Handle BaseButton types (Button, CheckBox, etc.)
	if _current_focus_owner is BaseButton:
		var button = _current_focus_owner as BaseButton
		button.pressed.emit()
		return

	# For other controls, simulate ui_accept
	var accept_event = InputEventAction.new()
	accept_event.action = "ui_accept"
	accept_event.pressed = true
	_current_focus_owner.gui_input.emit(accept_event)

## Processes a cancel command.
func _process_cancel_command() -> void:
	# Try to move focus back to default if configured
	if nav_config and nav_config.default_focus:
		var default_control = get_node(nav_config.default_focus) as Control
		if default_control and default_control != _current_focus_owner:
			default_control.grab_focus()
			_update_current_focus_owner(default_control)

## Processes a page command (delta: +1 for next page, -1 for previous page).
## This method handles the page navigation logic by emitting signals and invoking callbacks.
## The actual page/tab switching logic should be implemented in scene controllers
## or callback methods that respond to the page_changed signal.
func _process_page_command(_delta: int) -> void:
	# Page navigation is handled entirely through signals and callbacks.
	# The navigator does not directly mutate UI state - that responsibility
	# belongs to scene controllers or callback methods.
	# This keeps the navigator focused on navigation logic while allowing
	# flexible page management implementations.
	pass

## Finds the next focusable control in the given direction.
func _find_next_focusable_control(direction: Vector2) -> Control:
	if not _current_focus_owner or not nav_config:
		if debug_navigation:
			print("[NAV DEBUG] _find_next_focusable_control: No current focus owner or nav_config")
		return null

	if debug_navigation:
		print("[NAV DEBUG] --- _find_next_focusable_control ---")
		print("[NAV DEBUG] Current focus: %s" % _get_control_name(_current_focus_owner))
		print("[NAV DEBUG] respect_custom_neighbors: %s" % nav_config.respect_custom_neighbors)
		print("[NAV DEBUG] ordered_controls.size(): %d" % nav_config.ordered_controls.size())

	# Check custom neighbors first if enabled
	var custom_neighbor = _find_custom_neighbor_target(direction)
	if custom_neighbor:
		if debug_navigation:
			print("[NAV DEBUG] ✓ Using custom neighbor: %s (focus_mode: %s)" % [_get_control_name(custom_neighbor), _get_focus_mode_str(custom_neighbor.focus_mode)])
		# Validate focusability before returning
		if custom_neighbor.focus_mode == Control.FOCUS_NONE:
			if debug_navigation:
				print("[NAV DEBUG] ✗ WARNING: Custom neighbor has FOCUS_NONE, returning null")
			return null
		return custom_neighbor

	# If ordered controls are specified, use that logic (don't need candidates)
	if not nav_config.ordered_controls.is_empty():
		if debug_navigation:
			print("[NAV DEBUG] Using ordered_controls path")
		var result = _find_next_in_ordered_list(direction)
		if debug_navigation:
			if result:
				print("[NAV DEBUG] Ordered list returned: %s (focus_mode: %s)" % [_get_control_name(result), _get_focus_mode_str(result.focus_mode)])
			else:
				print("[NAV DEBUG] Ordered list returned: null")
		# Validate focusability before returning
		if result and result.focus_mode == Control.FOCUS_NONE:
			if debug_navigation:
				print("[NAV DEBUG] ✗ WARNING: Ordered list returned control with FOCUS_NONE, returning null")
			return null
		return result

	# Otherwise use directional heuristics (need candidates)
	var candidates = _get_focusable_candidates()

	if candidates.is_empty():
		if debug_navigation:
			print("[NAV DEBUG] No focusable candidates found")
		return null

	if debug_navigation:
		print("[NAV DEBUG] Found %d candidates" % candidates.size())
		print("[NAV DEBUG] Using position-based heuristics path")
	var result = _find_next_by_position(direction, candidates)
	if debug_navigation:
		if result:
			print("[NAV DEBUG] Position-based returned: %s (focus_mode: %s)" % [_get_control_name(result), _get_focus_mode_str(result.focus_mode)])
		else:
			print("[NAV DEBUG] Position-based returned: null")
	# Validate focusability before returning
	if result and result.focus_mode == Control.FOCUS_NONE:
		if debug_navigation:
			print("[NAV DEBUG] ✗ WARNING: Position-based returned control with FOCUS_NONE, returning null")
		return null
	return result

## Finds a custom neighbor target if one exists and is valid.
func _find_custom_neighbor_target(direction: Vector2) -> Control:
	if not nav_config.respect_custom_neighbors or not _current_focus_owner:
		return null

	if debug_navigation:
		print("[NAV DEBUG] Checking for custom neighbors on: %s" % _get_control_name(_current_focus_owner))

	var custom_neighbor = NavigationUtils.get_custom_focus_neighbor(_current_focus_owner, direction)
	if not custom_neighbor:
		if debug_navigation:
			print("[NAV DEBUG] No custom neighbor found in direction")
		return null

	if debug_navigation:
		print("[NAV DEBUG] ⚠ CUSTOM NEIGHBOR FOUND: %s (this will override ordered_controls!)" % _get_control_name(custom_neighbor))

	# Validate the custom neighbor is within scope and visible
	if not _is_control_visible(custom_neighbor):
		if debug_navigation:
			print("[NAV DEBUG] Custom neighbor is not visible, ignoring")
		return null

	var valid_candidates = _get_focusable_candidates()
	if custom_neighbor in valid_candidates:
		if debug_navigation:
			print("[NAV DEBUG] Custom neighbor is in valid candidates, using it")
		return custom_neighbor

	# If not in candidates but is valid, still allow it
	# (custom neighbors can override scope restrictions)
	if custom_neighbor.focus_mode != Control.FOCUS_NONE:
		if debug_navigation:
			print("[NAV DEBUG] Custom neighbor is focusable but not in candidates, using it anyway")
		return custom_neighbor

	if debug_navigation:
		print("[NAV DEBUG] Custom neighbor is not focusable, ignoring")
	return null

## Gets all focusable candidates within the navigation scope.
func _get_focusable_candidates() -> Array[Control]:
	var candidates: Array[Control] = []

	if not nav_config:
		if debug_navigation:
			print("[NAV DEBUG] _get_focusable_candidates: No nav_config")
		return candidates

	var root = get_node(nav_config.root_control) if nav_config.root_control else get_viewport()
	if not root:
		if debug_navigation:
			print("[NAV DEBUG] _get_focusable_candidates: Root node not found (path: %s)" % nav_config.root_control)
		return candidates

	if debug_navigation:
		print("[NAV DEBUG] _get_focusable_candidates: Starting search from root: %s" % _get_node_name(root))
		print("[NAV DEBUG]   restrict_to_focusable_children: %s" % nav_config.restrict_to_focusable_children)

	# Find all focusable controls in the scope
	_find_focusable_in_node(root, candidates)

	if debug_navigation:
		print("[NAV DEBUG] _get_focusable_candidates: Found %d focusable candidates" % candidates.size())
		for i in range(min(candidates.size(), 10)):  # Show first 10
			print("[NAV DEBUG]   [%d] %s (focus_mode: %s)" % [i, _get_control_name(candidates[i]), _get_focus_mode_str(candidates[i].focus_mode)])
		if candidates.size() > 10:
			print("[NAV DEBUG]   ... and %d more" % (candidates.size() - 10))

	return candidates

## Recursively finds focusable controls in a node tree.
func _find_focusable_in_node(node: Node, candidates: Array[Control]) -> void:
	if node is Control:
		var control = node as Control
		var is_visible = _is_control_visible(control)
		var is_focusable = control.focus_mode != Control.FOCUS_NONE
		
		if debug_navigation:
			print("[NAV DEBUG] _find_focusable_in_node: Checking %s" % _get_node_name(node))
			print("[NAV DEBUG]   visible: %s, focusable: %s, focus_mode: %s" % [is_visible, is_focusable, _get_focus_mode_str(control.focus_mode)])
		
		# Check visibility of control and all ancestors before considering focusability
		if is_visible:
			# Only add controls that are actually focusable
			# The restrict_to_focusable_children setting affects whether we traverse
			# into non-focusable containers, but we always filter to focusable controls
			if is_focusable:
				candidates.append(control)
				if debug_navigation:
					print("[NAV DEBUG]   ✓ Added to candidates")
			elif nav_config.restrict_to_focusable_children:
				# If restrict_to_focusable_children is true, don't traverse into
				# non-focusable containers (they're not candidates and we skip their children)
				if debug_navigation:
					print("[NAV DEBUG]   ✗ Skipping children (restrict_to_focusable_children=true)")
				return
		else:
			if debug_navigation:
				print("[NAV DEBUG]   ✗ Not visible, skipping")

	# Recursively check children (only if this node itself is visible)
	if node is Control and _is_control_visible(node as Control):
		# If restrict_to_focusable_children is true and this control is not focusable,
		# we already returned above, so we won't traverse children
		var children = node.get_children()
		if debug_navigation:
			print("[NAV DEBUG]   Traversing %d children" % children.size())
		for child in children:
			_find_focusable_in_node(child, candidates)

## Helper: Finds the next focusable control in ordered_controls starting from an index, with wrapping.
func _find_next_focusable_in_ordered_list(start_index: int, direction_int: int, wrap: bool) -> Control:
	if nav_config.ordered_controls.is_empty():
		if debug_navigation:
			print("[NAV DEBUG] ordered_controls is empty, returning null")
		return null
	
	var size = nav_config.ordered_controls.size()
	var checked = 0
	
	# Find first and last focusable indices for proper wrapping
	var first_focusable_index = -1
	var last_focusable_index = -1
	for i in range(size):
		var path = nav_config.ordered_controls[i]
		var control = get_node(path) as Control
		if control and control.focus_mode != Control.FOCUS_NONE:
			if first_focusable_index == -1:
				first_focusable_index = i
			last_focusable_index = i
	
	if debug_navigation:
		var direction_str = "UP/LEFT" if direction_int < 0 else "DOWN/RIGHT"
		print("[NAV DEBUG] === Starting ordered list search ===")
		print("[NAV DEBUG] Start index: %d" % start_index)
		print("[NAV DEBUG] Direction: %s (direction_int: %d)" % [direction_str, direction_int])
		print("[NAV DEBUG] Wrapping enabled: %s" % wrap)
		print("[NAV DEBUG] Total controls in list: %d" % size)
		print("[NAV DEBUG] First focusable index: %d, Last focusable index: %d" % [first_focusable_index, last_focusable_index])
		print("[NAV DEBUG] Current focus: %s (index %d)" % [_get_control_name(_current_focus_owner), start_index])
		print("[NAV DEBUG] Ordered controls list:")
		for i in range(size):
			var path = nav_config.ordered_controls[i]
			var control = get_node(path) as Control
			var focusable = control and control.focus_mode != Control.FOCUS_NONE
			var marker = " <-- CURRENT" if i == start_index else ""
			print("[NAV DEBUG]   [%d] %s -> %s (focusable: %s)%s" % [i, path, _get_control_name(control), focusable, marker])
	
	# Check if we're at a boundary and should wrap immediately
	var at_boundary = false
	if direction_int < 0:  # Going up/left
		at_boundary = (start_index == first_focusable_index)
	elif direction_int > 0:  # Going down/right
		at_boundary = (start_index == last_focusable_index)
	
	if at_boundary and wrap:
		if debug_navigation:
			print("[NAV DEBUG] At boundary of focusable items, wrapping immediately...")
		# Wrap to the opposite end (last focusable for up, first focusable for down)
		var target_index = last_focusable_index if direction_int < 0 else first_focusable_index
		var path = nav_config.ordered_controls[target_index]
		var control = get_node(path) as Control
		if control and control.focus_mode != Control.FOCUS_NONE:
			if debug_navigation:
				print("[NAV DEBUG] ✓ Wrapped to index %d: %s" % [target_index, _get_control_name(control)])
				print("[NAV DEBUG] === Search complete ===")
			return control
		# If wrapped target is not focusable (shouldn't happen), fall through to normal search
	
	# Normal search: start from the NEXT position (skip current item)
	var current_index = start_index + direction_int
	
	while checked < size:
		if debug_navigation:
			print("[NAV DEBUG] --- Step %d ---" % (checked + 1))
			print("[NAV DEBUG] Current index: %d" % current_index)
		
		# Check if we've gone out of bounds
		if current_index < 0 or current_index >= size:
			# Out of bounds - stop (wrapping already handled above if at boundary)
			if debug_navigation:
				print("[NAV DEBUG] Out of bounds, stopping search")
			break
		
		checked += 1
		
		var path = nav_config.ordered_controls[current_index]
		var control = get_node(path) as Control
		var is_focusable = control and control.focus_mode != Control.FOCUS_NONE
		
		if debug_navigation:
			print("[NAV DEBUG] Checking index %d: %s" % [current_index, path])
			print("[NAV DEBUG]   Control: %s" % _get_control_name(control))
			print("[NAV DEBUG]   Focusable: %s" % is_focusable)
			if control:
				print("[NAV DEBUG]   Focus mode: %s" % _get_focus_mode_str(control.focus_mode))
		
		if is_focusable:
			if debug_navigation:
				print("[NAV DEBUG] ✓ Found focusable control at index %d: %s" % [current_index, _get_control_name(control)])
				print("[NAV DEBUG] === Search complete ===")
			return control
		else:
			if debug_navigation:
				print("[NAV DEBUG] ✗ Control not focusable, continuing search...")
			# Move to next position
			current_index += direction_int
	
	if debug_navigation:
		print("[NAV DEBUG] ✗ No focusable control found after %d checks" % checked)
		print("[NAV DEBUG] === Search complete (no result) ===")
	
	return null

## Finds next control in ordered list based on direction.
func _find_next_in_ordered_list(direction: Vector2) -> Control:
	if not nav_config or nav_config.ordered_controls.is_empty():
		if debug_navigation:
			print("[NAV DEBUG] _find_next_in_ordered_list: nav_config or ordered_controls is empty")
		return null

	# Check if we should use ordered_controls for this direction
	var is_vertical = abs(direction.y) > abs(direction.x)
	if is_vertical and not nav_config.use_ordered_vertical:
		if debug_navigation:
			print("[NAV DEBUG] _find_next_in_ordered_list: Vertical movement but use_ordered_vertical is false, returning null")
		return null
	if not is_vertical and nav_config.use_ordered_vertical:
		if debug_navigation:
			print("[NAV DEBUG] _find_next_in_ordered_list: Horizontal movement but use_ordered_vertical is true, returning null")
		return null

	var current_index = -1
	if debug_navigation:
		print("[NAV DEBUG] Searching for current focus owner in ordered_controls...")
		print("[NAV DEBUG] Current focus owner: %s" % _get_control_name(_current_focus_owner))
	
	for i in range(nav_config.ordered_controls.size()):
		var path = nav_config.ordered_controls[i]
		var control = get_node(path) as Control
		if debug_navigation:
			print("[NAV DEBUG]   Checking index %d: path=%s, control=%s, matches=%s" % [i, path, _get_control_name(control), control == _current_focus_owner])
		if control == _current_focus_owner:
			current_index = i
			if debug_navigation:
				print("[NAV DEBUG] ✓ Found current focus at index %d" % current_index)
			break

	if current_index == -1:
		if debug_navigation:
			print("[NAV DEBUG] ✗ _find_next_in_ordered_list: Current focus owner not found in ordered_controls")
			print("[NAV DEBUG] Current focus: %s" % _get_control_name(_current_focus_owner))
			print("[NAV DEBUG] This will cause navigation to fail - check that ordered_controls includes the current focus")
		return null

	# Determine direction and wrapping
	var direction_int = 0
	var wrap = false
	var direction_name = ""
	if direction.y < 0:  # Up
		direction_int = -1
		wrap = nav_config.wrap_vertical
		direction_name = "UP"
	elif direction.y > 0:  # Down
		direction_int = 1
		wrap = nav_config.wrap_vertical
		direction_name = "DOWN"
	elif direction.x < 0:  # Left
		direction_int = -1
		wrap = nav_config.wrap_horizontal
		direction_name = "LEFT"
	elif direction.x > 0:  # Right
		direction_int = 1
		wrap = nav_config.wrap_horizontal
		direction_name = "RIGHT"
	
	if debug_navigation:
		print("[NAV DEBUG] ========================================")
		print("[NAV DEBUG] NAVIGATION REQUEST: %s" % direction_name)
		print("[NAV DEBUG] Direction vector: %s" % direction)
		print("[NAV DEBUG] use_ordered_vertical: %s" % nav_config.use_ordered_vertical)
		print("[NAV DEBUG] wrap_vertical: %s" % nav_config.wrap_vertical)
		print("[NAV DEBUG] wrap_horizontal: %s" % nav_config.wrap_horizontal)
		print("[NAV DEBUG] ========================================")

	# Use helper to find next focusable control
	return _find_next_focusable_in_ordered_list(current_index, direction_int, wrap)

## Finds next control by position-based heuristics.
func _find_next_by_position(direction: Vector2, candidates: Array[Control]) -> Control:
	if not _current_focus_owner:
		var first = candidates[0] if not candidates.is_empty() else null
		if debug_navigation:
			print("[NAV DEBUG] _find_next_by_position: No current focus, returning first candidate: %s" % _get_control_name(first))
		return first

	var current_pos = _current_focus_owner.get_global_rect().get_center()
	var best_candidate: Control = null
	var best_distance = INF
	var best_angle_diff = INF

	if debug_navigation:
		print("[NAV DEBUG] _find_next_by_position: Checking %d candidates" % candidates.size())

	for candidate in candidates:
		if candidate == _current_focus_owner:
			if debug_navigation:
				print("[NAV DEBUG]   Skipping current focus owner: %s" % _get_control_name(candidate))
			continue

		# Skip non-focusable candidates
		if candidate.focus_mode == Control.FOCUS_NONE:
			if debug_navigation:
				print("[NAV DEBUG]   Skipping non-focusable candidate: %s" % _get_control_name(candidate))
			continue

		var candidate_pos = candidate.get_global_rect().get_center()
		var to_candidate = candidate_pos - current_pos

		# Check if candidate is in the general direction (within 90 degrees)
		var angle_diff = abs(direction.angle_to(to_candidate))
		if angle_diff > PI/2:  # More than 90 degrees off
			if debug_navigation:
				print("[NAV DEBUG]   Skipping candidate (wrong direction): %s (angle_diff: %.2f)" % [_get_control_name(candidate), angle_diff])
			continue

		var distance = to_candidate.length()
		if angle_diff < best_angle_diff or (angle_diff == best_angle_diff and distance < best_distance):
			best_candidate = candidate
			best_distance = distance
			best_angle_diff = angle_diff
			if debug_navigation:
				print("[NAV DEBUG]   New best candidate: %s (distance: %.2f, angle: %.2f)" % [_get_control_name(candidate), distance, angle_diff])

	# If no candidate found, return null (position-based navigation stops at boundaries)
	# NOTE: Wrapping only works with ordered_controls, not position-based navigation.
	# Position-based navigation relies on spatial relationships, so wrapping doesn't make sense.
	# Use ordered_controls if you need wrapping behavior.
	if not best_candidate:
		if debug_navigation:
			print("[NAV DEBUG]   No candidate found in requested direction (position-based navigation stops at boundaries)")
		return null

	if debug_navigation:
		print("[NAV DEBUG] _find_next_by_position: Best candidate: %s" % _get_control_name(best_candidate))

	# Safety check: never return the current focus owner
	if best_candidate == _current_focus_owner:
		if debug_navigation:
			print("[NAV DEBUG] ✗ WARNING: Best candidate is current focus owner, returning null")
		return null

	return best_candidate

## Checks if a control is visible, including all its ancestors.
static func _is_control_visible(control: Control) -> bool:
	if not control.visible:
		return false

	# Check all ancestors for visibility
	var current = control.get_parent()
	while current:
		if current is Control and not (current as Control).visible:
			return false
		current = current.get_parent()

	return true

## Finds the first focusable control in a subtree.
func _find_first_focusable_control(root: Control) -> Control:
	var candidates: Array[Control] = []
	_find_focusable_in_node(root, candidates)

	for candidate in candidates:
		if candidate.focus_mode != Control.FOCUS_NONE:
			return candidate

	return null

## Auto-populates ordered_controls from focusable children under root_control.
## This is a helper method that can be called from editor tools.
func auto_populate_ordered_controls() -> void:
	if not nav_config or not nav_config.root_control:
		push_warning("ReactiveUINavigator: Cannot auto-populate - no root_control set in nav_config")
		return

	var root_node = get_node_or_null(nav_config.root_control)
	if not root_node:
		push_warning("ReactiveUINavigator: root_control path is invalid")
		return

	var candidates = _get_focusable_candidates()
	var paths: Array[NodePath] = []

	for candidate in candidates:
		if candidate != root_node:  # Don't include root itself
			var path = get_path_to(candidate)
			paths.append(path)

	nav_config.ordered_controls = paths
	print("ReactiveUINavigator: Auto-populated %d ordered controls" % paths.size())

## Helper function for debug output: Gets a readable name for a control.
func _get_control_name(control: Control) -> String:
	if not control:
		return "null"
	var control_name = control.name
	if control.get_parent():
		control_name = "%s/%s" % [control.get_parent().name, control_name]
	return control_name

## Helper function for debug output: Gets a readable name for a node (not just Control).
func _get_node_name(node: Node) -> String:
	if not node:
		return "null"
	var node_name = node.name
	if node.get_parent():
		node_name = "%s/%s" % [node.get_parent().name, node_name]
	return node_name

## Helper function for debug output: Gets a string representation of focus mode.
func _get_focus_mode_str(focus_mode: Control.FocusMode) -> String:
	match focus_mode:
		Control.FOCUS_NONE:
			return "FOCUS_NONE"
		Control.FOCUS_CLICK:
			return "FOCUS_CLICK"
		Control.FOCUS_ALL:
			return "FOCUS_ALL"
		_:
			return "UNKNOWN(%d)" % focus_mode

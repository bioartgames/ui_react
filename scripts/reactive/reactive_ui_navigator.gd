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

@export_group("Mode", "mode_")
@export var mode: NavigationMode = NavigationMode.INPUT_MAP:
	set(value):
		mode = value
		update_configuration()
		notify_property_list_changed()

@export var nav_config: NavigationConfig:
	set(value):
		nav_config = value
		update_configuration()

@export_group("Input (InputMap)", "input_profile_")
@export var input_profile: NavigationInputProfile

@export_group("Input (State-driven)", "nav_states_")
@export var nav_states: NavigationStateBundle

@export_group("Callbacks")
## Optional callback when submit action is triggered.
## Called with the currently focused control as the first argument.
@export var on_submit: Callable
## Optional callback when cancel action is triggered.
## Called with the currently focused control as the first argument.
@export var on_cancel: Callable

@export_group("Callbacks / Paging")
## Optional callback when page next action is triggered.
## Called with the currently focused control as the first argument.
@export var on_page_next: Callable
## Optional callback when page previous action is triggered.
## Called with the currently focused control as the first argument.
@export var on_page_prev: Callable

var _current_focus_owner: Control = null
var _is_ready: bool = false
var _repeat_state := {}  # internal structure for key repeat
var _prev_submit_value: bool = false
var _prev_cancel_value: bool = false
var _prev_page_next_value: bool = false
var _prev_page_prev_value: bool = false

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
		# Import and use AnimationUtilities.disable_focus_on_children if needed
		pass  # TODO: Implement once AnimationUtilities is available

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

## Custom property list to show/hide properties based on mode.
func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []

	# Add base properties
	properties.append({
		"name": "mode",
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "None,Input Map,State-driven,Both"
	})

	properties.append({
		"name": "nav_config",
		"type": TYPE_OBJECT,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_RESOURCE_TYPE,
		"hint_string": "NavigationConfig"
	})

	# Input (InputMap) group - only show for INPUT_MAP or BOTH modes
	if mode == NavigationMode.INPUT_MAP or mode == NavigationMode.BOTH:
		properties.append({
			"name": "input_profile",
			"type": TYPE_OBJECT,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string": "NavigationInputProfile"
		})

	# Input (State-driven) group - only show for STATE_DRIVEN or BOTH modes
	if mode == NavigationMode.STATE_DRIVEN or mode == NavigationMode.BOTH:
		properties.append({
			"name": "nav_states",
			"type": TYPE_OBJECT,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string": "NavigationStateBundle"
		})

	# Callbacks group - always show
	properties.append({
		"name": "on_submit",
		"type": TYPE_CALLABLE,
		"usage": PROPERTY_USAGE_DEFAULT
	})

	properties.append({
		"name": "on_cancel",
		"type": TYPE_CALLABLE,
		"usage": PROPERTY_USAGE_DEFAULT
	})

	properties.append({
		"name": "on_page_next",
		"type": TYPE_CALLABLE,
		"usage": PROPERTY_USAGE_DEFAULT
	})

	properties.append({
		"name": "on_page_prev",
		"type": TYPE_CALLABLE,
		"usage": PROPERTY_USAGE_DEFAULT
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
			if on_submit.is_valid():
				on_submit.call(_current_focus_owner)
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
			if on_cancel.is_valid():
				on_cancel.call(_current_focus_owner)
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
		if on_submit.is_valid():
			on_submit.call(_current_focus_owner)

	if cancel_value and not _prev_cancel_value:
		_queue_cancel()
		cancel_fired.emit(_current_focus_owner)
		if on_cancel.is_valid():
			on_cancel.call(_current_focus_owner)

	# Handle page navigation with edge detection
	var page_next_value = nav_states.page_next.value if nav_states.page_next else false
	var page_prev_value = nav_states.page_prev.value if nav_states.page_prev else false

	if page_next_value and not _prev_page_next_value:
		_queue_page(1)
		page_changed.emit(1, _current_focus_owner)
		if on_page_next.is_valid():
			on_page_next.call(_current_focus_owner)

	if page_prev_value and not _prev_page_prev_value:
		_queue_page(-1)
		page_changed.emit(-1, _current_focus_owner)
		if on_page_prev.is_valid():
			on_page_prev.call(_current_focus_owner)

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
	var next_control = _find_next_focusable_control(direction)
	if next_control and next_control != _current_focus_owner:
		next_control.grab_focus()
		_update_current_focus_owner(next_control)

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
		return null

	var candidates = _get_focusable_candidates()

	if candidates.is_empty():
		return null

	# If ordered controls are specified, use that logic
	if not nav_config.ordered_controls.is_empty():
		return _find_next_in_ordered_list(direction)

	# Otherwise use directional heuristics
	return _find_next_by_position(direction, candidates)

## Gets all focusable candidates within the navigation scope.
func _get_focusable_candidates() -> Array[Control]:
	var candidates: Array[Control] = []

	if not nav_config:
		return candidates

	var root = get_node(nav_config.root_control) if nav_config.root_control else get_viewport()
	if not root:
		return candidates

	# Find all focusable controls in the scope
	_find_focusable_in_node(root, candidates)

	return candidates

## Recursively finds focusable controls in a node tree.
func _find_focusable_in_node(node: Node, candidates: Array[Control]) -> void:
	if node is Control:
		var control = node as Control
		# Check visibility of control and all ancestors before considering focusability
		if _is_control_visible(control):
			if nav_config.restrict_to_focusable_children and control.focus_mode == Control.FOCUS_NONE:
				# Skip non-focusable controls if restriction is enabled
				pass
			else:
				candidates.append(control)

	# Recursively check children (only if this node itself is visible)
	if node is Control and _is_control_visible(node as Control):
		for child in node.get_children():
			_find_focusable_in_node(child, candidates)

## Finds next control in ordered list based on direction.
func _find_next_in_ordered_list(direction: Vector2) -> Control:
	if not nav_config or nav_config.ordered_controls.is_empty():
		return null

	var current_index = -1
	for i in range(nav_config.ordered_controls.size()):
		var path = nav_config.ordered_controls[i]
		var control = get_node(path) as Control
		if control == _current_focus_owner:
			current_index = i
			break

	if current_index == -1:
		return null

	var next_index = current_index
	if direction.y < 0:  # Up
		next_index -= 1
	elif direction.y > 0:  # Down
		next_index += 1
	elif direction.x < 0 and not nav_config.use_ordered_vertical:  # Left (if horizontal ordering)
		next_index -= 1
	elif direction.x > 0 and not nav_config.use_ordered_vertical:  # Right (if horizontal ordering)
		next_index += 1

	# Handle wrapping
	if next_index < 0:
		next_index = nav_config.ordered_controls.size() - 1 if nav_config.wrap_vertical else 0
	elif next_index >= nav_config.ordered_controls.size():
		next_index = 0 if nav_config.wrap_vertical else nav_config.ordered_controls.size() - 1

	var next_path = nav_config.ordered_controls[next_index]
	return get_node(next_path) as Control

## Finds next control by position-based heuristics.
func _find_next_by_position(direction: Vector2, candidates: Array[Control]) -> Control:
	if not _current_focus_owner:
		return candidates[0] if not candidates.is_empty() else null

	var current_pos = _current_focus_owner.get_global_rect().get_center()
	var best_candidate: Control = null
	var best_distance = INF
	var best_angle_diff = INF

	for candidate in candidates:
		if candidate == _current_focus_owner:
			continue

		var candidate_pos = candidate.get_global_rect().get_center()
		var to_candidate = candidate_pos - current_pos

		# Check if candidate is in the general direction (within 90 degrees)
		var angle_diff = abs(direction.angle_to(to_candidate))
		if angle_diff > PI/2:  # More than 90 degrees off
			continue

		var distance = to_candidate.length()
		if angle_diff < best_angle_diff or (angle_diff == best_angle_diff and distance < best_distance):
			best_candidate = candidate
			best_distance = distance
			best_angle_diff = angle_diff

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

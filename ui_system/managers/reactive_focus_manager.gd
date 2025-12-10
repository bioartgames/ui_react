## Focus order management (RefCounted).
## Manages focus order and focus state for a Control or navigation group.
class_name ReactiveFocusManager
extends RefCounted

## The owner Control that this manager is attached to.
var _owner: Control = null

## Array of NodePaths defining the focus order.
var _focus_order: Array[NodePath] = []

## Whether focus should wrap around.
var _wrap_around: bool = true

## Currently focused Control.
var _current_focus: Control = null

## Signal connections for cleanup.
var _signal_connections: Array[SignalConnection] = []

## Sets up the focus manager with the owner Control.
func setup(owner: Control) -> void:
	_owner = owner

## Sets the focus order for this manager.
func set_focus_order(order: Array[NodePath], wrap: bool = true) -> void:
	_focus_order = order.duplicate()
	_wrap_around = wrap

## Moves focus in the specified direction.
## Direction can be: "up", "down", "left", "right", "next", "previous"
## Returns true if focus was moved, false otherwise.
func move_focus(direction: String) -> bool:
	if _owner == null:
		return false
	
	# Get current focused control
	var current = _get_current_focused_control()
	
	# Find next/previous in focus order
	var next_index = _get_next_focus_index(current, direction)
	if next_index == -1:
		return false
	
	# Get the next control
	var next_path = _focus_order[next_index]
	if next_path == null or next_path.is_empty():
		return false
	
	var next_control = _owner.get_node_or_null(next_path)
	if next_control == null or not (next_control is Control):
		return false
	
	# Focus the next control
	next_control.grab_focus()
	_current_focus = next_control
	
	return true

## Gets the current focused control in the focus order.
func _get_current_focused_control() -> Control:
	# Check if we have a tracked current focus
	if _current_focus != null and is_instance_valid(_current_focus):
		if _current_focus.has_focus():
			return _current_focus
	
	# Find which control in focus order has focus
	for path in _focus_order:
		if path == null or path.is_empty():
			continue
		var control = _owner.get_node_or_null(path)
		if control != null and control is Control:
			if control.has_focus():
				_current_focus = control
				return control
	
	return null

## Gets the next focus index based on direction.
func _get_next_focus_index(current: Control, direction: String) -> int:
	if _focus_order.is_empty():
		return -1
	
	# Find current index
	var current_index = -1
	if current != null:
		for i in range(_focus_order.size()):
			var path = _focus_order[i]
			if path == null or path.is_empty():
				continue
			var control = _owner.get_node_or_null(path)
			if control == current:
				current_index = i
				break
	
	# Determine next index based on direction
	var next_index = -1
	match direction:
		"next", "down", "right":
			if current_index == -1:
				next_index = 0
			else:
				next_index = current_index + 1
				if next_index >= _focus_order.size():
					if _wrap_around:
						next_index = 0
					else:
						return -1
		"previous", "up", "left":
			if current_index == -1:
				next_index = _focus_order.size() - 1
			else:
				next_index = current_index - 1
				if next_index < 0:
					if _wrap_around:
						next_index = _focus_order.size() - 1
					else:
						return -1
		_:
			return -1
	
	return next_index

## Adds a control to the focus order.
func add_control(control: Control) -> void:
	if control == null:
		return
	if _owner == null:
		return
	
	# Get path relative to owner
	var path = _owner.get_path_to(control)
	if path == null or path.is_empty():
		return
	
	# Add if not already in order
	if not _focus_order.has(path):
		_focus_order.append(path)

## Removes a control from the focus order.
func remove_control(control: Control) -> void:
	if control == null:
		return
	if _owner == null:
		return
	
	# Get path relative to owner
	var path = _owner.get_path_to(control)
	if path == null or path.is_empty():
		return
	
	# Remove from order
	_focus_order.erase(path)
	
	# Clear current focus if it was this control
	if _current_focus == control:
		_current_focus = null

## Gets the focus order array.
func get_focus_order() -> Array[NodePath]:
	return _focus_order.duplicate()

## Gets the currently focused control.
func get_focused_control() -> Control:
	return _get_current_focused_control()

## Gets the owner Control.
func get_owner() -> Control:
	return _owner

## Cleans up the focus manager.
func cleanup() -> void:
	# Cleanup signal connections
	ReactiveLifecycleManager.cleanup_signal_connections(_signal_connections)
	
	# Clear references
	_owner = null
	_current_focus = null
	_focus_order.clear()


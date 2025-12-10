## Navigation orchestrator Node.
## Manages multiple navigation groups and delegates to specialized handlers.
## Recommended as autoload singleton.
extends Node
class_name ReactiveNavigation

## Dictionary of navigation groups (name -> ReactiveNavigationGroup).
var _navigation_groups: Dictionary = {}  # Dictionary[String, ReactiveNavigationGroup]

## Current active navigation group name.
var current_group: String = ""

## Focus manager for the current group.
var _focus_manager: ReactiveFocusManager = null

## Input handler for processing input.
var _input_handler: ReactiveInputHandler = null

## Signal connections for cleanup.
var _signal_connections: Array[SignalConnection] = []

func _ready() -> void:
	# Create focus manager and input handler
	_focus_manager = ReactiveFocusManager.new()
	# Setup focus manager with scene root as owner (for resolving NodePaths)
	# We'll set it up when the scene is ready
	call_deferred("_setup_focus_manager")
	_input_handler = ReactiveInputHandler.new()
	_input_handler.setup(_focus_manager)

## Sets up focus manager with scene root.
func _setup_focus_manager() -> void:
	if _focus_manager == null:
		return
	
	var scene_root = get_tree().current_scene if get_tree() != null else null
	if scene_root != null and scene_root is Control:
		_focus_manager.setup(scene_root)
	else:
		# Find first Control node in scene tree to use as owner
		var control = _find_control_in_scene()
		if control != null:
			_focus_manager.setup(control)

## Finds a Control node in the scene tree to use as owner.
func _find_control_in_scene() -> Control:
	var scene_root = get_tree().current_scene if get_tree() != null else null
	if scene_root == null:
		return null
	
	# Try to find a Control node (prefer scene root if it's a Control)
	if scene_root is Control:
		return scene_root
	
	# Search for first Control node
	var queue = [scene_root]
	while not queue.is_empty():
		var node = queue.pop_front()
		if node is Control:
			return node
		for child in node.get_children():
			queue.append(child)
	
	return null

func _process(_delta: float) -> void:
	# Process input for navigation
	if _input_handler != null:
		_input_handler.process_input()

## Registers a navigation group.
func register_group(group: ReactiveNavigationGroup) -> void:
	if group == null:
		return
	if group.name.is_empty():
		return
	
	_navigation_groups[group.name] = group
	
	# If no current group, set this as current
	if current_group.is_empty():
		current_group = group.name
		_update_focus_manager()

## Unregisters a navigation group.
func unregister_group(group_name: String) -> void:
	if group_name.is_empty():
		return
	
	_navigation_groups.erase(group_name)
	
	# If this was the current group, switch to another or clear
	if current_group == group_name:
		if not _navigation_groups.is_empty():
			current_group = _navigation_groups.keys()[0]
			_update_focus_manager()
		else:
			current_group = ""
			if _focus_manager != null:
				_focus_manager.set_focus_order([], false)

## Switches to a different navigation group.
func switch_group(group_name: String) -> bool:
	if not _navigation_groups.has(group_name):
		return false
	
	current_group = group_name
	_update_focus_manager()
	return true

## Gets all registered navigation group names.
## Used by editor plugins to populate dropdowns.
func get_group_names() -> Array[String]:
	return _navigation_groups.keys()

## Updates the focus manager with the current group's focus order.
func _update_focus_manager() -> void:
	if _focus_manager == null:
		return
	
	if current_group.is_empty():
		_focus_manager.set_focus_order([], false)
		return
	
	var nav_group = _navigation_groups.get(current_group)
	if nav_group == null:
		_focus_manager.set_focus_order([], false)
		return
	
	# Set focus order from group
	_focus_manager.set_focus_order(nav_group.focus_order, nav_group.wrap_around)

## Registers a control with a navigation group.
## This is called automatically by ReactiveControl on _ready().
func register_control(control: Control, group_name: String) -> void:
	if control == null:
		return
	
	# If group doesn't exist, create it
	if not _navigation_groups.has(group_name):
		var new_group = ReactiveNavigationGroup.new()
		new_group.name = group_name
		new_group.focus_order = []
		new_group.wrap_around = true
		_navigation_groups[group_name] = new_group
	
	var nav_group = _navigation_groups[group_name]
	if nav_group == null:
		return
	
	# Get path relative to scene root (or a common parent)
	var path = _get_control_path(control)
	if path == null or path.is_empty():
		return
	
	# Add to focus order if not already present
	if not nav_group.focus_order.has(path):
		nav_group.focus_order.append(path)
	
	# Update focus manager if this is the current group
	if current_group == group_name:
		_update_focus_manager()

## Unregisters a control from a navigation group.
func unregister_control(control: Control, group_name: String) -> void:
	if control == null:
		return
	
	if not _navigation_groups.has(group_name):
		return
	
	var nav_group = _navigation_groups[group_name]
	if nav_group == null:
		return
	
	# Get path and remove from focus order
	var path = _get_control_path(control)
	if path != null and not path.is_empty():
		nav_group.focus_order.erase(path)
	
	# Update focus manager if this is the current group
	if current_group == group_name:
		_update_focus_manager()

## Gets the path to a control relative to scene root.
func _get_control_path(control: Control) -> NodePath:
	if control == null:
		return NodePath()
	
	# Try to get path relative to scene root
	var scene_root = get_tree().current_scene
	if scene_root != null:
		return scene_root.get_path_to(control)
	
	# Fallback: use absolute path
	return control.get_path()

## Moves focus in the specified direction within the current group.
func move_focus(direction: String) -> bool:
	if _focus_manager == null:
		return false
	return _focus_manager.move_focus(direction)

## Cleans up navigation system.
func cleanup() -> void:
	# Cleanup handlers
	if _input_handler != null:
		_input_handler.cleanup()
		_input_handler = null
	
	if _focus_manager != null:
		_focus_manager.cleanup()
		_focus_manager = null
	
	# Cleanup signal connections
	ReactiveLifecycleManager.cleanup_signal_connections(_signal_connections)
	
	# Clear groups
	_navigation_groups.clear()
	current_group = ""

func _exit_tree() -> void:
	cleanup()


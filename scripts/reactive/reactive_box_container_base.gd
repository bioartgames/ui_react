@tool
extends RefCounted
class_name ReactiveBoxContainerBase

## Helper class for shared ReactiveVBoxContainer and ReactiveHBoxContainer logic.
## Uses composition pattern to avoid inheritance conflicts with Godot container inheritance.
##
## This class provides shared functionality for setting up focus neighbor wrapping
## in box containers, allowing VBox and HBox to share common logic while maintaining
## their respective Container type inheritance.

## Gets the appropriate focus target for a child control.
## [param child]: The child control to get focus target for.
## [param get_first]: If true, returns first focusable; if false, returns last focusable.
## [return]: The focusable control to link to, or null if none found.
static func get_focusable_target(child: Control, get_first: bool) -> Control:
	# Check if child is an enterable container
	if is_enterable_container(child):
		var focusable_controls = NavigationUtils.find_focusable_controls(child, true)
		if focusable_controls.is_empty():
			return child
		if get_first:
			return focusable_controls[0]
		else:
			return focusable_controls[focusable_controls.size() - 1]
	return child

## Checks if a child is an enterable container (can be navigated into).
## [param child]: The child control to check.
## [return]: true if the child is an enterable container.
static func is_enterable_container(child: Control) -> bool:
	# Check for known enterable containers
	if child is ReactiveVBoxContainer or child is ReactiveHBoxContainer:
		return true
	# Future: Check for interface/contract if we add one
	# For now, this is extensible by overriding in subclasses
	return false

## Sets up focus neighbors for a control based on direction.
## [param control]: The control to set neighbors on.
## [param target]: The target control to link to (or null to clear).
## [param direction]: Direction string ("top", "bottom", "left", "right").
static func set_focus_neighbor(
	control: Control,
	target: Control,
	direction: String
) -> void:
	var path = control.get_path_to(target) if target else NodePath("")
	match direction:
		"top":
			control.focus_neighbor_top = path
		"bottom":
			control.focus_neighbor_bottom = path
		"left":
			control.focus_neighbor_left = path
		"right":
			control.focus_neighbor_right = path

## Sets up wrapping for a container's children.
## [param container]: The container to set up wrapping for.
## [param get_sibling_targets_func]: Callable that returns sibling targets for a given index.
##   Should return Dictionary with keys: "previous", "next", "wrap_previous", "wrap_next".
## [param apply_neighbors_to_child_func]: Callable that applies neighbors to a child.
##   Signature: func(child: Control, targets: Dictionary) -> void
## [param apply_neighbors_to_inner_func]: Callable that applies neighbors to inner first/last.
##   Signature: func(first_in: Control, last_in: Control, targets: Dictionary) -> void
static func setup_wrapping(
	container: Container,
	get_sibling_targets_func: Callable,
	apply_neighbors_to_child_func: Callable,
	apply_neighbors_to_inner_func: Callable
) -> void:
	var children: Array[Control] = []
	for child in container.get_children():
		if child is Control:
			children.append(child as Control)
	
	if children.size() < 2:
		return
	
	for i in range(children.size()):
		var current = children[i]
		var targets = get_sibling_targets_func.call(children, i, false)
		
		# Set neighbors on direct child
		apply_neighbors_to_child_func.call(current, targets)
		
		# Set inner first/last for enterable containers
		if is_enterable_container(current):
			var first_in = get_focusable_target(current, true)
			var last_in = get_focusable_target(current, false)
			apply_neighbors_to_inner_func.call(first_in, last_in, targets)

## Sets up initial focus for a container.
## [param container]: The container to set up initial focus for.
## [param default_focus]: NodePath to the default focus control.
## [param focus_on_ready]: Whether to grab focus on ready.
static func setup_initial_focus(
	container: Container,
	default_focus: NodePath,
	focus_on_ready: bool
) -> void:
	if not focus_on_ready:
		return
	
	var initial_focus: Control = null
	if default_focus and not default_focus.is_empty():
		initial_focus = container.get_node_or_null(default_focus) as Control
	if not initial_focus and container.get_child_count() > 0:
		var first_child = container.get_child(0)
		if first_child is Control:
			initial_focus = first_child as Control
	
	if initial_focus and initial_focus.focus_mode != Control.FOCUS_NONE:
		initial_focus.grab_focus()

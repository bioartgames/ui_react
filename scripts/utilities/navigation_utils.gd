## Utility functions for UI navigation logic.
##
## This class provides stateless helper functions for common navigation operations
## such as finding focusable controls, position-based heuristics, and scope filtering.
extends RefCounted
class_name NavigationUtils

## Finds all focusable controls within a given root node.
static func find_focusable_controls(root: Node, restrict_to_focusable: bool = true) -> Array[Control]:
	var candidates: Array[Control] = []
	_find_focusable_in_node(root, candidates, restrict_to_focusable)
	return candidates

## Recursively finds focusable controls in a node tree.
static func _find_focusable_in_node(node: Node, candidates: Array[Control], restrict_to_focusable: bool) -> void:
	if node is Control:
		var control = node as Control
		if not restrict_to_focusable or control.focus_mode != Control.FOCUS_NONE:
			candidates.append(control)

	# Recursively check children
	for child in node.get_children():
		_find_focusable_in_node(child, candidates, restrict_to_focusable)

## Finds the closest control in a given direction using position-based heuristics.
static func find_closest_in_direction(current: Control, candidates: Array[Control], direction: Vector2) -> Control:
	if not current:
		return candidates[0] if not candidates.is_empty() else null

	var current_pos = current.get_global_rect().get_center()
	var best_candidate: Control = null
	var best_distance = INF
	var best_angle_diff = INF

	for candidate in candidates:
		if candidate == current:
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

## Gets the custom focus neighbor for a control in the given direction.
## Returns the control specified by focus_neighbor_* properties, or null if not set.
## [param control]: The control to get neighbor for.
## [param direction]: Direction vector (normalized or not).
## [return]: The neighbor control, or null if not configured.
static func get_custom_focus_neighbor(control: Control, direction: Vector2) -> Control:
	if not control:
		return null

	# Normalize direction to determine which neighbor property to check
	var normalized_dir = direction.normalized()
	var threshold = 0.5  # Threshold for diagonal detection

	# Determine primary direction (prioritize larger component)
	var neighbor_path: NodePath
	if abs(normalized_dir.y) > abs(normalized_dir.x):
		# Vertical movement
		if normalized_dir.y < -threshold:  # Up
			neighbor_path = control.focus_neighbor_top
		elif normalized_dir.y > threshold:  # Down
			neighbor_path = control.focus_neighbor_bottom
	else:
		# Horizontal movement
		if normalized_dir.x < -threshold:  # Left
			neighbor_path = control.focus_neighbor_left
		elif normalized_dir.x > threshold:  # Right
			neighbor_path = control.focus_neighbor_right

	# Resolve the NodePath to get the actual Control
	if neighbor_path and not neighbor_path.is_empty():
		var neighbor = control.get_node_or_null(neighbor_path)
		if neighbor is Control:
			return neighbor as Control

	return null

## Checks if a control has custom focus neighbors configured.
## [param control]: The control to check.
## [return]: true if any focus_neighbor_* property is set.
static func has_custom_focus_neighbors(control: Control) -> bool:
	if not control:
		return false

	# Check all four directions using focus_neighbor_* properties directly
	return (
		control.focus_neighbor_top != null and not control.focus_neighbor_top.is_empty() or
		control.focus_neighbor_bottom != null and not control.focus_neighbor_bottom.is_empty() or
		control.focus_neighbor_left != null and not control.focus_neighbor_left.is_empty() or
		control.focus_neighbor_right != null and not control.focus_neighbor_right.is_empty()
	)

## Returns true if the event is a "pressed" accept input (Enter, Space, A, or ui_accept action).
## [param event]: The input event to check.
## [return]: true if the event represents an accept/confirm action.
static func is_accept_event(event: InputEvent) -> bool:
	if event is InputEventAction:
		var ae = event as InputEventAction
		return ae.pressed and ae.action == "ui_accept"
	if event is InputEventKey:
		var ke = event as InputEventKey
		return ke.pressed and not ke.echo and ke.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]
	if event is InputEventJoypadButton:
		var jb = event as InputEventJoypadButton
		# South = 0 = A (Xbox) / Cross (PlayStation) = accept
		return jb.pressed and not jb.echo and jb.button_index == 0
	return false

## Returns true if the event is a "pressed" cancel input (Escape, B, or ui_cancel action).
## [param event]: The input event to check.
## [return]: true if the event represents a cancel/back action.
static func is_cancel_event(event: InputEvent) -> bool:
	if event is InputEventAction:
		var ae = event as InputEventAction
		return ae.pressed and ae.action == "ui_cancel"
	if event is InputEventKey:
		var ke = event as InputEventKey
		return ke.pressed and not ke.echo and ke.keycode == KEY_ESCAPE
	if event is InputEventJoypadButton:
		var jb = event as InputEventJoypadButton
		# East = 1 = B (Xbox) / Circle (PlayStation) = cancel
		return jb.pressed and not jb.echo and jb.button_index == 1
	return false

## Sets up focus neighbor chain for a list of controls with wrapping.
## [param focus_chain]: Array of Controls to chain together.
## [param wrap_vertical]: If true, sets up top/bottom neighbors with wrapping.
## [param wrap_horizontal]: If true, sets up left/right neighbors with wrapping.
static func setup_focus_chain(
	focus_chain: Array[Control],
	wrap_vertical: bool = false,
	wrap_horizontal: bool = false
) -> void:
	if focus_chain.size() < 2:
		return  # Need at least 2 items for a chain
	
	for i in range(focus_chain.size()):
		var current = focus_chain[i]
		
		if wrap_vertical:
			# Top neighbor (previous item, or wrap to last)
			if i > 0:
				current.focus_neighbor_top = current.get_path_to(focus_chain[i - 1])
			else:
				current.focus_neighbor_top = current.get_path_to(focus_chain[focus_chain.size() - 1])
			
			# Bottom neighbor (next item, or wrap to first)
			if i < focus_chain.size() - 1:
				current.focus_neighbor_bottom = current.get_path_to(focus_chain[i + 1])
			else:
				current.focus_neighbor_bottom = current.get_path_to(focus_chain[0])
		
		if wrap_horizontal:
			# Left neighbor (previous item, or wrap to last)
			if i > 0:
				current.focus_neighbor_left = current.get_path_to(focus_chain[i - 1])
			else:
				current.focus_neighbor_left = current.get_path_to(focus_chain[focus_chain.size() - 1])
			
			# Right neighbor (next item, or wrap to first)
			if i < focus_chain.size() - 1:
				current.focus_neighbor_right = current.get_path_to(focus_chain[i + 1])
			else:
				current.focus_neighbor_right = current.get_path_to(focus_chain[0])

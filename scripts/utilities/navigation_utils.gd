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

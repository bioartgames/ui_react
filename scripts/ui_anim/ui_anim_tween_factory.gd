## Tween and layout helpers for UI animations (extracted from UiAnimUtils).
class_name UiAnimTweenFactory
extends RefCounted

const PIVOT_CENTER_MULTIPLIER := 0.5

## Creates a tween with null checking and error handling.
static func create_safe_tween(node: Node) -> Tween:
	if not node:
		push_warning("UiAnimTweenFactory.create_safe_tween(): Cannot create tween - node is null.")
		return null
	var t = node.create_tween()
	if not t:
		push_warning("UiAnimTweenFactory.create_safe_tween(): Failed to create tween on node '%s'." % node.name)
	return t

## Calculates the center X position of a node relative to the viewport.
static func get_node_center(source_node: Node, target: Control) -> float:
	if not source_node or not target:
		var source_name: String = "null"
		var target_name: String = "null"
		if source_node != null:
			source_name = source_node.name
		if target != null:
			target_name = target.name
		push_warning("UiAnimTweenFactory.get_node_center(): Invalid source_node (%s) or target (%s)." % [source_name, target_name])
		return 0.0

	var viewport = source_node.get_viewport()
	if not viewport:
		push_warning("UiAnimTweenFactory.get_node_center(): source_node '%s' has no viewport." % source_node.name)
		return 0.0

	return (viewport.get_visible_rect().size.x * PIVOT_CENTER_MULTIPLIER) - (target.size.x * PIVOT_CENTER_MULTIPLIER)

## Calculates the pivot offset to center a control for scale animations.
static func get_center_pivot_offset(target: Control) -> Vector2:
	if not target:
		return Vector2.ZERO
	return Vector2(target.size.x * PIVOT_CENTER_MULTIPLIER, target.size.y * PIVOT_CENTER_MULTIPLIER)

## Calculates center Y for vertical centering animations.
static func get_node_center_y(source_node: Node, target: Control) -> float:
	if not source_node or not target:
		push_warning("UiAnimTweenFactory.get_node_center_y(): Invalid source_node or target.")
		return 0.0

	var viewport = source_node.get_viewport()
	if not viewport:
		push_warning("UiAnimTweenFactory.get_node_center_y(): source_node '%s' has no viewport." % source_node.name)
		return 0.0

	return (viewport.get_visible_rect().size.y * PIVOT_CENTER_MULTIPLIER) - (target.size.y * PIVOT_CENTER_MULTIPLIER)

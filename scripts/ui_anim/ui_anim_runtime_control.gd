## Global animation stop / interrupt helpers (extracted from [UiAnimUtils]).
class_name UiAnimRuntimeControl
extends RefCounted


static func stop_all_animations(source_node: Node, target: Control) -> void:
	if not source_node or not target:
		return

	var nodes_to_check: Array[Node] = [target]
	var checked_nodes: Dictionary = {}

	while nodes_to_check.size() > 0:
		var current_node = nodes_to_check.pop_front()
		if current_node == null or checked_nodes.has(current_node):
			continue
		checked_nodes[current_node] = true

		for child in current_node.get_children():
			if child.has_meta("_is_animation_loop_helper"):
				if child.has_method("stop"):
					child.call("stop")
			elif child.has_method("execute_sequence"):
				child.queue_free()

			nodes_to_check.append(child)

	var scene_tree = source_node.get_tree()
	if scene_tree:
		var temp_tween = source_node.create_tween()
		if temp_tween:
			temp_tween.kill()

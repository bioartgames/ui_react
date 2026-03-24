## Delay utilities for animation sequencing (extracted from UiAnimUtils).
class_name UiAnimDelayHelpers
extends RefCounted

## Creates a delay signal that can be awaited in animation sequences.
static func delay(source_node: Node, duration: float) -> Signal:
	if not source_node:
		push_warning("UiAnimDelayHelpers: Invalid source_node for delay")
		return Signal()

	var tree = source_node.get_tree()
	if not tree:
		push_warning("UiAnimDelayHelpers: source_node has no tree")
		return Signal()

	return tree.create_timer(duration).timeout

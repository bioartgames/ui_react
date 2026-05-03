## Stable node id strings aligned with [UiReactExplainGraphBuilder] / Dependency Graph snapshots.
class_name UiReactGraphNodeIds
extends RefCounted


static func control_id(host_path: NodePath) -> String:
	return "ctrl:%s" % str(host_path)


static func host_path_from_root(root: Node, node: Node) -> NodePath:
	if root == null or node == null:
		return NodePath()
	if node == root:
		return NodePath()
	if root.is_ancestor_of(node):
		return root.get_path_to(node)
	return NodePath(String(node.get_path()))


## Returns [code]state:…[/code] segment only (no mutation). Empty if [code]st[/code] null.
static func state_stable_id(host_path: NodePath, context_seg: String, st: UiState) -> String:
	if st == null:
		return ""
	var rp := st.resource_path
	if not rp.is_empty():
		return "state:%s" % rp
	return "state:emb:%s#%s#%d" % [str(host_path), context_seg, st.get_instance_id()]


static func state_display_label(host_path: NodePath, context_seg: String, st: UiState) -> String:
	if st == null:
		return ""
	var rp := st.resource_path
	if not rp.is_empty():
		return rp.get_file()
	return "embedded %s @ %s" % [context_seg, str(host_path)]


static func state_snapshot_extra(host_path: NodePath, context_seg: String, st: UiState) -> Dictionary:
	if st == null:
		return {}
	var rp := st.resource_path
	var extra: Dictionary = {}
	if not rp.is_empty():
		extra[&"state_file_path"] = rp
	else:
		extra[&"embedded_host_path"] = str(host_path)
		extra[&"embedded_context"] = context_seg
	return extra

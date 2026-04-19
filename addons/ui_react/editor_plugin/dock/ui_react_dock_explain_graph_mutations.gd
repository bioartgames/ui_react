## Small graph/details helpers split from [UiReactDockExplainPanel] (edge tokens, snapshot queries).
class_name UiReactDockExplainGraphMutations
extends RefCounted


static func edge_short_token(kind: int) -> String:
	match kind:
		UiReactExplainGraphSnapshot.EdgeKind.BINDING:
			return "bind"
		UiReactExplainGraphSnapshot.EdgeKind.COMPUTED_SOURCE:
			return "computed"
		UiReactExplainGraphSnapshot.EdgeKind.WIRE_FLOW:
			return "wire"
	return "edge"


static func snapshot_has_node_id(snap: Variant, node_id: String) -> bool:
	if snap == null or node_id.is_empty():
		return false
	var g: UiReactExplainGraphSnapshot = snap as UiReactExplainGraphSnapshot
	for nd: Variant in g.nodes:
		if nd is Dictionary and str((nd as Dictionary).get(&"id", "")) == node_id:
			return true
	return false


static func incident_edge_sig(ed: Dictionary) -> String:
	return "%s|%s|%d|%s" % [
		str(ed.get(&"from_id", "")),
		str(ed.get(&"to_id", "")),
		int(ed.get(&"kind", -1)),
		str(ed.get(&"label", "")),
	]

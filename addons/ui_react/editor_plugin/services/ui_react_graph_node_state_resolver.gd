## Maps Dependency Graph node ids ([UiReactExplainGraphBuilder]) to live [UiState] on the edited scene (**CB-058** step 2 canvas reconnect).
class_name UiReactGraphNodeStateResolver
extends RefCounted

const _WireIoScript := preload("res://addons/ui_react/editor_plugin/services/ui_react_wire_rule_introspection.gd")


static func try_resolve_uistate(root: Node, node_id: String, node_by_id: Dictionary) -> UiState:
	if root == null or node_id.is_empty():
		return null
	var d: Dictionary = node_by_id.get(node_id, {}) as Dictionary
	if d.is_empty():
		return null
	var fp := str(d.get(&"state_file_path", ""))
	if not fp.is_empty():
		var res: Resource = load(fp)
		return res as UiState if res is UiState else null
	var hp := str(d.get(&"embedded_host_path", ""))
	var ctx := str(d.get(&"embedded_context", ""))
	if hp.is_empty():
		return null
	if not root.has_node(NodePath(hp)):
		return null
	var hn: Node = root.get_node(NodePath(hp))
	if not (hn is Control):
		return null
	var host := hn as Control
	var want_id := _parse_emb_instance_id(node_id)
	if ctx == "wire.in" or ctx == "wire.out":
		return _find_wire_state_by_instance_id(host, want_id)
	if (
		ctx.begins_with("bind:")
		or ctx.begins_with("wire[")
		or ctx.begins_with("tab_config")
		or ctx.begins_with("animation_targets")
		or ctx.begins_with("action_targets")
		or ".src[" in ctx
	):
		var v: Variant = UiReactComputedGraphRebind.follow_path(host, ctx)
		return v as UiState if v is UiState else null
	var prop_sn := StringName(ctx)
	if prop_sn in host:
		var v2: Variant = host.get(prop_sn)
		return v2 as UiState if v2 is UiState else null
	return null


static func _parse_emb_instance_id(node_id: String) -> int:
	if not node_id.begins_with("state:emb:"):
		return 0
	var body := node_id.substr("state:emb:".length())
	var parts := body.split("#")
	if parts.size() < 3:
		return 0
	return int(parts[parts.size() - 1])


static func _find_wire_state_by_instance_id(host: Control, want_id: int) -> UiState:
	if want_id == 0 or not (&"wire_rules" in host):
		return null
	var wr: Variant = host.get(&"wire_rules")
	if wr == null or not (wr is Array):
		return null
	for item in wr as Array:
		if item == null or not (item is UiReactWireRule):
			continue
		var rule := item as UiReactWireRule
		for ref in _WireIoScript.list_io(rule):
			var st: Variant = ref.get(&"state", null)
			if st is UiState and (st as UiState).get_instance_id() == want_id:
				return st as UiState
	return null

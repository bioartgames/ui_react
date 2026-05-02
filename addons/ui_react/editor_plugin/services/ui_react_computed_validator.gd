## Editor dock: [UiComputed*] with [code]sources[/code] that are never bound to a registry export **and** not used only as a nested source of another computed.
class_name UiReactComputedValidator
extends RefCounted


static func validate_under_root(root: Node) -> Array[UiReactDiagnosticModel.DiagnosticIssue]:
	var issues: Array[UiReactDiagnosticModel.DiagnosticIssue] = []
	if root == null:
		return issues

	var bound_registry_ids: Dictionary = {}
	var nodes: Array[Node] = UiReactScannerService.collect_react_nodes(root)

	for node in nodes:
		var component := UiReactScannerService.get_component_name_from_script(node.get_script() as Script)
		if component.is_empty():
			continue
		var node_path := (
			root.get_path_to(node) if root and node.is_inside_tree() else NodePath(String(node.get_path()))
		)
		var bindings: Array = UiReactComponentRegistry.BINDINGS_BY_COMPONENT.get(component, [])
		for b in bindings:
			var prop: StringName = b.get("property", &"")
			if prop == &"" or not prop in node:
				continue
			var val: Variant = node.get(prop)
			if val is UiComputedStringState or val is UiComputedBoolState:
				bound_registry_ids[(val as UiState).get_instance_id()] = true

	var seen_computed: Dictionary = {} # int id -> NodePath first path
	var nested_source_ids: Dictionary = {}

	for node in nodes:
		var np := (
			root.get_path_to(node) if root and node.is_inside_tree() else NodePath(String(node.get_path()))
		)
		_collect_from_react_node(node, np, seen_computed, nested_source_ids)

	var computed_by_id: Dictionary = {} # int -> UiState (first occurrence)
	for node2 in nodes:
		_collect_computed_states_from_node(node2, computed_by_id)
	for cid2 in computed_by_id.keys():
		var cst: UiState = computed_by_id[cid2] as UiState
		if cst != null and UiReactComputedService.sources_dependency_graph_has_cycle(cst):
			var np_cycle: NodePath = seen_computed.get(cid2, NodePath("")) as NodePath
			issues.append(
				UiReactDiagnosticModel.DiagnosticIssue.make_structured(
					UiReactDiagnosticModel.Severity.ERROR,
					"UiComputed",
					"",
					(
						"This computed resource has a cyclic [code]sources[/code] graph (dependency cycle). Runtime wiring will be refused."
					),
					"Remove or reorder [code]sources[/code] so no computed depends—directly or indirectly—on itself.",
					np_cycle,
					&"",
					&"",
					UiReactDiagnosticModel.IssueKind.GENERIC,
					"",
				)
			)

	for cid in seen_computed.keys():
		if bound_registry_ids.has(cid):
			continue
		if nested_source_ids.has(cid):
			continue
		var np: NodePath = seen_computed[cid]
		issues.append(
			UiReactDiagnosticModel.DiagnosticIssue.make_structured(
				UiReactDiagnosticModel.Severity.WARNING,
				"UiComputed",
				"",
				"This computed resource has inputs but is not hooked to any Ui React control binding (and is not only used inside another computed).",
				"Assign it to an Inspector binding on a UiReact* control (for example text or checked state), or use it only as a nested source of another computed, or clear its sources if unused.",
				np,
				&"",
				&"",
				UiReactDiagnosticModel.IssueKind.GENERIC,
				"",
			)
		)
	return issues


static func _collect_computed_states_from_node(node: Node, computed_by_id: Dictionary) -> void:
	var component := UiReactScannerService.get_component_name_from_script(node.get_script() as Script)
	if component.is_empty():
		return
	var bindings: Array = UiReactComponentRegistry.BINDINGS_BY_COMPONENT.get(component, [])
	for b in bindings:
		var prop: StringName = b.get("property", &"")
		if prop == &"":
			continue
		if prop in node:
			_walk_variant_collect_computeds(node.get(prop), computed_by_id)
	for extra in [&"wire_rules", &"animation_targets", &"action_targets", &"audio_targets", &"haptic_targets"]:
		if extra in node:
			_walk_variant_collect_computeds(node.get(extra), computed_by_id)


static func _walk_variant_collect_computeds(v: Variant, computed_by_id: Dictionary) -> void:
	if v == null:
		return
	if v is UiComputedStringState or v is UiComputedBoolState:
		var c := v as UiState
		var id := c.get_instance_id()
		if not computed_by_id.has(id):
			computed_by_id[id] = c
		return
	if v is Array:
		for el in v:
			_walk_variant_collect_computeds(el, computed_by_id)
		return
	if v is Dictionary:
		for k in v:
			_walk_variant_collect_computeds(v[k], computed_by_id)
		return


static func _collect_from_react_node(
	node: Node, node_path: NodePath, seen_computed: Dictionary, nested_source_ids: Dictionary
) -> void:
	var component := UiReactScannerService.get_component_name_from_script(node.get_script() as Script)
	if component.is_empty():
		return
	var bindings: Array = UiReactComponentRegistry.BINDINGS_BY_COMPONENT.get(component, [])
	for b in bindings:
		var prop: StringName = b.get("property", &"")
		if prop == &"":
			continue
		if prop in node:
			_walk_variant(node.get(prop), node_path, seen_computed, nested_source_ids)
	for extra in [&"wire_rules", &"animation_targets", &"action_targets", &"audio_targets", &"haptic_targets"]:
		if extra in node:
			_walk_variant(node.get(extra), node_path, seen_computed, nested_source_ids)


static func _walk_variant(
	v: Variant, node_path: NodePath, seen_computed: Dictionary, nested_source_ids: Dictionary
) -> void:
	if v == null:
		return
	if v is UiComputedStringState or v is UiComputedBoolState:
		var c := v as UiState
		var id := c.get_instance_id()
		var raw: Variant = c.get(&"sources")
		if typeof(raw) == TYPE_ARRAY and (raw as Array).size() > 0:
			if not seen_computed.has(id):
				seen_computed[id] = node_path
			for it in raw as Array:
				if it is UiComputedStringState or it is UiComputedBoolState:
					nested_source_ids[(it as UiState).get_instance_id()] = true
		return
	if v is Array:
		for el in v:
			_walk_variant(el, node_path, seen_computed, nested_source_ids)
		return
	if v is Dictionary:
		for k in v:
			_walk_variant(v[k], node_path, seen_computed, nested_source_ids)
		return

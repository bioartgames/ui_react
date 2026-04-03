## Validates [UiReact*] bindings and [UiAnimTarget] rows (editor-only; façade over split validators).
class_name UiReactValidatorService
extends RefCounted


static func validate_nodes(
	nodes: Array[Node],
	root_for_paths: Node,
) -> Array[UiReactDiagnosticModel.DiagnosticIssue]:
	var issues: Array[UiReactDiagnosticModel.DiagnosticIssue] = []
	for node in nodes:
		if node == null or not (node is Control):
			continue
		var component := UiReactScannerService.get_component_name_from_script(node.get_script() as Script)
		if component.is_empty():
			continue
		var node_path := root_for_paths.get_path_to(node) if root_for_paths and node.is_inside_tree() else NodePath(String(node.get_path()))
		issues.append_array(UiReactBindingValidator.validate_bindings(component, node as Control, node_path))
		issues.append_array(UiReactAnimValidator.validate_anim_targets(component, node as Control, node_path))
		issues.append_array(UiReactActionValidator.validate_action_targets(component, node as Control, node_path))
		issues.append_array(UiReactWiringValidator.validate_wire_rules(component, node as Control, node_path))
	return issues


static func validate_wiring_under_root(root: Node) -> Array[UiReactDiagnosticModel.DiagnosticIssue]:
	return UiReactWiringValidator.validate_wiring_under_root(root)

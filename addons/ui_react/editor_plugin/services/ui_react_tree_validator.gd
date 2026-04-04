## Validates [member UiReactTree.tree_items_state] payload (editor diagnostics).
class_name UiReactTreeValidator
extends RefCounted

const _MAX_DEPTH: int = 64
const _TREE_NODE_SCRIPT: Script = preload("res://addons/ui_react/scripts/api/models/ui_react_tree_node.gd")


static func validate_tree_items(
	component: String, owner: Control, node_path: NodePath
) -> Array[UiReactDiagnosticModel.DiagnosticIssue]:
	var out: Array[UiReactDiagnosticModel.DiagnosticIssue] = []
	if component != "UiReactTree":
		return out
	if not &"tree_items_state" in owner:
		return out
	var tis: Variant = owner.get(&"tree_items_state")
	if tis == null:
		out.append(
			UiReactDiagnosticModel.DiagnosticIssue.make_structured(
				UiReactDiagnosticModel.Severity.ERROR,
				component,
				str(owner.name),
				"tree_items_state is not assigned.",
				"Assign a UiArrayState whose value is an Array of UiReactTreeNode.",
				node_path,
				&"tree_items_state",
				&"UiArrayState",
				UiReactDiagnosticModel.IssueKind.GENERIC,
				"",
			)
		)
		return out
	if not (tis is UiArrayState):
		out.append(
			UiReactDiagnosticModel.DiagnosticIssue.make_structured(
				UiReactDiagnosticModel.Severity.ERROR,
				component,
				str(owner.name),
				"tree_items_state must be a UiArrayState.",
				"Assign a UiArrayState resource.",
				node_path,
				&"tree_items_state",
				&"UiArrayState",
				UiReactDiagnosticModel.IssueKind.GENERIC,
				"",
			)
		)
		return out
	var arr_st := tis as UiArrayState
	var raw: Variant = arr_st.get_value()
	if raw == null:
		return out
	if not (raw is Array):
		out.append(
			UiReactDiagnosticModel.DiagnosticIssue.make_structured(
				UiReactDiagnosticModel.Severity.ERROR,
				component,
				str(owner.name),
				"tree_items_state value must be an Array.",
				"Set the UiArrayState value to an Array of UiReactTreeNode.",
				node_path,
				&"tree_items_state",
				&"UiArrayState",
				UiReactDiagnosticModel.IssueKind.GENERIC,
				"",
			)
		)
		return out
	var top: Array = raw as Array
	for i in range(top.size()):
		out.append_array(_validate_node_at(top[i], "[%d]" % i, 0, component, str(owner.name), node_path))
	return out


static func _validate_node_at(
	node: Variant,
	path: String,
	depth: int,
	component: String,
	owner_name: String,
	node_path: NodePath
) -> Array[UiReactDiagnosticModel.DiagnosticIssue]:
	var out: Array[UiReactDiagnosticModel.DiagnosticIssue] = []
	if depth > _MAX_DEPTH:
		out.append(
			UiReactDiagnosticModel.DiagnosticIssue.make_structured(
				UiReactDiagnosticModel.Severity.ERROR,
				component,
				owner_name,
				"UiReactTreeNode at tree_items_state%s exceeds max depth (%d)." % [path, _MAX_DEPTH],
				"Reduce nesting depth.",
				node_path,
				&"tree_items_state",
				&"",
				UiReactDiagnosticModel.IssueKind.GENERIC,
				"",
			)
		)
		return out
	if node == null:
		out.append(
			UiReactDiagnosticModel.DiagnosticIssue.make_structured(
				UiReactDiagnosticModel.Severity.ERROR,
				component,
				owner_name,
				"Null UiReactTreeNode at tree_items_state%s." % path,
				"Remove the entry or assign a UiReactTreeNode.",
				node_path,
				&"tree_items_state",
				&"UiReactTreeNode",
				UiReactDiagnosticModel.IssueKind.GENERIC,
				"",
			)
		)
		return out
	if not is_instance_of(node, _TREE_NODE_SCRIPT):
		out.append(
			UiReactDiagnosticModel.DiagnosticIssue.make_structured(
				UiReactDiagnosticModel.Severity.ERROR,
				component,
				owner_name,
				"tree_items_state%s must be UiReactTreeNode (got %s)." % [path, UiReactValidatorCommon.variant_type_name(node)],
				"Use only UiReactTreeNode entries in the array.",
				node_path,
				&"tree_items_state",
				&"UiReactTreeNode",
				UiReactDiagnosticModel.IssueKind.GENERIC,
				"",
			)
		)
		return out
	var n := node as Resource
	if n.get(&"icon") == null:
		out.append(
			UiReactDiagnosticModel.DiagnosticIssue.make_structured(
				UiReactDiagnosticModel.Severity.ERROR,
				component,
				owner_name,
				"UiReactTreeNode at tree_items_state%s has no icon." % path,
				"Assign a Texture2D to icon.",
				node_path,
				&"tree_items_state",
				&"",
				UiReactDiagnosticModel.IssueKind.GENERIC,
				"",
			)
		)
	var ch: Variant = n.get(&"children")
	if typeof(ch) != TYPE_ARRAY:
		out.append(
			UiReactDiagnosticModel.DiagnosticIssue.make_structured(
				UiReactDiagnosticModel.Severity.ERROR,
				component,
				owner_name,
				"UiReactTreeNode at tree_items_state%s has invalid children." % path,
				"children must be an Array of UiReactTreeNode.",
				node_path,
				&"tree_items_state",
				&"",
				UiReactDiagnosticModel.IssueKind.GENERIC,
				"",
			)
		)
		return out
	var children: Array = ch as Array
	for j in range(children.size()):
		out.append_array(_validate_node_at(children[j], "%s.children[%d]" % [path, j], depth + 1, component, owner_name, node_path))
	return out

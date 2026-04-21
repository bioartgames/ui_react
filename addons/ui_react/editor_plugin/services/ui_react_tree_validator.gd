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
				"Tree has no Tree items state assigned, so rows cannot load.",
				"In the Inspector, assign Tree items state to a UiArrayState whose value is an array of UiReactTreeNode resources.",
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
				"Tree items state must be a UiArrayState resource.",
				"In the Inspector, pick a UiArrayState (or create one) and assign it to Tree items state.",
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
				"Tree items state value must be an array of row nodes.",
				"In the Inspector, set the UiArrayState value to an Array where each entry is a UiReactTreeNode.",
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
				"Tree row data at tree_items_state%s is nested deeper than allowed (%d levels)." % [path, _MAX_DEPTH],
				"Flatten the tree in the array (fewer nested children) or split into multiple trees.",
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
				"Tree row at tree_items_state%s is empty (null entry)." % path,
				"Remove the slot or assign a UiReactTreeNode resource for that row.",
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
				"Tree row at tree_items_state%s must be a UiReactTreeNode (found %s instead)." % [path, UiReactValidatorCommon.variant_type_name(node)],
				"Replace that array entry with a UiReactTreeNode subresource.",
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
				"Tree row at tree_items_state%s has no icon texture." % path,
				"In the Inspector, open that UiReactTreeNode and assign Icon (Texture2D).",
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
				"Tree row at tree_items_state%s has an invalid Children field." % path,
				"Children must be an array of UiReactTreeNode entries (same shape as top-level rows).",
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

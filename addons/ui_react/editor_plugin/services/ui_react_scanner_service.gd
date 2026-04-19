## Finds [UiReact*] nodes and binding metadata for editor diagnostics.
## Binding tables live in [UiReactComponentRegistry]; use that type for single-source edits.
class_name UiReactScannerService
extends RefCounted

const _REACT_SCRIPT_SUFFIX := "/ui_react_"


static func get_component_name_from_script(script: Script) -> String:
	if script == null:
		return ""
	var gn := String(script.get_global_name())
	if not gn.is_empty() and UiReactComponentRegistry.BINDINGS_BY_COMPONENT.has(gn):
		return gn
	var path := script.resource_path
	if path.is_empty() or not path.contains(_REACT_SCRIPT_SUFFIX):
		return ""
	var base := path.get_file().get_basename()
	return String(UiReactComponentRegistry.SCRIPT_STEM_TO_COMPONENT.get(base, ""))


static func collect_react_nodes(root: Node) -> Array[Node]:
	var out: Array[Node] = []
	if root == null:
		return out
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if is_react_node(n):
			out.append(n)
		for c in n.get_children():
			stack.append(c)
	return out


static func is_react_node(node: Node) -> bool:
	var sc := node.get_script()
	if sc == null:
		return false
	return not get_component_name_from_script(sc).is_empty()


static func kind_to_suggested_class(kind: String) -> StringName:
	match kind:
		"bool":
			return &"UiBoolState"
		"int":
			return &"UiIntState"
		"float":
			return &"UiFloatState"
		"string":
			return &"UiStringState"
		"array":
			return &"UiArrayState"
		_:
			return &""

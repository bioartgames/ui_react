## Finds [UiReact*] nodes and binding metadata for editor diagnostics.
class_name UiSystemScannerService
extends RefCounted

const _REACT_SCRIPT_SUFFIX := "/ui_react_"

## Maps script file stem to global [code]class_name[/code] used in warnings.
const SCRIPT_STEM_TO_COMPONENT: Dictionary = {
	"ui_react_button": "UiReactButton",
	"ui_react_check_box": "UiReactCheckBox",
	"ui_react_slider": "UiReactSlider",
	"ui_react_spin_box": "UiReactSpinBox",
	"ui_react_progress_bar": "UiReactProgressBar",
	"ui_react_line_edit": "UiReactLineEdit",
	"ui_react_label": "UiReactLabel",
	"ui_react_option_button": "UiReactOptionButton",
	"ui_react_item_list": "UiReactItemList",
	"ui_react_tab_container": "UiReactTabContainer",
}

## Binding slots: [code]property[/code], [code]kind[/code] for suggested typed state, [code]optional[/code].
const BINDINGS_BY_COMPONENT: Dictionary = {
	"UiReactButton": [
		{"property": &"pressed_state", "kind": "bool", "optional": true},
		{"property": &"disabled_state", "kind": "bool", "optional": true},
	],
	"UiReactCheckBox": [
		{"property": &"checked_state", "kind": "bool", "optional": true},
		{"property": &"disabled_state", "kind": "bool", "optional": true},
	],
	"UiReactSlider": [
		{"property": &"value_state", "kind": "float", "optional": true},
	],
	"UiReactSpinBox": [
		{"property": &"value_state", "kind": "float", "optional": true},
		{"property": &"disabled_state", "kind": "bool", "optional": true},
	],
	"UiReactProgressBar": [
		{"property": &"value_state", "kind": "float", "optional": true},
	],
	"UiReactLineEdit": [
		{"property": &"text_state", "kind": "string", "optional": true},
	],
	"UiReactLabel": [
		{"property": &"text_state", "kind": "string", "optional": true},
	],
	"UiReactOptionButton": [
		{"property": &"selected_state", "kind": "string", "optional": true},
		{"property": &"disabled_state", "kind": "bool", "optional": true},
	],
	"UiReactItemList": [
		{"property": &"items_state", "kind": "array", "optional": true},
		{"property": &"selected_state", "kind": "float", "optional": true},
		{"property": &"disabled_state", "kind": "bool", "optional": true},
	],
	"UiReactTabContainer": [
		{"property": &"selected_state", "kind": "float", "optional": true},
	],
}


static func get_component_name_from_script(script: Script) -> String:
	if script == null:
		return ""
	var path := script.resource_path
	if path.is_empty() or not path.contains(_REACT_SCRIPT_SUFFIX):
		return ""
	var base := path.get_file().get_basename()
	return String(SCRIPT_STEM_TO_COMPONENT.get(base, ""))


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
		"float":
			return &"UiFloatState"
		"string":
			return &"UiStringState"
		"array":
			return &"UiArrayState"
		_:
			return &"UiState"

## Single source of truth for [UiReact*] scanner metadata (stems + binding slots). Edit here when adding a control.
class_name UiReactComponentRegistry
extends RefCounted

## Maps script file stem to global [code]class_name[/code] used in warnings.
const SCRIPT_STEM_TO_COMPONENT: Dictionary = {
	"ui_react_button": "UiReactButton",
	"ui_react_check_box": "UiReactCheckBox",
	"ui_react_slider": "UiReactSlider",
	"ui_react_spin_box": "UiReactSpinBox",
	"ui_react_progress_bar": "UiReactProgressBar",
	"ui_react_line_edit": "UiReactLineEdit",
	"ui_react_label": "UiReactLabel",
	"ui_react_rich_text_label": "UiReactRichTextLabel",
	"ui_react_option_button": "UiReactOptionButton",
	"ui_react_item_list": "UiReactItemList",
	"ui_react_tab_container": "UiReactTabContainer",
	"ui_react_texture_button": "UiReactTextureButton",
	"ui_react_tree": "UiReactTree",
	"ui_react_transactional_actions": "UiReactTransactionalActions",
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
	"UiReactRichTextLabel": [
		{"property": &"text_state", "kind": "string", "optional": true},
	],
	"UiReactOptionButton": [
		{"property": &"selected_state", "kind": "string", "optional": true},
		{"property": &"disabled_state", "kind": "bool", "optional": true},
	],
	"UiReactItemList": [
		{"property": &"items_state", "kind": "array", "optional": true},
		{"property": &"selected_state", "kind": "int", "optional": true},
	],
	"UiReactTabContainer": [
		{"property": &"selected_state", "kind": "int", "optional": true},
	],
	"UiReactTextureButton": [
		{"property": &"pressed_state", "kind": "bool", "optional": true},
		{"property": &"disabled_state", "kind": "bool", "optional": true},
	],
	"UiReactTree": [
		{"property": &"selected_state", "kind": "int", "optional": true},
	],
	"UiReactTransactionalActions": [],
}

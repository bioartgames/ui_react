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
		{"property": &"tree_items_state", "kind": "array", "optional": false},
		{"property": &"selected_state", "kind": "int", "optional": true},
	],
}

## [UiAnimTarget.Trigger] values each [UiReact*] host actually wires and dispatches (see [code]_validate_animation_targets[/code] on each control).
## When adding or changing signal wiring for animation triggers, update this map and [code]README.md[/code] (animation triggers table).
const ANIM_TRIGGERS_BY_COMPONENT: Dictionary = {
	"UiReactButton": [
		UiAnimTarget.Trigger.PRESSED,
		UiAnimTarget.Trigger.FOCUS_ENTERED,
		UiAnimTarget.Trigger.FOCUS_EXITED,
		UiAnimTarget.Trigger.HOVER_ENTER,
		UiAnimTarget.Trigger.HOVER_EXIT,
		UiAnimTarget.Trigger.TOGGLED_ON,
		UiAnimTarget.Trigger.TOGGLED_OFF,
	],
	"UiReactTextureButton": [
		UiAnimTarget.Trigger.PRESSED,
		UiAnimTarget.Trigger.FOCUS_ENTERED,
		UiAnimTarget.Trigger.FOCUS_EXITED,
		UiAnimTarget.Trigger.HOVER_ENTER,
		UiAnimTarget.Trigger.HOVER_EXIT,
		UiAnimTarget.Trigger.TOGGLED_ON,
		UiAnimTarget.Trigger.TOGGLED_OFF,
	],
	"UiReactCheckBox": [
		UiAnimTarget.Trigger.TOGGLED_ON,
		UiAnimTarget.Trigger.TOGGLED_OFF,
		UiAnimTarget.Trigger.FOCUS_ENTERED,
		UiAnimTarget.Trigger.FOCUS_EXITED,
		UiAnimTarget.Trigger.HOVER_ENTER,
		UiAnimTarget.Trigger.HOVER_EXIT,
	],
	"UiReactSlider": [
		UiAnimTarget.Trigger.VALUE_CHANGED,
		UiAnimTarget.Trigger.VALUE_INCREASED,
		UiAnimTarget.Trigger.VALUE_DECREASED,
		UiAnimTarget.Trigger.DRAG_STARTED,
		UiAnimTarget.Trigger.DRAG_ENDED,
		UiAnimTarget.Trigger.FOCUS_ENTERED,
		UiAnimTarget.Trigger.FOCUS_EXITED,
		UiAnimTarget.Trigger.HOVER_ENTER,
		UiAnimTarget.Trigger.HOVER_EXIT,
	],
	"UiReactSpinBox": [
		UiAnimTarget.Trigger.VALUE_CHANGED,
		UiAnimTarget.Trigger.VALUE_INCREASED,
		UiAnimTarget.Trigger.VALUE_DECREASED,
		UiAnimTarget.Trigger.FOCUS_ENTERED,
		UiAnimTarget.Trigger.FOCUS_EXITED,
		UiAnimTarget.Trigger.HOVER_ENTER,
		UiAnimTarget.Trigger.HOVER_EXIT,
	],
	"UiReactProgressBar": [
		UiAnimTarget.Trigger.VALUE_CHANGED,
		UiAnimTarget.Trigger.VALUE_INCREASED,
		UiAnimTarget.Trigger.VALUE_DECREASED,
		UiAnimTarget.Trigger.COMPLETED,
		UiAnimTarget.Trigger.FOCUS_ENTERED,
		UiAnimTarget.Trigger.FOCUS_EXITED,
		UiAnimTarget.Trigger.HOVER_ENTER,
		UiAnimTarget.Trigger.HOVER_EXIT,
	],
	"UiReactLineEdit": [
		UiAnimTarget.Trigger.TEXT_CHANGED,
		UiAnimTarget.Trigger.TEXT_ENTERED,
		UiAnimTarget.Trigger.FOCUS_ENTERED,
		UiAnimTarget.Trigger.FOCUS_EXITED,
		UiAnimTarget.Trigger.HOVER_ENTER,
		UiAnimTarget.Trigger.HOVER_EXIT,
	],
	"UiReactLabel": [
		UiAnimTarget.Trigger.TEXT_CHANGED,
		UiAnimTarget.Trigger.HOVER_ENTER,
		UiAnimTarget.Trigger.HOVER_EXIT,
	],
	"UiReactRichTextLabel": [
		UiAnimTarget.Trigger.TEXT_CHANGED,
		UiAnimTarget.Trigger.HOVER_ENTER,
		UiAnimTarget.Trigger.HOVER_EXIT,
	],
	"UiReactOptionButton": [
		UiAnimTarget.Trigger.SELECTION_CHANGED,
		UiAnimTarget.Trigger.FOCUS_ENTERED,
		UiAnimTarget.Trigger.FOCUS_EXITED,
		UiAnimTarget.Trigger.HOVER_ENTER,
		UiAnimTarget.Trigger.HOVER_EXIT,
	],
	"UiReactItemList": [
		UiAnimTarget.Trigger.SELECTION_CHANGED,
		UiAnimTarget.Trigger.FOCUS_ENTERED,
		UiAnimTarget.Trigger.FOCUS_EXITED,
		UiAnimTarget.Trigger.HOVER_ENTER,
		UiAnimTarget.Trigger.HOVER_EXIT,
	],
	"UiReactTree": [
		UiAnimTarget.Trigger.SELECTION_CHANGED,
		UiAnimTarget.Trigger.FOCUS_ENTERED,
		UiAnimTarget.Trigger.FOCUS_EXITED,
		UiAnimTarget.Trigger.HOVER_ENTER,
		UiAnimTarget.Trigger.HOVER_EXIT,
	],
	"UiReactTabContainer": [
		UiAnimTarget.Trigger.SELECTION_CHANGED,
		UiAnimTarget.Trigger.FOCUS_ENTERED,
		UiAnimTarget.Trigger.FOCUS_EXITED,
		UiAnimTarget.Trigger.HOVER_ENTER,
		UiAnimTarget.Trigger.HOVER_EXIT,
	],
}

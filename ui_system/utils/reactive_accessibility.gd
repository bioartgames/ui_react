## Accessibility utilities for reactive UI system.
## Provides helper functions for screen reader support and accessibility features.
class_name ReactiveAccessibility
extends RefCounted

## Sets accessibility description for a Control.
## Description is read by screen readers.
static func set_accessibility_description(control: Control, description: String) -> void:
	if control == null:
		return
	
	# Use Godot 4.5 accessibility API
	# Note: API may vary, adjust as needed
	if control.has_method("set_accessibility_description"):
		control.set_accessibility_description(description)
	else:
		# Fallback: store in metadata
		control.set_meta("accessibility_description", description)

## Gets accessibility description for a Control.
static func get_accessibility_description(control: Control) -> String:
	if control == null:
		return ""
	
	if control.has_method("get_accessibility_description"):
		return control.get_accessibility_description()
	else:
		return control.get_meta("accessibility_description", "")

## Sets accessibility label for a Control.
## Label is used by screen readers to identify the control.
static func set_accessibility_label(control: Control, label: String) -> void:
	if control == null:
		return
	
	# Use Godot 4.5 accessibility API
	if control.has_method("set_accessibility_label"):
		control.set_accessibility_label(label)
	else:
		# Fallback: store in metadata
		control.set_meta("accessibility_label", label)

## Gets accessibility label for a Control.
static func get_accessibility_label(control: Control) -> String:
	if control == null:
		return ""
	
	if control.has_method("get_accessibility_label"):
		return control.get_accessibility_label()
	else:
		return control.get_meta("accessibility_label", "")

## Sets accessibility role for a Control.
## Role describes what type of control this is (button, label, etc.).
static func set_accessibility_role(control: Control, role: String) -> void:
	if control == null:
		return
	
	# Use Godot 4.5 accessibility API
	if control.has_method("set_accessibility_role"):
		control.set_accessibility_role(role)
	else:
		# Fallback: store in metadata
		control.set_meta("accessibility_role", role)

## Gets accessibility role for a Control.
static func get_accessibility_role(control: Control) -> String:
	if control == null:
		return ""
	
	if control.has_method("get_accessibility_role"):
		return control.get_accessibility_role()
	else:
		return control.get_meta("accessibility_role", "")

## Sets up accessibility for a ReactiveControl.
## Applies description and label from ReactiveControl properties.
static func setup_reactive_control_accessibility(control: Control, description: String, label: String) -> void:
	if control == null:
		return
	
	if not description.is_empty():
		set_accessibility_description(control, description)
	
	if not label.is_empty():
		set_accessibility_label(control, label)

## Gets a human-readable name for a control type.
## Used for default accessibility labels.
static func get_control_type_name(control: Control) -> String:
	if control == null:
		return "Control"
	
	var class_type = control.get_class()
	
	# Map common control types to readable names
	match class_type:
		"Button":
			return "Button"
		"Label":
			return "Label"
		"LineEdit":
			return "Text Input"
		"CheckBox":
			return "Checkbox"
		"OptionButton":
			return "Dropdown"
		"SpinBox":
			return "Spin Box"
		"Slider":
			return "Slider"
		"ProgressBar":
			return "Progress Bar"
		"ItemList":
			return "List"
		_:
			return class_type

## Creates an accessibility-friendly name from a control's text/label.
static func create_accessibility_name(control: Control) -> String:
	if control == null:
		return ""
	
	# Try to get text from common properties
	if control.has_method("get_text"):
		var text = control.get_text()
		if not text.is_empty():
			return text
	
	if control.has_method("get_label"):
		var label = control.get_label()
		if not label.is_empty():
			return label
	
	# Fallback to type name
	return get_control_type_name(control)


## Input field component with two-way binding support.
## Demonstrates two-way binding: LineEdit ↔ ReactiveString
extends ReactiveControl
class_name ReactiveLineEdit

## The LineEdit node for input.
@onready var line_edit: LineEdit = null

func _ready() -> void:
	super._ready()
	
	# Find or create LineEdit child
	line_edit = _find_or_create_line_edit()
	
	# If no line edit found, create one
	if line_edit == null:
		line_edit = LineEdit.new()
		line_edit.name = "LineEdit"
		add_child(line_edit)

## Finds existing LineEdit child or returns null.
func _find_or_create_line_edit() -> LineEdit:
	for child in get_children():
		if child is LineEdit:
			return child as LineEdit
	return null


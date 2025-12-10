## Input field component with two-way binding support.
## Demonstrates two-way binding: LineEdit ↔ ReactiveString
extends ReactiveControl
class_name ReactiveLineEdit

## The LineEdit node for input.
var line_edit: LineEdit = null

func _ready() -> void:
	# Create LineEdit BEFORE calling super._ready() so it exists when bindings sync
	line_edit = _find_or_create_line_edit()
	
	# If no line edit found, create one
	if line_edit == null:
		line_edit = LineEdit.new()
		line_edit.name = "LineEdit"
		add_child(line_edit)
	
	# Now call super to set up bindings (LineEdit will exist for sync)
	super._ready()

## Finds existing LineEdit child or returns null.
func _find_or_create_line_edit() -> LineEdit:
	for child in get_children():
		if child is LineEdit:
			return child as LineEdit
	return null


## Simple label component with one-way binding support.
## Demonstrates one-way binding: ReactiveValue → Label.text
extends ReactiveControl
class_name ReactiveLabel

## The Label node to display text.
var label: Label = null

func _ready() -> void:
	# Create Label BEFORE calling super._ready() so it exists when bindings sync
	label = _find_or_create_label()
	
	# If no label found, create one
	if label == null:
		label = Label.new()
		label.name = "Label"
		add_child(label)
	
	# Now call super to set up bindings (Label will exist for sync)
	super._ready()

## Finds existing Label child or returns null.
func _find_or_create_label() -> Label:
	for child in get_children():
		if child is Label:
			return child as Label
	return null


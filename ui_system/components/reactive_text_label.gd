## Text label component that uses TextBuilder for dynamic text.
## Can use Label or RichTextLabel.
extends ReactiveControl
class_name ReactiveTextLabel

## The TextBuilder resource to use.
@export var text_builder: TextBuilder = null

## Whether to use RichTextLabel (true) or Label (false).
@export var use_rich_text: bool = false

## The Label or RichTextLabel node.
var label: Control = null

## Signal connections tracked for cleanup.
var _text_builder_connections: Array[SignalConnection] = []

func _ready() -> void:
	# Create Label or RichTextLabel BEFORE calling super._ready()
	label = _find_or_create_label()
	
	# If no label found, create one
	if label == null:
		if use_rich_text:
			label = RichTextLabel.new()
			label.name = "RichTextLabel"
		else:
			label = Label.new()
			label.name = "Label"
		add_child(label)
	
	# Connect to TextBuilder if provided
	if text_builder != null:
		var callable = Callable(self, "_on_text_builder_changed")
		text_builder.text_changed.connect(callable)
		_text_builder_connections.append(SignalConnection.create(text_builder.text_changed, callable))
		
		# Build initial text
		_update_text()
	
	# Now call super to set up bindings
	super._ready()

func _exit_tree() -> void:
	# Cleanup text builder connections
	ReactiveLifecycleManager.cleanup_signal_connections(_text_builder_connections)
	_text_builder_connections.clear()
	
	# Cleanup text builder
	if text_builder != null:
		text_builder.cleanup()
	
	super._exit_tree()

## Handles notifications (including translation changes).
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		# Rebuild text when language changes
		_update_text()

## Finds existing Label or RichTextLabel child or returns null.
func _find_or_create_label() -> Control:
	for child in get_children():
		if child is Label and not use_rich_text:
			return child as Control
		if child is RichTextLabel and use_rich_text:
			return child as Control
	return null

## Called when TextBuilder text changes.
func _on_text_builder_changed() -> void:
	_update_text()

## Updates the label text from TextBuilder.
func _update_text() -> void:
	if text_builder == null or label == null:
		return
	
	var text = text_builder.build()
	
	if label is RichTextLabel:
		(label as RichTextLabel).text = text
	elif label is Label:
		(label as Label).text = text


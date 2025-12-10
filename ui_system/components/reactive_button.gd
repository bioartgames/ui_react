## Button component with action support.
## Triggers actions on pressed signal.
extends ReactiveControl
class_name ReactiveButton

## The Button node to display.
var button: Button = null

## Signal connections tracked for cleanup.
var _signal_connections: Array[SignalConnection] = []

func _ready() -> void:
	# Create Button BEFORE calling super._ready() so it exists when bindings sync
	button = _find_or_create_button()
	
	# If no button found, create one
	if button == null:
		button = Button.new()
		button.name = "Button"
		add_child(button)
	
	# Connect to button's pressed signal
	if button.pressed.is_connected(_on_button_pressed):
		# Already connected, skip
		pass
	else:
		var callable = Callable(self, "_on_button_pressed")
		button.pressed.connect(callable)
		_signal_connections.append(SignalConnection.create(button.pressed, callable))
	
	# Now call super to set up bindings (Button will exist for sync)
	super._ready()

func _exit_tree() -> void:
	# Cleanup signal connections
	ReactiveLifecycleManager.cleanup_signal_connections(_signal_connections)
	_signal_connections.clear()
	
	super._exit_tree()

## Finds existing Button child or returns null.
func _find_or_create_button() -> Button:
	for child in get_children():
		if child is Button:
			return child as Button
	return null

## Called when button is pressed.
func _on_button_pressed() -> void:
	execute_actions()


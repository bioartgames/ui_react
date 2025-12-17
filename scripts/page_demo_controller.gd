extends Node

@onready var navigator: Node = get_parent().get_node("ReactiveUINavigator")
@onready var label: Label = get_parent().get_node("VBox/Label")
@onready var buttons = [
	get_parent().get_node("VBox/Button1"),
	get_parent().get_node("VBox/Button2"),
	get_parent().get_node("VBox/Button3")
]

var current_page := 1

func _ready() -> void:
	# Connect to page navigation signals
	navigator.page_changed.connect(_on_page_changed)
	navigator.connect("page_changed", _on_page_changed)  # Alternative connection method

	# Connect page callbacks
	navigator.on_page_next = Callable(self, "_handle_page_next")
	navigator.on_page_prev = Callable(self, "_handle_page_previous")

	_update_ui()

func _on_page_changed(delta: int, focus_owner: Control) -> void:
	print("Page changed: delta=%d, focused='%s'" % [delta, focus_owner.name])
	_handle_page_change(delta)

func _handle_page_next(focus_owner: Control) -> void:
	print("Page next callback triggered by: " + focus_owner.name)
	_handle_page_change(1)

func _handle_page_previous(focus_owner: Control) -> void:
	print("Page previous callback triggered by: " + focus_owner.name)
	_handle_page_change(-1)

func _handle_page_change(delta: int) -> void:
	current_page += delta

	# Wrap pages (1-3 for demo)
	if current_page < 1:
		current_page = 3
	elif current_page > 3:
		current_page = 1

	_update_ui()

func _update_ui() -> void:
	# Update label
	label.text = "Advanced Navigation Demo (Page %d)
- Use keyboard arrows or gamepad
- Try analog stick (diagonals enabled)
- Press 'Page Next' to change pages
- Current page: %d" % [current_page, current_page]

	# Update button text based on page
	for i in range(buttons.size()):
		var button = buttons[i]
		button.text = "Button %d (Page %d)" % [i + 1, current_page]

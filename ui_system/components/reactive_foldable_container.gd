## FoldableContainer wrapper/extender for collapsible UI sections.
## Supports accordion-style interfaces and reactive state binding.
extends Control
class_name ReactiveFoldableContainer

## Whether the container is currently expanded.
@export var expanded: bool = true

## Optional ReactiveBool to bind expanded state to.
@export var expanded_binding: ReactiveBool = null

## Signal emitted when expanded state changes.
signal expanded_changed(is_expanded: bool)

## The header button/control that toggles expansion.
var _header: Control = null

## The content container that shows/hides.
var _content: Control = null

## Whether we're updating from reactive value (prevents circular updates).
var _updating_from_reactive: bool = false

func _ready() -> void:
	# Setup header and content
	_setup_structure()
	
	# Connect to expanded binding if set
	if expanded_binding != null:
		expanded_binding.value_changed.connect(_on_expanded_binding_changed)
		# Sync initial state
		expanded = expanded_binding.value
	
	# Apply initial expanded state
	_update_expanded_state()

## Sets up the container structure (header and content).
func _setup_structure() -> void:
	# Create header if it doesn't exist
	if _header == null:
		_header = _create_header()
		add_child(_header)
	
	# Create content container if it doesn't exist
	if _content == null:
		_content = VBoxContainer.new()
		_content.name = "Content"
		add_child(_content)
	
	# Connect header click to toggle
	if _header is Button:
		(_header as Button).pressed.connect(_on_header_clicked)
	elif _header.has_signal("pressed"):
		_header.pressed.connect(_on_header_clicked)
	else:
		# Use gui_input as fallback
		_header.gui_input.connect(_on_header_gui_input)

## Creates the default header control.
func _create_header() -> Control:
	var button = Button.new()
	button.text = "▼ " if expanded else "▶ "
	button.flat = true
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	return button

## Handles header click to toggle expansion.
func _on_header_clicked() -> void:
	toggle_expanded()

## Handles header GUI input (fallback for non-button headers).
func _on_header_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		toggle_expanded()

## Toggles the expanded state.
func toggle_expanded() -> void:
	set_expanded(not expanded)

## Sets the expanded state.
func set_expanded(value: bool) -> void:
	if expanded == value:
		return
	
	expanded = value
	
	# Update reactive binding if set
	if expanded_binding != null and not _updating_from_reactive:
		_updating_from_reactive = true
		expanded_binding.value = expanded
		_updating_from_reactive = false
	
	_update_expanded_state()
	expanded_changed.emit(expanded)

## Updates the visual state based on expanded flag.
func _update_expanded_state() -> void:
	if _content == null:
		return
	
	_content.visible = expanded
	
	# Update header icon
	if _header is Button:
		var button = _header as Button
		button.text = "▼ " if expanded else "▶ "

## Handles changes from reactive binding.
func _on_expanded_binding_changed(_new_value: Variant, _old_value: Variant) -> void:
	if _updating_from_reactive:
		return
	
	_updating_from_reactive = true
	expanded = expanded_binding.value
	_update_expanded_state()
	expanded_changed.emit(expanded)
	_updating_from_reactive = false

## Gets the content container (for adding child controls).
func get_content() -> Control:
	return _content

## Gets the header control.
func get_header() -> Control:
	return _header

## Sets a custom header control.
func set_header(header: Control) -> void:
	if _header != null and is_instance_valid(_header):
		_header.queue_free()
	
	_header = header
	if _header != null:
		add_child(_header)
		_header.set_owner(get_tree().edited_scene_root)
		_move_to_front(_header)
		_setup_structure()

## Moves a child to the front (first position).
func _move_to_front(child: Node) -> void:
	move_child(child, 0)

func _exit_tree() -> void:
	# Disconnect from reactive binding
	if expanded_binding != null:
		if expanded_binding.value_changed.is_connected(_on_expanded_binding_changed):
			expanded_binding.value_changed.disconnect(_on_expanded_binding_changed)


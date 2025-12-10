## General-purpose cell component for use in lists, grids, or standalone.
## Binds directly to item properties via item_source.get_item_reactive_value().
## Supports selection and hover visual feedback.
extends ReactiveControl
class_name ReactiveCell

## Index of the item this cell represents (set by parent ReactiveList/ReactiveGrid).
@export var item_index: int = -1

## The ReactiveArray source (set by parent ReactiveList/ReactiveGrid).
@export var item_source: ReactiveArray = null

## Optional selection reference (set by parent ReactiveList/ReactiveGrid).
@export var selection_reference: ReactiveReference = null

## Optional StyleBox for hover visual state.
@export var hover_style: StyleBox = null

## Optional StyleBox for selected visual state.
@export var selected_style: StyleBox = null

## Optional color modulation for hover state (default: Color.WHITE - no change).
@export var hover_modulate: Color = Color.WHITE

## Optional color modulation for selected state (default: Color.WHITE - no change).
@export var selected_modulate: Color = Color.WHITE

## Whether the cell is currently hovered.
var _is_hovered: bool = false

## Signal connections tracked for cleanup.
var _selection_connections: Array[SignalConnection] = []

## Computed property: whether this cell is selected.
var is_selected: bool:
	get:
		if selection_reference == null or item_source == null or item_index < 0:
			return false
		
		var selected_item = selection_reference.value
		if selected_item == null:
			return false
		
		# Compare with the item at this index
		var current_item = item_source.get_item(item_index)
		return selected_item == current_item

func _ready() -> void:
	super._ready()
	
	# Enable mouse input for hover and click detection
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Connect mouse signals for hover detection
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Connect to selection reference if provided
	if selection_reference != null:
		var callable = Callable(self, "_on_selection_changed")
		selection_reference.value_changed.connect(callable)
		_selection_connections.append(SignalConnection.create(selection_reference.value_changed, callable))
	
	# Update visual state initially
	_update_visual_state()

func _exit_tree() -> void:
	# Cleanup selection connections
	ReactiveLifecycleManager.cleanup_signal_connections(_selection_connections)
	_selection_connections.clear()
	
	super._exit_tree()

## Gets a reactive value for an item property.
## Helper method to access item properties reactively.
## Returns the ReactiveValue if available, null otherwise.
func get_item_property_reactive(property_path: String) -> ReactiveValue:
	if item_source == null or item_index < 0:
		return null
	
	return item_source.get_item_reactive_value(item_index, property_path)

## Gets the current item this cell represents.
func get_current_item() -> Variant:
	if item_source == null or item_index < 0:
		return null
	return item_source.get_item(item_index)

## Called when mouse enters the cell.
func _on_mouse_entered() -> void:
	_is_hovered = true
	_update_visual_state()

## Called when mouse exits the cell.
func _on_mouse_exited() -> void:
	_is_hovered = false
	_update_visual_state()

## Handles GUI input events (mouse clicks).
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			# Set this item as selected
			if selection_reference != null and item_source != null and item_index >= 0:
				var item = item_source.get_item(item_index)
				if item != null:
					selection_reference.set_reference(item as ReactiveValue)

## Called when selection changes.
func _on_selection_changed(_new_value: Variant, _old_value: Variant) -> void:
	_update_visual_state()

## Updates the visual state based on selection and hover.
func _update_visual_state() -> void:
	var currently_selected = is_selected
	
	# Visual priority: Selected state overrides hover state
	if currently_selected:
		# Apply selected style or modulate
		if selected_style != null:
			add_theme_stylebox_override("panel", selected_style)
		else:
			remove_theme_stylebox_override("panel")
		
		if selected_modulate != Color.WHITE:
			modulate = selected_modulate
		else:
			modulate = Color.WHITE
	elif _is_hovered:
		# Apply hover style or modulate
		if hover_style != null:
			add_theme_stylebox_override("panel", hover_style)
		else:
			remove_theme_stylebox_override("panel")
		
		if hover_modulate != Color.WHITE:
			modulate = hover_modulate
		else:
			modulate = Color.WHITE
	else:
		# Clear all visual overrides
		remove_theme_stylebox_override("panel")
		modulate = Color.WHITE


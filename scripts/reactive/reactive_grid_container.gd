@tool
extends GridContainer
class_name ReactiveGridContainer

## Emitted when a cell is activated (via mouse click or controller submit).
##
## Provides a hook for higher-level game code to handle cell activation
## without embedding game logic in the UI control.
signal cell_activated(index: int, item_data: Variant, cell: Control)

## Binds the grid contents to a State resource containing an array of item descriptors.
##
## items_state.value should be an Array of item view models (Dictionaries or Resources).
## Each element represents one grid item with properties like icon, name, count, etc.
@export var items_state: State

## Optional State for tracking the currently selected grid cell index.
##
## selection_state.value should be an int (selected index) or null (no selection).
## Future extension: support Array[int] for multi-selection.
@export var selection_state: State

## Configuration resource defining grid behavior and appearance.
##
## Defines cell scene, layout options, and empty cell handling.
## If null, the grid falls back to defaults.
@export var grid_config: GridContainerConfig

## Whether to update selection_state when a cell receives focus.
##
## If true, moving focus to a cell will also update selection_state.
## If false, selection only changes on explicit submit actions.
@export var select_on_focus: bool = false

## Whether to update selection_state when a cell is activated via submit.
##
## If true, pressing submit/enter on a focused cell will update selection_state.
@export var select_on_submit: bool = true

@export_group("Navigation")
## ENTERABLE: Parent links to first/last cell; grid is not focusable. FOCUSABLE_ENTER: Grid is one focusable; Enter to enter cells, Escape to exit.
enum NavigationMode { ENTERABLE, FOCUSABLE_ENTER }
@export var navigation_mode: NavigationMode = NavigationMode.ENTERABLE

## Holds references to instantiated cell controls for indexing and cleanup.
var _current_cells: Array[Control] = []

## When true, focus is inside the grid (FOCUSABLE_ENTER mode only).
var _entered: bool = false

## Initializes the reactive grid container.
##
## In editor mode: no runtime behavior.
## At runtime: connects to state signals and performs initial sync.
func _ready() -> void:
	if Engine.is_editor_hint():
		return

	# Connect to items_state
	if items_state:
		items_state.value_changed.connect(_on_items_state_changed)
		_on_items_state_changed(items_state.value, items_state.value)

	# Connect to selection_state (if configured)
	if selection_state:
		selection_state.value_changed.connect(_on_selection_state_changed)
		_on_selection_state_changed(selection_state.value, selection_state.value)

	if navigation_mode == NavigationMode.FOCUSABLE_ENTER:
		focus_mode = Control.FOCUS_ALL
	else:
		focus_mode = Control.FOCUS_NONE

## Returns true when the grid should be treated as enterable by parent containers.
func is_enterable_navigation() -> bool:
	return navigation_mode == NavigationMode.ENTERABLE

## Normalizes a value to an Array for grid items.
##
## [param value]: The value to normalize (expected to be Array or null)
## [return]: Normalized Array (empty if value is null or not an Array)
func _normalize_items(value: Variant) -> Array:
	if value is Array:
		return value
	elif value == null:
		return []
	else:
		push_warning("ReactiveGridContainer '%s': items_state.value must be an Array. Got: %s. Treating as empty." % [name, typeof(value)])
		return []

## Handles changes to selection_state.value.
##
## Updates the visual selection state of cells when selection changes.
func _on_selection_state_changed(new_value: Variant, _old_value: Variant) -> void:
	var selected_index: int = -1
	if new_value is int:
		selected_index = int(new_value)
	elif new_value == null:
		selected_index = -1

	# Update cell selection states and trigger cell-level animations
	for i in range(_current_cells.size()):
		var cell: Control = _current_cells[i]
		if cell:
			var is_selected: bool = i == selected_index

			# Update selection state
			if cell.has_method("set_selected"):
				cell.set_selected(is_selected)

			# Optionally trigger cell-level selection animations
			if cell.has_method("on_grid_selection_changed"):
				cell.on_grid_selection_changed(is_selected)

## Handles changes to items_state.value.
##
## Normalizes the new value and rebuilds the grid contents accordingly.
func _on_items_state_changed(new_value: Variant, _old_value: Variant) -> void:
	var items := _normalize_items(new_value)
	_rebuild_cells(items)

## Rebuilds the grid contents with the provided items array.
##
## Clears existing cells and creates new ones based on items and grid configuration.
func _rebuild_cells(items: Array) -> void:
	# Clear existing cells
	for cell in _current_cells:
		if cell:
			cell.queue_free()
	_current_cells.clear()

	# Determine target cell count
	var target_cell_count = items.size()
	if grid_config:
		if grid_config.target_cell_count > 0:
			target_cell_count = max(items.size(), grid_config.target_cell_count)

	# Create cells for each position
	for i in range(target_cell_count):
		var item_data: Variant
		if i < items.size():
			item_data = items[i]
		else:
			item_data = null  # Empty slot

		var cell: Control = _create_cell(item_data, i)
		if cell:
			add_child(cell)
			_current_cells.append(cell)
			_apply_cell_data(cell, item_data, i)

	call_deferred("_setup_internal_focus")

## Creates a cell control for the given item data and index.
##
## [param item_data]: The item descriptor (Dictionary/Resource) or null for empty slots
## [param index]: The cell index in the grid
## [return]: The created cell control, or null if creation failed
func _create_cell(_item_data: Variant, index: int) -> Control:
	# Determine cell scene
	var cell_scene: PackedScene
	if grid_config and grid_config.cell_scene:
		cell_scene = grid_config.cell_scene
	else:
		push_warning("ReactiveGridContainer '%s': No cell_scene configured in grid_config. Skipping cell creation." % name)
		return null

	# Instantiate the cell
	var cell_instance = cell_scene.instantiate()
	if not cell_instance is Control:
		push_warning("ReactiveGridContainer '%s': cell_scene must instantiate a Control. Got: %s" % [name, cell_instance.get_class()])
		cell_instance.queue_free()
		return null

	var cell: Control = cell_instance as Control

	# Make cells focusable for navigation
	cell.focus_mode = Control.FOCUS_ALL

	# Connect cell signals for navigation and activation
	if select_on_focus and not cell.focus_entered.is_connected(_on_cell_focus_entered):
		cell.focus_entered.connect(_on_cell_focus_entered.bind(index))

	var supports_pressed := cell.has_signal("pressed")
	if supports_pressed and not cell.pressed.is_connected(_on_cell_pressed):
		cell.pressed.connect(_on_cell_pressed.bind(index))

	# Prefer pressed when available to avoid duplicate activation handling on button-based cells.
	if not supports_pressed and cell.has_signal("gui_input") and not cell.gui_input.is_connected(_on_cell_gui_input):
		cell.gui_input.connect(_on_cell_gui_input.bind(index))

	return cell

## Applies item data and selection state to a cell already in the tree.
## Call after add_child so the cell's @onready refs are valid.
func _apply_cell_data(cell: Control, item_data: Variant, index: int) -> void:
	if cell.has_method("set_item"):
		cell.set_item(item_data, index)
	if cell.has_method("set_selected"):
		var is_selected := false
		if selection_state and selection_state.value is int:
			is_selected = (selection_state.value as int) == index
		cell.set_selected(is_selected)

## Selects the cell at the given index and updates selection_state.
##
## Called when a cell is activated (e.g., via submit from navigator).
func _select_index(index: int) -> void:
	if selection_state == null:
		return
	selection_state.set_value(index)

## Handles focus entering a cell.
##
## Updates selection_state if select_on_focus is enabled.
func _on_cell_focus_entered(index: int) -> void:
	if select_on_focus:
		_select_index(index)

## Handles cell button press (mouse click).
##
## Updates selection and emits cell_activated signal.
func _on_cell_pressed(index: int) -> void:
	if select_on_submit:
		_select_index(index)

	# Emit activation signal with cell data
	var item_data: Variant = null
	if items_state and items_state.value is Array:
		var items: Array = items_state.value as Array
		if index >= 0 and index < items.size():
			item_data = items[index]

	var cell: Control = _current_cells[index] if index >= 0 and index < _current_cells.size() else null
	cell_activated.emit(index, item_data, cell)

## Handles GUI input on cells for controller submit events.
##
## Processes ui_accept input to simulate submit activation.
func _on_cell_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventAction and event.action == "ui_accept" and event.pressed:
		if select_on_submit:
			_select_index(index)

		# Emit activation signal with cell data
		var item_data: Variant = null
		if items_state and items_state.value is Array:
			var items: Array = items_state.value as Array
			if index >= 0 and index < items.size():
				item_data = items[index]

		var cell: Control = _current_cells[index] if index >= 0 and index < _current_cells.size() else null
		cell_activated.emit(index, item_data, cell)

## Returns the control to focus when entering the grid (FOCUSABLE_ENTER mode).
## Prefers selected cell if selection_state is a valid index, otherwise first cell.
func _get_first_focusable_inside() -> Control:
	if selection_state != null and selection_state.value is int:
		var idx: int = int(selection_state.value)
		if idx >= 0 and idx < _current_cells.size():
			var cell: Control = _current_cells[idx]
			if cell and cell.focus_mode != Control.FOCUS_NONE:
				return cell
	var focusables: Array[Control] = NavigationUtils.find_focusable_controls(self, true)
	return focusables[0] if not focusables.is_empty() else null

func _gui_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if navigation_mode != NavigationMode.FOCUSABLE_ENTER:
		return
	if NavigationUtils.is_accept_event(event) and has_focus() and not _entered:
		var first_inside := _get_first_focusable_inside()
		if first_inside:
			_entered = true
			first_inside.grab_focus()
			accept_event()
		return
	if NavigationUtils.is_cancel_event(event) and _entered:
		var focus_owner = get_viewport().gui_get_focus_owner()
		if focus_owner and is_ancestor_of(focus_owner):
			_entered = false
			grab_focus()
			accept_event()

func _unhandled_key_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if navigation_mode != NavigationMode.FOCUSABLE_ENTER or not _entered:
		return
	if NavigationUtils.is_cancel_event(event):
		var focus_owner = get_viewport().gui_get_focus_owner()
		if focus_owner and is_ancestor_of(focus_owner):
			_entered = false
			grab_focus()
			get_viewport().set_input_as_handled()

## Sets up focus neighbor chain between cells for keyboard navigation.
## Called deferred after _rebuild_cells so the chain matches current _current_cells.
## Does not set first cell's top/left or last cell's bottom/right so the parent (e.g. VBox)
## can keep "exit" links (first cell Up -> previous sibling, last cell Down -> next sibling).
func _setup_internal_focus() -> void:
	if Engine.is_editor_hint():
		return
	if _current_cells.is_empty():
		return
	var focus_chain: Array[Control] = []
	for cell in _current_cells:
		if cell and cell.focus_mode != Control.FOCUS_NONE:
			focus_chain.append(cell)
	if focus_chain.size() < 2:
		return
	var n := focus_chain.size()
	for i in range(n):
		var current: Control = focus_chain[i]
		# Vertical: set bottom for all except last; set top for all except first (parent owns first.top / last.bottom)
		if i < n - 1:
			current.focus_neighbor_bottom = current.get_path_to(focus_chain[i + 1])
		if i > 0:
			current.focus_neighbor_top = current.get_path_to(focus_chain[i - 1])
		# Horizontal: set right for all except last; set left for all except first
		if i < n - 1:
			current.focus_neighbor_right = current.get_path_to(focus_chain[i + 1])
		if i > 0:
			current.focus_neighbor_left = current.get_path_to(focus_chain[i - 1])

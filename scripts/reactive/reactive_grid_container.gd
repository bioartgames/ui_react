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

## Animation reels attached to the grid itself.
##
## Supports grid-level animations like hover enter/exit and selection changes.
@export var animations: Array[AnimationReel] = []

## Whether to update selection_state when a cell receives focus.
##
## If true, moving focus to a cell will also update selection_state.
## If false, selection only changes on explicit submit actions.
@export var select_on_focus: bool = false

## Whether to update selection_state when a cell is activated via submit.
##
## If true, pressing submit/enter on a focused cell will update selection_state.
@export var select_on_submit: bool = true

## Holds references to instantiated cell controls for indexing and cleanup.
var _current_cells: Array[Control] = []

## Used to avoid firing certain reactions/animations during initial population.
var _is_initializing: bool = true

## Guards against feedback loops when updating selection_state from grid events.
var _suppress_state_updates: bool = false

## Initializes the reactive grid container.
##
## In editor mode: Only validates animation reels to enable trigger filtering in the Inspector.
## At runtime: Connects to state signals, performs initial sync, validates animation reels,
## and schedules initialization completion to allow animations to trigger after setup.
func _ready() -> void:
	if Engine.is_editor_hint():
		# In the editor, only validate reels so trigger options are filtered.
		_validate_animation_reels()
		return

	# Connect to items_state
	if items_state:
		items_state.value_changed.connect(_on_items_state_changed)
		_on_items_state_changed(items_state.value, items_state.value)

	# Connect to selection_state (if configured)
	if selection_state:
		selection_state.value_changed.connect(_on_selection_state_changed)
		_on_selection_state_changed(selection_state.value, selection_state.value)

	_validate_animation_reels()
	# Finish initialization after all signals are processed
	call_deferred("_finish_initialization")

## Validates animation reels and filters out invalid ones.
##
## Sets the control context on each reel for Inspector filtering and connects
## hover signals based on which animation triggers are actually used.
func _validate_animation_reels() -> void:
	var result = AnimationReel.validate_for_control(self, animations)
	animations = result.valid_reels

	# Set control context on each reel for Inspector filtering
	var control_type = _get_control_type_hint()
	for reel in animations:
		if reel:
			reel.control_type_context = control_type

	# Control-specific signal connections (stays in class)
	var has_selection_changed_targets = result.trigger_map.get(AnimationReel.Trigger.SELECTION_CHANGED, false)
	var has_hover_enter_targets = result.trigger_map.get(AnimationReel.Trigger.HOVER_ENTER, false)
	var has_hover_exit_targets = result.trigger_map.get(AnimationReel.Trigger.HOVER_EXIT, false)
	var has_value_changed_targets = result.trigger_map.get(AnimationReel.Trigger.VALUE_CHANGED, false)

	# Connect signals based on which triggers are used
	if has_selection_changed_targets and selection_state:
		# Selection changes are handled via selection_state.value_changed
		# (connection already made in _ready())
		pass
	if has_hover_enter_targets:
		if not mouse_entered.is_connected(_on_trigger_hover_enter):
			mouse_entered.connect(_on_trigger_hover_enter)
	if has_hover_exit_targets:
		if not mouse_exited.is_connected(_on_trigger_hover_exit):
			mouse_exited.connect(_on_trigger_hover_exit)
	if has_value_changed_targets:
		# Value changes are handled via items_state.value_changed
		# (connection already made in _ready())
		pass

## Handles SELECTION_CHANGED trigger animations.
func _on_trigger_selection_changed() -> void:
	# Skip animations during initialization
	if _is_initializing:
		return
	_trigger_animations(AnimationReel.Trigger.SELECTION_CHANGED)

## Handles HOVER_ENTER trigger animations.
func _on_trigger_hover_enter() -> void:
	_trigger_animations(AnimationReel.Trigger.HOVER_ENTER)

## Handles HOVER_EXIT trigger animations.
func _on_trigger_hover_exit() -> void:
	_trigger_animations(AnimationReel.Trigger.HOVER_EXIT)

## Handles VALUE_CHANGED trigger animations.
func _on_trigger_value_changed() -> void:
	# Skip animations during initialization
	if _is_initializing:
		return
	_trigger_animations(AnimationReel.Trigger.VALUE_CHANGED)

## Triggers animations for reels matching the specified trigger type.
## [param trigger_type]: The trigger type to match.
func _trigger_animations(trigger_type: AnimationReel.Trigger) -> void:
	if animations.is_empty():
		return

	# Apply animations for reels matching this trigger
	for reel in animations:
		if reel == null:
			continue
		if reel.trigger != trigger_type:
			continue
		reel.apply(self)

## Finishes initialization, allowing animations to trigger on state changes.
func _finish_initialization() -> void:
	_is_initializing = false

## Gets the control type hint for this reactive control.
## Used to filter available triggers in the Inspector.
func _get_control_type_hint() -> AnimationReel.ControlTypeHint:
	return AnimationReel.ControlTypeHint.SELECTION

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
	if _suppress_state_updates:
		return

	var selected_index: int = -1
	if new_value is int:
		selected_index = int(new_value)
	elif new_value == null:
		selected_index = -1

	# Update cell selection states and trigger cell-level animations
	for i in range(_current_cells.size()):
		var cell = _current_cells[i]
		if cell:
			var is_selected = i == selected_index

			# Update selection state
			if cell.has_method("set_selected"):
				cell.set_selected(is_selected)

			# Optionally trigger cell-level selection animations
			if cell.has_method("on_grid_selection_changed"):
				cell.on_grid_selection_changed(is_selected)

	# Trigger SELECTION_CHANGED animations if configured
	if not _is_initializing:
		_on_trigger_selection_changed()

## Handles changes to items_state.value.
##
## Normalizes the new value and rebuilds the grid contents accordingly.
func _on_items_state_changed(new_value: Variant, _old_value: Variant) -> void:
	var items := _normalize_items(new_value)
	_rebuild_cells(items)
	# Trigger VALUE_CHANGED animations if configured (after _is_initializing check)
	if not _is_initializing:
		_on_trigger_value_changed()

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

		var cell = _create_cell(item_data, i)
		if cell:
			add_child(cell)
			_current_cells.append(cell)

## Creates a cell control for the given item data and index.
##
## [param item_data]: The item descriptor (Dictionary/Resource) or null for empty slots
## [param index]: The cell index in the grid
## [return]: The created cell control, or null if creation failed
func _create_cell(item_data: Variant, index: int) -> Control:
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

	var cell = cell_instance as Control

	# Set standard interface on the cell
	if cell.has_method("set_item"):
		cell.set_item(item_data, index)

	if cell.has_method("set_selected"):
		# Set initial selection state based on selection_state
		var is_selected = false
		if selection_state and selection_state.value is int:
			is_selected = (selection_state.value as int) == index
		cell.set_selected(is_selected)

	# Make cells focusable for navigation
	cell.focus_mode = Control.FOCUS_ALL

	# Connect cell signals for navigation and activation
	if select_on_focus and not cell.focus_entered.is_connected(_on_cell_focus_entered):
		cell.focus_entered.connect(_on_cell_focus_entered.bind(index))

	if cell.has_signal("pressed") and not cell.pressed.is_connected(_on_cell_pressed):
		cell.pressed.connect(_on_cell_pressed.bind(index))

	if cell.has_signal("gui_input") and not cell.gui_input.is_connected(_on_cell_gui_input):
		cell.gui_input.connect(_on_cell_gui_input.bind(index))

	return cell

## Selects the cell at the given index and updates selection_state.
##
## Called when a cell is activated (e.g., via submit from navigator).
func _select_index(index: int) -> void:
	if selection_state == null:
		return
	_suppress_state_updates = true
	selection_state.set_value(index)
	_suppress_state_updates = false

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
		var items = items_state.value as Array
		if index >= 0 and index < items.size():
			item_data = items[index]

	var cell = _current_cells[index] if index >= 0 and index < _current_cells.size() else null
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
			var items = items_state.value as Array
			if index >= 0 and index < items.size():
				item_data = items[index]

		var cell = _current_cells[index] if index >= 0 and index < _current_cells.size() else null
		cell_activated.emit(index, item_data, cell)

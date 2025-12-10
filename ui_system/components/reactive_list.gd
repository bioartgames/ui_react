## List component that displays ReactiveArray items reactively.
## Auto-generates list items from array and updates reactively when array changes.
extends ItemList
class_name ReactiveList

## The ReactiveArray source to display.
@export var source: ReactiveArray = null

## Optional item template (PackedScene of ReactiveCell).
## If null, uses default ItemList rendering.
@export var item_template: PackedScene = null

## Optional selection reference (shared with all cells).
@export var selection: ReactiveReference = null

## Signal connections tracked for cleanup.
var _signal_connections: Array[SignalConnection] = []

## Cache of cell instances (if using template).
var _cell_instances: Array[ReactiveCell] = []

func _ready() -> void:
	# Connect to source array signals
	if source != null:
		_connect_array_signals()
		_refresh_items()
	
	# Connect to ItemList selection if not using templates
	if item_template == null:
		item_selected.connect(_on_item_selected)
		item_activated.connect(_on_item_activated)

func _exit_tree() -> void:
	_cleanup_connections()
	_cleanup_cells()

## Connects to ReactiveArray signals.
func _connect_array_signals() -> void:
	if source == null:
		return
	
	var item_added_callable = Callable(self, "_on_item_added")
	source.item_added.connect(item_added_callable)
	_signal_connections.append(SignalConnection.create(source.item_added, item_added_callable))
	
	var item_removed_callable = Callable(self, "_on_item_removed")
	source.item_removed.connect(item_removed_callable)
	_signal_connections.append(SignalConnection.create(source.item_removed, item_removed_callable))
	
	var item_changed_callable = Callable(self, "_on_item_changed")
	source.item_changed.connect(item_changed_callable)
	_signal_connections.append(SignalConnection.create(source.item_changed, item_changed_callable))
	
	var array_changed_callable = Callable(self, "_on_array_changed")
	source.array_changed.connect(array_changed_callable)
	_signal_connections.append(SignalConnection.create(source.array_changed, array_changed_callable))

## Refreshes all items in the list.
func _refresh_items() -> void:
	if source == null:
		return
	
	# Clear existing items
	clear()
	_cleanup_cells()
	
	# If using template, create cells
	if item_template != null:
		_refresh_items_with_template()
	else:
		_refresh_items_default()

## Refreshes items using default ItemList rendering.
func _refresh_items_default() -> void:
	if source == null:
		return
	
	var arr = source.value as Array
	for i in range(arr.size()):
		var item = arr[i]
		var display_text = _get_item_display_text(item)
		add_item(display_text)

## Refreshes items using ReactiveCell template.
func _refresh_items_with_template() -> void:
	if source == null or item_template == null:
		return
	
	var arr = source.value as Array
	for i in range(arr.size()):
		var item = arr[i]
		
		# Instantiate cell from template
		var cell = item_template.instantiate() as ReactiveCell
		if cell == null:
			# Fallback to default if template doesn't produce ReactiveCell
			var fallback_text = _get_item_display_text(item)
			add_item(fallback_text)
			continue
		
		# Set cell properties
		cell.item_index = i
		cell.item_source = source
		cell.selection_reference = selection
		
		# Add cell as child (ItemList will handle layout)
		add_child(cell)
		_cell_instances.append(cell)
		
		# For ItemList, we need to add an item entry for the cell
		# The cell will be positioned at the item index
		var item_text = _get_item_display_text(item)
		add_item(item_text)
		
		# Set the item's custom control to the cell
		set_item_custom_fg_color(i, Color.TRANSPARENT)  # Make item text transparent
		# Note: ItemList doesn't directly support custom controls per item
		# We'll use the cell as a child and position it manually if needed
		# For now, the cell will be a child node

## Gets display text for an item.
func _get_item_display_text(item: Variant) -> String:
	if item == null:
		return ""
	
	# If it's a ReactiveObject, try to get a "name" or "text" property
	if item is ReactiveObject:
		var reactive_obj = item as ReactiveObject
		var name_prop = reactive_obj.get_property("name")
		if name_prop != null:
			return str(name_prop)
		var text_prop = reactive_obj.get_property("text")
		if text_prop != null:
			return str(text_prop)
	
	# Otherwise, convert to string
	return str(item)

## Called when an item is added to the array.
func _on_item_added(_index: int, item: Variant) -> void:
	if item_template != null:
		_refresh_items_with_template()
	else:
		var item_text = _get_item_display_text(item)
		add_item(item_text)

## Called when an item is removed from the array.
func _on_item_removed(index: int) -> void:
	if item_template != null:
		_refresh_items()
	else:
		remove_item(index)

## Called when an item in the array changes.
func _on_item_changed(index: int, new_value: Variant, _old_value: Variant) -> void:
	if item_template != null:
		# Refresh the specific cell
		if index < _cell_instances.size():
			var cell = _cell_instances[index]
			if cell != null:
				# Update cell's item_index in case array was modified
				cell.item_index = index
	else:
		# Update the item text
		var updated_text = _get_item_display_text(new_value)
		set_item_text(index, updated_text)

## Called when the array structure changes.
func _on_array_changed() -> void:
	_refresh_items()

## Called when an item in the ItemList is selected (default rendering only).
func _on_item_selected(index: int) -> void:
	if selection != null and source != null:
		var item = source.get_item(index)
		if item != null:
			selection.set_reference(item as ReactiveValue)

## Called when an item in the ItemList is activated (double-clicked, default rendering only).
func _on_item_activated(index: int) -> void:
	_on_item_selected(index)

## Cleans up signal connections.
func _cleanup_connections() -> void:
	ReactiveLifecycleManager.cleanup_signal_connections(_signal_connections)
	_signal_connections.clear()

## Cleans up cell instances.
func _cleanup_cells() -> void:
	for cell in _cell_instances:
		if is_instance_valid(cell):
			cell.queue_free()
	_cell_instances.clear()


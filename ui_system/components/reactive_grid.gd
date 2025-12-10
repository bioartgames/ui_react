## Grid component that displays ReactiveArray items reactively.
## Auto-generates grid cells from array and updates reactively when array changes.
extends GridContainer
class_name ReactiveGrid

## The ReactiveArray source to display.
@export var source: ReactiveArray = null

## Optional selection reference (shared with all cells).
@export var selection: ReactiveReference = null

## Signal connections tracked for cleanup.
var _signal_connections: Array[SignalConnection] = []

## Cache of cell instances.
var _cell_instances: Array[ReactiveCell] = []

func _ready() -> void:
	# Set default columns if not already set (GridContainer.columns is inherited)
	if columns == 0:
		columns = 3
	
	# Connect to source array signals
	if source != null:
		_connect_array_signals()
		_refresh_cells()

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

## Refreshes all cells in the grid.
func _refresh_cells() -> void:
	if source == null:
		return
	
	# Clean up existing cells
	_cleanup_cells()
	
	var arr = source.value as Array
	for i in range(arr.size()):
		# Create ReactiveCell for this item
		var cell = ReactiveCell.new()
		cell.item_index = i
		cell.item_source = source
		cell.selection_reference = selection
		cell.name = "Cell_%d" % i
		
		# Add cell to grid
		add_child(cell)
		_cell_instances.append(cell)

## Called when an item is added to the array.
func _on_item_added(_index: int, _item: Variant) -> void:
	_refresh_cells()

## Called when an item is removed from the array.
func _on_item_removed(_index: int) -> void:
	_refresh_cells()

## Called when an item in the array changes.
func _on_item_changed(index: int, _new_value: Variant, _old_value: Variant) -> void:
	# Update the specific cell if it exists
	if index < _cell_instances.size():
		var cell = _cell_instances[index]
		if cell != null:
			# Update cell's item_index in case array was modified
			cell.item_index = index
			# The cell's bindings will update reactively if they're bound to reactive properties

## Called when the array structure changes.
func _on_array_changed() -> void:
	_refresh_cells()

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


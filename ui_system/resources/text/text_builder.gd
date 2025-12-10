## Text builder resource that combines text segments.
## Processes segments sequentially and auto-updates when sources change.
@icon("res://icon.svg")
class_name TextBuilder
extends Resource

## Array of text segments in order.
@export var segments: Array[TextSegment] = []

## Signal connections tracked for cleanup.
var _source_connections: Array[SignalConnection] = []

## Context for building text.
var _context: SegmentContext = null

## Builds the complete text from all segments.
func build() -> String:
	if segments.is_empty():
		return ""
	
	# Ensure context exists
	if _context == null:
		_context = SegmentContext.new()
	
	# Collect all source ReactiveValues and connect to them
	_collect_and_connect_sources()
	
	# Build text from segments
	var result = ""
	for segment in segments:
		if segment == null:
			continue
		result += segment.build(_context)
	
	return result

## Collects all ReactiveValues from source segments and connects to them.
func _collect_and_connect_sources() -> void:
	# Connect to all sources that are already registered in context
	if _context == null:
		return
	
	# Disconnect old connections first
	_cleanup_connections()
	
	# Connect to all ReactiveValues in context
	for source_name in _context.reactive_values:
		var reactive_value = _context.get_reactive_value(source_name)
		if reactive_value != null:
			var callable = Callable(self, "_on_source_changed")
			reactive_value.value_changed.connect(callable)
			_source_connections.append(SignalConnection.create(reactive_value.value_changed, callable))
	
	# Note: TranslationServer doesn't have language_changed signal in Godot 4.5
	# Translation segments will still work correctly, but won't auto-update on language change
	# To update translations when language changes, manually call build() or trigger text_changed signal
	# Components using TextBuilder can listen for language changes via other means if needed

## Sets a ReactiveValue in the context by name.
## Call this to register ReactiveValues that segments reference.
func set_source(name: String, reactive_value: ReactiveValue) -> void:
	if _context == null:
		_context = SegmentContext.new()
	
	# Remove old connection if exists
	var old_value = _context.get_reactive_value(name)
	if old_value != null:
		_disconnect_source(old_value)
	
	# Set new value
	_context.set_reactive_value(name, reactive_value)
	
	# Connect to new value
	if reactive_value != null:
		var callable = Callable(self, "_on_source_changed")
		reactive_value.value_changed.connect(callable)
		_source_connections.append(SignalConnection.create(reactive_value.value_changed, callable))

## Disconnects from a source ReactiveValue.
func _disconnect_source(reactive_value: ReactiveValue) -> void:
	if reactive_value == null:
		return
	
	# Find and remove connection
	for i in range(_source_connections.size() - 1, -1, -1):
		var conn = _source_connections[i]
		if conn.signal_ref == reactive_value.value_changed:
			_source_connections.remove_at(i)

## Called when a source ReactiveValue changes.
func _on_source_changed(_new_value: Variant, _old_value: Variant) -> void:
	# Emit signal that text needs to be rebuilt
	# Components listening to this will call build() again
	text_changed.emit()

## Signal emitted when text needs to be rebuilt (source changed).
signal text_changed

## Cleans up all signal connections.
func cleanup() -> void:
	_cleanup_connections()

## Internal cleanup method.
func _cleanup_connections() -> void:
	ReactiveLifecycleManager.cleanup_signal_connections(_source_connections)
	_source_connections.clear()


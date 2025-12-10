## Typed context Resource for segment building.
## Provides typed access to ReactiveValues and other context data.
@icon("res://icon.svg")
class_name SegmentContext
extends Resource

## Dictionary of ReactiveValues keyed by name.
## Segments can access reactive values via context.get_reactive_value(name).
@export var reactive_values: Dictionary = {}

## Gets a ReactiveValue by name from the context.
func get_reactive_value(name: String) -> ReactiveValue:
	if not reactive_values.has(name):
		return null
	return reactive_values[name] as ReactiveValue

## Sets a ReactiveValue in the context.
func set_reactive_value(name: String, value: ReactiveValue) -> void:
	reactive_values[name] = value


## Reactive value source segment.
## Reads from ReactiveValue and applies optional formatter.
@icon("res://icon.svg")
class_name SegmentSource
extends TextSegment

## Name of the ReactiveValue in the context.
@export var source_name: String = ""

## Optional formatter to apply to the value.
@export var formatter: TextFormatter = null

## Reads from ReactiveValue and applies formatter if present.
func build(context: SegmentContext) -> String:
	if source_name.is_empty():
		return ""
	
	var reactive_value = context.get_reactive_value(source_name)
	if reactive_value == null:
		return ""
	
	var value = reactive_value.value
	
	# Apply formatter if present
	if formatter != null:
		return formatter.format(value)
	
	# Otherwise, convert to string
	return str(value)


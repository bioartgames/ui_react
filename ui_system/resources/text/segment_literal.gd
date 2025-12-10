## Static text segment that returns literal text.
@icon("res://icon.svg")
class_name SegmentLiteral
extends TextSegment

## The literal text to return.
@export var text: String = ""

## Returns the literal text.
func build(context: SegmentContext) -> String:
	return text


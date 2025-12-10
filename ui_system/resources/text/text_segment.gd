## Base abstract class for text segments.
## Segments generate portions of text for TextBuilder.
@icon("res://icon.svg")
class_name TextSegment
extends Resource

## Builds the text for this segment using the provided context.
## Must be implemented by subclasses.
func build(context: SegmentContext) -> String:
	return ""


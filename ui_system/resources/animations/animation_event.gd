## Base abstract class for animation events.
## Events trigger actions or signals at specific points during animations.
@icon("res://icon.svg")
class_name AnimationEvent
extends Resource

## Triggers the event with the given context.
## Must be implemented by subclasses.
func trigger(_context: AnimationEventContext) -> void:
	pass

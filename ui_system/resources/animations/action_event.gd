## Event that triggers a ReactiveActionBinding when triggered.
## Reuses the action system from Phase 3.
@icon("res://icon.svg")
class_name ActionEvent
extends AnimationEvent

## The action binding to execute when this event triggers.
@export var action_binding: ReactiveActionBinding = null

## Triggers the event by executing the action binding.
func trigger(context: AnimationEventContext) -> void:
	if action_binding == null:
		return
	
	# Execute the action binding
	action_binding.execute()


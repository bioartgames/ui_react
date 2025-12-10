## Typed context Resource for animation events.
## Provides typed access to animation state, target Control, and event data.
@icon("res://icon.svg")
class_name AnimationEventContext
extends Resource

## The target Control being animated.
var target: Control

## The animation step that triggered this event (if applicable).
var step: AnimationStep

## The animation that triggered this event.
var animation: ReactiveAnimation

## Event type: "step_start", "step_complete", "animation_start", "animation_complete".
var event_type: String = ""

## Optional custom data for the event.
var data: Dictionary = {}

## Creates a new AnimationEventContext.
static func create(
	tgt: Control,
	anim: ReactiveAnimation,
	evt_type: String,
	anim_step: AnimationStep = null,
	custom_data: Dictionary = {}
) -> AnimationEventContext:
	var context = AnimationEventContext.new()
	context.target = tgt
	context.animation = anim
	context.step = anim_step
	context.event_type = evt_type
	context.data = custom_data
	return context


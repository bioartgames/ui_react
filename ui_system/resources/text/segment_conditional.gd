## Conditional segment that evaluates a condition and returns then_text or else_text.
## Reuses ValueComparisonCondition from Phase 3.
@icon("res://icon.svg")
class_name SegmentConditional
extends TextSegment

## The condition to evaluate.
@export var condition: ValueComparisonCondition = null

## The ReactiveValue to evaluate the condition against.
@export var source_name: String = ""

## Text to return if condition is true.
@export var then_text: String = ""

## Text to return if condition is false.
@export var else_text: String = ""

## Evaluates the condition and returns appropriate text.
func build(context: SegmentContext) -> String:
	if condition == null or source_name.is_empty():
		return else_text
	
	var reactive_value = context.get_reactive_value(source_name)
	if reactive_value == null:
		return else_text
	
	# Evaluate condition
	if condition.evaluate(reactive_value):
		return then_text
	else:
		return else_text


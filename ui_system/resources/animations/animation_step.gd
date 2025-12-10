## Single animation step that animates one property.
## Defines a property change with duration, easing, delay, and optional events.
@icon("res://icon.svg")
class_name AnimationStep
extends Resource

## Value mode enum: absolute or relative to current value.
enum ValueMode {
	ABSOLUTE,  ## End value is absolute
	RELATIVE   ## End value is relative to start (added to start)
}

## The target property path (e.g., "modulate:a", "position:x", "scale").
@export var target_property: String = ""

## Whether end_value is absolute or relative to start.
@export var value_mode: ValueMode = ValueMode.ABSOLUTE

## Starting value (optional for RELATIVE mode - uses current value if not set).
@export var start_value: Variant = null

## Ending value (absolute value or relative offset based on value_mode).
@export var end_value: Variant = null

## Duration of the animation step in seconds.
@export var duration: float = 0.5

## Delay before this step starts (for sequences).
@export var delay: float = 0.0

## Easing type for the animation.
@export var easing: Tween.EaseType = Tween.EASE_IN_OUT

## Events to trigger during this step (on_start, on_complete).
@export var events: Array[AnimationEvent] = []

## Gets the effective start value for the animation.
## If RELATIVE mode and start_value is null, returns current property value.
func get_start_value(target: Control) -> Variant:
	if value_mode == ValueMode.RELATIVE and start_value == null:
		# Get current property value
		return _get_property_value(target, target_property)
	return start_value

## Gets the effective end value for the animation.
## If RELATIVE mode, adds end_value to start value.
func get_end_value(target: Control) -> Variant:
	if value_mode == ValueMode.RELATIVE:
		var start = get_start_value(target)
		# Handle different types
		if start is float or start is int:
			return start + end_value
		elif start is Vector2:
			return start + (end_value as Vector2)
		elif start is Vector3:
			return start + (end_value as Vector3)
		elif start is Color:
			return start + (end_value as Color)
		# Fallback: try to add
		return start + end_value
	return end_value

## Gets a property value from the target Control using dot notation.
func _get_property_value(target: Control, property_path: String) -> Variant:
	if property_path.is_empty():
		return null
	
	var parts = property_path.split(":")
	if parts.size() == 1:
		# Simple property
		return target.get(property_path)
	elif parts.size() == 2:
		# Nested property (e.g., "modulate:a")
		var obj = target.get(parts[0])
		if obj != null:
			return obj.get(parts[1])
	
	return null

## Sets a property value on the target Control using dot notation.
func set_property_value(target: Control, property_path: String, value: Variant) -> void:
	if property_path.is_empty():
		return
	
	var parts = property_path.split(":")
	if parts.size() == 1:
		# Simple property
		target.set(property_path, value)
	elif parts.size() == 2:
		# Nested property (e.g., "modulate:a")
		var obj = target.get(parts[0])
		if obj != null:
			obj.set(parts[1], value)


## Condition that compares a target value to a constant or another ReactiveValue.
@icon("res://icon.svg")
class_name ValueComparisonCondition
extends ReactiveCondition

## Comparison operator enum.
enum ComparisonOperator {
	GREATER_THAN,      # >
	LESS_THAN,         # <
	EQUAL,             # ==
	NOT_EQUAL,         # !=
	LESS_THAN_OR_EQUAL,  # <=
	GREATER_THAN_OR_EQUAL,  # >=
	CONTAINS           # contains (for strings)
}

## The comparison operator to use.
@export var operator: ComparisonOperator = ComparisonOperator.EQUAL

## Constant value to compare against (if compare_to_reactive is null).
@export var compare_to_constant: Variant = null

## Optional ReactiveValue to compare against (takes precedence over compare_to_constant).
@export var compare_to_reactive: ReactiveValue = null

## Evaluates the condition against the target.
func evaluate(target: ReactiveValue) -> bool:
	if target == null:
		return false
	
	var target_value = target.value
	
	# Get comparison value
	var compare_value: Variant = null
	if compare_to_reactive != null:
		compare_value = compare_to_reactive.value
	else:
		compare_value = compare_to_constant
	
	# Perform comparison based on operator
	match operator:
		ComparisonOperator.GREATER_THAN:
			return _compare_greater_than(target_value, compare_value)
		ComparisonOperator.LESS_THAN:
			return _compare_less_than(target_value, compare_value)
		ComparisonOperator.EQUAL:
			return _compare_equal(target_value, compare_value)
		ComparisonOperator.NOT_EQUAL:
			return not _compare_equal(target_value, compare_value)
		ComparisonOperator.LESS_THAN_OR_EQUAL:
			return _compare_less_than(target_value, compare_value) or _compare_equal(target_value, compare_value)
		ComparisonOperator.GREATER_THAN_OR_EQUAL:
			return _compare_greater_than(target_value, compare_value) or _compare_equal(target_value, compare_value)
		ComparisonOperator.CONTAINS:
			return _compare_contains(target_value, compare_value)
	
	return false

## Compares if target_value > compare_value.
func _compare_greater_than(target_value: Variant, compare_value: Variant) -> bool:
	if target_value is int and compare_value is int:
		return target_value as int > compare_value as int
	elif target_value is float and compare_value is float:
		return target_value as float > compare_value as float
	elif target_value is int and compare_value is float:
		return target_value as int > compare_value as float
	elif target_value is float and compare_value is int:
		return target_value as float > compare_value as int
	return false

## Compares if target_value < compare_value.
func _compare_less_than(target_value: Variant, compare_value: Variant) -> bool:
	if target_value is int and compare_value is int:
		return target_value as int < compare_value as int
	elif target_value is float and compare_value is float:
		return target_value as float < compare_value as float
	elif target_value is int and compare_value is float:
		return target_value as int < compare_value as float
	elif target_value is float and compare_value is int:
		return target_value as float < compare_value as int
	return false

## Compares if target_value == compare_value.
func _compare_equal(target_value: Variant, compare_value: Variant) -> bool:
	return target_value == compare_value

## Checks if target_value contains compare_value (for strings).
func _compare_contains(target_value: Variant, compare_value: Variant) -> bool:
	if target_value is String and compare_value is String:
		return (target_value as String).contains(compare_value as String)
	return false


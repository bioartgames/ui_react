## Target/Action pair resource.
## Pairs a ReactiveValue target with an action and optional condition.
@icon("res://icon.svg")
class_name ReactiveActionBinding
extends Resource

## The target ReactiveValue (optional for ActionGroup - groups don't need single target).
@export var target: ReactiveValue = null

## The action to execute (can be ReactiveAction OR ActionGroup Resource).
@export var action: Variant = null

## Typed parameters for the action (e.g., IncrementParams, SetParams).
@export var params: ActionParams = null

## Optional condition - action only executes if condition evaluates to true.
@export var condition: ReactiveCondition = null

## Executes the action binding.
## Returns true if successful, false otherwise.
func execute() -> bool:
	# Check condition if present
	if condition != null:
		if target == null:
			return false
		if not condition.evaluate(target):
			return false
	
	# Validate action
	if action == null:
		return false
	
	# Handle ActionGroup
	if action is ActionGroup:
		var action_group = action as ActionGroup
		return action_group.execute(target)
	
	# Handle ReactiveAction
	if not (action is ReactiveAction):
		return false
	
	var reactive_action = action as ReactiveAction
	
	# Validate before executing
	if not reactive_action.validate_before_execute(target, params):
		return false
	
	# Execute the action
	return reactive_action.execute(target, params)


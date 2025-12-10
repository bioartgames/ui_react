## Action group resource for parallel/sequential execution.
## Can contain ReactiveActions or other ActionGroups (full nesting support).
@icon("res://icon.svg")
class_name ActionGroup
extends Resource

## Execution mode enum.
enum ExecutionMode {
	PARALLEL,  # All actions execute simultaneously
	SEQUENCE   # Actions execute sequentially (one after another)
}

## Actions to execute (can contain ReactiveActionBinding or ActionGroup).
@export var actions: Array[ReactiveActionBinding] = []

## How to execute the actions.
@export var execution_mode: ExecutionMode = ExecutionMode.PARALLEL

## Executes all actions in the group according to execution_mode.
## Returns true if all actions succeed, false if any fail.
## target parameter is optional (some actions may have their own targets).
func execute(_target: ReactiveValue = null) -> bool:
	if actions.is_empty():
		return true
	
	match execution_mode:
		ExecutionMode.PARALLEL:
			return _execute_parallel()
		ExecutionMode.SEQUENCE:
			return _execute_sequence()
	
	return false

## Executes all actions in parallel.
func _execute_parallel() -> bool:
	var all_succeeded = true
	for action_binding in actions:
		if action_binding == null:
			continue
		if not action_binding.execute():
			all_succeeded = false
	return all_succeeded

## Executes actions sequentially (one after another).
## Stops on first failure.
func _execute_sequence() -> bool:
	for action_binding in actions:
		if action_binding == null:
			continue
		if not action_binding.execute():
			return false  # Stop on first failure
	return true


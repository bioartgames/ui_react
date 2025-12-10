## Base abstract class for reactive actions.
## Actions perform operations on ReactiveValue targets.
@icon("res://icon.svg")
class_name ReactiveAction
extends Resource

## Executes the action on the target with the given parameters.
## Returns true if successful, false otherwise.
## Must be implemented by subclasses.
func execute(_target: ReactiveValue, _params: ActionParams) -> bool:
	return false

## Validates that the action can be executed on the target with the given parameters.
## Returns true if valid, false otherwise.
## Can be overridden by subclasses for custom validation.
func validate_before_execute(target: ReactiveValue, params: ActionParams) -> bool:
	if target == null:
		return false
	if params == null:
		return false
	return true

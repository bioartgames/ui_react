## Base abstract class for reactive conditions.
## Conditions evaluate runtime state to determine if actions should execute.
@icon("res://icon.svg")
class_name ReactiveCondition
extends Resource

## Evaluates the condition against the target.
## Returns true if condition is met, false otherwise.
## Must be implemented by subclasses.
func evaluate(_target: ReactiveValue) -> bool:
	return false

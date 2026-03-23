## Prevents re-entrant two-way binding between [State] and controls.
class_name ReactiveBindingGuard
extends RefCounted

var _updating: bool = false

## Returns true if the guard was entered; false if already updating (reentrant call).
func try_enter() -> bool:
	if _updating:
		return false
	_updating = true
	return true

func exit() -> void:
	_updating = false

func is_busy() -> bool:
	return _updating

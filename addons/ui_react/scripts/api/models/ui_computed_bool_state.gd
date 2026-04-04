@tool
@abstract
## Boolean [UiState] whose [member value] is refreshed by [method recompute] from explicit [member sources].
## Override [method compute_bool] in a concrete subclass. There is **no** dependency solver; avoid dependency cycles.
## Dependency updates: assign this resource to a [UiReact*] binding (e.g. [member UiReactCheckBox.checked_state]); [UiReactComputedService] wires [member sources] at runtime so [signal Resource.changed] on each dependency triggers [method recompute] (via [method Resource.emit_changed] on [UiState] updates).
class_name UiComputedBoolState
extends UiBoolState

@export var sources: Array[UiState] = []


func recompute() -> void:
	set_value(compute_bool())


@abstract func compute_bool() -> bool

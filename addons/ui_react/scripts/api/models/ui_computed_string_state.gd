@tool
@abstract
## String [UiState] whose [member value] is refreshed by [method recompute] from explicit [member sources].
## Override [method compute_string] in a concrete subclass. There is **no** dependency solver; avoid dependency cycles.
## Pair with [UiReactComputedSync] so [signal Resource.changed] on sources triggers [method recompute] (via [method Resource.emit_changed] on [UiState] updates).
class_name UiComputedStringState
extends UiStringState

@export var sources: Array[UiState] = []


func recompute() -> void:
	set_value(compute_string())


@abstract func compute_string() -> String

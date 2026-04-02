@tool
@abstract
## Boolean [UiState] whose [member value] is refreshed by [method recompute] from explicit [member sources].
## Override [method compute_bool] in a concrete subclass. There is **no** dependency solver; avoid dependency cycles.
## Pair with [UiReactComputedSync] so [signal value_changed] / [signal changed] on sources trigger [method recompute].
class_name UiComputedBoolState
extends UiBoolState

@export var sources: Array[UiState] = []


func recompute() -> void:
	set_value(compute_bool())


@abstract func compute_bool() -> bool

@tool
## Batch orchestration for multiple [UiTransactionalState] resources on one screen (e.g. options **Apply** / **Cancel**).
## Assign [member states] in order; call [method begin_edit_all], [method apply_all], or [method cancel_all] instead of looping in scene code.
## For inspector-driven wiring, prefer [UiReactButton] / [UiReactTextureButton] with [member UiReactButton.transactional_group], [UiTransactionalScreenConfig], and [UiReactTransactionalSession]; [UiReactTransactionalActions] remains for path-based Apply/Cancel (deprecated).
class_name UiTransactionalGroup
extends Resource

@export var states: Array[UiTransactionalState] = []


func begin_edit_all() -> void:
	for s in states:
		if s != null:
			s.begin_edit()


func apply_all() -> void:
	for s in states:
		if s != null:
			s.apply_draft()


func cancel_all() -> void:
	for s in states:
		if s != null:
			s.cancel_draft()


func has_pending_changes() -> bool:
	for s in states:
		if s != null and s.has_pending_changes():
			return true
	return false

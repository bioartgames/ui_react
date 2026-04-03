@tool
## Transactional [UiState] for draft / commit workflows (e.g. options screens).
## [member committed_value] is the last applied value; [method get_value] / [method set_value] read and write the **draft**.
## Open a sheet with [method begin_edit] (refresh draft from committed), then [method apply_draft] or [method cancel_draft] / [method reset_to_committed].
## For several transactional resources on one screen, batch [method begin_edit], [method apply_draft], and [method cancel_draft] via [UiTransactionalGroup] and optional [UiReactTransactionalActions].
class_name UiTransactionalState
extends UiState

@export var committed_value: Variant = 0.0

var _draft_value: Variant = 0.0


func _init(initial_committed: Variant = null) -> void:
	if typeof(initial_committed) != TYPE_NIL:
		committed_value = _clone_variant(initial_committed)
	_draft_value = _clone_variant(committed_value)


## Copies [member committed_value] into the draft and notifies listeners when the draft actually changes.
func begin_edit() -> void:
	var old_draft: Variant = _draft_value
	_draft_value = _clone_variant(committed_value)
	if _variants_equal(_draft_value, old_draft):
		emit_changed()
		return
	emit_changed()
	if not Engine.is_editor_hint():
		value_changed.emit(_draft_value, old_draft)


func get_value() -> Variant:
	return _draft_value


func set_value(new_value: Variant) -> void:
	if _variants_equal(_draft_value, new_value):
		return
	var old: Variant = _draft_value
	_draft_value = _clone_variant(new_value)
	if not Engine.is_editor_hint():
		value_changed.emit(_draft_value, old)
	emit_changed()


func set_silent(new_value: Variant) -> void:
	_draft_value = _clone_variant(new_value)
	emit_changed()


## Writes the draft into [member committed_value] (commit). Does not emit [signal UiState.value_changed] if draft already matched committed.
func apply_draft() -> void:
	if _variants_equal(committed_value, _draft_value):
		return
	committed_value = _clone_variant(_draft_value)
	emit_changed()


## Alias of [method cancel_draft].
func reset_to_committed() -> void:
	cancel_draft()


## Restores the draft from [member committed_value] and notifies listeners when the draft actually changes.
func cancel_draft() -> void:
	if _variants_equal(_draft_value, committed_value):
		return
	var old: Variant = _draft_value
	_draft_value = _clone_variant(committed_value)
	if not Engine.is_editor_hint():
		value_changed.emit(_draft_value, old)
	emit_changed()


func get_committed_value() -> Variant:
	return committed_value


func get_draft_value() -> Variant:
	return _draft_value


func has_pending_changes() -> bool:
	return not _variants_equal(_draft_value, committed_value)


## Used by editor validator: whether this resource’s payload matches a typed [UiState] binding slot.
func matches_expected_binding_class(expected: StringName) -> bool:
	var t: int = typeof(committed_value)
	match String(expected):
		"UiBoolState":
			return t == TYPE_BOOL
		"UiIntState":
			return t == TYPE_INT
		"UiFloatState":
			return t == TYPE_FLOAT or t == TYPE_INT
		"UiStringState":
			return t == TYPE_STRING or t == TYPE_STRING_NAME
		"UiArrayState":
			return t == TYPE_ARRAY
		_:
			return false


static func _clone_variant(v: Variant) -> Variant:
	match typeof(v):
		TYPE_ARRAY:
			return (v as Array).duplicate()
		TYPE_DICTIONARY:
			return (v as Dictionary).duplicate()
		_:
			return v


static func _variants_equal(a: Variant, b: Variant) -> bool:
	var ta := typeof(a)
	var tb := typeof(b)
	if ta != tb:
		var a_is_number := ta == TYPE_INT or ta == TYPE_FLOAT
		var b_is_number := tb == TYPE_INT or tb == TYPE_FLOAT
		if a_is_number and b_is_number:
			return is_equal_approx(float(a), float(b))
		return false
	if ta == TYPE_FLOAT:
		return is_equal_approx(float(a), float(b))
	return a == b

@tool
## Typed [UiState] for integer payloads (tab index, list selection, discrete indices).
## Only [int] values and [code]null[/code] (stored as [code]0[/code]) are accepted; [float] and other types are rejected with a warning.
class_name UiIntState
extends UiState

@export var value: int = 0


func _init(initial_value: Variant = 0) -> void:
	match typeof(initial_value):
		TYPE_NIL:
			## Default [code]value[/code] stays [code]0[/code].
			pass
		TYPE_INT:
			value = initial_value
		TYPE_FLOAT:
			push_warning("UiIntState: float initial value is not supported; use int")
		_:
			push_warning("UiIntState: unsupported initial type %s; use int" % type_string(typeof(initial_value)))


func get_value() -> Variant:
	return value


func set_value(new_value: Variant) -> void:
	var v: int
	if new_value == null:
		v = 0
	elif typeof(new_value) == TYPE_INT:
		v = new_value
	elif typeof(new_value) == TYPE_FLOAT:
		push_warning("UiIntState.set_value: float is not supported; use int")
		return
	else:
		push_warning("UiIntState.set_value: expected int, got %s" % type_string(typeof(new_value)))
		return
	if value == v:
		return
	var old: int = value
	value = v
	if not Engine.is_editor_hint():
		value_changed.emit(v, old)
	emit_changed()


func set_silent(new_value: Variant) -> void:
	if new_value == null:
		value = 0
		emit_changed()
		return
	if typeof(new_value) == TYPE_INT:
		value = new_value
		emit_changed()
		return
	if typeof(new_value) == TYPE_FLOAT:
		push_warning("UiIntState.set_silent: float is not supported; use int")
		return
	push_warning("UiIntState.set_silent: expected int, got %s" % type_string(typeof(new_value)))


func get_int_value() -> int:
	return value


func set_int_value(v: int) -> void:
	set_value(v)

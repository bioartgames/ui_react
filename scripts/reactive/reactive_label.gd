extends Label
class_name ReactiveLabel

@export var text_state: State
var _updating: bool = false
var _nested_states: Array[State] = []

func _ready() -> void:
	if text_state:
		text_state.value_changed.connect(_on_text_state_changed)
		_on_text_state_changed(text_state.value, text_state.value)

func _on_text_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _updating:
		return
	_rebind_nested_states(new_value)
	var new_text := _to_text(new_value)
	if text == new_text:
		return
	_updating = true
	text = new_text
	_updating = false

func _rebind_nested_states(value: Variant) -> void:
	for s in _nested_states:
		if is_instance_valid(s) and s.value_changed.is_connected(_on_nested_changed):
			s.value_changed.disconnect(_on_nested_changed)
	_nested_states.clear()
	if value is Array:
		for v in value:
			if v is State:
				var st: State = v
				if not st.value_changed.is_connected(_on_nested_changed):
					st.value_changed.connect(_on_nested_changed)
				_nested_states.append(st)

func _on_nested_changed(_new_value: Variant, _old_value: Variant) -> void:
	if text_state:
		_on_text_state_changed(text_state.value, text_state.value)

func _to_text(value: Variant) -> String:
	if value is State:
		return _to_text(value.value)
	if value is Array:
		var parts: Array[String] = []
		for v in value:
			parts.append(_to_text(v))
		return "".join(parts)
	return str(value)


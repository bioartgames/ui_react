extends LineEdit
class_name ReactiveLineEdit

@export var text_state: State
var _updating: bool = false

func _ready() -> void:
	text_changed.connect(_on_text_changed)
	if text_state:
		text_state.value_changed.connect(_on_text_state_changed)
		_on_text_state_changed(text_state.value, text_state.value)

func _on_text_changed(new_text: String) -> void:
	if not text_state or _updating:
		return
	if text_state.value == new_text:
		return
	_updating = true
	text_state.set_value(new_text)
	_updating = false

func _on_text_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _updating:
		return
	var new_text := _to_text(new_value)
	if text == new_text:
		return
	_updating = true
	text = new_text
	_updating = false

func _to_text(value: Variant) -> String:
	if value is Array:
		var parts: Array[String] = []
		for v in value:
			parts.append(str(v))
		return "".join(parts)
	return str(value)

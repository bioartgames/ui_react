extends HSlider
class_name ReactiveSlider

@export var value_state: State
var _updating: bool = false

func _ready() -> void:
	value_changed.connect(_on_value_changed)
	if value_state:
		value_state.value_changed.connect(_on_value_state_changed)
		_on_value_state_changed(value_state.value, value_state.value)

func _on_value_changed(v: float) -> void:
	if not value_state or _updating:
		return
	if float(value_state.value) == v:
		return
	_updating = true
	value_state.set_value(v)
	_updating = false

func _on_value_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _updating:
		return
	var target := float(new_value)
	if is_equal_approx(value, target):
		return
	_updating = true
	value = target
	_updating = false


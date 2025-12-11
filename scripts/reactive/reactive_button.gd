extends Button
class_name ReactiveButton

@export var pressed_state: State
@export var disabled_state: State
var _updating: bool = false

func _ready() -> void:
	pressed.connect(_on_pressed)
	toggled.connect(_on_toggled)
	if pressed_state:
		pressed_state.value_changed.connect(_on_pressed_state_changed)
		_on_pressed_state_changed(pressed_state.value, pressed_state.value)
	if disabled_state:
		disabled_state.value_changed.connect(_on_disabled_state_changed)
		_on_disabled_state_changed(disabled_state.value, disabled_state.value)

func _on_pressed() -> void:
	if not pressed_state or toggle_mode:
		return
	if _updating:
		return
	_updating = true
	pressed_state.set_value(true)
	_updating = false

func _on_toggled(active: bool) -> void:
	if not pressed_state or not toggle_mode or _updating:
		return
	if pressed_state.value == active:
		return
	_updating = true
	pressed_state.set_value(active)
	_updating = false

func _on_pressed_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _updating:
		return
	var desired := bool(new_value)
	if toggle_mode:
		if button_pressed == desired:
			return
		_updating = true
		button_pressed = desired
		_updating = false

func _on_disabled_state_changed(new_value: Variant, _old_value: Variant) -> void:
	var desired := bool(new_value)
	if disabled == desired:
		return
	disabled = desired

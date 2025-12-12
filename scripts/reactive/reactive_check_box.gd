extends CheckBox
class_name ReactiveCheckBox

@export var checked_state: State
@export var disabled_state: State
@export_group("Animation")
## Whether to enable toggle animation (default: true).
@export var toggle_animation: bool = true
## Duration for toggle animation in seconds.
@export var toggle_duration: float = 0.15
var _updating: bool = false

func _ready() -> void:
	toggled.connect(_on_toggled)
	if checked_state:
		checked_state.value_changed.connect(_on_checked_state_changed)
		_on_checked_state_changed(checked_state.value, checked_state.value)
	if disabled_state:
		disabled_state.value_changed.connect(_on_disabled_state_changed)
		_on_disabled_state_changed(disabled_state.value, disabled_state.value)

func _on_toggled(active: bool) -> void:
	if toggle_animation:
		# Quick scale animation for toggle feedback
		pivot_offset = UIAnimationUtils.get_center_pivot_offset(self)
		var t = UIAnimationUtils.create_safe_tween(self)
		if t:
			t.tween_property(self, "scale", Vector2(1.1, 1.1), toggle_duration * 0.5)
			t.tween_property(self, "scale", UIAnimationUtils.SCALE_MAX, toggle_duration * 0.5)

	if not checked_state or _updating:
		return
	if checked_state.value == active:
		return
	_updating = true
	checked_state.set_value(active)
	_updating = false

func _on_checked_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _updating:
		return
	var desired := bool(new_value)
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

extends Button
class_name UiReactButton

## Two-way binding for pressed state ([bool]). **Optional** — omit for a normal Button without external state sync.
@export var pressed_state: UiBoolState
## Two-way binding for disabled state ([bool]). **Optional**.
@export var disabled_state: UiBoolState

## **Optional** — Inspector-driven tweens (pressed, hover, toggled). Leave empty for no automatic animations.
## Each [UiAnimTarget] sets Trigger, Target NodePath, and animation type; no extra resource files required.
@export var animation_targets: Array[UiAnimTarget] = []

var _updating: bool = false
var _is_initializing: bool = true

func _ready() -> void:
	pressed.connect(_on_pressed)
	toggled.connect(_on_toggled)
	if pressed_state:
		pressed_state.value_changed.connect(_on_pressed_state_changed)
		_on_pressed_state_changed(pressed_state.get_value(), pressed_state.get_value())
	if disabled_state:
		disabled_state.value_changed.connect(_on_disabled_state_changed)
		_on_disabled_state_changed(disabled_state.get_value(), disabled_state.get_value())
	_validate_animation_targets()
	UiReactStateBindingHelper.deferred_finish_initialization(self)

## Validates animation targets and filters out invalid ones.
## Called automatically in [method _ready].
func _validate_animation_targets() -> void:
	var trigger_map: Dictionary = UiReactAnimTargetHelper.apply_validated_targets(self, "UiReactButton")

	# Connect signals based on which triggers are used
	if trigger_map.has(UiAnimTarget.Trigger.PRESSED):
		UiReactAnimTargetHelper.connect_if_absent(pressed, _on_trigger_pressed)
	if trigger_map.has(UiAnimTarget.Trigger.HOVER_ENTER):
		UiReactAnimTargetHelper.connect_if_absent(mouse_entered, _on_trigger_hover_enter)
	if trigger_map.has(UiAnimTarget.Trigger.HOVER_EXIT):
		UiReactAnimTargetHelper.connect_if_absent(mouse_exited, _on_trigger_hover_exit)
	if trigger_map.has(UiAnimTarget.Trigger.TOGGLED_ON) or trigger_map.has(UiAnimTarget.Trigger.TOGGLED_OFF):
		UiReactAnimTargetHelper.connect_if_absent(toggled, _on_trigger_toggled)

## Handles PRESSED trigger animations.
func _on_trigger_pressed() -> void:
	_trigger_animations(UiAnimTarget.Trigger.PRESSED)

## Handles HOVER_ENTER trigger animations.
func _on_trigger_hover_enter() -> void:
	_trigger_animations(UiAnimTarget.Trigger.HOVER_ENTER)

## Handles HOVER_EXIT trigger animations.
func _on_trigger_hover_exit() -> void:
	_trigger_animations(UiAnimTarget.Trigger.HOVER_EXIT)

## Finishes initialization, allowing animations to trigger on toggle changes.
func _finish_initialization() -> void:
	_is_initializing = false

## Handles TOGGLED_ON and TOGGLED_OFF trigger animations.
func _on_trigger_toggled(active: bool) -> void:
	# Skip animations during initialization
	if _is_initializing:
		return
	
	if active:
		_trigger_animations(UiAnimTarget.Trigger.TOGGLED_ON)
	else:
		_trigger_animations(UiAnimTarget.Trigger.TOGGLED_OFF)

## Triggers animations for targets matching the specified trigger type.
## [param trigger_type]: The trigger type to match.
func _trigger_animations(trigger_type: UiAnimTarget.Trigger) -> void:
	UiReactAnimTargetHelper.trigger_animations(self, animation_targets, trigger_type, true, disabled)

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
	if pressed_state.get_value() == active:
		return
	_updating = true
	pressed_state.set_value(active)
	_updating = false

func _on_pressed_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _updating:
		return
	var desired := UiReactStateBindingHelper.coerce_bool(new_value)
	if toggle_mode:
		if button_pressed == desired:
			return
		_updating = true
		button_pressed = desired
		_updating = false

func _on_disabled_state_changed(new_value: Variant, _old_value: Variant) -> void:
	var desired := UiReactStateBindingHelper.coerce_bool(new_value)
	if disabled == desired:
		return
	disabled = desired

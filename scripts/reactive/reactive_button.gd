extends Button
class_name ReactiveButton

@export var pressed_state: State
@export var disabled_state: State

## Targets to animate based on button events.
##
## Drag nodes here and configure each target's animation properties directly in the Inspector.
## Each target can specify its own trigger (pressed, hover enter/exit, toggled on/off), animation type,
## duration, and settings - no resource files needed! Leave empty to use manual signal connections.
@export var animation_targets: Array[AnimationTarget] = []

var _updating: bool = false
var _is_initializing: bool = true

func _ready() -> void:
	pressed.connect(_on_pressed)
	toggled.connect(_on_toggled)
	if pressed_state:
		pressed_state.value_changed.connect(_on_pressed_state_changed)
		_on_pressed_state_changed(pressed_state.value, pressed_state.value)
	if disabled_state:
		disabled_state.value_changed.connect(_on_disabled_state_changed)
		_on_disabled_state_changed(disabled_state.value, disabled_state.value)
	_validate_animation_targets()
	# Finish initialization after all signals are processed
	call_deferred("_finish_initialization")

## Validates animation targets and filters out invalid ones.
## Called automatically in [method _ready].
func _validate_animation_targets() -> void:
	animation_targets = ReactiveAnimationTargetHelper.validate_animation_targets(self, "ReactiveButton", animation_targets)
	var trigger_map = ReactiveAnimationTargetHelper.collect_triggers(animation_targets)
	
	# Connect signals based on which triggers are used
	if trigger_map.has(AnimationTarget.Trigger.PRESSED):
		if not pressed.is_connected(_on_trigger_pressed):
			pressed.connect(_on_trigger_pressed)
	if trigger_map.has(AnimationTarget.Trigger.HOVER_ENTER):
		if not mouse_entered.is_connected(_on_trigger_hover_enter):
			mouse_entered.connect(_on_trigger_hover_enter)
	if trigger_map.has(AnimationTarget.Trigger.HOVER_EXIT):
		if not mouse_exited.is_connected(_on_trigger_hover_exit):
			mouse_exited.connect(_on_trigger_hover_exit)
	if trigger_map.has(AnimationTarget.Trigger.TOGGLED_ON) or trigger_map.has(AnimationTarget.Trigger.TOGGLED_OFF):
		if not toggled.is_connected(_on_trigger_toggled):
			toggled.connect(_on_trigger_toggled)

## Handles PRESSED trigger animations.
func _on_trigger_pressed() -> void:
	_trigger_animations(AnimationTarget.Trigger.PRESSED)

## Handles HOVER_ENTER trigger animations.
func _on_trigger_hover_enter() -> void:
	_trigger_animations(AnimationTarget.Trigger.HOVER_ENTER)

## Handles HOVER_EXIT trigger animations.
func _on_trigger_hover_exit() -> void:
	_trigger_animations(AnimationTarget.Trigger.HOVER_EXIT)

## Finishes initialization, allowing animations to trigger on toggle changes.
func _finish_initialization() -> void:
	_is_initializing = false

## Handles TOGGLED_ON and TOGGLED_OFF trigger animations.
func _on_trigger_toggled(active: bool) -> void:
	# Skip animations during initialization
	if _is_initializing:
		return
	
	if active:
		_trigger_animations(AnimationTarget.Trigger.TOGGLED_ON)
	else:
		_trigger_animations(AnimationTarget.Trigger.TOGGLED_OFF)

## Triggers animations for targets matching the specified trigger type.
## [param trigger_type]: The trigger type to match.
func _trigger_animations(trigger_type: AnimationTarget.Trigger) -> void:
	ReactiveAnimationTargetHelper.trigger_animations(self, animation_targets, trigger_type, true, disabled)

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

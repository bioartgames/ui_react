extends Button
class_name ReactiveButton

@export_group("State Binding")
@export var pressed_state: State
@export var disabled_state: State

@export_group("Animation")
## Animation reels to execute based on button events.
##
## Drag AnimationReel resources here in the Inspector. Each reel can specify its trigger type
## (pressed, hover enter/exit, toggled on/off), target controls to animate, and animation clips
## to execute. Supports automatic execution modes: single, multi-target, and sequences.
@export var animations: Array[AnimationReel] = []

var _helper: ReactiveControlHelper

func _ready() -> void:
	# Initialize helper FIRST, before any state connections
	_helper = ReactiveControlHelper.new(self)

	pressed.connect(_on_pressed)
	toggled.connect(_on_toggled)
	if pressed_state:
		pressed_state.value_changed.connect(_on_pressed_state_changed)
		_on_pressed_state_changed(pressed_state.value, pressed_state.value)
	if disabled_state:
		disabled_state.value_changed.connect(_on_disabled_state_changed)
		_on_disabled_state_changed(disabled_state.value, disabled_state.value)
	_validate_animation_reels()
	# Finish initialization after all signals are processed
	call_deferred("_finish_initialization")

## Validates animation reels and filters out invalid ones.
## Called automatically in [method _ready].
func _validate_animation_reels() -> void:
	var result = AnimationReel.validate_for_control(self, animations)
	animations = result.valid_reels

	# Control-specific signal connections (stays in class)
	# Only connect signals for triggers that this control type supports
	if result.trigger_map.get(AnimationReel.Trigger.PRESSED, false):
		if not pressed.is_connected(_on_trigger_pressed):
			pressed.connect(_on_trigger_pressed)
	if result.trigger_map.get(AnimationReel.Trigger.HOVER_ENTER, false):
		if not mouse_entered.is_connected(_on_trigger_hover_enter):
			mouse_entered.connect(_on_trigger_hover_enter)
	if result.trigger_map.get(AnimationReel.Trigger.HOVER_EXIT, false):
		if not mouse_exited.is_connected(_on_trigger_hover_exit):
			mouse_exited.connect(_on_trigger_hover_exit)
	if result.trigger_map.get(AnimationReel.Trigger.TOGGLED_ON, false) or result.trigger_map.get(AnimationReel.Trigger.TOGGLED_OFF, false):
		if not toggled.is_connected(_on_trigger_toggled):
			toggled.connect(_on_trigger_toggled)

## Handles PRESSED trigger animations.
func _on_trigger_pressed() -> void:
	AnimationReel.trigger_matching(self, animations, AnimationReel.Trigger.PRESSED)

## Handles HOVER_ENTER trigger animations.
func _on_trigger_hover_enter() -> void:
	AnimationReel.trigger_matching(self, animations, AnimationReel.Trigger.HOVER_ENTER)

## Handles HOVER_EXIT trigger animations.
func _on_trigger_hover_exit() -> void:
	AnimationReel.trigger_matching(self, animations, AnimationReel.Trigger.HOVER_EXIT)

## Finishes initialization, allowing animations to trigger on toggle changes.
func _finish_initialization() -> void:
	# Mark initialization complete AFTER all state is synchronized
	_helper.finish_initialization()

## Handles TOGGLED_ON and TOGGLED_OFF trigger animations.
func _on_trigger_toggled(active: bool) -> void:
	# Skip animations during initialization
	if _helper.is_initializing():
		return
	
	if active:
		AnimationReel.trigger_matching(self, animations, AnimationReel.Trigger.TOGGLED_ON)
	else:
		AnimationReel.trigger_matching(self, animations, AnimationReel.Trigger.TOGGLED_OFF)

func _on_pressed() -> void:
	if not pressed_state or toggle_mode:
		return
	if _helper.is_updating():
		return
	_helper.set_updating(true)
	pressed_state.set_value(true)
	_helper.set_updating(false)

func _on_toggled(active: bool) -> void:
	if not pressed_state or not toggle_mode or _helper.is_updating():
		return
	if pressed_state.value == active:
		return
	_helper.set_updating(true)
	pressed_state.set_value(active)
	_helper.set_updating(false)

func _on_pressed_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _helper.is_initializing():
		return
	if toggle_mode:
		_helper.update_property_if_changed("button_pressed", new_value, func(x): return bool(x))

func _on_disabled_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _helper.is_initializing():
		return
	_helper.update_property_if_changed("disabled", new_value, func(x): return bool(x))

func _exit_tree() -> void:
	# Clean up any unified snapshots when the control is freed
	AnimationStateUtils.clear_unified_snapshot_for_target(self)

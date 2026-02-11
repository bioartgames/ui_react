@tool
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
	if Engine.is_editor_hint():
		# In the editor, only validate reels so trigger options are filtered.
		_validate_animation_reels()
		return

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
	var trigger_map: Dictionary = ReactiveAnimationSetup.setup_reels(self, animations, _get_control_type_hint())
	
	# Connect trigger signals
	var bindings: Array = [
		[AnimationReel.Trigger.PRESSED, pressed, _on_trigger_pressed],
		[AnimationReel.Trigger.HOVER_ENTER, mouse_entered, _on_trigger_hover_enter],
		[AnimationReel.Trigger.HOVER_EXIT, mouse_exited, _on_trigger_hover_exit],
		[AnimationReel.Trigger.TOGGLED_ON, toggled, _on_trigger_toggled],
		[AnimationReel.Trigger.TOGGLED_OFF, toggled, _on_trigger_toggled],
	]
	ReactiveAnimationSetup.connect_trigger_bindings(self, trigger_map, bindings)
	
	# Connect focus-driven hover animations
	var has_hover_triggers: bool = trigger_map.get(AnimationReel.Trigger.HOVER_ENTER, false) or trigger_map.get(AnimationReel.Trigger.HOVER_EXIT, false)
	if has_hover_triggers:
		ReactiveAnimationSetup.connect_focus_driven_hover(self, animations, func(): return _helper.is_initializing())

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

## Gets the control type hint for this reactive control.
## Used to filter available triggers in the Inspector.
func _get_control_type_hint() -> AnimationReel.ControlTypeHint:
	return AnimationReel.ControlTypeHint.BUTTON

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
	_helper.sync_focus_mode_to_disabled()

func _exit_tree() -> void:
	FocusDrivenHover.cleanup(self)
	# Clean up any unified snapshots when the control is freed
	AnimationStateUtils.clear_unified_snapshot_for_target(self)

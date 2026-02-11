@tool
extends SpinBox
class_name ReactiveSpinBox

@export var value_state: State
@export var disabled_state: State

## Targets to animate based on spin box events.
##
## Drag nodes here and configure each target's animation properties directly in the Inspector.
## Each target can specify its own trigger (value changed, increased, decreased, text entered, focus entered/exited, hover),
## animation type, duration, and settings - no resource files needed!
@export var animations: Array[AnimationReel] = []

var _helper: ReactiveControlHelper
var _last_value: float = 0.0

func _ready() -> void:
	if Engine.is_editor_hint():
		# In the editor, only validate reels so trigger options are filtered.
		_validate_animation_reels()
		return

	# Initialize helper FIRST, before any state connections
	_helper = ReactiveControlHelper.new(self)

	value_changed.connect(_on_value_changed)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	if value_state:
		value_state.value_changed.connect(_on_value_state_changed)
		_on_value_state_changed(value_state.value, value_state.value)
		_last_value = float(value_state.value) if value_state.value != null else 0.0
	else:
		_last_value = value
	_validate_animation_reels()
	# Finish initialization after all signals are processed
	call_deferred("_finish_initialization")

## Validates animation reels and filters out invalid ones.
## Called automatically in [method _ready].
func _validate_animation_reels() -> void:
	var trigger_map: Dictionary = ReactiveAnimationSetup.setup_reels(self, animations, _get_control_type_hint())
	
	# Connect trigger signals
	# Note: value_changed, focus_entered, and focus_exited are always connected in _ready
	var bindings: Array = [
		[AnimationReel.Trigger.HOVER_ENTER, mouse_entered, _on_trigger_hover_enter],
		[AnimationReel.Trigger.HOVER_EXIT, mouse_exited, _on_trigger_hover_exit],
	]
	ReactiveAnimationSetup.connect_trigger_bindings(self, trigger_map, bindings)
	
	# Note: FOCUS_ENTERED/FOCUS_EXITED are handled directly in _on_focus_entered/_on_focus_exited
	# Focus-driven hover is also handled there

## Finishes initialization, allowing animations to trigger on value changes.
func _finish_initialization() -> void:
	_helper.finish_initialization()

## Handles VALUE_CHANGED, VALUE_INCREASED, and VALUE_DECREASED trigger animations.
func _on_trigger_value_changed(new_value: float) -> void:
	# Skip animations during initialization
	if _helper.is_initializing():
		_last_value = new_value
		return
	
	_trigger_animations(AnimationReel.Trigger.VALUE_CHANGED)

	if new_value > _last_value:
		_trigger_animations(AnimationReel.Trigger.VALUE_INCREASED)
	elif new_value < _last_value:
		_trigger_animations(AnimationReel.Trigger.VALUE_DECREASED)

	_last_value = new_value

## Handles FOCUS_ENTERED trigger animations.
func _on_trigger_focus_entered() -> void:
	_trigger_animations(AnimationReel.Trigger.FOCUS_ENTERED)

## Handles FOCUS_EXITED trigger animations.
func _on_trigger_focus_exited() -> void:
	_trigger_animations(AnimationReel.Trigger.FOCUS_EXITED)

## Handles HOVER_ENTER trigger animations.
func _on_trigger_hover_enter() -> void:
	_trigger_animations(AnimationReel.Trigger.HOVER_ENTER)

## Handles HOVER_EXIT trigger animations.
func _on_trigger_hover_exit() -> void:
	_trigger_animations(AnimationReel.Trigger.HOVER_EXIT)

## Triggers animations for reels matching the specified trigger type.
## [param trigger_type]: The trigger type to match.
func _trigger_animations(trigger_type) -> void:
	AnimationReel.trigger_matching(self, animations, trigger_type)

func _on_value_changed(new_value: float) -> void:
	# Trigger animations if configured
	if animations.size() > 0:
		_on_trigger_value_changed(new_value)
	
	if not value_state or _helper.is_updating():
		return
	if float(value_state.value) == new_value:
		return
	_helper.set_updating(true)
	value_state.set_value(new_value)
	_helper.set_updating(false)

func _on_focus_entered() -> void:
	# Trigger animations if configured
	if animations.size() > 0:
		_on_trigger_focus_entered()
	# Handle focus-driven hover animations
	FocusDrivenHover.handle_focus_entered(self, animations, func(): return _helper.is_initializing())

func _on_focus_exited() -> void:
	# Trigger animations if configured
	if animations.size() > 0:
		_on_trigger_focus_exited()
	# Handle focus-driven hover animations
	FocusDrivenHover.handle_focus_exited(self, animations, func(): return _helper.is_initializing())

func _on_value_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _helper.is_updating():
		return
	var target_value := float(new_value)
	if is_equal_approx(value, target_value):
		return
	_helper.set_updating(true)
	value = target_value
	_last_value = value
	_helper.set_updating(false)

func _on_disabled_state_changed(_new_value: Variant, _old_value: Variant) -> void:
	# Note: SpinBox doesn't expose disabled property in Godot 4.5, so this is a no-op
	pass

## Gets the control type hint for this reactive control.
## Used to filter available triggers in the Inspector.
func _get_control_type_hint() -> AnimationReel.ControlTypeHint:
	return AnimationReel.ControlTypeHint.VALUE_INPUT

func _exit_tree() -> void:
	FocusDrivenHover.cleanup(self)

@tool
extends ProgressBar
class_name ReactiveProgressBar

@export var value_state: State

## Targets to animate based on progress bar events.
##
## Drag nodes here and configure each target's animation properties directly in the Inspector.
## Each target can specify its own trigger (value changed, increased, decreased, completed, hover),
## animation type, duration, and settings - no resource files needed!
@export var animations: Array[AnimationReel] = []

var _helper: ReactiveControlHelper
var _last_value: float = 0.0
var _was_completed: bool = false

func _ready() -> void:
	if Engine.is_editor_hint():
		# In the editor, only validate reels so trigger options are filtered.
		_validate_animation_reels()
		return

	# Initialize helper FIRST, before any state connections
	_helper = ReactiveControlHelper.new(self)

	if value_state:
		value_state.value_changed.connect(_on_value_state_changed)
		_on_value_state_changed(value_state.value, value_state.value)
		_last_value = float(value_state.value)
	else:
		_last_value = value
	_was_completed = _is_completed()
	_validate_animation_reels()
	# Finish initialization after all signals are processed
	call_deferred("_finish_initialization")

## Checks if progress bar is at completion (100%).
func _is_completed() -> bool:
	return value >= max_value

## Validates animation targets and filters out invalid ones.
## Called automatically in [method _ready].
func _validate_animation_reels() -> void:
	var trigger_map: Dictionary = ReactiveAnimationSetup.setup_reels(self, animations, _get_control_type_hint())
	
	# Connect trigger signals
	var bindings: Array = [
		[AnimationReel.Trigger.HOVER_ENTER, mouse_entered, _on_trigger_hover_enter],
		[AnimationReel.Trigger.HOVER_EXIT, mouse_exited, _on_trigger_hover_exit],
	]
	ReactiveAnimationSetup.connect_trigger_bindings(self, trigger_map, bindings)
	
	# Connect focus-driven hover animations
	ReactiveAnimationSetup.connect_focus_driven_hover(self, animations, func(): return _helper.is_initializing())

## Finishes initialization, allowing animations to trigger on value changes.
func _finish_initialization() -> void:
	_helper.finish_initialization()

## Handles VALUE_CHANGED, VALUE_INCREASED, VALUE_DECREASED, and COMPLETED trigger animations.
func _on_trigger_value_changed(new_value: float) -> void:
	# Skip animations during initialization
	if _helper.is_initializing():
		_last_value = new_value
		# Update completion state but don't trigger animation
		_was_completed = _is_completed()
		return
	
	_trigger_animations(AnimationReel.Trigger.VALUE_CHANGED)

	if new_value > _last_value:
		_trigger_animations(AnimationReel.Trigger.VALUE_INCREASED)
	elif new_value < _last_value:
		_trigger_animations(AnimationReel.Trigger.VALUE_DECREASED)

	# Check for completion
	var is_completed: bool = _is_completed()
	if is_completed and not _was_completed:
		_trigger_animations(AnimationReel.Trigger.COMPLETED)
	_was_completed = is_completed

	_last_value = new_value

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

func _on_value_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _helper.is_updating():
		return
	var target := float(new_value)
	if is_equal_approx(value, target):
		return
	_helper.set_updating(true)
	value = target
	
	# Trigger animations if configured
	if animations.size() > 0:
		_on_trigger_value_changed(target)

	_helper.set_updating(false)

## Gets the control type hint for this reactive control.
## Used to filter available triggers in the Inspector.
func _get_control_type_hint() -> AnimationReel.ControlTypeHint:
	return AnimationReel.ControlTypeHint.VALUE_INPUT

func _exit_tree() -> void:
	FocusDrivenHover.cleanup(self)

extends ProgressBar
class_name ReactiveProgressBar

@export var value_state: State

## Targets to animate based on progress bar events.
##
## Drag nodes here and configure each target's animation properties directly in the Inspector.
## Each target can specify its own trigger (value changed, increased, decreased, completed, hover),
## animation type, duration, and settings - no resource files needed!
@export var animation_targets: Array[AnimationTarget] = []

var _updating: bool = false
var _last_value: float = 0.0
var _was_completed: bool = false
var _is_initializing: bool = true

func _ready() -> void:
	if value_state:
		value_state.value_changed.connect(_on_value_state_changed)
		_on_value_state_changed(value_state.value, value_state.value)
		_last_value = float(value_state.value)
	else:
		_last_value = value
	_was_completed = _is_completed()
	_validate_animation_targets()
	# Finish initialization after all signals are processed
	call_deferred("_finish_initialization")

## Checks if progress bar is at completion (100%).
func _is_completed() -> bool:
	return value >= max_value

## Validates animation targets and filters out invalid ones.
## Called automatically in [method _ready].
func _validate_animation_targets() -> void:
	animation_targets = ReactiveAnimationTargetHelper.validate_animation_targets(self, "ReactiveProgressBar", animation_targets)
	var trigger_map = ReactiveAnimationTargetHelper.collect_triggers(animation_targets)
	
	# Connect signals based on which triggers are used
	if trigger_map.has(AnimationTarget.Trigger.HOVER_ENTER):
		if not mouse_entered.is_connected(_on_trigger_hover_enter):
			mouse_entered.connect(_on_trigger_hover_enter)
	if trigger_map.has(AnimationTarget.Trigger.HOVER_EXIT):
		if not mouse_exited.is_connected(_on_trigger_hover_exit):
			mouse_exited.connect(_on_trigger_hover_exit)

## Finishes initialization, allowing animations to trigger on value changes.
func _finish_initialization() -> void:
	_is_initializing = false

## Handles VALUE_CHANGED, VALUE_INCREASED, VALUE_DECREASED, and COMPLETED trigger animations.
func _on_trigger_value_changed(new_value: float) -> void:
	# Skip animations during initialization
	if _is_initializing:
		_last_value = new_value
		# Update completion state but don't trigger animation
		_was_completed = _is_completed()
		return
	
	_trigger_animations(AnimationTarget.Trigger.VALUE_CHANGED)
	
	if new_value > _last_value:
		_trigger_animations(AnimationTarget.Trigger.VALUE_INCREASED)
	elif new_value < _last_value:
		_trigger_animations(AnimationTarget.Trigger.VALUE_DECREASED)
	
	# Check for completion
	var is_completed = _is_completed()
	if is_completed and not _was_completed:
		_trigger_animations(AnimationTarget.Trigger.COMPLETED)
	_was_completed = is_completed
	
	_last_value = new_value

## Handles HOVER_ENTER trigger animations.
func _on_trigger_hover_enter() -> void:
	_trigger_animations(AnimationTarget.Trigger.HOVER_ENTER)

## Handles HOVER_EXIT trigger animations.
func _on_trigger_hover_exit() -> void:
	_trigger_animations(AnimationTarget.Trigger.HOVER_EXIT)

## Triggers animations for targets matching the specified trigger type.
## [param trigger_type]: The trigger type to match.
func _trigger_animations(trigger_type: AnimationTarget.Trigger) -> void:
	ReactiveAnimationTargetHelper.trigger_animations(self, animation_targets, trigger_type)

func _on_value_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _updating:
		return
	var target := float(new_value)
	if is_equal_approx(value, target):
		return
	_updating = true
	value = target
	
	# Trigger animations if configured
	if animation_targets.size() > 0:
		_on_trigger_value_changed(target)
	
	_updating = false

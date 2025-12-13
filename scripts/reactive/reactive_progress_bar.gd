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
	var valid_targets: Array[AnimationTarget] = []
	var has_hover_enter_targets = false
	var has_hover_exit_targets = false
	
	for anim_target in animation_targets:
		if anim_target == null:
			continue
		
		# Check if target is set
		if anim_target.target.is_empty():
			push_warning("ReactiveProgressBar '%s': AnimationTarget has no target. Set target (NodePath) in the Inspector. Tip: Drag a node to target." % name)
			continue
		
		# Verify the target resolves to a valid Control
		var target_node = get_node_or_null(anim_target.target)
		if target_node == null:
			push_warning("ReactiveProgressBar '%s': AnimationTarget target '%s' not found. Check the NodePath." % [name, anim_target.target])
			continue
		
		if not (target_node is Control):
			push_warning("ReactiveProgressBar '%s': AnimationTarget target '%s' is not a Control node." % [name, anim_target.target])
			continue
		
		valid_targets.append(anim_target)
		
		# Track which triggers we need to connect (only hover needs signal connections)
		match anim_target.trigger:
			AnimationTarget.Trigger.HOVER_ENTER:
				has_hover_enter_targets = true
			AnimationTarget.Trigger.HOVER_EXIT:
				has_hover_exit_targets = true
	
	animation_targets = valid_targets
	
	# Connect signals based on which triggers are used
	if has_hover_enter_targets:
		if not mouse_entered.is_connected(_on_trigger_hover_enter):
			mouse_entered.connect(_on_trigger_hover_enter)
	if has_hover_exit_targets:
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
	if animation_targets.size() == 0:
		return
	
	# Apply animations for targets matching this trigger
	for anim_target in animation_targets:
		if anim_target == null:
			continue
		
		if anim_target.trigger != trigger_type:
			continue
		
		anim_target.apply(self)

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

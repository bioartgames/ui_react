extends CheckBox
class_name ReactiveCheckBox

@export var checked_state: State
@export var disabled_state: State

## Targets to animate based on checkbox events.
##
## Drag nodes here and configure each target's animation properties directly in the Inspector.
## Each target can specify its own trigger (toggled on/off, hover enter/exit), animation type,
## duration, and settings - no resource files needed! Leave empty to use manual signal connections.
@export var animation_targets: Array[AnimationTarget] = []

var _updating: bool = false

func _ready() -> void:
	toggled.connect(_on_toggled)
	if checked_state:
		checked_state.value_changed.connect(_on_checked_state_changed)
		_on_checked_state_changed(checked_state.value, checked_state.value)
	if disabled_state:
		disabled_state.value_changed.connect(_on_disabled_state_changed)
		_on_disabled_state_changed(disabled_state.value, disabled_state.value)
	_validate_animation_targets()

## Validates animation targets and filters out invalid ones.
## Called automatically in [method _ready].
func _validate_animation_targets() -> void:
	var valid_targets: Array[AnimationTarget] = []
	var has_toggled_on_targets = false
	var has_toggled_off_targets = false
	var has_hover_enter_targets = false
	var has_hover_exit_targets = false
	
	for anim_target in animation_targets:
		if anim_target == null:
			continue
		
		# Check if target is set
		if anim_target.target.is_empty():
			push_warning("ReactiveCheckBox '%s': AnimationTarget has no target. Set target (NodePath) in the Inspector. Tip: Drag a node to target." % name)
			continue
		
		# Verify the target resolves to a valid Control
		var target_node = get_node_or_null(anim_target.target)
		if target_node == null:
			push_warning("ReactiveCheckBox '%s': AnimationTarget target '%s' not found. Check the NodePath." % [name, anim_target.target])
			continue
		
		if not (target_node is Control):
			push_warning("ReactiveCheckBox '%s': AnimationTarget target '%s' is not a Control node." % [name, anim_target.target])
			continue
		
		valid_targets.append(anim_target)
		
		# Track which triggers we need to connect
		match anim_target.trigger:
			AnimationTarget.Trigger.TOGGLED_ON:
				has_toggled_on_targets = true
			AnimationTarget.Trigger.TOGGLED_OFF:
				has_toggled_off_targets = true
			AnimationTarget.Trigger.HOVER_ENTER:
				has_hover_enter_targets = true
			AnimationTarget.Trigger.HOVER_EXIT:
				has_hover_exit_targets = true
	
	animation_targets = valid_targets
	
	# Connect signals based on which triggers are used
	if has_toggled_on_targets or has_toggled_off_targets:
		if not toggled.is_connected(_on_trigger_toggled):
			toggled.connect(_on_trigger_toggled)
	if has_hover_enter_targets:
		if not mouse_entered.is_connected(_on_trigger_hover_enter):
			mouse_entered.connect(_on_trigger_hover_enter)
	if has_hover_exit_targets:
		if not mouse_exited.is_connected(_on_trigger_hover_exit):
			mouse_exited.connect(_on_trigger_hover_exit)

## Handles TOGGLED_ON and TOGGLED_OFF trigger animations.
func _on_trigger_toggled(active: bool) -> void:
	if active:
		_trigger_animations(AnimationTarget.Trigger.TOGGLED_ON)
	else:
		_trigger_animations(AnimationTarget.Trigger.TOGGLED_OFF)

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
		
		# Respect disabled state if configured
		if anim_target.respect_disabled and disabled:
			continue
		
		anim_target.apply(self)

func _on_toggled(active: bool) -> void:
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

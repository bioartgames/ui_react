extends LineEdit
class_name ReactiveLineEdit

@export var text_state: State

## Targets to animate based on line edit events.
##
## Drag nodes here and configure each target's animation properties directly in the Inspector.
## Each target can specify its own trigger (text changed, text entered, focus entered/exited, hover),
## animation type, duration, and settings - no resource files needed!
@export var animation_targets: Array[AnimationTarget] = []

var _updating: bool = false

func _ready() -> void:
	text_changed.connect(_on_text_changed)
	if text_state:
		text_state.value_changed.connect(_on_text_state_changed)
		_on_text_state_changed(text_state.value, text_state.value)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	_validate_animation_targets()

## Validates animation targets and filters out invalid ones.
## Called automatically in [method _ready].
func _validate_animation_targets() -> void:
	var valid_targets: Array[AnimationTarget] = []
	var has_text_entered_targets = false
	var has_hover_enter_targets = false
	var has_hover_exit_targets = false
	
	for anim_target in animation_targets:
		if anim_target == null:
			continue
		
		# Check if target is set
		if anim_target.target.is_empty():
			push_warning("ReactiveLineEdit '%s': AnimationTarget has no target. Set target (NodePath) in the Inspector. Tip: Drag a node to target." % name)
			continue
		
		# Verify the target resolves to a valid Control
		var target_node = get_node_or_null(anim_target.target)
		if target_node == null:
			push_warning("ReactiveLineEdit '%s': AnimationTarget target '%s' not found. Check the NodePath." % [name, anim_target.target])
			continue
		
		if not (target_node is Control):
			push_warning("ReactiveLineEdit '%s': AnimationTarget target '%s' is not a Control node." % [name, anim_target.target])
			continue
		
		valid_targets.append(anim_target)
		
		# Track which triggers we need to connect
		match anim_target.trigger:
			AnimationTarget.Trigger.TEXT_ENTERED:
				has_text_entered_targets = true
			AnimationTarget.Trigger.HOVER_ENTER:
				has_hover_enter_targets = true
			AnimationTarget.Trigger.HOVER_EXIT:
				has_hover_exit_targets = true
	
	animation_targets = valid_targets
	
	# Connect signals based on which triggers are used
	if has_text_entered_targets:
		if not text_submitted.is_connected(_on_trigger_text_entered):
			text_submitted.connect(_on_trigger_text_entered)
	if has_hover_enter_targets:
		if not mouse_entered.is_connected(_on_trigger_hover_enter):
			mouse_entered.connect(_on_trigger_hover_enter)
	if has_hover_exit_targets:
		if not mouse_exited.is_connected(_on_trigger_hover_exit):
			mouse_exited.connect(_on_trigger_hover_exit)

## Handles TEXT_CHANGED trigger animations.
func _on_trigger_text_changed(_new_text: String) -> void:
	_trigger_animations(AnimationTarget.Trigger.TEXT_CHANGED)

## Handles TEXT_ENTERED trigger animations.
func _on_trigger_text_entered(_text: String) -> void:
	_trigger_animations(AnimationTarget.Trigger.TEXT_ENTERED)

## Handles FOCUS_ENTERED trigger animations.
func _on_focus_entered() -> void:
	_trigger_animations(AnimationTarget.Trigger.FOCUS_ENTERED)

## Handles FOCUS_EXITED trigger animations.
func _on_focus_exited() -> void:
	_trigger_animations(AnimationTarget.Trigger.FOCUS_EXITED)

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

func _on_text_changed(new_text: String) -> void:
	# Trigger animations if configured
	if animation_targets.size() > 0:
		_on_trigger_text_changed(new_text)
	
	if not text_state or _updating:
		return
	if text_state.value == new_text:
		return
	_updating = true
	text_state.set_value(new_text)
	_updating = false

func _on_text_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _updating:
		return
	var new_text := _to_text(new_value)
	if text == new_text:
		return
	_updating = true
	text = new_text
	_updating = false

func _to_text(value: Variant) -> String:
	if value is Array:
		var parts: Array[String] = []
		for v in value:
			parts.append(str(v))
		return "".join(parts)
	return str(value)

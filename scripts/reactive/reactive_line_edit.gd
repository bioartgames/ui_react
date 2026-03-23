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
var _is_initializing: bool = true

func _ready() -> void:
	text_changed.connect(_on_text_changed)
	if text_state:
		text_state.value_changed.connect(_on_text_state_changed)
		_on_text_state_changed(text_state.value, text_state.value)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	_validate_animation_targets()
	ReactiveStateBindingHelper.deferred_finish_initialization(self)

## Validates animation targets and filters out invalid ones.
## Called automatically in [method _ready].
func _validate_animation_targets() -> void:
	var r = ReactiveAnimationTargetHelper.validate_and_map_triggers(self, "ReactiveLineEdit", animation_targets)
	animation_targets = r["animation_targets"]
	var trigger_map = r["trigger_map"]
	
	# Connect signals based on which triggers are used
	if trigger_map.has(AnimationTarget.Trigger.TEXT_ENTERED):
		if not text_submitted.is_connected(_on_trigger_text_entered):
			text_submitted.connect(_on_trigger_text_entered)
	if trigger_map.has(AnimationTarget.Trigger.HOVER_ENTER):
		if not mouse_entered.is_connected(_on_trigger_hover_enter):
			mouse_entered.connect(_on_trigger_hover_enter)
	if trigger_map.has(AnimationTarget.Trigger.HOVER_EXIT):
		if not mouse_exited.is_connected(_on_trigger_hover_exit):
			mouse_exited.connect(_on_trigger_hover_exit)

## Finishes initialization, allowing animations to trigger on text changes.
func _finish_initialization() -> void:
	_is_initializing = false

## Handles TEXT_CHANGED trigger animations.
func _on_trigger_text_changed(_new_text: String) -> void:
	# Skip animations during initialization
	if _is_initializing:
		return
	
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
	ReactiveAnimationTargetHelper.trigger_animations(self, animation_targets, trigger_type)

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

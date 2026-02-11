@tool
extends LineEdit
class_name ReactiveLineEdit

@export var text_state: State

## Targets to animate based on line edit events.
##
## Drag nodes here and configure each target's animation properties directly in the Inspector.
## Each target can specify its own trigger (text changed, text entered, focus entered/exited, hover),
## animation type, duration, and settings - no resource files needed!
@export var animations: Array[AnimationReel] = []

var _helper: ReactiveControlHelper

func _ready() -> void:
	if Engine.is_editor_hint():
		# In the editor, only validate reels so trigger options are filtered.
		_validate_animation_reels()
		return

	# Initialize helper FIRST, before any state connections
	_helper = ReactiveControlHelper.new(self)

	text_changed.connect(_on_text_changed)
	if text_state:
		text_state.value_changed.connect(_on_text_state_changed)
		_on_text_state_changed(text_state.value, text_state.value)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	_validate_animation_reels()
	# Finish initialization after all signals are processed
	call_deferred("_finish_initialization")

## Validates animation reels and filters out invalid ones.
## Called automatically in [method _ready].
func _validate_animation_reels() -> void:
	var validation_result = AnimationReel.validate_for_control(self, animations)
	animations = validation_result.valid_reels

	# Set control context on each reel for Inspector filtering
	var control_type = _get_control_type_hint()
	for reel in animations:
		if reel:
			reel.control_type_context = control_type

	# Control-specific signal connections (stays in class)
	var has_text_entered_targets: bool = validation_result.trigger_map.get(AnimationReel.Trigger.TEXT_ENTERED, false)
	var has_hover_enter_targets: bool = validation_result.trigger_map.get(AnimationReel.Trigger.HOVER_ENTER, false)
	var has_hover_exit_targets: bool = validation_result.trigger_map.get(AnimationReel.Trigger.HOVER_EXIT, false)

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

## Finishes initialization, allowing animations to trigger on text changes.
func _finish_initialization() -> void:
	_helper.finish_initialization()

## Handles TEXT_CHANGED trigger animations.
func _on_trigger_text_changed(_new_text: String) -> void:
	# Skip animations during initialization
	if _helper.is_initializing():
		return
	
	_trigger_animations(AnimationReel.Trigger.TEXT_CHANGED)

## Handles TEXT_ENTERED trigger animations.
func _on_trigger_text_entered(_text: String) -> void:
	_trigger_animations(AnimationReel.Trigger.TEXT_ENTERED)

## Handles FOCUS_ENTERED trigger animations.
func _on_focus_entered() -> void:
	# Trigger FOCUS_ENTERED animations
	_trigger_animations(AnimationReel.Trigger.FOCUS_ENTERED)
	# Handle focus-driven hover animations
	FocusDrivenHover.handle_focus_entered(self, animations, func(): return _helper.is_initializing())

## Handles FOCUS_EXITED trigger animations.
func _on_focus_exited() -> void:
	# Trigger FOCUS_EXITED animations
	_trigger_animations(AnimationReel.Trigger.FOCUS_EXITED)
	# Handle focus-driven hover animations
	FocusDrivenHover.handle_focus_exited(self, animations, func(): return _helper.is_initializing())

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

func _on_text_changed(new_text: String) -> void:
	# Trigger animations if configured
	if animations.size() > 0:
		_on_trigger_text_changed(new_text)
	
	if not text_state or _helper.is_updating():
		return
	if text_state.value == new_text:
		return
	_helper.set_updating(true)
	text_state.set_value(new_text)
	_helper.set_updating(false)

func _on_text_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _helper.is_updating():
		return
	var new_text := _to_text(new_value)
	
	# Use helper to update property safely
	_helper.update_property_if_changed("text", new_text, func(x): return str(x))

func _to_text(value: Variant) -> String:
	if value is Array:
		var parts: Array[String] = []
		for v in value:
			parts.append(str(v))
		return "".join(parts)
	return str(value)

## Gets the control type hint for this reactive control.
## Used to filter available triggers in the Inspector.
func _get_control_type_hint() -> AnimationReel.ControlTypeHint:
	return AnimationReel.ControlTypeHint.TEXT_INPUT

func _exit_tree() -> void:
	FocusDrivenHover.cleanup(self)

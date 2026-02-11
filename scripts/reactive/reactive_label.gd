@tool
extends Label
class_name ReactiveLabel

@export var text_state: State

## Targets to animate based on label events.
##
## Drag nodes here and configure each target's animation properties directly in the Inspector.
## Each target can specify its own trigger (text changed, hover enter/exit), animation type,
## duration, and settings - no resource files needed! Leave empty to use manual signal connections.
@export var animations: Array[AnimationReel] = []

var _helper: ReactiveControlHelper
var _nested_states: Array[State] = []

func _ready() -> void:
	if Engine.is_editor_hint():
		# In the editor, only validate reels so trigger options are filtered.
		_validate_animation_reels()
		return

	# Initialize helper FIRST, before any state connections
	_helper = ReactiveControlHelper.new(self)

	if text_state:
		text_state.value_changed.connect(_on_text_state_changed)
		_on_text_state_changed(text_state.value, text_state.value)
	_validate_animation_reels()
	# Finish initialization after all signals are processed
	call_deferred("_finish_initialization")

## Validates animation reels and filters out invalid ones.
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

## Finishes initialization, allowing animations to trigger on text changes.
func _finish_initialization() -> void:
	_helper.finish_initialization()

## Handles TEXT_CHANGED trigger animations.
func _on_trigger_text_changed(_new_value: Variant, _old_value: Variant) -> void:
	# Skip animations during initialization
	if _helper.is_initializing():
		return
	
	_trigger_animations(AnimationReel.Trigger.TEXT_CHANGED)

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

func _on_text_state_changed(new_value: Variant, old_value: Variant) -> void:
	if _helper.is_updating():
		return
	_rebind_nested_states(new_value)
	var new_text := _to_text(new_value)
	
	# Use helper to update property safely
	if _helper.update_property_if_changed("text", new_text, func(x): return str(x)):
		# Trigger animations if configured
		if animations.size() > 0:
			_on_trigger_text_changed(new_value, old_value)

func _rebind_nested_states(value: Variant) -> void:
	for s in _nested_states:
		if is_instance_valid(s) and s.value_changed.is_connected(_on_nested_changed):
			s.value_changed.disconnect(_on_nested_changed)
	_nested_states.clear()
	if value is Array:
		for v in value:
			if v is State:
				var st: State = v
				if not st.value_changed.is_connected(_on_nested_changed):
					st.value_changed.connect(_on_nested_changed)
				_nested_states.append(st)

func _on_nested_changed(_new_value: Variant, _old_value: Variant) -> void:
	if text_state:
		_on_text_state_changed(text_state.value, text_state.value)

func _to_text(value: Variant) -> String:
	if value is State:
		return _to_text(value.value)
	if value is Array:
		var parts: Array[String] = []
		for v in value:
			parts.append(_to_text(v))
		return "".join(parts)
	return str(value)

## Gets the control type hint for this reactive control.
## Used to filter available triggers in the Inspector.
func _get_control_type_hint() -> AnimationReel.ControlTypeHint:
	return AnimationReel.ControlTypeHint.LABEL

func _exit_tree() -> void:
	FocusDrivenHover.cleanup(self)

@tool
extends HSlider
class_name ReactiveSlider

@export var value_state: State

## Targets to animate based on slider events.
##
## Drag nodes here and configure each target's animation properties directly in the Inspector.
## Each target can specify its own trigger (value changed, increased, decreased, drag started/ended, hover),
## animation type, duration, and settings - no resource files needed!
@export var animations: Array[AnimationReel] = []

var _helper: ReactiveControlHelper
var _last_value: float = 0.0
var _is_dragging: bool = false

func _ready() -> void:
	if Engine.is_editor_hint():
		# In the editor, only validate reels so trigger options are filtered.
		_validate_animation_reels()
		return

	# Initialize helper FIRST, before any state connections
	_helper = ReactiveControlHelper.new(self)

	value_changed.connect(_on_value_changed)
	if value_state:
		value_state.value_changed.connect(_on_value_state_changed)
		_on_value_state_changed(value_state.value, value_state.value)
		_last_value = float(value_state.value)
	else:
		_last_value = value
	gui_input.connect(_on_gui_input)
	_validate_animation_reels()
	# Finish initialization after all signals are processed
	call_deferred("_finish_initialization")

## Handles GUI input to detect drag start/end.
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				if not _is_dragging:
					_is_dragging = true
					_trigger_animations(AnimationReel.Trigger.DRAG_STARTED)
			else:
				if _is_dragging:
					_is_dragging = false
					_trigger_animations(AnimationReel.Trigger.DRAG_ENDED)

## Validates animation reels and filters out invalid ones.
## Called automatically in [method _ready].
func _validate_animation_reels() -> void:
	var trigger_map = ReactiveAnimationSetup.setup_reels(self, animations, _get_control_type_hint())
	
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

func _on_value_changed(v: float) -> void:
	# Trigger animations if configured
	if animations.size() > 0:
		_on_trigger_value_changed(v)
	
	if not value_state or _helper.is_updating():
		return
	if float(value_state.value) == v:
		return
	_helper.set_updating(true)
	value_state.set_value(v)
	_helper.set_updating(false)

func _on_value_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _helper.is_updating():
		return
	var target := float(new_value)
	if is_equal_approx(value, target):
		return
	_helper.set_updating(true)
	value = target
	_helper.set_updating(false)

## Gets the control type hint for this reactive control.
## Used to filter available triggers in the Inspector.
func _get_control_type_hint() -> AnimationReel.ControlTypeHint:
	return AnimationReel.ControlTypeHint.VALUE_INPUT

func _exit_tree() -> void:
	FocusDrivenHover.cleanup(self)

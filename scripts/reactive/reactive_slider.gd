extends HSlider
class_name ReactiveSlider

@export var value_state: State

## Targets to animate based on slider events.
##
## Drag nodes here and configure each target's animation properties directly in the Inspector.
## Each target can specify its own trigger (value changed, increased, decreased, drag started/ended, hover),
## animation type, duration, and settings - no resource files needed!
@export var animation_targets: Array[AnimationTarget] = []

var _updating: bool = false
var _last_value: float = 0.0
var _is_dragging: bool = false
var _is_initializing: bool = true

func _ready() -> void:
	value_changed.connect(_on_value_changed)
	if value_state:
		value_state.value_changed.connect(_on_value_state_changed)
		_on_value_state_changed(value_state.value, value_state.value)
		_last_value = float(value_state.value)
	else:
		_last_value = value
	gui_input.connect(_on_gui_input)
	_validate_animation_targets()
	ReactiveStateBindingHelper.deferred_finish_initialization(self)

## Handles GUI input to detect drag start/end.
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				if not _is_dragging:
					_is_dragging = true
					_trigger_animations(AnimationTarget.Trigger.DRAG_STARTED)
			else:
				if _is_dragging:
					_is_dragging = false
					_trigger_animations(AnimationTarget.Trigger.DRAG_ENDED)

## Validates animation targets and filters out invalid ones.
## Called automatically in [method _ready].
func _validate_animation_targets() -> void:
	var r = ReactiveAnimationTargetHelper.validate_and_map_triggers(self, "ReactiveSlider", animation_targets)
	animation_targets = r["animation_targets"]
	var trigger_map = r["trigger_map"]
	
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

## Handles VALUE_CHANGED, VALUE_INCREASED, and VALUE_DECREASED trigger animations.
func _on_trigger_value_changed(new_value: float) -> void:
	# Skip animations during initialization
	if _is_initializing:
		_last_value = new_value
		return
	
	_trigger_animations(AnimationTarget.Trigger.VALUE_CHANGED)
	
	if new_value > _last_value:
		_trigger_animations(AnimationTarget.Trigger.VALUE_INCREASED)
	elif new_value < _last_value:
		_trigger_animations(AnimationTarget.Trigger.VALUE_DECREASED)
	
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

func _on_value_changed(v: float) -> void:
	# Trigger animations if configured
	if animation_targets.size() > 0:
		_on_trigger_value_changed(v)
	
	if not value_state or _updating:
		return
	if float(value_state.value) == v:
		return
	_updating = true
	value_state.set_value(v)
	_updating = false

func _on_value_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _updating:
		return
	var target := float(new_value)
	if is_equal_approx(value, target):
		return
	_updating = true
	value = target
	_updating = false

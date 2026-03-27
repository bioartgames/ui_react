extends HSlider
class_name UiReactSlider

## Two-way binding for the slider value ([float]). **Assign** for reactive sync; omit for a local-only slider.
@export var value_state: UiState

## **Optional** — Inspector-driven tweens (value changed, drag, hover). Leave empty for no automatic animations.
@export var animation_targets: Array[UiAnimTarget] = []

var _updating: bool = false
var _last_value: float = 0.0
var _is_dragging: bool = false
var _is_initializing: bool = true

func _ready() -> void:
	value_changed.connect(_on_value_changed)
	if value_state:
		value_state.value_changed.connect(_on_value_state_changed)
		_on_value_state_changed(value_state.value, value_state.value)
		_last_value = UiReactStateBindingHelper.coerce_float(value_state.value)
	else:
		_last_value = value
	gui_input.connect(_on_gui_input)
	_validate_animation_targets()
	UiReactStateBindingHelper.deferred_finish_initialization(self)

## Handles GUI input to detect drag start/end.
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				if not _is_dragging:
					_is_dragging = true
					_trigger_animations(UiAnimTarget.Trigger.DRAG_STARTED)
			else:
				if _is_dragging:
					_is_dragging = false
					_trigger_animations(UiAnimTarget.Trigger.DRAG_ENDED)

## Validates animation targets and filters out invalid ones.
## Called automatically in [method _ready].
func _validate_animation_targets() -> void:
	var validation_result := UiReactAnimTargetHelper.validate_and_map_triggers(self, "UiReactSlider", animation_targets)
	animation_targets = validation_result.animation_targets
	var trigger_map: Dictionary = validation_result.trigger_map
	
	# Connect signals based on which triggers are used
	if trigger_map.has(UiAnimTarget.Trigger.HOVER_ENTER):
		UiReactAnimTargetHelper.connect_if_absent(mouse_entered, _on_trigger_hover_enter)
	if trigger_map.has(UiAnimTarget.Trigger.HOVER_EXIT):
		UiReactAnimTargetHelper.connect_if_absent(mouse_exited, _on_trigger_hover_exit)

## Finishes initialization, allowing animations to trigger on value changes.
func _finish_initialization() -> void:
	_is_initializing = false

## Handles VALUE_CHANGED, VALUE_INCREASED, and VALUE_DECREASED trigger animations.
func _on_trigger_value_changed(new_value: float) -> void:
	# Skip animations during initialization
	if _is_initializing:
		_last_value = new_value
		return
	
	_trigger_animations(UiAnimTarget.Trigger.VALUE_CHANGED)
	
	if new_value > _last_value:
		_trigger_animations(UiAnimTarget.Trigger.VALUE_INCREASED)
	elif new_value < _last_value:
		_trigger_animations(UiAnimTarget.Trigger.VALUE_DECREASED)
	
	_last_value = new_value

## Handles HOVER_ENTER trigger animations.
func _on_trigger_hover_enter() -> void:
	_trigger_animations(UiAnimTarget.Trigger.HOVER_ENTER)

## Handles HOVER_EXIT trigger animations.
func _on_trigger_hover_exit() -> void:
	_trigger_animations(UiAnimTarget.Trigger.HOVER_EXIT)

## Triggers animations for targets matching the specified trigger type.
## [param trigger_type]: The trigger type to match.
func _trigger_animations(trigger_type: UiAnimTarget.Trigger) -> void:
	UiReactAnimTargetHelper.trigger_animations(self, animation_targets, trigger_type)

func _on_value_changed(v: float) -> void:
	# Trigger animations if configured
	if animation_targets.size() > 0:
		_on_trigger_value_changed(v)
	
	if not value_state or _updating:
		return
	if UiReactStateBindingHelper.coerce_float(value_state.value) == v:
		return
	_updating = true
	value_state.set_value(v)
	_updating = false

func _on_value_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _updating:
		return
	var target_value: float = UiReactStateBindingHelper.coerce_float(new_value)
	if is_equal_approx(value, target_value):
		return
	_updating = true
	value = target_value
	_updating = false

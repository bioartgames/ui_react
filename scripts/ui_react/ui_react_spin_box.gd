extends SpinBox
class_name UiReactSpinBox

@export var value_state: UiState
@export var disabled_state: UiState

## Targets to animate based on spin box events.
##
## Drag nodes here and configure each target's animation properties directly in the Inspector.
## Each target can specify its own trigger (value changed, increased, decreased, text entered, focus entered/exited, hover),
## animation type, duration, and settings - no resource files needed!
@export var animation_targets: Array[UiAnimTarget] = []

var _updating: bool = false
var _last_value: float = 0.0
var _is_initializing: bool = true

func _ready() -> void:
	value_changed.connect(_on_value_changed)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	if value_state:
		value_state.value_changed.connect(_on_value_state_changed)
		_on_value_state_changed(value_state.value, value_state.value)
		_last_value = float(value_state.value) if value_state.value != null else 0.0
	else:
		_last_value = value
	if disabled_state:
		disabled_state.value_changed.connect(_on_disabled_state_changed)
		_on_disabled_state_changed(disabled_state.value, disabled_state.value)
	_validate_animation_targets()
	UiReactStateBindingHelper.deferred_finish_initialization(self)

## Validates animation targets and filters out invalid ones.
## Called automatically in [method _ready].
func _validate_animation_targets() -> void:
	var validation_result := UiReactAnimTargetHelper.validate_and_map_triggers(self, "UiReactSpinBox", animation_targets)
	animation_targets = validation_result.animation_targets
	var trigger_map: Dictionary = validation_result.trigger_map
	
	# Connect signals based on which triggers are used
	# Note: value_changed, focus_entered, and focus_exited are always connected
	if trigger_map.has(UiAnimTarget.Trigger.HOVER_ENTER):
		if not mouse_entered.is_connected(_on_trigger_hover_enter):
			mouse_entered.connect(_on_trigger_hover_enter)
	if trigger_map.has(UiAnimTarget.Trigger.HOVER_EXIT):
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
	
	_trigger_animations(UiAnimTarget.Trigger.VALUE_CHANGED)
	
	if new_value > _last_value:
		_trigger_animations(UiAnimTarget.Trigger.VALUE_INCREASED)
	elif new_value < _last_value:
		_trigger_animations(UiAnimTarget.Trigger.VALUE_DECREASED)
	
	_last_value = new_value

## Handles FOCUS_ENTERED trigger animations.
func _on_trigger_focus_entered() -> void:
	_trigger_animations(UiAnimTarget.Trigger.FOCUS_ENTERED)

## Handles FOCUS_EXITED trigger animations.
func _on_trigger_focus_exited() -> void:
	_trigger_animations(UiAnimTarget.Trigger.FOCUS_EXITED)

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

func _on_value_changed(new_value: float) -> void:
	# Trigger animations if configured
	if animation_targets.size() > 0:
		_on_trigger_value_changed(new_value)
	
	if not value_state or _updating:
		return
	if float(value_state.value) == new_value:
		return
	_updating = true
	value_state.set_value(new_value)
	_updating = false

func _on_focus_entered() -> void:
	# Trigger animations if configured
	if animation_targets.size() > 0:
		_on_trigger_focus_entered()

func _on_focus_exited() -> void:
	# Trigger animations if configured
	if animation_targets.size() > 0:
		_on_trigger_focus_exited()

func _on_value_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _updating:
		return
	var target_value := float(new_value)
	if is_equal_approx(value, target_value):
		return
	_updating = true
	value = target_value
	_last_value = value
	_updating = false

func _on_disabled_state_changed(new_value: Variant, _old_value: Variant) -> void:
	editable = not bool(new_value)

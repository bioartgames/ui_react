extends SpinBox
class_name UiReactSpinBox

## Two-way binding for numeric value ([float]). **Assign** for reactive sync with [UiFloatState].
@export var value_state: UiState
## Two-way binding for editable/disabled ([bool]). **Optional**.
@export var disabled_state: UiBoolState

## **Optional** — Inspector-driven tweens (value, focus, hover). Leave empty for no automatic animations.
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
		_on_value_state_changed(value_state.get_value(), value_state.get_value())
		_last_value = UiReactStateBindingHelper.coerce_float(value_state.get_value())
	else:
		_last_value = value
	if disabled_state:
		disabled_state.value_changed.connect(_on_disabled_state_changed)
		_on_disabled_state_changed(disabled_state.get_value(), disabled_state.get_value())
	_validate_animation_targets()
	UiReactStateBindingHelper.deferred_finish_initialization(self)

## Validates animation targets and filters out invalid ones.
## Called automatically in [method _ready].
func _validate_animation_targets() -> void:
	var trigger_map: Dictionary = UiReactAnimTargetHelper.apply_validated_targets(self, "UiReactSpinBox")

	# Note: value_changed, focus_entered, and focus_exited are always connected
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
	if UiReactStateBindingHelper.coerce_float(value_state.get_value()) == new_value:
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
	var target_value: float = UiReactStateBindingHelper.coerce_float(new_value)
	if is_equal_approx(value, target_value):
		return
	_updating = true
	value = target_value
	_last_value = value
	_updating = false

func _on_disabled_state_changed(new_value: Variant, _old_value: Variant) -> void:
	editable = not UiReactStateBindingHelper.coerce_bool(new_value)

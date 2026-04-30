extends ProgressBar
class_name UiReactProgressBar

var _bind := UiReactTwoWayBindingDriver.new()
var _value_state: UiState

## Two-way binding for [member Range.value] ([float]). **Assign** for reactive sync.
@export var value_state: UiState:
	get:
		return _value_state
	set(v):
		if _value_state == v:
			return
		if is_node_ready():
			_disconnect_all_states()
		_value_state = v
		if is_node_ready():
			_connect_all_states()

## **Optional** — Inspector-driven tweens (value, completed, hover). Leave empty for no automatic animations.
@export var animation_targets: Array[UiAnimTarget] = []

var _last_value: float = 0.0
var _was_completed: bool = false

func _ready() -> void:
	_disconnect_all_states()
	_connect_all_states()
	if _value_state == null:
		_last_value = value
	_was_completed = _is_completed()
	_validate_animation_targets()
	UiReactStateBindingHelper.deferred_finish_initialization(self)


func _exit_tree() -> void:
	_disconnect_all_states()


func _disconnect_all_states() -> void:
	if _value_state != null:
		UiReactControlStateWire.unbind_value_changed(self, _value_state, &"value_state", _on_value_state_changed)


func _connect_all_states() -> void:
	if _value_state != null:
		UiReactControlStateWire.bind_value_changed(self, _value_state, &"value_state", _on_value_state_changed)
		_last_value = UiReactStateBindingHelper.coerce_float(_value_state.get_value())
	else:
		_last_value = value
	_was_completed = _is_completed()


## Checks if progress bar is at completion (100%).
func _is_completed() -> bool:
	return value >= max_value


## Validates animation targets and filters out invalid ones.
## Called automatically in [method _ready].
func _validate_animation_targets() -> void:
	var trigger_map: Dictionary = UiReactAnimTargetHelper.apply_validated_targets(self, "UiReactProgressBar")

	# Connect signals based on which triggers are used
	if trigger_map.has(UiAnimTarget.Trigger.HOVER_ENTER):
		UiReactAnimTargetHelper.connect_if_absent(mouse_entered, _on_trigger_hover_enter)
	if trigger_map.has(UiAnimTarget.Trigger.HOVER_EXIT):
		UiReactAnimTargetHelper.connect_if_absent(mouse_exited, _on_trigger_hover_exit)


## Finishes initialization, allowing animations to trigger on value changes.
func _finish_initialization() -> void:
	_bind.finish_initialization()


## Handles VALUE_CHANGED, VALUE_INCREASED, VALUE_DECREASED, and COMPLETED trigger animations.
func _on_trigger_value_changed(new_value: float) -> void:
	# Skip animations during initialization
	if _bind.initializing:
		_last_value = new_value
		# Update completion state but don't trigger animation
		_was_completed = _is_completed()
		return

	_trigger_animations(UiAnimTarget.Trigger.VALUE_CHANGED)

	if new_value > _last_value:
		_trigger_animations(UiAnimTarget.Trigger.VALUE_INCREASED)
	elif new_value < _last_value:
		_trigger_animations(UiAnimTarget.Trigger.VALUE_DECREASED)

	# Check for completion
	var is_completed = _is_completed()
	if is_completed and not _was_completed:
		_trigger_animations(UiAnimTarget.Trigger.COMPLETED)
	_was_completed = is_completed

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


func _on_value_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _bind.updating:
		return
	var target_value: float = UiReactStateBindingHelper.coerce_float(new_value)
	if is_equal_approx(value, target_value):
		return
	_bind.updating = true
	value = target_value

	# Trigger animations if configured
	if animation_targets.size() > 0:
		_on_trigger_value_changed(target_value)

	_bind.updating = false

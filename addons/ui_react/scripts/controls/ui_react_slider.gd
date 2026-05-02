extends HSlider
class_name UiReactSlider

const _UiReactExitTeardown := preload("res://addons/ui_react/scripts/internal/react/ui_react_control_exit_teardown.gd")

var _bind := UiReactTwoWayBindingDriver.new()
var _local_signal_scope: UiReactSubscriptionScope
var _value_state: UiState

## Two-way binding for the slider value ([float]). **Assign** for reactive sync; omit for a local-only slider.
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

## **Optional** — Inspector-driven tweens (value changed, drag, hover). Leave empty for no automatic animations.
@export var animation_targets: Array[UiAnimTarget] = []

## **Optional** — Feedback ([code]docs/FEEDBACK_LAYER.md[/code]): one-shot audio / controller rumble on triggers.
@export var audio_targets: Array[UiReactAudioFeedbackTarget] = []

## **Optional** — Feedback ([code]docs/FEEDBACK_LAYER.md[/code]): [method Input.start_joy_vibration] on triggers.
@export var haptic_targets: Array[UiReactHapticFeedbackTarget] = []

var _last_value: float = 0.0
var _is_dragging: bool = false

func _ready() -> void:
	if _local_signal_scope != null:
		_local_signal_scope.dispose()
	_local_signal_scope = UiReactSubscriptionScope.new()
	_local_signal_scope.connect_bound(value_changed, _on_value_changed)
	_local_signal_scope.connect_bound(gui_input, _on_gui_input)
	_disconnect_all_states()
	_connect_all_states()
	if _value_state == null:
		_last_value = value
	_validate_animation_targets()
	UiReactStateBindingHelper.deferred_finish_initialization(self)


func _reactive_teardown() -> void:
	UiReactFeedbackTargetHelper.teardown_for_control_exit(self)
	_disconnect_local_control_signals()
	_UiReactExitTeardown.teardown_no_wire(Callable(self, "_disconnect_all_states"))


func _disconnect_local_control_signals() -> void:
	if _local_signal_scope != null:
		_local_signal_scope.dispose()
		_local_signal_scope = null


func _exit_tree() -> void:
	_reactive_teardown()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_reactive_teardown()


func _disconnect_all_states() -> void:
	if _value_state != null:
		UiReactControlStateWire.unbind_value_changed(self, _value_state, &"value_state", _on_value_state_changed)


func _connect_all_states() -> void:
	if _value_state != null:
		UiReactControlStateWire.bind_value_changed(self, _value_state, &"value_state", _on_value_state_changed)
		_last_value = UiReactStateBindingHelper.coerce_float(_value_state.get_value())


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
	var trigger_map: Dictionary = UiReactAnimTargetHelper.apply_validated_targets(self, "UiReactSlider")
	UiReactFeedbackTargetHelper.apply_validated_audio_and_haptic_and_merge_triggers(self, "UiReactSlider", trigger_map)

	# Connect signals based on which triggers are used
	if trigger_map.has(UiAnimTarget.Trigger.HOVER_ENTER):
		_local_signal_scope.connect_bound(mouse_entered, _on_trigger_hover_enter)
	if trigger_map.has(UiAnimTarget.Trigger.HOVER_EXIT):
		_local_signal_scope.connect_bound(mouse_exited, _on_trigger_hover_exit)

	UiReactFeedbackTargetHelper.sync_initial_state(self, "UiReactSlider", audio_targets, haptic_targets)


## Finishes initialization, allowing animations to trigger on value changes.
func _finish_initialization() -> void:
	_bind.finish_initialization()


## Handles VALUE_CHANGED, VALUE_INCREASED, and VALUE_DECREASED trigger animations.
func _on_trigger_value_changed(new_value: float) -> void:
	# Skip animations during initialization
	if _bind.initializing:
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
	UiReactFeedbackTargetHelper.run_audio_feedback(self, "UiReactSlider", audio_targets, trigger_type)
	UiReactFeedbackTargetHelper.run_haptic_feedback(self, "UiReactSlider", haptic_targets, trigger_type)


func _on_value_changed(v: float) -> void:
	# Trigger animations if configured
	if (
		animation_targets.size() > 0
		or audio_targets.size() > 0
		or haptic_targets.size() > 0
	):
		_on_trigger_value_changed(v)

	if not _value_state or _bind.updating:
		return
	if UiReactStateBindingHelper.coerce_float(_value_state.get_value()) == v:
		return
	_bind.updating = true
	_value_state.set_value(v)
	_bind.updating = false


func _on_value_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _bind.updating:
		return
	var target_value: float = UiReactStateBindingHelper.coerce_float(new_value)
	if is_equal_approx(value, target_value):
		return
	_bind.updating = true
	value = target_value
	_bind.updating = false

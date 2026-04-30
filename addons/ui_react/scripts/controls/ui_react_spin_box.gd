extends SpinBox
class_name UiReactSpinBox

var _bind := UiReactTwoWayBindingDriver.new()
var _value_state: UiState
var _disabled_state: UiBoolState

## Two-way binding for numeric value ([float]). **Assign** for reactive sync with [UiFloatState].
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

## Two-way binding for editable/disabled ([bool]). **Optional**.
@export var disabled_state: UiBoolState:
	get:
		return _disabled_state
	set(v):
		if _disabled_state == v:
			return
		if is_node_ready():
			_disconnect_all_states()
		_disabled_state = v
		if is_node_ready():
			_connect_all_states()

## **Optional** — Inspector-driven tweens (value, focus, hover). Leave empty for no automatic animations.
@export var animation_targets: Array[UiAnimTarget] = []

var _last_value: float = 0.0

func _ready() -> void:
	value_changed.connect(_on_value_changed)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	_disconnect_all_states()
	_connect_all_states()
	if _value_state == null:
		_last_value = value
	_validate_animation_targets()
	UiReactStateBindingHelper.deferred_finish_initialization(self)


func _exit_tree() -> void:
	_disconnect_all_states()


func _disconnect_all_states() -> void:
	if _value_state != null:
		UiReactControlStateWire.unbind_value_changed(self, _value_state, &"value_state", _on_value_state_changed)
	if _disabled_state != null:
		UiReactControlStateWire.unbind_value_changed(self, _disabled_state, &"disabled_state", _on_disabled_state_changed)


func _connect_all_states() -> void:
	if _value_state != null:
		UiReactControlStateWire.bind_value_changed(self, _value_state, &"value_state", _on_value_state_changed)
		_last_value = UiReactStateBindingHelper.coerce_float(_value_state.get_value())
	else:
		_last_value = value
	if _disabled_state != null:
		UiReactControlStateWire.bind_value_changed(self, _disabled_state, &"disabled_state", _on_disabled_state_changed)


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

	if not _value_state or _bind.updating:
		return
	if UiReactStateBindingHelper.coerce_float(_value_state.get_value()) == new_value:
		return
	_bind.updating = true
	_value_state.set_value(new_value)
	_bind.updating = false


func _on_focus_entered() -> void:
	# Trigger animations if configured
	if animation_targets.size() > 0:
		_on_trigger_focus_entered()


func _on_focus_exited() -> void:
	# Trigger animations if configured
	if animation_targets.size() > 0:
		_on_trigger_focus_exited()


func _on_value_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _bind.updating:
		return
	var target_value: float = UiReactStateBindingHelper.coerce_float(new_value)
	if is_equal_approx(value, target_value):
		return
	_bind.updating = true
	value = target_value
	_last_value = value
	_bind.updating = false


func _on_disabled_state_changed(new_value: Variant, _old_value: Variant) -> void:
	editable = not UiReactStateBindingHelper.coerce_bool(new_value)

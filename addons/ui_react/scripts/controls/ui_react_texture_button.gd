extends TextureButton
class_name UiReactTextureButton

var _bind := UiReactTwoWayBindingDriver.new()
var _pressed_state: UiBoolState
var _disabled_state: UiBoolState

## Two-way binding for pressed state ([bool]). **Optional** — omit for a plain TextureButton without external state sync.
@export var pressed_state: UiBoolState:
	get:
		return _pressed_state
	set(value):
		if _pressed_state == value:
			return
		if is_node_ready():
			_disconnect_all_states()
		_pressed_state = value
		if is_node_ready():
			_connect_all_states()

## Two-way binding for disabled state ([bool]). **Optional**.
@export var disabled_state: UiBoolState:
	get:
		return _disabled_state
	set(value):
		if _disabled_state == value:
			return
		if is_node_ready():
			_disconnect_all_states()
		_disabled_state = value
		if is_node_ready():
			_connect_all_states()

## **Optional** — Inspector-driven tweens (pressed, hover, toggled). Leave empty for no automatic animations.
## Each [UiAnimTarget] sets Trigger, Target NodePath, and animation type; no extra resource files required.
@export var animation_targets: Array[UiAnimTarget] = []

## **Optional** — Action layer ([code]docs/ACTION_LAYER.md[/code]): focus, visibility, [code]mouse_filter[/code], bounded float ops, etc.
@export var action_targets: Array[UiReactActionTarget] = []

## Optional one-way write to a [UiFloatState] on [signal BaseButton.pressed].
@export var press_writes_float_state: UiFloatState
@export var press_writes_float_value: float = 100.0

func _ready() -> void:
	pressed.connect(_on_pressed)
	pressed.connect(_on_press_writes_float)
	if has_signal(&"toggled"):
		toggled.connect(_on_toggled)
	_disconnect_all_states()
	_connect_all_states()
	_validate_animation_targets()
	UiReactStateBindingHelper.deferred_finish_initialization(self)


func _disconnect_all_states() -> void:
	if _pressed_state != null:
		UiReactComputedService.hook_unbind(_pressed_state, self, &"pressed_state")
	if _pressed_state != null and _pressed_state.value_changed.is_connected(_on_pressed_state_changed):
		_pressed_state.value_changed.disconnect(_on_pressed_state_changed)
	if _disabled_state != null:
		UiReactComputedService.hook_unbind(_disabled_state, self, &"disabled_state")
	if _disabled_state != null and _disabled_state.value_changed.is_connected(_on_disabled_state_changed):
		_disabled_state.value_changed.disconnect(_on_disabled_state_changed)


func _connect_all_states() -> void:
	if _pressed_state != null:
		_pressed_state.value_changed.connect(_on_pressed_state_changed)
		_on_pressed_state_changed(_pressed_state.get_value(), _pressed_state.get_value())
		UiReactComputedService.hook_bind(_pressed_state, self, &"pressed_state")
	if _disabled_state != null:
		_disabled_state.value_changed.connect(_on_disabled_state_changed)
		_on_disabled_state_changed(_disabled_state.get_value(), _disabled_state.get_value())
		UiReactComputedService.hook_bind(_disabled_state, self, &"disabled_state")


## Validates animation targets and filters out invalid ones.
## Called automatically in [method _ready].
func _validate_animation_targets() -> void:
	var trigger_map: Dictionary = UiReactAnimTargetHelper.apply_validated_targets(self, "UiReactTextureButton")
	UiReactActionTargetHelper.apply_validated_actions_and_merge_triggers(self, "UiReactTextureButton", trigger_map)

	if trigger_map.has(UiAnimTarget.Trigger.PRESSED):
		UiReactAnimTargetHelper.connect_if_absent(pressed, _on_trigger_pressed)
	if trigger_map.has(UiAnimTarget.Trigger.HOVER_ENTER):
		UiReactAnimTargetHelper.connect_if_absent(mouse_entered, _on_trigger_hover_enter)
	if trigger_map.has(UiAnimTarget.Trigger.HOVER_EXIT):
		UiReactAnimTargetHelper.connect_if_absent(mouse_exited, _on_trigger_hover_exit)
	if (trigger_map.has(UiAnimTarget.Trigger.TOGGLED_ON) or trigger_map.has(UiAnimTarget.Trigger.TOGGLED_OFF)) and has_signal(&"toggled"):
		UiReactAnimTargetHelper.connect_if_absent(toggled, _on_trigger_toggled)

	UiReactActionTargetHelper.sync_initial_state(self, "UiReactTextureButton", action_targets)


func _on_trigger_pressed() -> void:
	_trigger_animations(UiAnimTarget.Trigger.PRESSED)


func _on_trigger_hover_enter() -> void:
	_trigger_animations(UiAnimTarget.Trigger.HOVER_ENTER)


func _on_trigger_hover_exit() -> void:
	_trigger_animations(UiAnimTarget.Trigger.HOVER_EXIT)


func _finish_initialization() -> void:
	_bind.finish_initialization()


func _on_trigger_toggled(active: bool) -> void:
	if _bind.initializing:
		return
	if active:
		_trigger_animations(UiAnimTarget.Trigger.TOGGLED_ON)
	else:
		_trigger_animations(UiAnimTarget.Trigger.TOGGLED_OFF)


func _trigger_animations(trigger_type: UiAnimTarget.Trigger) -> void:
	UiReactAnimTargetHelper.trigger_animations(self, animation_targets, trigger_type, true, disabled)
	UiReactActionTargetHelper.run_actions(
		self, "UiReactTextureButton", action_targets, trigger_type, true, disabled
	)


func _on_press_writes_float() -> void:
	if press_writes_float_state == null:
		return
	press_writes_float_state.set_value(press_writes_float_value)


func _on_pressed() -> void:
	if not _pressed_state or toggle_mode:
		return
	if _bind.updating:
		return
	_bind.updating = true
	_pressed_state.set_value(true)
	_bind.updating = false


func _on_toggled(active: bool) -> void:
	if not _pressed_state or not toggle_mode or _bind.updating:
		return
	if _pressed_state.get_value() == active:
		return
	_bind.updating = true
	_pressed_state.set_value(active)
	_bind.updating = false


func _on_pressed_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _bind.updating:
		return
	var desired := UiReactStateBindingHelper.coerce_bool(new_value)
	if toggle_mode:
		if button_pressed == desired:
			return
		_bind.updating = true
		button_pressed = desired
		_bind.updating = false


func _on_disabled_state_changed(new_value: Variant, _old_value: Variant) -> void:
	var desired := UiReactStateBindingHelper.coerce_bool(new_value)
	if disabled == desired:
		return
	disabled = desired

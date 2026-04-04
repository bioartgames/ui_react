extends CheckBox
class_name UiReactCheckBox

var _bind := UiReactTwoWayBindingDriver.new()
var _checked_state: UiState
var _disabled_state: UiBoolState

## Two-way binding for checked state ([bool]). **Optional** — omit for a plain CheckBox.
@export var checked_state: UiState:
	get:
		return _checked_state
	set(value):
		if _checked_state == value:
			return
		if is_node_ready():
			_disconnect_all_states()
		_checked_state = value
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

## **Optional** — Inspector-driven tweens (toggled, hover). Leave empty for no automatic animations.
@export var animation_targets: Array[UiAnimTarget] = []

## Optional node implementing [code]get_animation_selection_index() -> int[/code] for [member UiAnimTarget.selection_slot] filtering.
@export var animation_selection_provider: NodePath = NodePath()

## **Optional** — Action layer presets ([code]docs/ACTION_LAYER.md[/code]).
@export var action_targets: Array[UiReactActionTarget] = []

## **Optional** — Wiring rules ([code]docs/WIRING_LAYER.md[/code] §5).
@export var wire_rules: Array[UiReactWireRule] = []

func _ready() -> void:
	toggled.connect(_on_toggled)
	_disconnect_all_states()
	_connect_all_states()
	_validate_animation_targets()
	UiReactStateBindingHelper.deferred_finish_initialization(self)


func _disconnect_all_states() -> void:
	if _checked_state != null and _checked_state.value_changed.is_connected(_on_checked_state_changed):
		_checked_state.value_changed.disconnect(_on_checked_state_changed)
	if _disabled_state != null and _disabled_state.value_changed.is_connected(_on_disabled_state_changed):
		_disabled_state.value_changed.disconnect(_on_disabled_state_changed)


func _connect_all_states() -> void:
	if _checked_state != null:
		_checked_state.value_changed.connect(_on_checked_state_changed)
		_on_checked_state_changed(_checked_state.get_value(), _checked_state.get_value())
	if _disabled_state != null:
		_disabled_state.value_changed.connect(_on_disabled_state_changed)
		_on_disabled_state_changed(_disabled_state.get_value(), _disabled_state.get_value())


## Validates animation targets and filters out invalid ones.
## Called automatically in [method _ready].
func _validate_animation_targets() -> void:
	var trigger_map: Dictionary = UiReactAnimTargetHelper.apply_validated_targets(self, "UiReactCheckBox")
	UiReactActionTargetHelper.apply_validated_actions_and_merge_triggers(self, "UiReactCheckBox", trigger_map)

	# Connect signals based on which triggers are used
	if trigger_map.has(UiAnimTarget.Trigger.TOGGLED_ON) or trigger_map.has(UiAnimTarget.Trigger.TOGGLED_OFF):
		UiReactAnimTargetHelper.connect_if_absent(toggled, _on_trigger_toggled)
	if trigger_map.has(UiAnimTarget.Trigger.HOVER_ENTER):
		UiReactAnimTargetHelper.connect_if_absent(mouse_entered, _on_trigger_hover_enter)
	if trigger_map.has(UiAnimTarget.Trigger.HOVER_EXIT):
		UiReactAnimTargetHelper.connect_if_absent(mouse_exited, _on_trigger_hover_exit)


## Finishes initialization, allowing animations to trigger on toggle changes.
func _finish_initialization() -> void:
	_bind.finish_initialization()


## Handles TOGGLED_ON and TOGGLED_OFF trigger animations.
func _on_trigger_toggled(active: bool) -> void:
	# Skip animations during initialization
	if _bind.initializing:
		return

	if active:
		_trigger_animations(UiAnimTarget.Trigger.TOGGLED_ON)
	else:
		_trigger_animations(UiAnimTarget.Trigger.TOGGLED_OFF)


## Handles HOVER_ENTER trigger animations.
func _on_trigger_hover_enter() -> void:
	_trigger_animations(UiAnimTarget.Trigger.HOVER_ENTER)


## Handles HOVER_EXIT trigger animations.
func _on_trigger_hover_exit() -> void:
	_trigger_animations(UiAnimTarget.Trigger.HOVER_EXIT)


## Triggers animations for targets matching the specified trigger type.
## [param trigger_type]: The trigger type to match.
func _trigger_animations(trigger_type: UiAnimTarget.Trigger) -> void:
	UiReactAnimTargetHelper.trigger_animations(self, animation_targets, trigger_type, true, disabled)
	UiReactActionTargetHelper.run_actions(self, "UiReactCheckBox", action_targets, trigger_type, true, disabled)


func _on_toggled(active: bool) -> void:
	if not _checked_state or _bind.updating:
		return
	if _checked_state.get_value() == active:
		return
	_bind.updating = true
	_checked_state.set_value(active)
	_bind.updating = false


func _on_checked_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _bind.updating:
		return
	var desired := bool(new_value)
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

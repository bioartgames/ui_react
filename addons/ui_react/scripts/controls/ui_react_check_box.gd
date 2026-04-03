extends CheckBox
class_name UiReactCheckBox

## Two-way binding for checked state ([bool]). **Optional** — omit for a plain CheckBox.
@export var checked_state: UiState
## Two-way binding for disabled state ([bool]). **Optional**.
@export var disabled_state: UiBoolState

## **Optional** — Inspector-driven tweens (toggled, hover). Leave empty for no automatic animations.
@export var animation_targets: Array[UiAnimTarget] = []

## **Optional** — Action layer presets ([code]docs/ACTION_LAYER.md[/code]).
@export var action_targets: Array[UiReactActionTarget] = []

var _updating: bool = false
var _is_initializing: bool = true

func _ready() -> void:
	toggled.connect(_on_toggled)
	if checked_state:
		checked_state.value_changed.connect(_on_checked_state_changed)
		_on_checked_state_changed(checked_state.get_value(), checked_state.get_value())
	if disabled_state:
		disabled_state.value_changed.connect(_on_disabled_state_changed)
		_on_disabled_state_changed(disabled_state.get_value(), disabled_state.get_value())
	_validate_animation_targets()
	UiReactStateBindingHelper.deferred_finish_initialization(self)

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
	_is_initializing = false

## Handles TOGGLED_ON and TOGGLED_OFF trigger animations.
func _on_trigger_toggled(active: bool) -> void:
	# Skip animations during initialization
	if _is_initializing:
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
	if not checked_state or _updating:
		return
	if checked_state.get_value() == active:
		return
	_updating = true
	checked_state.set_value(active)
	_updating = false

func _on_checked_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _updating:
		return
	var desired := bool(new_value)
	if button_pressed == desired:
		return
	_updating = true
	button_pressed = desired
	_updating = false

func _on_disabled_state_changed(new_value: Variant, _old_value: Variant) -> void:
	var desired := UiReactStateBindingHelper.coerce_bool(new_value)
	if disabled == desired:
		return
	disabled = desired

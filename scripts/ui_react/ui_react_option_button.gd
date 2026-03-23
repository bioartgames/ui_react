extends OptionButton
class_name UiReactOptionButton

@export var selected_state: UiState
@export var disabled_state: UiState

## Targets to animate based on option button events.
##
## Drag nodes here and configure each target's animation properties directly in the Inspector.
## Each target can specify its own trigger (selection changed, hover enter/exit), animation type,
## duration, and settings - no resource files needed! Leave empty to use manual signal connections.
@export var animation_targets: Array[UiAnimTarget] = []

var _updating: bool = false
var _is_initializing: bool = true

func _ready() -> void:
	item_selected.connect(_on_item_selected)
	if selected_state:
		selected_state.value_changed.connect(_on_selected_state_changed)
		_on_selected_state_changed(selected_state.value, selected_state.value)
	if disabled_state:
		disabled_state.value_changed.connect(_on_disabled_state_changed)
		_on_disabled_state_changed(disabled_state.value, disabled_state.value)
	_validate_animation_targets()
	UiReactStateBindingHelper.deferred_finish_initialization(self)

## Validates animation targets and filters out invalid ones.
## Called automatically in [method _ready].
func _validate_animation_targets() -> void:
	var validation_result := UiReactAnimTargetHelper.validate_and_map_triggers(self, "UiReactOptionButton", animation_targets)
	animation_targets = validation_result.animation_targets
	var trigger_map: Dictionary = validation_result.trigger_map
	
	# Connect signals based on which triggers are used
	if trigger_map.has(UiAnimTarget.Trigger.SELECTION_CHANGED):
		if not item_selected.is_connected(_on_trigger_selection_changed):
			item_selected.connect(_on_trigger_selection_changed)
	if trigger_map.has(UiAnimTarget.Trigger.HOVER_ENTER):
		if not mouse_entered.is_connected(_on_trigger_hover_enter):
			mouse_entered.connect(_on_trigger_hover_enter)
	if trigger_map.has(UiAnimTarget.Trigger.HOVER_EXIT):
		if not mouse_exited.is_connected(_on_trigger_hover_exit):
			mouse_exited.connect(_on_trigger_hover_exit)

## Finishes initialization, allowing animations to trigger on selection changes.
func _finish_initialization() -> void:
	_is_initializing = false

## Handles SELECTION_CHANGED trigger animations.
func _on_trigger_selection_changed(_index: int) -> void:
	# Skip animations during initialization
	if _is_initializing:
		return
	
	_trigger_animations(UiAnimTarget.Trigger.SELECTION_CHANGED)

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

func _on_item_selected(index: int) -> void:
	if not selected_state or _updating:
		return
	var new_value: Variant = get_item_text(index)
	if selected_state.value == new_value:
		return
	_updating = true
	selected_state.set_value(new_value)
	_updating = false

func _on_selected_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _updating:
		return
	var index := _resolve_option_index(new_value)
	if index < 0 or index >= item_count:
		return
	if get_selected_id() == index or selected == index:
		return

	_updating = true
	select(index)
	_updating = false

func _on_disabled_state_changed(new_value: Variant, _old_value: Variant) -> void:
	disabled = bool(new_value)


func _resolve_option_index(new_value: Variant) -> int:
	if new_value is String:
		return _find_item_by_text(new_value)
	return int(new_value)


func _find_item_by_text(text_value: String) -> int:
	for i in item_count:
		if get_item_text(i) == text_value:
			return i
	return -1

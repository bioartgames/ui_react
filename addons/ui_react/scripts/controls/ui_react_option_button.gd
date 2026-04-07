extends OptionButton
class_name UiReactOptionButton

var _bind := UiReactTwoWayBindingDriver.new()
var _selected_state: UiStringState
var _disabled_state: UiBoolState

## Two-way binding for the selected item (typically [String] item text). **Assign** for reactive sync.
@export var selected_state: UiStringState:
	get:
		return _selected_state
	set(v):
		if _selected_state == v:
			return
		if is_node_ready():
			_disconnect_all_states()
		_selected_state = v
		if is_node_ready():
			_connect_all_states()

## Two-way binding for disabled state ([bool]). **Optional**.
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

## **Optional** — Inspector-driven tweens (selection, hover). Leave empty for no automatic animations.
@export var animation_targets: Array[UiAnimTarget] = []

## **Optional** — Action layer ([code]docs/ACTION_LAYER.md[/code]): focus, visibility, [code]mouse_filter[/code], UI bool flags, bounded float ops.
@export var action_targets: Array[UiReactActionTarget] = []

## **Optional** — Wiring rules ([code]docs/WIRING_LAYER.md[/code] §5). Applied by [UiReactWireRuleHelper].
@export var wire_rules: Array[UiReactWireRule] = []


func _enter_tree() -> void:
	UiReactWireRuleHelper.schedule_attach(self)


func _exit_tree() -> void:
	UiReactWireRuleHelper.detach(self)


func _ready() -> void:
	item_selected.connect(_on_item_selected)
	_disconnect_all_states()
	_connect_all_states()
	_validate_animation_targets()
	UiReactStateBindingHelper.deferred_finish_initialization(self)


func _disconnect_all_states() -> void:
	if _selected_state != null:
		UiReactComputedService.hook_unbind(_selected_state, self, &"selected_state")
	if _selected_state != null and _selected_state.value_changed.is_connected(_on_selected_state_changed):
		_selected_state.value_changed.disconnect(_on_selected_state_changed)
	if _disabled_state != null:
		UiReactComputedService.hook_unbind(_disabled_state, self, &"disabled_state")
	if _disabled_state != null and _disabled_state.value_changed.is_connected(_on_disabled_state_changed):
		_disabled_state.value_changed.disconnect(_on_disabled_state_changed)


func _connect_all_states() -> void:
	if _selected_state != null:
		_selected_state.value_changed.connect(_on_selected_state_changed)
		_on_selected_state_changed(_selected_state.get_value(), _selected_state.get_value())
		UiReactComputedService.hook_bind(_selected_state, self, &"selected_state")
	if _disabled_state != null:
		_disabled_state.value_changed.connect(_on_disabled_state_changed)
		_on_disabled_state_changed(_disabled_state.get_value(), _disabled_state.get_value())
		UiReactComputedService.hook_bind(_disabled_state, self, &"disabled_state")


## Validates animation targets and filters out invalid ones.
## Called automatically in [method _ready].
func _validate_animation_targets() -> void:
	var trigger_map: Dictionary = UiReactAnimTargetHelper.apply_validated_targets(self, "UiReactOptionButton")
	UiReactActionTargetHelper.apply_validated_actions_and_merge_triggers(self, "UiReactOptionButton", trigger_map)

	# Connect signals based on which triggers are used
	if trigger_map.has(UiAnimTarget.Trigger.SELECTION_CHANGED):
		UiReactAnimTargetHelper.connect_if_absent(item_selected, _on_trigger_selection_changed)
	if trigger_map.has(UiAnimTarget.Trigger.HOVER_ENTER):
		UiReactAnimTargetHelper.connect_if_absent(mouse_entered, _on_trigger_hover_enter)
	if trigger_map.has(UiAnimTarget.Trigger.HOVER_EXIT):
		UiReactAnimTargetHelper.connect_if_absent(mouse_exited, _on_trigger_hover_exit)

	UiReactActionTargetHelper.sync_initial_state(self, "UiReactOptionButton", action_targets)


## Finishes initialization, allowing animations to trigger on selection changes.
func _finish_initialization() -> void:
	_bind.finish_initialization()


## Handles SELECTION_CHANGED trigger animations.
func _on_trigger_selection_changed(_index: int) -> void:
	# Skip animations during initialization
	if _bind.initializing:
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
	UiReactActionTargetHelper.run_actions(
		self, "UiReactOptionButton", action_targets, trigger_type, true, disabled
	)


func _on_item_selected(index: int) -> void:
	if not _selected_state or _bind.updating:
		return
	var new_value: Variant = get_item_text(index)
	if _selected_state.get_value() == new_value:
		return
	_bind.updating = true
	_selected_state.set_value(new_value)
	_bind.updating = false


func _on_selected_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _bind.updating:
		return
	var index := _resolve_option_index(new_value)
	if index < 0 or index >= item_count:
		return
	if get_selected_id() == index or selected == index:
		return

	_bind.updating = true
	select(index)
	_bind.updating = false


func _on_disabled_state_changed(new_value: Variant, _old_value: Variant) -> void:
	disabled = UiReactStateBindingHelper.coerce_bool(new_value)


func _resolve_option_index(new_value: Variant) -> int:
	if new_value is String:
		return _find_item_by_text(new_value)
	return int(new_value)


func _find_item_by_text(text_value: String) -> int:
	for i in item_count:
		if get_item_text(i) == text_value:
			return i
	return -1

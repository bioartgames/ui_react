extends TabContainer
class_name UiReactTabContainer

const _UiReactHostWireTree := preload("res://addons/ui_react/scripts/internal/react/ui_react_host_wire_tree.gd")

var _bind := UiReactTwoWayBindingDriver.new()
var _selected_state: UiIntState
var _tab_config: UiTabContainerCfg

## Two-way binding for current tab index ([int]). **Optional** — assign for external control of selection.
@export var selected_state: UiIntState:
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

## **Optional** — Advanced tabs: dynamic tab list, per-tab content [UiState]s, disabled/visible arrays ([UiTabContainerCfg]).
@export var tab_config: UiTabContainerCfg:
	get:
		return _tab_config
	set(v):
		if _tab_config == v:
			return
		if is_node_ready():
			_disconnect_tab_config_signals()
		_tab_config = v
		if is_node_ready():
			_connect_tab_config_signals()

## **Optional** — Inspector-driven tweens (selection changed, hover). Leave empty for no automatic animations.
@export var animation_targets: Array[UiAnimTarget] = []

## **Optional** — Action layer ([code]docs/ACTION_LAYER.md[/code]): focus, visibility, [code]mouse_filter[/code], UI bool flags, bounded float ops.
@export var action_targets: Array[UiReactActionTarget] = []

## **Optional** — Wiring rules ([code]docs/WIRING_LAYER.md[/code] §5). Applied by [UiReactWireRuleHelper] via [UiReactHostWireTree].
@export var wire_rules: Array[UiReactWireRule] = []

var _previous_tab_index: int = -1


func _enter_tree() -> void:
	_UiReactHostWireTree.on_enter(self)


func _exit_tree() -> void:
	_disconnect_all_states()
	_UiReactHostWireTree.on_exit(self)


func _ready() -> void:
	tab_selected.connect(_on_tab_selected)
	_previous_tab_index = current_tab
	_disconnect_all_states()
	_connect_all_states()
	_validate_animation_targets()
	UiReactStateBindingHelper.deferred_finish_initialization(self)


func _disconnect_all_states() -> void:
	if _selected_state != null:
		UiReactControlStateWire.unbind_value_changed(self, _selected_state, &"selected_state", _on_selected_state_changed, false)
	_disconnect_tab_config_signals()


func _connect_all_states() -> void:
	if _selected_state != null:
		UiReactControlStateWire.bind_value_changed(self, _selected_state, &"selected_state", _on_selected_state_changed, false)
	_connect_tab_config_signals()


func _disconnect_tab_config_signals() -> void:
	if _tab_config == null:
		return
	if _tab_config.tabs_state != null and _tab_config.tabs_state.value_changed.is_connected(_on_tabs_state_changed):
		_tab_config.tabs_state.value_changed.disconnect(_on_tabs_state_changed)
	if _tab_config.disabled_tabs_state != null and _tab_config.disabled_tabs_state.value_changed.is_connected(_on_disabled_tabs_state_changed):
		_tab_config.disabled_tabs_state.value_changed.disconnect(_on_disabled_tabs_state_changed)
	if _tab_config.visible_tabs_state != null and _tab_config.visible_tabs_state.value_changed.is_connected(_on_visible_tabs_state_changed):
		_tab_config.visible_tabs_state.value_changed.disconnect(_on_visible_tabs_state_changed)


func _connect_tab_config_signals() -> void:
	if _tab_config == null:
		return
	if _tab_config.tabs_state != null:
		_tab_config.tabs_state.value_changed.connect(_on_tabs_state_changed)
		_on_tabs_state_changed(_tab_config.tabs_state.get_value(), null)
	if _tab_config.disabled_tabs_state != null:
		_tab_config.disabled_tabs_state.value_changed.connect(_on_disabled_tabs_state_changed)
		_on_disabled_tabs_state_changed(_tab_config.disabled_tabs_state.get_value(), null)
	if _tab_config.visible_tabs_state != null:
		_tab_config.visible_tabs_state.value_changed.connect(_on_visible_tabs_state_changed)
		_on_visible_tabs_state_changed(_tab_config.visible_tabs_state.get_value(), null)


func _validate_animation_targets() -> void:
	var trigger_map: Dictionary = UiReactAnimTargetHelper.apply_validated_targets(
		self,
		"UiReactTabContainer",
		[UiAnimTarget.Trigger.SELECTION_CHANGED],
	)
	UiReactActionTargetHelper.apply_validated_actions_and_merge_triggers(self, "UiReactTabContainer", trigger_map)

	if trigger_map.has(UiAnimTarget.Trigger.SELECTION_CHANGED):
		UiReactAnimTargetHelper.connect_if_absent(tab_selected, _on_trigger_selection_changed)
	if trigger_map.has(UiAnimTarget.Trigger.HOVER_ENTER):
		UiReactAnimTargetHelper.connect_if_absent(mouse_entered, _on_trigger_hover_enter)
	if trigger_map.has(UiAnimTarget.Trigger.HOVER_EXIT):
		UiReactAnimTargetHelper.connect_if_absent(mouse_exited, _on_trigger_hover_exit)

	UiReactActionTargetHelper.sync_initial_state(self, "UiReactTabContainer", action_targets)


func _finish_initialization() -> void:
	_bind.finish_initialization()


func _on_trigger_selection_changed(_tab_index: int) -> void:
	if _bind.initializing:
		return
	_trigger_animations(UiAnimTarget.Trigger.SELECTION_CHANGED)


func _on_trigger_hover_enter() -> void:
	_trigger_animations(UiAnimTarget.Trigger.HOVER_ENTER)


func _on_trigger_hover_exit() -> void:
	_trigger_animations(UiAnimTarget.Trigger.HOVER_EXIT)


func _trigger_animations(trigger_type: UiAnimTarget.Trigger) -> void:
	UiReactAnimTargetHelper.trigger_animations(self, animation_targets, trigger_type)
	UiReactActionTargetHelper.run_actions(self, "UiReactTabContainer", action_targets, trigger_type)


func _on_tab_selected(tab_index: int) -> void:
	if _previous_tab_index >= 0 and _previous_tab_index != tab_index:
		UiTabTransitionAnimator.animate_tab_switch(self, _previous_tab_index, tab_index, animation_targets)

	_previous_tab_index = tab_index

	UiTabContentStateBinder.bind_tab_content(self, _tab_config, tab_index, Callable(self, "_on_tab_content_state_changed"))

	_on_trigger_selection_changed(tab_index)

	if not _selected_state or _bind.updating:
		return
	var new_value: Variant = tab_index
	if _selected_state.get_value() == new_value:
		return
	_bind.updating = true
	_selected_state.set_value(new_value)
	_bind.updating = false


func _on_selected_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _bind.updating:
		return
	var index: int = UiTabSelectionBinding.resolve_tab_index(self, new_value)
	if index < 0 or index >= get_tab_count():
		return
	if current_tab == index:
		return

	if _previous_tab_index >= 0 and _previous_tab_index != index:
		UiTabTransitionAnimator.animate_tab_switch(self, _previous_tab_index, index, animation_targets)
	UiTabContentStateBinder.bind_tab_content(self, _tab_config, index, Callable(self, "_on_tab_content_state_changed"))

	_bind.updating = true
	_previous_tab_index = index
	current_tab = index
	_bind.updating = false


func _on_tabs_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _bind.updating:
		return

	var coerced_tabs: Variant = _expect_array_state(new_value, "tabs_state")
	if coerced_tabs == null:
		return
	var tabs_array: Array = coerced_tabs

	_bind.updating = true

	var prev_update = UiTabCollectionSync.apply_tabs_from_array(self, tabs_array, _tab_config)
	if prev_update != null:
		_previous_tab_index = int(prev_update)

	_bind.updating = false


func _on_tab_content_state_changed(tab_index: int, property: StringName, new_value: Variant, _old_value: Variant) -> void:
	UiTabContentStateBinder.propagate_content_change(self, tab_index, property, new_value)


func _on_disabled_tabs_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _bind.updating:
		return

	var coerced_disabled: Variant = _expect_array_state(new_value, "disabled_tabs_state")
	if coerced_disabled == null:
		return
	var disabled_array: Array = coerced_disabled

	var tab_count = get_tab_count()

	_bind.updating = true

	for i in range(min(disabled_array.size(), tab_count)):
		var is_disabled = UiReactStateBindingHelper.coerce_bool(disabled_array[i])
		set_tab_disabled(i, is_disabled)

	_bind.updating = false


func _on_visible_tabs_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _bind.updating:
		return

	var coerced_visible: Variant = _expect_array_state(new_value, "visible_tabs_state")
	if coerced_visible == null:
		return
	var visible_array: Array = coerced_visible

	var tab_count = get_tab_count()

	_bind.updating = true

	for i in range(min(visible_array.size(), tab_count)):
		var tab_visible = UiReactStateBindingHelper.coerce_bool(visible_array[i])
		set_tab_hidden(i, not tab_visible)

	_bind.updating = false


func _expect_array_state(value: Variant, field_name: String) -> Variant:
	return UiReactStateBindingHelper.expect_array_state("UiReactTabContainer", name, field_name, value)

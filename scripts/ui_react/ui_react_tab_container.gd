extends TabContainer
class_name UiReactTabContainer

## Binds the selected tab index to a UiState resource for two-way data binding.
@export var selected_state: UiState

## Configuration resource for dynamic tab management, content binding, and tab states.
## Create a UiTabContainerCfg resource and assign it here to enable advanced tab features.
@export var tab_config: UiTabContainerCfg

## Targets to animate based on tab container events.
##
## Drag nodes here and configure each target's animation properties directly in the Inspector.
## Each target can specify its own trigger (selection changed, hover enter/exit), animation type,
## duration, and settings - no resource files needed!
@export var animation_targets: Array[UiAnimTarget] = []

var _updating: bool = false
var _previous_tab_index: int = -1
var _is_initializing: bool = true

func _ready() -> void:
	tab_selected.connect(_on_tab_selected)
	_previous_tab_index = current_tab

	if selected_state:
		selected_state.value_changed.connect(_on_selected_state_changed)
		_on_selected_state_changed(selected_state.value, selected_state.value)

	if tab_config:
		if tab_config.tabs_state:
			tab_config.tabs_state.value_changed.connect(_on_tabs_state_changed)
			_on_tabs_state_changed(tab_config.tabs_state.value, null)
		if tab_config.disabled_tabs_state:
			tab_config.disabled_tabs_state.value_changed.connect(_on_disabled_tabs_state_changed)
			_on_disabled_tabs_state_changed(tab_config.disabled_tabs_state.value, null)
		if tab_config.visible_tabs_state:
			tab_config.visible_tabs_state.value_changed.connect(_on_visible_tabs_state_changed)
			_on_visible_tabs_state_changed(tab_config.visible_tabs_state.value, null)

	_validate_animation_targets()
	UiReactStateBindingHelper.deferred_finish_initialization(self)

func _validate_animation_targets() -> void:
	var validation_result := UiReactAnimTargetHelper.validate_and_map_triggers(
		self,
		"UiReactTabContainer",
		animation_targets,
		[UiAnimTarget.Trigger.SELECTION_CHANGED]
	)
	animation_targets = validation_result.animation_targets
	var trigger_map: Dictionary = validation_result.trigger_map

	if trigger_map.has(UiAnimTarget.Trigger.SELECTION_CHANGED):
		if not tab_selected.is_connected(_on_trigger_selection_changed):
			tab_selected.connect(_on_trigger_selection_changed)
	if trigger_map.has(UiAnimTarget.Trigger.HOVER_ENTER):
		if not mouse_entered.is_connected(_on_trigger_hover_enter):
			mouse_entered.connect(_on_trigger_hover_enter)
	if trigger_map.has(UiAnimTarget.Trigger.HOVER_EXIT):
		if not mouse_exited.is_connected(_on_trigger_hover_exit):
			mouse_exited.connect(_on_trigger_hover_exit)

func _finish_initialization() -> void:
	_is_initializing = false

func _on_trigger_selection_changed(_tab_index: int) -> void:
	if _is_initializing:
		return
	_trigger_animations(UiAnimTarget.Trigger.SELECTION_CHANGED)

func _on_trigger_hover_enter() -> void:
	_trigger_animations(UiAnimTarget.Trigger.HOVER_ENTER)

func _on_trigger_hover_exit() -> void:
	_trigger_animations(UiAnimTarget.Trigger.HOVER_EXIT)

func _trigger_animations(trigger_type: UiAnimTarget.Trigger) -> void:
	UiReactAnimTargetHelper.trigger_animations(self, animation_targets, trigger_type)

func _on_tab_selected(tab_index: int) -> void:
	if _previous_tab_index >= 0 and _previous_tab_index != tab_index:
		UiTabTransitionAnimator.animate_tab_switch(self, _previous_tab_index, tab_index, animation_targets)

	_previous_tab_index = tab_index

	UiTabContentStateBinder.bind_tab_content(self, tab_config, tab_index, Callable(self, "_on_tab_content_state_changed"))

	if animation_targets.size() > 0:
		_on_trigger_selection_changed(tab_index)

	if not selected_state or _updating:
		return
	var new_value: Variant = tab_index
	if selected_state.value == new_value:
		return
	_updating = true
	selected_state.set_value(new_value)
	_updating = false

func _on_selected_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _updating:
		return
	var index: int = UiTabSelectionBinding.resolve_tab_index(self, new_value)
	if index < 0 or index >= get_tab_count():
		return
	if current_tab == index:
		return

	if _previous_tab_index >= 0 and _previous_tab_index != index:
		UiTabTransitionAnimator.animate_tab_switch(self, _previous_tab_index, index, animation_targets)
	UiTabContentStateBinder.bind_tab_content(self, tab_config, index, Callable(self, "_on_tab_content_state_changed"))

	_updating = true
	_previous_tab_index = index
	current_tab = index
	_updating = false

func _on_tabs_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _updating:
		return

	if not (new_value is Array):
		push_warning("UiReactTabContainer '%s': tabs_state.value must be an Array. Got: %s" % [name, typeof(new_value)])
		return

	var tabs_array: Array = new_value

	_updating = true

	var prev_update = UiTabCollectionSync.apply_tabs_from_array(self, tabs_array, tab_config)
	if prev_update != null:
		_previous_tab_index = int(prev_update)

	_updating = false

func _on_tab_content_state_changed(tab_index: int, property: String, new_value: Variant, _old_value: Variant) -> void:
	UiTabContentStateBinder.propagate_content_change(self, tab_index, property, new_value)

func _on_disabled_tabs_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _updating:
		return

	if not (new_value is Array):
		push_warning("UiReactTabContainer '%s': disabled_tabs_state.value must be an Array. Got: %s" % [name, typeof(new_value)])
		return

	var disabled_array: Array = new_value
	var tab_count = get_tab_count()

	_updating = true

	for i in range(min(disabled_array.size(), tab_count)):
		var is_disabled = bool(disabled_array[i])
		set_tab_disabled(i, is_disabled)

	_updating = false

func _on_visible_tabs_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _updating:
		return

	if not (new_value is Array):
		push_warning("UiReactTabContainer '%s': visible_tabs_state.value must be an Array. Got: %s" % [name, typeof(new_value)])
		return

	var visible_array: Array = new_value
	var tab_count = get_tab_count()

	_updating = true

	for i in range(min(visible_array.size(), tab_count)):
		var tab_visible = bool(visible_array[i])
		set_tab_hidden(i, not tab_visible)

	_updating = false

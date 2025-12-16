extends TabContainer
class_name ReactiveTabContainer

@export_group("State Binding")
## Binds the selected tab index to a State resource for two-way data binding.
@export var selected_state: State

@export_group("Configuration")
## Configuration resource for dynamic tab management, content binding, and tab states.
## Create a TabContainerConfig resource and assign it here to enable advanced tab features.
@export var tab_config: TabContainerConfig

@export_group("Animation")
## Targets to animate based on tab container events.
##
## Drag nodes here and configure each target's animation properties directly in the Inspector.
## Each target can specify its own trigger (selection changed, hover enter/exit), animation type,
## duration, and settings - no resource files needed!
@export var animations: Array[AnimationReel] = []

var _helper: TabContainerHelper
var _updating: bool = false
var _previous_tab_index: int = -1
var _is_initializing: bool = true

func _ready() -> void:
	# Initialize helper with tab config
	if tab_config:
		_helper = TabContainerHelper.new(self, tab_config)

	tab_selected.connect(_on_tab_selected)
	_previous_tab_index = current_tab

	if selected_state:
		selected_state.value_changed.connect(_on_selected_state_changed)
		_on_selected_state_changed(selected_state.value, selected_state.value)
	
	# Connect tab config properties if config is set
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
	
	_validate_animation_reels()
	# Finish initialization after all signals are processed
	call_deferred("_finish_initialization")

## Validates animation targets and filters out invalid ones.
## Called automatically in [method _ready].
func _validate_animation_reels() -> void:
	var valid_reels: Array[AnimationReel] = []
	var has_selection_changed_targets = false
	var has_hover_enter_targets = false
	var has_hover_exit_targets = false

	for reel in animations:
		if reel == null:
			continue

		# Validate targets array (at least one target required)
		if reel.targets.size() == 0:
			push_warning("ReactiveTabContainer '%s': AnimationReel has no targets. Add at least one target NodePath." % name)
			continue

		# Validate all targets resolve to Controls
		var has_valid_target = false
		for path in reel.targets:
			var node = get_node_or_null(path)
			if node is Control:
				has_valid_target = true
				break

		if not has_valid_target:
			push_warning("ReactiveTabContainer '%s': AnimationReel has no valid targets. Check NodePaths." % name)
			continue

		valid_reels.append(reel)

		# Track which triggers we need to connect
		match reel.trigger:
			AnimationReel.Trigger.SELECTION_CHANGED:
				has_selection_changed_targets = true
			AnimationReel.Trigger.HOVER_ENTER:
				has_hover_enter_targets = true
			AnimationReel.Trigger.HOVER_EXIT:
				has_hover_exit_targets = true

	animations = valid_reels

	# Connect signals based on which triggers are used
	if has_selection_changed_targets:
		if not tab_selected.is_connected(_on_trigger_selection_changed):
			tab_selected.connect(_on_trigger_selection_changed)
	if has_hover_enter_targets:
		if not mouse_entered.is_connected(_on_trigger_hover_enter):
			mouse_entered.connect(_on_trigger_hover_enter)
	if has_hover_exit_targets:
		if not mouse_exited.is_connected(_on_trigger_hover_exit):
			mouse_exited.connect(_on_trigger_hover_exit)

## Finishes initialization, allowing animations to trigger on selection changes.
func _finish_initialization() -> void:
	_is_initializing = false

## Handles SELECTION_CHANGED trigger animations.
func _on_trigger_selection_changed(_tab_index: int) -> void:
	# Skip animations during initialization
	if _is_initializing:
		return
	
	_trigger_animations(AnimationReel.Trigger.SELECTION_CHANGED)

## Handles HOVER_ENTER trigger animations.
func _on_trigger_hover_enter() -> void:
	_trigger_animations(AnimationReel.Trigger.HOVER_ENTER)

## Handles HOVER_EXIT trigger animations.
func _on_trigger_hover_exit() -> void:
	_trigger_animations(AnimationReel.Trigger.HOVER_EXIT)

## Triggers animations for reels matching the specified trigger type.
## [param trigger_type]: The trigger type to match.
func _trigger_animations(trigger_type) -> void:
	if animations.size() == 0:
		return

	# Apply animations for reels matching this trigger
	for reel in animations:
		if reel == null:
			continue

		if reel.trigger != trigger_type:
			continue

		# Note: respect_disabled is now per-clip, not per-reel
		reel.apply(self)

func _on_tab_selected(tab_index: int) -> void:
	# Handle tab switching animations (animate old tab out, new tab in)
	if _previous_tab_index >= 0 and _previous_tab_index != tab_index:
		_animate_tab_switch(_previous_tab_index, tab_index)
	
	_previous_tab_index = tab_index
	
	# Bind tab content to its State if configured
	_bind_tab_content_state(tab_index)
	
	# Trigger animations if configured
	if animations.size() > 0:
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
	var index := -1
	if new_value is int:
		index = int(new_value)
	elif new_value is String:
		# Try to find tab by name
		for i in get_tab_count():
			if get_tab_title(i) == new_value:
				index = i
				break
	if index < 0 or index >= get_tab_count():
		return
	if current_tab == index:
		return
	
	# Handle tab switching animations and content binding
	if _previous_tab_index >= 0 and _previous_tab_index != index:
		_animate_tab_switch(_previous_tab_index, index)
	_bind_tab_content_state(index)
	
	_updating = true
	_previous_tab_index = index
	current_tab = index
	_updating = false

## Handles dynamic tab management from tabs_state.
## tabs_state.value should be an Array of tab data (Dictionary with "title", "icon", etc., or just Strings).
func _on_tabs_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _updating:
		return

	if not (new_value is Array):
		push_warning("ReactiveTabContainer '%s': tabs_state.value must be an Array. Got: %s" % [name, typeof(new_value)])
		return

	_updating = true
	_helper.update_tabs_from_state(new_value)
	_previous_tab_index = current_tab
	_updating = false

## Binds the selected tab's content to its corresponding State.
## This allows each tab's content to be reactive to its own State resource.
func _bind_tab_content_state(tab_index: int) -> void:
	if _helper:
		_helper.bind_tab_content_state(tab_index)

## Helper to update tab content when its State changes.
func _on_tab_content_state_changed(new_value: Variant, _old_value: Variant, tab_index: int, property: String) -> void:
	var tab_child = get_tab_control(tab_index)
	if tab_child == null:
		return
	
	# Handle child property (e.g., "child_text_state")
	if property.begins_with("child_"):
		var actual_prop = property.substr(6)  # Remove "child_" prefix
		var first_child = tab_child.get_child(0) if tab_child.get_child_count() > 0 else null
		if first_child != null and first_child.has(actual_prop):
			var child_state = first_child.get(actual_prop)
			if child_state is State:
				child_state.set_silent(new_value)
	else:
		# Handle direct property
		if tab_child.has(property):
			var child_state = tab_child.get(property)
			if child_state is State:
				child_state.set_silent(new_value)

## Handles per-tab enable/disable from disabled_tabs_state.
## disabled_tabs_state.value should be an Array of booleans (one per tab).
func _on_disabled_tabs_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _updating:
		return

	if not (new_value is Array):
		push_warning("ReactiveTabContainer '%s': disabled_tabs_state.value must be an Array. Got: %s" % [name, typeof(new_value)])
		return

	_updating = true
	_helper.update_disabled_tabs(new_value)
	_updating = false

## Handles tab visibility control from visible_tabs_state.
## visible_tabs_state.value should be an Array of booleans (one per tab).
func _on_visible_tabs_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _updating:
		return

	if not (new_value is Array):
		push_warning("ReactiveTabContainer '%s': visible_tabs_state.value must be an Array. Got: %s" % [name, typeof(new_value)])
		return

	_updating = true
	_helper.update_visible_tabs(new_value)
	_updating = false

## Animates tab switching by fading out old tab content and fading in new tab content.
## This enhances the SELECTION_CHANGED trigger to animate tab content transitions.
func _animate_tab_switch(old_index: int, new_index: int) -> void:
	var old_child = get_tab_control(old_index)
	var new_child = get_tab_control(new_index)
	
	if old_child == null or new_child == null:
		return
	
	# Look for SELECTION_CHANGED animations that target tab content
	for reel in animations:
		if reel == null:
			continue
		if reel.trigger != AnimationReel.Trigger.SELECTION_CHANGED:
			continue

		var old_path = get_path_to(old_child)
		var new_path = get_path_to(new_child)

		# Check if any of the reel's targets match the old or new tab
		var targets_old = old_path in reel.targets or reel.targets.size() == 0
		var targets_new = new_path in reel.targets or reel.targets.size() == 0

		# For now, apply the reel to both old and new children
		# TODO: This logic may need to be redesigned for AnimationReel system
		if targets_old or targets_new:
			if targets_old and old_child:
				reel.apply(old_child)
			if targets_new and new_child:
				reel.apply(new_child)


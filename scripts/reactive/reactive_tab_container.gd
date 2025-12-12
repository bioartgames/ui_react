extends TabContainer
class_name ReactiveTabContainer

## Binds the selected tab index to a State resource for two-way data binding.
@export var selected_state: State

## Configuration resource for dynamic tab management, content binding, and tab states.
## Create a TabContainerConfig resource and assign it here to enable advanced tab features.
@export var tab_config: TabContainerConfig

## Targets to animate based on tab container events.
##
## Drag nodes here and configure each target's animation properties directly in the Inspector.
## Each target can specify its own trigger (selection changed, hover enter/exit), animation type,
## duration, and settings - no resource files needed!
@export var animation_targets: Array[AnimationTarget] = []

var _updating: bool = false
var _previous_tab_index: int = -1

func _ready() -> void:
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
	
	_validate_animation_targets()

## Validates animation targets and filters out invalid ones.
## Called automatically in [method _ready].
func _validate_animation_targets() -> void:
	var valid_targets: Array[AnimationTarget] = []
	var has_selection_changed_targets = false
	var has_hover_enter_targets = false
	var has_hover_exit_targets = false
	
	for anim_target in animation_targets:
		if anim_target == null:
			continue
		
		# Check if target is set
		if anim_target.target.is_empty():
			push_warning("ReactiveTabContainer '%s': AnimationTarget has no target. Set target (NodePath) in the Inspector. Tip: Drag a node to target." % name)
			continue
		
		# Verify the target resolves to a valid Control
		var target_node = get_node_or_null(anim_target.target)
		if target_node == null:
			push_warning("ReactiveTabContainer '%s': AnimationTarget target '%s' not found. Check the NodePath." % [name, anim_target.target])
			continue
		
		if not (target_node is Control):
			push_warning("ReactiveTabContainer '%s': AnimationTarget target '%s' is not a Control node." % [name, anim_target.target])
			continue
		
		valid_targets.append(anim_target)
		
		# Track which triggers we need to connect
		match anim_target.trigger:
			AnimationTarget.Trigger.SELECTION_CHANGED:
				has_selection_changed_targets = true
			AnimationTarget.Trigger.HOVER_ENTER:
				has_hover_enter_targets = true
			AnimationTarget.Trigger.HOVER_EXIT:
				has_hover_exit_targets = true
	
	animation_targets = valid_targets
	
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

## Handles SELECTION_CHANGED trigger animations.
func _on_trigger_selection_changed(_tab_index: int) -> void:
	_trigger_animations(AnimationTarget.Trigger.SELECTION_CHANGED)

## Handles HOVER_ENTER trigger animations.
func _on_trigger_hover_enter() -> void:
	_trigger_animations(AnimationTarget.Trigger.HOVER_ENTER)

## Handles HOVER_EXIT trigger animations.
func _on_trigger_hover_exit() -> void:
	_trigger_animations(AnimationTarget.Trigger.HOVER_EXIT)

## Triggers animations for targets matching the specified trigger type.
## [param trigger_type]: The trigger type to match.
func _trigger_animations(trigger_type: AnimationTarget.Trigger) -> void:
	if animation_targets.size() == 0:
		return
	
	# Apply animations for targets matching this trigger
	for anim_target in animation_targets:
		if anim_target == null:
			continue
		
		if anim_target.trigger != trigger_type:
			continue
		
		# Note: TabContainer doesn't expose disabled property, so respect_disabled is not supported
		
		anim_target.apply(self)

func _on_tab_selected(tab_index: int) -> void:
	# Handle tab switching animations (animate old tab out, new tab in)
	if _previous_tab_index >= 0 and _previous_tab_index != tab_index:
		_animate_tab_switch(_previous_tab_index, tab_index)
	
	_previous_tab_index = tab_index
	
	# Bind tab content to its State if configured
	_bind_tab_content_state(tab_index)
	
	# Trigger animations if configured
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
	
	var tabs_array: Array = new_value
	var current_count = get_tab_count()
	var new_count = tabs_array.size()
	
	_updating = true
	
	# Remove excess tabs (remove from end)
	if new_count < current_count:
		for i in range(current_count - 1, new_count - 1, -1):
			var child = get_tab_control(i)
			if child:
				remove_child(child)
				child.queue_free()
	
	# Add or update tabs
	for i in range(new_count):
		var tab_data = tabs_array[i]
		var tab_title: String = ""
		var tab_icon: Texture2D = null
		
		# Handle different data formats
		if tab_data is Dictionary:
			tab_title = tab_data.get("title", "")
			tab_icon = tab_data.get("icon", null)
		elif tab_data is String:
			tab_title = tab_data
		else:
			tab_title = str(tab_data)
		
		# Update existing tab or create new one
		if i < current_count:
			# Update existing tab
			set_tab_title(i, tab_title)
			if tab_icon:
				set_tab_icon(i, tab_icon)
		else:
			# Create new tab (TabContainer creates tabs for child nodes)
			# Create a placeholder Control if needed
			var child = Control.new()
			child.name = "Tab%d" % i
			add_child(child)
			set_tab_title(i, tab_title)
			if tab_icon:
				set_tab_icon(i, tab_icon)
	
	# Validate current_tab is still valid
	if current_tab >= new_count and new_count > 0:
		current_tab = new_count - 1
		_previous_tab_index = current_tab
	elif current_tab < 0 and new_count > 0:
		current_tab = 0
		_previous_tab_index = 0
	
	# Resize tab_content_states array to match tab count if needed
	if tab_config and tab_config.tab_content_states.size() < new_count:
		tab_config.tab_content_states.resize(new_count)
	
	_updating = false

## Binds the selected tab's content to its corresponding State.
## This allows each tab's content to be reactive to its own State resource.
func _bind_tab_content_state(tab_index: int) -> void:
	if not tab_config or tab_index < 0 or tab_index >= tab_config.tab_content_states.size():
		return
	
	var content_state = tab_config.tab_content_states[tab_index]
	if content_state == null:
		return
	
	# Get the tab's child control
	var tab_child = get_tab_control(tab_index)
	if tab_child == null:
		return
	
	# Try to find a State property in the child
	# Common patterns: text_state, value_state, selected_state, etc.
	var state_properties = ["text_state", "value_state", "selected_state", "checked_state", "pressed_state"]
	for prop in state_properties:
		if tab_child.has(prop):
			var child_state = tab_child.get(prop)
			if child_state is State:
				# Update the child's State with the content State's value
				child_state.set_silent(content_state.value)
				# Connect for future updates (disconnect first to avoid duplicates)
				var callable = _on_tab_content_state_changed.bind(tab_index, prop)
				if content_state.value_changed.is_connected(callable):
					content_state.value_changed.disconnect(callable)
				content_state.value_changed.connect(callable)
				return  # Found and bound, exit
	
	# Also check direct children for reactive controls (first child only)
	var first_child = tab_child.get_child(0) if tab_child.get_child_count() > 0 else null
	if first_child != null:
		for prop in state_properties:
			if first_child.has(prop):
				var child_state = first_child.get(prop)
				if child_state is State:
					child_state.set_silent(content_state.value)
					var callable = _on_tab_content_state_changed.bind(tab_index, "child_" + prop)
					if content_state.value_changed.is_connected(callable):
						content_state.value_changed.disconnect(callable)
					content_state.value_changed.connect(callable)
					return

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
	
	var disabled_array: Array = new_value
	var tab_count = get_tab_count()
	
	_updating = true
	
	for i in range(min(disabled_array.size(), tab_count)):
		var is_disabled = bool(disabled_array[i])
		set_tab_disabled(i, is_disabled)
	
	_updating = false

## Handles tab visibility control from visible_tabs_state.
## visible_tabs_state.value should be an Array of booleans (one per tab).
func _on_visible_tabs_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _updating:
		return
	
	if not (new_value is Array):
		push_warning("ReactiveTabContainer '%s': visible_tabs_state.value must be an Array. Got: %s" % [name, typeof(new_value)])
		return
	
	var visible_array: Array = new_value
	var tab_count = get_tab_count()
	
	_updating = true
	
	for i in range(min(visible_array.size(), tab_count)):
		var tab_visible = bool(visible_array[i])
		set_tab_hidden(i, not tab_visible)
	
	_updating = false

## Animates tab switching by fading out old tab content and fading in new tab content.
## This enhances the SELECTION_CHANGED trigger to animate tab content transitions.
func _animate_tab_switch(old_index: int, new_index: int) -> void:
	var old_child = get_tab_control(old_index)
	var new_child = get_tab_control(new_index)
	
	if old_child == null or new_child == null:
		return
	
	# Look for SELECTION_CHANGED animations that target tab content
	for anim_target in animation_targets:
		if anim_target == null:
			continue
		if anim_target.trigger != AnimationTarget.Trigger.SELECTION_CHANGED:
			continue
		
		var old_path = get_path_to(old_child)
		var new_path = get_path_to(new_child)
		var targets_old = anim_target.target == old_path or anim_target.target.is_empty()
		var targets_new = anim_target.target == new_path or anim_target.target.is_empty()
		
		# Animate old tab out (fade out or slide out)
		if targets_old:
			var fade_out = anim_target.duplicate()
			fade_out.reverse = true
			# If it's a fade_in animation, reverse it for fade out
			if fade_out.animation == AnimationTarget.AnimationAction.FADE_IN:
				fade_out.apply(old_child)
			else:
				fade_out.apply(old_child)
		
		# Animate new tab in (fade in or slide in)
		if targets_new:
			var fade_in = anim_target.duplicate()
			fade_in.reverse = false
			fade_in.apply(new_child)
		
		# If target is empty, we've handled both, so break
		if anim_target.target.is_empty():
			break


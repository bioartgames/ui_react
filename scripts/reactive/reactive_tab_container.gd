@tool
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
var _control_helper: ReactiveControlHelper
var _previous_tab_index: int = -1
## Prefix for child property access (e.g., "child_text_state").
const CHILD_PREFIX := "child_"
## Whether focus has "entered" the TabContainer (user pressed Select).
## When false, TabContainer acts as a single focusable item. When true, focus is inside.
var _entered: bool = false

func _ready() -> void:
	if Engine.is_editor_hint():
		# In the editor, only validate reels so trigger options are filtered.
		_validate_animation_reels()
		return

	# Make TabContainer focusable so VBox/HBox can focus it as a single item
	focus_mode = Control.FOCUS_ALL

	# Initialize control helper FIRST, before any state connections
	_control_helper = ReactiveControlHelper.new(self)

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
	# Set up internal focus chain
	call_deferred("_setup_internal_focus")

## Validates animation reels and filters out invalid ones.
## Called automatically in [method _ready].
func _validate_animation_reels() -> void:
	var trigger_map: Dictionary = ReactiveAnimationSetup.setup_reels(self, animations, _get_control_type_hint())
	
	# Connect trigger signals
	var bindings: Array = [
		[AnimationReel.Trigger.SELECTION_CHANGED, tab_selected, _on_trigger_selection_changed],
		[AnimationReel.Trigger.HOVER_ENTER, mouse_entered, _on_trigger_hover_enter],
		[AnimationReel.Trigger.HOVER_EXIT, mouse_exited, _on_trigger_hover_exit],
	]
	ReactiveAnimationSetup.connect_trigger_bindings(self, trigger_map, bindings)
	
	# Connect focus-driven hover animations
	ReactiveAnimationSetup.connect_focus_driven_hover(self, animations, func(): return _control_helper.is_initializing())

## Finishes initialization, allowing animations to trigger on selection changes.
func _finish_initialization() -> void:
	_control_helper.finish_initialization()

## Handles SELECTION_CHANGED trigger animations.
func _on_trigger_selection_changed(_tab_index: int) -> void:
	# Skip animations during initialization
	if _control_helper.is_initializing():
		return
	
	_trigger_animations(AnimationReel.Trigger.SELECTION_CHANGED)

## Handles HOVER_ENTER trigger animations.
func _on_trigger_hover_enter() -> void:
	_trigger_animations(AnimationReel.Trigger.HOVER_ENTER)

## Handles HOVER_EXIT trigger animations.
func _on_trigger_hover_exit() -> void:
	_trigger_animations(AnimationReel.Trigger.HOVER_EXIT)

	
	# If focus left TabContainer entirely (not just moved inside), reset entered state
	var focus_owner = get_viewport().gui_get_focus_owner()
	if not focus_owner or not is_ancestor_of(focus_owner):
		_entered = false

## Triggers animations for reels matching the specified trigger type.
## [param trigger_type]: The trigger type to match.
func _trigger_animations(trigger_type) -> void:
	AnimationReel.trigger_matching(self, animations, trigger_type)

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
	
	# Rebuild internal focus chain for new current tab
	call_deferred("_setup_internal_focus")
	
	if not selected_state or _control_helper.is_updating():
		return
	var new_value: Variant = tab_index
	if selected_state.value == new_value:
		return
	_control_helper.set_updating(true)
	selected_state.set_value(new_value)
	_control_helper.set_updating(false)

func _on_selected_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _control_helper.is_updating():
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
	
	_control_helper.set_updating(true)
	_previous_tab_index = index
	current_tab = index
	_control_helper.set_updating(false)

## Handles dynamic tab management from tabs_state.
## tabs_state.value should be an Array of tab data (Dictionary with "title", "icon", etc., or just Strings).
func _on_tabs_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _control_helper.is_updating():
		return

	if not (new_value is Array):
		push_warning("ReactiveTabContainer '%s': tabs_state.value must be an Array. Got: %s" % [name, typeof(new_value)])
		return

	_control_helper.set_updating(true)
	_helper.update_tabs_from_state(new_value)
	_previous_tab_index = current_tab
	_control_helper.set_updating(false)

## Binds the selected tab's content to its corresponding State.
## This allows each tab's content to be reactive to its own State resource.
func _bind_tab_content_state(tab_index: int) -> void:
	if _helper:
		_helper.bind_tab_content_state(tab_index)

## Helper to update tab content when its State changes.
func _on_tab_content_state_changed(new_value: Variant, _old_value: Variant, tab_index: int, property: String) -> void:
	var tab_child: Control = get_tab_control(tab_index)
	if tab_child == null:
		return
	
	# Handle child property (e.g., "child_text_state")
	if property.begins_with(CHILD_PREFIX):
		var actual_prop: String = property.substr(CHILD_PREFIX.length())  # Remove "child_" prefix
		var first_child: Node = tab_child.get_child(0) if tab_child.get_child_count() > 0 else null
		if first_child != null and first_child.has(actual_prop):
			var child_state: Variant = first_child.get(actual_prop)
			if child_state is State:
				child_state.set_silent(new_value)
	else:
		# Handle direct property
		if tab_child.has(property):
			var child_state: Variant = tab_child.get(property)
			if child_state is State:
				child_state.set_silent(new_value)

## Handles per-tab enable/disable from disabled_tabs_state.
## disabled_tabs_state.value should be an Array of booleans (one per tab).
func _on_disabled_tabs_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _control_helper.is_updating():
		return

	if not (new_value is Array):
		push_warning("ReactiveTabContainer '%s': disabled_tabs_state.value must be an Array. Got: %s" % [name, typeof(new_value)])
		return

	_control_helper.set_updating(true)
	_helper.update_disabled_tabs(new_value)
	_control_helper.set_updating(false)

## Handles tab visibility control from visible_tabs_state.
## visible_tabs_state.value should be an Array of booleans (one per tab).
func _on_visible_tabs_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _control_helper.is_updating():
		return

	if not (new_value is Array):
		push_warning("ReactiveTabContainer '%s': visible_tabs_state.value must be an Array. Got: %s" % [name, typeof(new_value)])
		return

	_control_helper.set_updating(true)
	_helper.update_visible_tabs(new_value)
	_control_helper.set_updating(false)

## Animates tab switching by fading out old tab content and fading in new tab content.
## This enhances the SELECTION_CHANGED trigger to animate tab content transitions.
func _animate_tab_switch(old_index: int, new_index: int) -> void:
	var old_child: Control = get_tab_control(old_index)
	var new_child: Control = get_tab_control(new_index)
	
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
		var targets_old: bool = old_path in reel.targets or reel.targets.size() == 0
		var targets_new: bool = new_path in reel.targets or reel.targets.size() == 0

		# Tab switch uses apply_to_control so reels stay configured relative to TabContainer.
		if targets_old or targets_new:
			if targets_old and old_child:
				reel.apply_to_control(self, old_child)
			if targets_new and new_child:
				reel.apply_to_control(self, new_child)

## Gets the control type hint for this reactive control.
## Used to filter available triggers in the Inspector.
func _get_control_type_hint() -> AnimationReel.ControlTypeHint:
	return AnimationReel.ControlTypeHint.SELECTION

## Gets the first focusable control inside the TabContainer for entering.
## Prefers tab bar if focusable, otherwise first focusable in current tab.
## [return]: The control to focus when entering, or null if none.
func _get_first_focusable_inside() -> Control:
	# Try tab bar first
	var tab_bar: TabBar = get_tab_bar()
	if tab_bar is Control:
		var bar_control: Control = tab_bar
		if bar_control.focus_mode != Control.FOCUS_NONE:
			return bar_control
	# Fall back to first focusable in current tab
	var current_tab_control: Control = get_current_tab_control()
	if current_tab_control:
		var focusables: Array[Control] = NavigationUtils.find_focusable_controls(current_tab_control, true)
		if not focusables.is_empty():
			return focusables[0]
	return null

## Handles input for entering/exiting TabContainer.
## Enter: ui_accept / Enter / Space / A when focused and not entered
## Exit: ui_cancel / Escape / B when entered and focus is inside
func _gui_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	
	# Enter on accept (key/action/joypad) when TabContainer has focus and not entered
	if NavigationUtils.is_accept_event(event) and has_focus() and not _entered:
		var first_inside = _get_first_focusable_inside()
		if first_inside:
			_entered = true
			first_inside.grab_focus()
			accept_event()
		return
	
	# Exit on cancel when entered and focus is inside TabContainer
	if NavigationUtils.is_cancel_event(event) and _entered:
		var focus_owner = get_viewport().gui_get_focus_owner()
		if focus_owner and is_ancestor_of(focus_owner):
			_entered = false
			grab_focus()  # Return focus to TabContainer node itself
			accept_event()

## Handles unhandled key input for cancel when focus is inside TabContainer.
## This catches Escape/B when children don't consume it.
func _unhandled_key_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	
	# Only handle cancel when entered (focus is inside)
	if not _entered:
		return
	
	if NavigationUtils.is_cancel_event(event):
		var focus_owner = get_viewport().gui_get_focus_owner()
		if focus_owner and is_ancestor_of(focus_owner):
			_entered = false
			grab_focus()  # Return focus to TabContainer node itself
			get_viewport().set_input_as_handled()  # Mark event as handled

## Sets up focus neighbor chain for tab bar and current tab content.
## Creates a vertical chain: tab bar <-> first focusable <-> ... <-> last focusable.
## Also sets wrap: first's top -> last, last's bottom -> first.
func _setup_internal_focus() -> void:
	if Engine.is_editor_hint():
		return
	
	# Build list: tab bar (if focusable) + focusables in current tab
	var focus_chain: Array[Control] = []
	
	# Add tab bar if focusable
	var tab_bar: TabBar = get_tab_bar()
	if tab_bar is Control:
		var bar_control: Control = tab_bar
		if bar_control.focus_mode != Control.FOCUS_NONE:
			focus_chain.append(bar_control)
	
	# Add focusables in current tab
	var current_tab_control: Control = get_current_tab_control()
	if current_tab_control:
		var tab_focusables: Array[Control] = NavigationUtils.find_focusable_controls(current_tab_control, true)
		focus_chain.append_array(tab_focusables)
	
	# Use NavigationUtils to set up the focus chain with vertical and horizontal wrapping
	NavigationUtils.setup_focus_chain(focus_chain, true, true)

func _exit_tree() -> void:
	FocusDrivenHover.cleanup(self)

@tool
extends ItemList
class_name ReactiveItemList

@export var selected_state: State
@export var disabled_state: State

## Targets to animate based on item list events.
##
## Drag nodes here and configure each target's animation properties directly in the Inspector.
## Each target can specify its own trigger (selection changed, hover enter/exit), animation type,
## duration, and settings - no resource files needed!
@export var animations: Array[AnimationReel] = []

var _updating: bool = false
var _is_initializing: bool = true

func _ready() -> void:
	if Engine.is_editor_hint():
		# In the editor, only validate reels so trigger options are filtered.
		_validate_animation_reels()
		return

	item_selected.connect(_on_item_selected)
	item_activated.connect(_on_item_activated)
	if selected_state:
		selected_state.value_changed.connect(_on_selected_state_changed)
		_on_selected_state_changed(selected_state.value, selected_state.value)
	if disabled_state:
		disabled_state.value_changed.connect(_on_disabled_state_changed)
		_on_disabled_state_changed(disabled_state.value, disabled_state.value)
	_validate_animation_reels()
	# Finish initialization after all signals are processed
	call_deferred("_finish_initialization")

## Validates animation reels and filters out invalid ones.
## Called automatically in [method _ready].
func _validate_animation_reels() -> void:
	var result = AnimationReel.validate_for_control(self, animations)
	animations = result.valid_reels

	# Set control context on each reel for Inspector filtering
	var control_type = _get_control_type_hint()
	for reel in animations:
		if reel:
			reel.control_type_context = control_type

	# Control-specific signal connections (stays in class)
	var has_selection_changed_targets = result.trigger_map.get(AnimationReel.Trigger.SELECTION_CHANGED, false)
	var has_hover_enter_targets = result.trigger_map.get(AnimationReel.Trigger.HOVER_ENTER, false)
	var has_hover_exit_targets = result.trigger_map.get(AnimationReel.Trigger.HOVER_EXIT, false)

	# Connect signals based on which triggers are used
	if has_selection_changed_targets:
		if not item_selected.is_connected(_on_trigger_selection_changed):
			item_selected.connect(_on_trigger_selection_changed)
	if has_hover_enter_targets:
		if not mouse_entered.is_connected(_on_trigger_hover_enter):
			mouse_entered.connect(_on_trigger_hover_enter)
	if has_hover_exit_targets:
		if not mouse_exited.is_connected(_on_trigger_hover_exit):
			mouse_exited.connect(_on_trigger_hover_exit)
	# Connect focus signals for navigation-driven hover animations
	if has_hover_enter_targets or has_hover_exit_targets:
		if not focus_entered.is_connected(_on_navigation_focus_entered):
			focus_entered.connect(_on_navigation_focus_entered)
		if not focus_exited.is_connected(_on_navigation_focus_exited):
			focus_exited.connect(_on_navigation_focus_exited)

## Finishes initialization, allowing animations to trigger on selection changes.
func _finish_initialization() -> void:
	_is_initializing = false

## Handles SELECTION_CHANGED trigger animations.
func _on_trigger_selection_changed(_index: int) -> void:
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

## Handles navigation-driven focus changes to trigger hover animations.
func _on_navigation_focus_entered() -> void:
	# Skip animations during initialization
	if _is_initializing:
		return

	# Only trigger hover animations if this focus change was caused by navigation (not mouse)
	const META_NAVIGATION_FOCUS = "_navigation_focus_change"
	if has_meta(META_NAVIGATION_FOCUS):
		# Remove the meta flag immediately to avoid lingering state
		remove_meta(META_NAVIGATION_FOCUS)
		# Mark that navigation hover is active
		set_meta("_nav_hover_active", true)
		# Trigger hover enter animation
		_trigger_animations(AnimationReel.Trigger.HOVER_ENTER)

## Handles navigation-driven focus loss to trigger hover exit animations.
func _on_navigation_focus_exited() -> void:
	# Skip animations during initialization
	if _is_initializing:
		return

	# Only trigger hover exit if navigation hover was active
	if has_meta("_nav_hover_active"):
		# Clear the active flag
		remove_meta("_nav_hover_active")
		# Trigger hover exit animation
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

func _on_item_selected(_index: int) -> void:
	if not selected_state or _updating:
		return
	
	# Get selected items array
	var selected_items: Array[int] = get_selected_items()
	var new_value: Variant
	
	if select_mode == ItemList.SELECT_SINGLE:
		# Single selection: store index or -1 if nothing selected
		new_value = selected_items[0] if selected_items.size() > 0 else -1
	else:
		# Multi selection: store array of indices
		new_value = selected_items
	
	if selected_state.value == new_value:
		return
	
	_updating = true
	selected_state.set_value(new_value)
	_updating = false

func _on_item_activated(index: int) -> void:
	# Also trigger selection changed on activation
	_on_item_selected(index)

func _on_selected_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _updating:
		return
	
	if new_value is int:
		# Single selection mode
		var index = int(new_value)
		if index < 0 or index >= item_count:
			return
		
		_updating = true
		deselect_all()
		if index >= 0:
			select(index)
		_updating = false
	elif new_value is Array:
		# Multi selection mode
		var indices: Array[int] = []
		for item in new_value:
			if item is int:
				var idx = int(item)
				if idx >= 0 and idx < item_count:
					indices.append(idx)
		
		_updating = true
		deselect_all()
		for idx in indices:
			select(idx)
		_updating = false

func _on_disabled_state_changed(_new_value: Variant, _old_value: Variant) -> void:
	# Note: ItemList doesn't expose disabled property in Godot 4.5, so this is a no-op
	pass

## Gets the control type hint for this reactive control.
## Used to filter available triggers in the Inspector.
func _get_control_type_hint() -> AnimationReel.ControlTypeHint:
	return AnimationReel.ControlTypeHint.SELECTION


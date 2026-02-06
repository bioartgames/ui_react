@tool
extends OptionButton
class_name ReactiveOptionButton

@export var selected_state: State
@export var disabled_state: State

## Targets to animate based on option button events.
##
## Drag nodes here and configure each target's animation properties directly in the Inspector.
## Each target can specify its own trigger (selection changed, hover enter/exit), animation type,
## duration, and settings - no resource files needed! Leave empty to use manual signal connections.
@export var animations: Array[AnimationReel] = []

var _helper: ReactiveControlHelper

func _ready() -> void:
	if Engine.is_editor_hint():
		# In the editor, only validate reels so trigger options are filtered.
		_validate_animation_reels()
		return

	# Initialize helper FIRST, before any state connections
	_helper = ReactiveControlHelper.new(self)

	item_selected.connect(_on_item_selected)
	if selected_state:
		selected_state.value_changed.connect(_on_selected_state_changed)
		_on_selected_state_changed(selected_state.value, selected_state.value)
	if disabled_state:
		disabled_state.value_changed.connect(_on_disabled_state_changed)
		_on_disabled_state_changed(disabled_state.value, disabled_state.value)
	_validate_animation_reels()
	# Finish initialization after all signals are processed
	call_deferred("_finish_initialization")

## Validates animation targets and filters out invalid ones.
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
	_helper.finish_initialization()

## Handles SELECTION_CHANGED trigger animations.
func _on_trigger_selection_changed(_index: int) -> void:
	# Skip animations during initialization
	if _helper.is_initializing():
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
	FocusDrivenHover.handle_focus_entered(self, animations, func(): return _helper.is_initializing())

## Handles navigation-driven focus loss to trigger hover exit animations.
func _on_navigation_focus_exited() -> void:
	FocusDrivenHover.handle_focus_exited(self, animations, func(): return _helper.is_initializing())

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

func _on_item_selected(index: int) -> void:
	if not selected_state or _helper.is_updating():
		return
	var new_value: Variant = get_item_text(index)
	if selected_state.value == new_value:
		return
	_helper.set_updating(true)
	selected_state.set_value(new_value)
	_helper.set_updating(false)

func _on_selected_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _helper.is_updating():
		return
	var index := -1
	if new_value is String:
		index = _find_item_by_text(new_value)
	else:
		index = int(new_value)
	if index < 0 or index >= item_count:
		return
	if get_selected_id() == index or selected == index:
		return

	_helper.set_updating(true)
	select(index)
	_helper.set_updating(false)

func _on_disabled_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _helper.is_initializing():
		return
	if _helper.update_property_if_changed("disabled", new_value, func(x): return bool(x)):
		_helper.sync_focus_mode_to_disabled()

func _find_item_by_text(text_value: String) -> int:
	for i in item_count:
		if get_item_text(i) == text_value:
			return i
	return -1

## Gets the control type hint for this reactive control.
## Used to filter available triggers in the Inspector.
func _get_control_type_hint() -> AnimationReel.ControlTypeHint:
	return AnimationReel.ControlTypeHint.SELECTION

func _exit_tree() -> void:
	FocusDrivenHover.cleanup(self)
	# Clean up any unified snapshots when the control is freed
	AnimationStateUtils.clear_unified_snapshot_for_target(self)

@tool
extends CheckBox
class_name ReactiveCheckBox

@export var checked_state: State
@export var disabled_state: State

## Animation reels to execute based on checkbox events.
##
## Drag AnimationReel resources here in the Inspector. Each reel can specify its trigger type
## (toggled on/off, hover enter/exit), target controls to animate, and animation clips
## to execute. Supports automatic execution modes: single, multi-target, and sequences.
@export var animations: Array[AnimationReel] = []

var _updating: bool = false
var _is_initializing: bool = true

func _ready() -> void:
	if Engine.is_editor_hint():
		# In the editor, only validate reels so trigger options are filtered.
		_validate_animation_reels()
		return

	toggled.connect(_on_toggled)
	if checked_state:
		checked_state.value_changed.connect(_on_checked_state_changed)
		_on_checked_state_changed(checked_state.value, checked_state.value)
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
	var has_toggled_on_targets = result.trigger_map.get(AnimationReel.Trigger.TOGGLED_ON, false)
	var has_toggled_off_targets = result.trigger_map.get(AnimationReel.Trigger.TOGGLED_OFF, false)
	var has_hover_enter_targets = result.trigger_map.get(AnimationReel.Trigger.HOVER_ENTER, false)
	var has_hover_exit_targets = result.trigger_map.get(AnimationReel.Trigger.HOVER_EXIT, false)

	# Connect signals based on which triggers are used
	if has_toggled_on_targets or has_toggled_off_targets:
		if not toggled.is_connected(_on_trigger_toggled):
			toggled.connect(_on_trigger_toggled)
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

## Finishes initialization, allowing animations to trigger on toggle changes.
func _finish_initialization() -> void:
	_is_initializing = false

## Handles TOGGLED_ON and TOGGLED_OFF trigger animations.
func _on_trigger_toggled(active: bool) -> void:
	# Skip animations during initialization
	if _is_initializing:
		return
	
	if active:
		_trigger_animations(AnimationReel.Trigger.TOGGLED_ON)
	else:
		_trigger_animations(AnimationReel.Trigger.TOGGLED_OFF)

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

func _on_toggled(active: bool) -> void:
	if not checked_state or _updating:
		return
	if checked_state.value == active:
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
	var desired := bool(new_value)
	if disabled == desired:
		return
	disabled = desired
	ReactiveControlHelper.sync_focus_mode_to_disabled_static(self)

## Gets the control type hint for this reactive control.
## Used to filter available triggers in the Inspector.
func _get_control_type_hint() -> AnimationReel.ControlTypeHint:
	return AnimationReel.ControlTypeHint.BUTTON

func _exit_tree() -> void:
	ReactiveControlHelper.release_stored_focus_mode(self)

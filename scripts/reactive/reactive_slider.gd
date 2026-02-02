@tool
extends HSlider
class_name ReactiveSlider

@export var value_state: State

## Targets to animate based on slider events.
##
## Drag nodes here and configure each target's animation properties directly in the Inspector.
## Each target can specify its own trigger (value changed, increased, decreased, drag started/ended, hover),
## animation type, duration, and settings - no resource files needed!
@export var animations: Array[AnimationReel] = []

var _updating: bool = false
var _last_value: float = 0.0
var _is_dragging: bool = false
var _is_initializing: bool = true

func _ready() -> void:
	if Engine.is_editor_hint():
		# In the editor, only validate reels so trigger options are filtered.
		_validate_animation_reels()
		return

	value_changed.connect(_on_value_changed)
	if value_state:
		value_state.value_changed.connect(_on_value_state_changed)
		_on_value_state_changed(value_state.value, value_state.value)
		_last_value = float(value_state.value)
	else:
		_last_value = value
	gui_input.connect(_on_gui_input)
	_validate_animation_reels()
	# Finish initialization after all signals are processed
	call_deferred("_finish_initialization")

## Handles GUI input to detect drag start/end.
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				if not _is_dragging:
					_is_dragging = true
					_trigger_animations(AnimationReel.Trigger.DRAG_STARTED)
			else:
				if _is_dragging:
					_is_dragging = false
					_trigger_animations(AnimationReel.Trigger.DRAG_ENDED)

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
	var has_hover_enter_targets = result.trigger_map.get(AnimationReel.Trigger.HOVER_ENTER, false)
	var has_hover_exit_targets = result.trigger_map.get(AnimationReel.Trigger.HOVER_EXIT, false)

	# Connect signals based on which triggers are used
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

## Finishes initialization, allowing animations to trigger on value changes.
func _finish_initialization() -> void:
	_is_initializing = false

## Handles VALUE_CHANGED, VALUE_INCREASED, and VALUE_DECREASED trigger animations.
func _on_trigger_value_changed(new_value: float) -> void:
	# Skip animations during initialization
	if _is_initializing:
		_last_value = new_value
		return
	
	_trigger_animations(AnimationReel.Trigger.VALUE_CHANGED)

	if new_value > _last_value:
		_trigger_animations(AnimationReel.Trigger.VALUE_INCREASED)
	elif new_value < _last_value:
		_trigger_animations(AnimationReel.Trigger.VALUE_DECREASED)

	_last_value = new_value

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

func _on_value_changed(v: float) -> void:
	# Trigger animations if configured
	if animations.size() > 0:
		_on_trigger_value_changed(v)
	
	if not value_state or _updating:
		return
	if float(value_state.value) == v:
		return
	_updating = true
	value_state.set_value(v)
	_updating = false

func _on_value_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _updating:
		return
	var target := float(new_value)
	if is_equal_approx(value, target):
		return
	_updating = true
	value = target
	_updating = false

## Gets the control type hint for this reactive control.
## Used to filter available triggers in the Inspector.
func _get_control_type_hint() -> AnimationReel.ControlTypeHint:
	return AnimationReel.ControlTypeHint.VALUE_INPUT

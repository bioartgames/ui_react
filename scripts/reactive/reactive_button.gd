extends Button
class_name ReactiveButton

@export var pressed_state: State
@export var disabled_state: State

## Animation reels to execute based on button events.
##
## Drag AnimationReel resources here in the Inspector. Each reel can specify its trigger type
## (pressed, hover enter/exit, toggled on/off), target controls to animate, and animation clips
## to execute. Supports automatic execution modes: single, multi-target, and sequences.
@export var animations: Array[AnimationReel] = []

var _updating: bool = false
var _is_initializing: bool = true

func _ready() -> void:
	pressed.connect(_on_pressed)
	toggled.connect(_on_toggled)
	if pressed_state:
		pressed_state.value_changed.connect(_on_pressed_state_changed)
		_on_pressed_state_changed(pressed_state.value, pressed_state.value)
	if disabled_state:
		disabled_state.value_changed.connect(_on_disabled_state_changed)
		_on_disabled_state_changed(disabled_state.value, disabled_state.value)
	_validate_animation_reels()
	# Finish initialization after all signals are processed
	call_deferred("_finish_initialization")

## Validates animation reels and filters out invalid ones.
## Called automatically in [method _ready].
func _validate_animation_reels() -> void:
	var valid_reels: Array[AnimationReel] = []
	var has_pressed_targets = false
	var has_hover_enter_targets = false
	var has_hover_exit_targets = false
	var has_toggled_on_targets = false
	var has_toggled_off_targets = false

	for reel in animations:
		if reel == null:
			continue

		# Validate targets array (at least one target required)
		if reel.targets.size() == 0:
			push_warning("ReactiveButton '%s': AnimationReel has no targets. Add at least one target NodePath." % name)
			continue

		# Validate all targets resolve to Controls
		var has_valid_target = false
		for path in reel.targets:
			var node = get_node_or_null(path)
			if node is Control:
				has_valid_target = true
				break

		if not has_valid_target:
			push_warning("ReactiveButton '%s': AnimationReel has no valid targets. Check NodePaths." % name)
			continue

		valid_reels.append(reel)

		# Track which triggers we need to connect
		match reel.trigger:
			AnimationReel.Trigger.PRESSED:
				has_pressed_targets = true
			AnimationReel.Trigger.HOVER_ENTER:
				has_hover_enter_targets = true
			AnimationReel.Trigger.HOVER_EXIT:
				has_hover_exit_targets = true
			AnimationReel.Trigger.TOGGLED_ON:
				has_toggled_on_targets = true
			AnimationReel.Trigger.TOGGLED_OFF:
				has_toggled_off_targets = true

	animations = valid_reels

	# Connect signals based on which triggers are used
	if has_pressed_targets:
		if not pressed.is_connected(_on_trigger_pressed):
			pressed.connect(_on_trigger_pressed)
	if has_hover_enter_targets:
		if not mouse_entered.is_connected(_on_trigger_hover_enter):
			mouse_entered.connect(_on_trigger_hover_enter)
	if has_hover_exit_targets:
		if not mouse_exited.is_connected(_on_trigger_hover_exit):
			mouse_exited.connect(_on_trigger_hover_exit)
	if has_toggled_on_targets or has_toggled_off_targets:
		if not toggled.is_connected(_on_trigger_toggled):
			toggled.connect(_on_trigger_toggled)

## Handles PRESSED trigger animations.
func _on_trigger_pressed() -> void:
	_trigger_animations(AnimationReel.Trigger.PRESSED)

## Handles HOVER_ENTER trigger animations.
func _on_trigger_hover_enter() -> void:
	_trigger_animations(AnimationReel.Trigger.HOVER_ENTER)

## Handles HOVER_EXIT trigger animations.
func _on_trigger_hover_exit() -> void:
	_trigger_animations(AnimationReel.Trigger.HOVER_EXIT)

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

func _on_pressed() -> void:
	if not pressed_state or toggle_mode:
		return
	if _updating:
		return
	_updating = true
	pressed_state.set_value(true)
	_updating = false

func _on_toggled(active: bool) -> void:
	if not pressed_state or not toggle_mode or _updating:
		return
	if pressed_state.value == active:
		return
	_updating = true
	pressed_state.set_value(active)
	_updating = false

func _on_pressed_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _updating:
		return
	var desired := bool(new_value)
	if toggle_mode:
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

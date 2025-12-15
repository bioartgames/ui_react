extends Label
class_name ReactiveLabel

@export var text_state: State

## Targets to animate based on label events.
##
## Drag nodes here and configure each target's animation properties directly in the Inspector.
## Each target can specify its own trigger (text changed, hover enter/exit), animation type,
## duration, and settings - no resource files needed! Leave empty to use manual signal connections.
@export var animations: Array = []

var _updating: bool = false
var _nested_states: Array[State] = []
var _is_initializing: bool = true

func _ready() -> void:
	if text_state:
		text_state.value_changed.connect(_on_text_state_changed)
		_on_text_state_changed(text_state.value, text_state.value)
	_validate_animation_reels()
	# Finish initialization after all signals are processed
	call_deferred("_finish_initialization")

## Validates animation reels and filters out invalid ones.
## Called automatically in [method _ready].
func _validate_animation_reels() -> void:
	var valid_reels: Array[AnimationReel] = []
	var has_hover_enter_targets = false
	var has_hover_exit_targets = false

	for reel in animations:
		if reel == null:
			continue

		# Validate targets array (at least one target required)
		if reel.targets.size() == 0:
			push_warning("ReactiveLabel '%s': AnimationReel has no targets. Add at least one target NodePath." % name)
			continue

		# Validate all targets resolve to Controls
		var has_valid_target = false
		for path in reel.targets:
			var node = get_node_or_null(path)
			if node is Control:
				has_valid_target = true
				break

		if not has_valid_target:
			push_warning("ReactiveLabel '%s': AnimationReel has no valid targets. Check NodePaths." % name)
			continue

		valid_reels.append(reel)

		# Track which triggers we need to connect (only hover needs signal connections)
		match reel.trigger:
			AnimationReel.Trigger.HOVER_ENTER:
				has_hover_enter_targets = true
			AnimationReel.Trigger.HOVER_EXIT:
				has_hover_exit_targets = true

	animations = valid_reels

	# Connect signals based on which triggers are used
	if has_hover_enter_targets:
		if not mouse_entered.is_connected(_on_trigger_hover_enter):
			mouse_entered.connect(_on_trigger_hover_enter)
	if has_hover_exit_targets:
		if not mouse_exited.is_connected(_on_trigger_hover_exit):
			mouse_exited.connect(_on_trigger_hover_exit)

## Finishes initialization, allowing animations to trigger on text changes.
func _finish_initialization() -> void:
	_is_initializing = false

## Handles TEXT_CHANGED trigger animations.
func _on_trigger_text_changed(_new_value: Variant, _old_value: Variant) -> void:
	# Skip animations during initialization
	if _is_initializing:
		return
	
	_trigger_animations(AnimationReel.Trigger.TEXT_CHANGED)

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

func _on_text_state_changed(new_value: Variant, old_value: Variant) -> void:
	if _updating:
		return
	_rebind_nested_states(new_value)
	var new_text := _to_text(new_value)
	if text == new_text:
		return
	_updating = true

	text = new_text
	
	# Trigger animations if configured
	if animations.size() > 0:
		_on_trigger_text_changed(new_value, old_value)

	_updating = false

func _rebind_nested_states(value: Variant) -> void:
	for s in _nested_states:
		if is_instance_valid(s) and s.value_changed.is_connected(_on_nested_changed):
			s.value_changed.disconnect(_on_nested_changed)
	_nested_states.clear()
	if value is Array:
		for v in value:
			if v is State:
				var st: State = v
				if not st.value_changed.is_connected(_on_nested_changed):
					st.value_changed.connect(_on_nested_changed)
				_nested_states.append(st)

func _on_nested_changed(_new_value: Variant, _old_value: Variant) -> void:
	if text_state:
		_on_text_state_changed(text_state.value, text_state.value)

func _to_text(value: Variant) -> String:
	if value is State:
		return _to_text(value.value)
	if value is Array:
		var parts: Array[String] = []
		for v in value:
			parts.append(_to_text(v))
		return "".join(parts)
	return str(value)


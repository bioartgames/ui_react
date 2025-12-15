extends OptionButton
class_name ReactiveOptionButton

@export var selected_state: State
@export var disabled_state: State

## Targets to animate based on option button events.
##
## Drag nodes here and configure each target's animation properties directly in the Inspector.
## Each target can specify its own trigger (selection changed, hover enter/exit), animation type,
## duration, and settings - no resource files needed! Leave empty to use manual signal connections.
@export var animations: Array = []

var _updating: bool = false
var _is_initializing: bool = true

func _ready() -> void:
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
	var valid_reels: Array = []
	var has_selection_changed_targets = false
	var has_hover_enter_targets = false
	var has_hover_exit_targets = false

	for reel in animations:
		if reel == null:
			continue

		# Validate targets array (at least one target required)
		if reel.targets.size() == 0:
			push_warning("ReactiveOptionButton '%s': AnimationReel has no targets. Add at least one target NodePath." % name)
			continue

		# Validate all targets resolve to Controls
		var has_valid_target = false
		for path in reel.targets:
			var node = get_node_or_null(path)
			if node is Control:
				has_valid_target = true
				break

		if not has_valid_target:
			push_warning("ReactiveOptionButton '%s': AnimationReel has no valid targets. Check NodePaths." % name)
			continue

		valid_reels.append(reel)

		# Track which triggers we need to connect
		# For now, assume all triggers are possible since we can't access AnimationReel enum
		has_selection_changed_targets = true
		has_hover_enter_targets = true
		has_hover_exit_targets = true

	animations = valid_reels

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

## Finishes initialization, allowing animations to trigger on selection changes.
func _finish_initialization() -> void:
	_is_initializing = false

## Handles SELECTION_CHANGED trigger animations.
func _on_trigger_selection_changed(_index: int) -> void:
	# Skip animations during initialization
	if _is_initializing:
		return
	
	_trigger_animations(6)  # SELECTION_CHANGED

## Handles HOVER_ENTER trigger animations.
func _on_trigger_hover_enter() -> void:
	_trigger_animations(1)  # HOVER_ENTER

## Handles HOVER_EXIT trigger animations.
func _on_trigger_hover_exit() -> void:
	_trigger_animations(2)  # HOVER_EXIT

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
	if not selected_state or _updating:
		return
	var new_value: Variant = get_item_text(index)
	if selected_state.value == new_value:
		return
	_updating = true
	selected_state.set_value(new_value)
	_updating = false

func _on_selected_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _updating:
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

	_updating = true
	select(index)
	_updating = false

func _on_disabled_state_changed(new_value: Variant, _old_value: Variant) -> void:
	disabled = bool(new_value)

func _find_item_by_text(text_value: String) -> int:
	for i in item_count:
		if get_item_text(i) == text_value:
			return i
	return -1

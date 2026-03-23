extends ItemList
class_name ReactiveItemList

@export var selected_state: State
@export var disabled_state: State

## Targets to animate based on item list events.
##
## Drag nodes here and configure each target's animation properties directly in the Inspector.
## Each target can specify its own trigger (selection changed, hover enter/exit), animation type,
## duration, and settings - no resource files needed!
@export var animation_targets: Array[AnimationTarget] = []

var _updating: bool = false
var _is_initializing: bool = true

func _ready() -> void:
	item_selected.connect(_on_item_selected)
	item_activated.connect(_on_item_activated)
	if selected_state:
		selected_state.value_changed.connect(_on_selected_state_changed)
		_on_selected_state_changed(selected_state.value, selected_state.value)
	if disabled_state:
		disabled_state.value_changed.connect(_on_disabled_state_changed)
		_on_disabled_state_changed(disabled_state.value, disabled_state.value)
	_validate_animation_targets()
	ReactiveStateBindingHelper.deferred_finish_initialization(self)

## Validates animation targets and filters out invalid ones.
## Called automatically in [method _ready].
func _validate_animation_targets() -> void:
	var r = ReactiveAnimationTargetHelper.validate_and_map_triggers(self, "ReactiveItemList", animation_targets)
	animation_targets = r["animation_targets"]
	var trigger_map = r["trigger_map"]
	
	# Connect signals based on which triggers are used
	if trigger_map.has(AnimationTarget.Trigger.SELECTION_CHANGED):
		if not item_selected.is_connected(_on_trigger_selection_changed):
			item_selected.connect(_on_trigger_selection_changed)
	if trigger_map.has(AnimationTarget.Trigger.HOVER_ENTER):
		if not mouse_entered.is_connected(_on_trigger_hover_enter):
			mouse_entered.connect(_on_trigger_hover_enter)
	if trigger_map.has(AnimationTarget.Trigger.HOVER_EXIT):
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
	ReactiveAnimationTargetHelper.trigger_animations(self, animation_targets, trigger_type)

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

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
			push_warning("ReactiveItemList '%s': AnimationTarget has no target. Set target (NodePath) in the Inspector. Tip: Drag a node to target." % name)
			continue
		
		# Verify the target resolves to a valid Control
		var target_node = get_node_or_null(anim_target.target)
		if target_node == null:
			push_warning("ReactiveItemList '%s': AnimationTarget target '%s' not found. Check the NodePath." % [name, anim_target.target])
			continue
		
		if not (target_node is Control):
			push_warning("ReactiveItemList '%s': AnimationTarget target '%s' is not a Control node." % [name, anim_target.target])
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
		if not item_selected.is_connected(_on_trigger_selection_changed):
			item_selected.connect(_on_trigger_selection_changed)
	if has_hover_enter_targets:
		if not mouse_entered.is_connected(_on_trigger_hover_enter):
			mouse_entered.connect(_on_trigger_hover_enter)
	if has_hover_exit_targets:
		if not mouse_exited.is_connected(_on_trigger_hover_exit):
			mouse_exited.connect(_on_trigger_hover_exit)

## Handles SELECTION_CHANGED trigger animations.
func _on_trigger_selection_changed(_index: int) -> void:
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
		
		# Note: ItemList doesn't expose disabled property, so respect_disabled is not supported
		
		anim_target.apply(self)

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


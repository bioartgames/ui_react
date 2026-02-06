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

var _helper: ReactiveControlHelper

func _ready() -> void:
	if Engine.is_editor_hint():
		# In the editor, only validate reels so trigger options are filtered.
		_validate_animation_reels()
		return

	# Initialize helper FIRST, before any state connections
	_helper = ReactiveControlHelper.new(self)

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
	var trigger_map = ReactiveAnimationSetup.setup_reels(self, animations, _get_control_type_hint())
	
	# Connect trigger signals
	var bindings: Array = [
		[AnimationReel.Trigger.SELECTION_CHANGED, item_selected, _on_trigger_selection_changed],
		[AnimationReel.Trigger.HOVER_ENTER, mouse_entered, _on_trigger_hover_enter],
		[AnimationReel.Trigger.HOVER_EXIT, mouse_exited, _on_trigger_hover_exit],
	]
	ReactiveAnimationSetup.connect_trigger_bindings(self, trigger_map, bindings)
	
	# Connect focus-driven hover animations
	ReactiveAnimationSetup.connect_focus_driven_hover(self, animations, func(): return _helper.is_initializing())

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


## Triggers animations for reels matching the specified trigger type.
## [param trigger_type]: The trigger type to match.
func _trigger_animations(trigger_type) -> void:
	AnimationReel.trigger_matching(self, animations, trigger_type)

func _on_item_selected(_index: int) -> void:
	if not selected_state or _helper.is_updating():
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
	
	_helper.set_updating(true)
	selected_state.set_value(new_value)
	_helper.set_updating(false)

func _on_item_activated(index: int) -> void:
	# Also trigger selection changed on activation
	_on_item_selected(index)

func _on_selected_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _helper.is_updating():
		return
	
	if new_value is int:
		# Single selection mode
		var index = int(new_value)
		if index < 0 or index >= item_count:
			return
		
		_helper.set_updating(true)
		deselect_all()
		if index >= 0:
			select(index)
		_helper.set_updating(false)
	elif new_value is Array:
		# Multi selection mode
		var indices: Array[int] = []
		for item in new_value:
			if item is int:
				var idx = int(item)
				if idx >= 0 and idx < item_count:
					indices.append(idx)
		
		_helper.set_updating(true)
		deselect_all()
		for idx in indices:
			select(idx)
		_helper.set_updating(false)

func _on_disabled_state_changed(_new_value: Variant, _old_value: Variant) -> void:
	# Note: ItemList doesn't expose disabled property in Godot 4.5, so this is a no-op
	pass

## Gets the control type hint for this reactive control.
## Used to filter available triggers in the Inspector.
func _get_control_type_hint() -> AnimationReel.ControlTypeHint:
	return AnimationReel.ControlTypeHint.SELECTION

func _exit_tree() -> void:
	FocusDrivenHover.cleanup(self)

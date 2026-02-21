## Grid cell control for ReactiveGridContainer.
##
## Implements the cell contract: set_item, set_selected, on_grid_selection_changed.
## Displays item data (icon, name, count) and supports AnimationReels for hover and selection.
@tool
extends Button
class_name ReactiveGridCell

@export_group("Animation")
## Animation reels for hover and selection feedback.
##
## Supports PRESSED, HOVER_ENTER, HOVER_EXIT, and SELECTION_CHANGED triggers.
## Reels use ControlTypeHint.SELECTION (same as ItemList, TabContainer).
@export var animations: Array[AnimationReel] = []

var _control_helper: ReactiveControlHelper

@onready var _icon: TextureRect = $ContentRoot/MarginContainer/VBoxContainer/Icon
@onready var _label: Label = $ContentRoot/MarginContainer/VBoxContainer/Label
@onready var _selection_highlight: ColorRect = $ContentRoot/SelectionHighlight


func _ready() -> void:
	if Engine.is_editor_hint():
		_validate_animation_reels()
		return
	_control_helper = ReactiveControlHelper.new(self)
	_validate_animation_reels()
	call_deferred("_finish_initialization")


## Populates the cell from item data. Handles Dictionary, Resource, or null (empty slot).
##
## Convention: item_data uses "icon" (Texture2D), "name" or "text" (String), "count" (int).
func set_item(item_data: Variant, _index: int) -> void:
	var icon_texture = _get_item_property(item_data, "icon") as Texture2D
	var name_text = _get_item_property(item_data, "name", "") as String
	if name_text.is_empty():
		name_text = _get_item_property(item_data, "text", "") as String
	var count = _get_item_property(item_data, "count", 1)
	if count is float:
		count = int(count)
	elif not (count is int):
		count = 1

	if _icon:
		_icon.texture = icon_texture
		_icon.visible = icon_texture != null

	if _label:
		if item_data == null:
			_label.text = ""
		elif count > 1:
			_label.text = "x%d" % count
		else:
			_label.text = str(name_text)


## Updates the selection highlight. Called by ReactiveGridContainer when selection changes.
func set_selected(is_selected: bool) -> void:
	if _selection_highlight:
		_selection_highlight.visible = is_selected


## Hook for selection animations. Called by ReactiveGridContainer.
## Skips during init; only triggers SELECTION_CHANGED when this cell became selected.
func on_grid_selection_changed(is_selected: bool) -> void:
	if _is_initializing():
		return
	if not is_selected:
		return
	_trigger_animations(AnimationReel.Trigger.SELECTION_CHANGED)


func _validate_animation_reels() -> void:
	var trigger_map: Dictionary = ReactiveAnimationSetup.setup_reels(
		self, animations, AnimationReel.ControlTypeHint.SELECTION
	)
	var bindings: Array = [
		[AnimationReel.Trigger.PRESSED, pressed, _on_trigger_pressed],
		[AnimationReel.Trigger.HOVER_ENTER, mouse_entered, _on_trigger_hover_enter],
		[AnimationReel.Trigger.HOVER_EXIT, mouse_exited, _on_trigger_hover_exit],
		[AnimationReel.Trigger.HOVER_ENTER, focus_entered, _on_focus_trigger_hover_enter],
		[AnimationReel.Trigger.HOVER_EXIT, focus_exited, _on_focus_trigger_hover_exit],
	]
	ReactiveAnimationSetup.connect_trigger_bindings(self, trigger_map, bindings)


func _finish_initialization() -> void:
	if _control_helper:
		_control_helper.finish_initialization()


func _is_initializing() -> bool:
	return _control_helper == null or _control_helper.is_initializing()


func _on_trigger_pressed() -> void:
	_trigger_animations(AnimationReel.Trigger.PRESSED)


func _on_trigger_hover_enter() -> void:
	_trigger_animations(AnimationReel.Trigger.HOVER_ENTER)


func _on_trigger_hover_exit() -> void:
	_trigger_animations(AnimationReel.Trigger.HOVER_EXIT)


func _on_focus_trigger_hover_enter() -> void:
	if _is_initializing():
		return
	_trigger_animations(AnimationReel.Trigger.HOVER_ENTER)


func _on_focus_trigger_hover_exit() -> void:
	if _is_initializing():
		return
	_trigger_animations(AnimationReel.Trigger.HOVER_EXIT)


func _trigger_animations(trigger_type: AnimationReel.Trigger) -> void:
	AnimationReel.trigger_matching(self, animations, trigger_type)


func _get_item_property(data: Variant, key: String, default: Variant = null) -> Variant:
	if data == null:
		return default
	if data is Dictionary:
		return data.get(key, default)
	if data is Resource:
		var v = data.get(key)
		return v if v != null else default
	return default


func _exit_tree() -> void:
	FocusDrivenHover.cleanup(self)
	AnimationStateUtils.clear_unified_snapshot_for_target(self)

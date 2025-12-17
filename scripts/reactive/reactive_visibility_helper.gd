## Helper for State-driven visibility with animated transitions.
##
## This helper connects to a State resource and controls the visibility of a
## control with optional animated transitions using AnimationReel.
extends Node
class_name ReactiveVisibilityHelper

@export var visible_state: State
@export var show_reels: Array[AnimationReel] = []
@export var hide_reels: Array[AnimationReel] = []

var _target_control: Control = null
var _previous_visible: bool = true

func _ready() -> void:
	# Find the target control (typically the parent or a sibling)
	_target_control = _find_target_control()
	if not _target_control:
		push_warning("ReactiveVisibilityHelper '%s': Could not find target control to manage" % name)
		return

	# Connect to state changes
	if visible_state:
		visible_state.value_changed.connect(_on_visible_state_changed)
		# Initialize with current state
		_on_visible_state_changed(visible_state.value, null)
	else:
		push_warning("ReactiveVisibilityHelper '%s': visible_state is not set" % name)

## Finds the appropriate target control to manage.
func _find_target_control() -> Control:
	# Try parent first
	var parent = get_parent()
	if parent is Control:
		return parent as Control

	# Try to find a sibling control
	for sibling in get_parent().get_children():
		if sibling is Control and sibling != self:
			return sibling as Control

	return null

## Called when the visible_state changes.
func _on_visible_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if not _target_control:
		return

	var should_be_visible = bool(new_value)
	var changed = should_be_visible != _previous_visible

	if changed:
		if should_be_visible:
			# Becoming visible - apply show animations then set visible
			_apply_show_animations()
			_target_control.visible = true
		else:
			# Becoming hidden - apply hide animations then set invisible
			_apply_hide_animations()
			_target_control.visible = false

	_previous_visible = should_be_visible

## Applies show animation reels to the target control.
func _apply_show_animations() -> void:
	for reel in show_reels:
		if reel:
			reel.apply(_target_control)

## Applies hide animation reels to the target control.
func _apply_hide_animations() -> void:
	for reel in hide_reels:
		if reel:
			reel.apply(_target_control)

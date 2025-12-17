## Helper for applying AnimationReel instances when focus changes.
##
## This node listens to ReactiveUINavigator.focus_changed signals and applies
## animation reels to the old and new focused controls, enabling focus-based
## animations without modifying ReactiveUINavigator itself.
extends Node
class_name FocusAnimationHelper

@export var navigator: NodePath
@export var focus_in_reels: Array[AnimationReel] = []
@export var focus_out_reels: Array[AnimationReel] = []

var _navigator: ReactiveUINavigator = null

func _ready() -> void:
	if not navigator:
		push_warning("FocusAnimationHelper '%s': navigator NodePath is not set" % name)
		return

	var nav_node = get_node_or_null(navigator)
	if not nav_node:
		push_warning("FocusAnimationHelper '%s': navigator path '%s' does not exist" % [name, navigator])
		return

	if not nav_node is ReactiveUINavigator:
		push_warning("FocusAnimationHelper '%s': navigator must point to a ReactiveUINavigator node, got %s" % [name, nav_node.get_class()])
		return

	_navigator = nav_node as ReactiveUINavigator
	_navigator.focus_changed.connect(_on_focus_changed)

## Called when focus changes in the navigator.
func _on_focus_changed(old_focus: Control, new_focus: Control) -> void:
	# Apply focus out animations to the previously focused control
	if old_focus and not focus_out_reels.is_empty():
		for reel in focus_out_reels:
			if reel:
				reel.apply(old_focus)

	# Apply focus in animations to the newly focused control
	if new_focus and not focus_in_reels.is_empty():
		for reel in focus_in_reels:
			if reel:
				reel.apply(new_focus)

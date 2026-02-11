@tool
extends HBoxContainer
class_name ReactiveHBoxContainer

## A reactive horizontal box container that automatically configures focus neighbor wrapping.
##
## ReactiveHBoxContainer extends HBoxContainer to automatically set up focus_neighbor_*
## properties for its direct children, enabling wrapping navigation. This container can
## contain any Control nodes (buttons, other containers, etc.) and will configure
## horizontal navigation (left/right) with optional wrapping.
##
## When wrap_horizontal is enabled, navigating left from the first item wraps to the last,
## and navigating right from the last item wraps to the first.
##
## This container works hierarchically - nested containers handle their own wrapping
## independently, allowing complex navigation layouts.
##
## Example:
##   var hbox = ReactiveHBoxContainer.new()
##   hbox.wrap_horizontal = true
##   # Add buttons or other containers as children
##   # Navigation will automatically wrap

## Whether horizontal navigation wraps around (last item wraps to first).
##
## When true, pressing LEFT on the first item moves focus to the last item,
## and pressing RIGHT on the last item moves focus to the first item.
@export var wrap_horizontal: bool = false

## Path to the child control that should receive initial focus.
##
## If set, this control will receive focus when focus_on_ready is enabled.
## If not set or invalid, falls back to the first child in the navigation order.
@export var default_focus: NodePath = NodePath("")

## Whether to automatically grab focus on the default_focus control when the scene loads.
##
## When true, the container will automatically call grab_focus() on the default_focus
## control (or first child if default_focus is not set) during initialization.
@export var focus_on_ready: bool = false

## Initializes the reactive horizontal box container.
##
## In editor mode: Early return (no validation needed for simple containers).
## At runtime: Sets up focus neighbor wrapping for direct children.
func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	call_deferred("_setup_wrapping")
	call_deferred("_setup_initial_focus")

## Gets sibling targets for horizontal navigation.
func _get_sibling_targets(children: Array[Control], index: int, _get_first: bool) -> Dictionary:
	var result: Dictionary = {}
	if index > 0:
		result.previous = ReactiveBoxContainerBase.get_focusable_target(children[index - 1], false)
	elif wrap_horizontal:
		result.wrap_previous = ReactiveBoxContainerBase.get_focusable_target(children[children.size() - 1], false)
	if index < children.size() - 1:
		result.next = ReactiveBoxContainerBase.get_focusable_target(children[index + 1], true)
	elif wrap_horizontal:
		result.wrap_next = ReactiveBoxContainerBase.get_focusable_target(children[0], true)
	return result

## Applies neighbor properties to a direct child for horizontal navigation.
func _apply_neighbors_to_child(child: Control, targets: Dictionary) -> void:
	var left_target: Control = targets.get("previous") if targets.has("previous") else targets.get("wrap_previous")
	var right_target: Control = targets.get("next") if targets.has("next") else targets.get("wrap_next")
	ReactiveBoxContainerBase.set_focus_neighbor(child, left_target, "left")
	ReactiveBoxContainerBase.set_focus_neighbor(child, right_target, "right")

## Applies neighbor properties to inner first/last of enterable containers for horizontal navigation.
func _apply_neighbors_to_inner(first_in: Control, last_in: Control, targets: Dictionary) -> void:
	if first_in and targets.has("previous"):
		ReactiveBoxContainerBase.set_focus_neighbor(first_in, targets.previous, "left")
	if last_in and targets.has("next"):
		ReactiveBoxContainerBase.set_focus_neighbor(last_in, targets.next, "right")

## Configures focus neighbor properties for direct children with wrapping support.
##
## Collects direct children in scene order, then sets up focus_neighbor_left and
## focus_neighbor_right for each child to enable horizontal navigation with optional
## wrapping. Nested ReactiveVBoxContainer and ReactiveHBoxContainer automatically
## link to their first/last focusable controls.
func _setup_wrapping() -> void:
	ReactiveBoxContainerBase.setup_wrapping(
		self,
		_get_sibling_targets,
		_apply_neighbors_to_child,
		_apply_neighbors_to_inner
	)

## Sets up initial focus if focus_on_ready is enabled.
func _setup_initial_focus() -> void:
	ReactiveBoxContainerBase.setup_initial_focus(self, default_focus, focus_on_ready)

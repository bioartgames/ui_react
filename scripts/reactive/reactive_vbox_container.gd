@tool
extends VBoxContainer
class_name ReactiveVBoxContainer

## A reactive vertical box container that automatically configures focus neighbor wrapping.
##
## ReactiveVBoxContainer extends VBoxContainer to automatically set up focus_neighbor_*
## properties for its direct children, enabling wrapping navigation. This container can
## contain any Control nodes (buttons, other containers, etc.) and will configure
## vertical navigation (up/down) with optional wrapping.
##
## When wrap_vertical is enabled, navigating up from the first item wraps to the last,
## and navigating down from the last item wraps to the first.
##
## This container works hierarchically - nested containers handle their own wrapping
## independently, allowing complex navigation layouts.
##
## Example:
##   var vbox = ReactiveVBoxContainer.new()
##   vbox.wrap_vertical = true
##   # Add buttons or other containers as children
##   # Navigation will automatically wrap

## Whether vertical navigation wraps around (last item wraps to first).
##
## When true, pressing UP on the first item moves focus to the last item,
## and pressing DOWN on the last item moves focus to the first item.
@export var wrap_vertical: bool = false

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

## Initializes the reactive vertical box container.
##
## In editor mode: Early return (no validation needed for simple containers).
## At runtime: Sets up focus neighbor wrapping for direct children.
func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	call_deferred("_setup_wrapping")
	call_deferred("_setup_initial_focus")

## Gets sibling targets for vertical navigation.
func _get_sibling_targets(children: Array[Control], index: int, _get_first: bool) -> Dictionary:
	var result = {}
	if index > 0:
		result.previous = ReactiveBoxContainerBase.get_focusable_target(children[index - 1], false)
	elif wrap_vertical:
		result.wrap_previous = ReactiveBoxContainerBase.get_focusable_target(children[children.size() - 1], false)
	if index < children.size() - 1:
		result.next = ReactiveBoxContainerBase.get_focusable_target(children[index + 1], true)
	elif wrap_vertical:
		result.wrap_next = ReactiveBoxContainerBase.get_focusable_target(children[0], true)
	return result

## Applies neighbor properties to a direct child for vertical navigation.
func _apply_neighbors_to_child(child: Control, targets: Dictionary) -> void:
	var top_target = targets.get("previous") if targets.has("previous") else targets.get("wrap_previous")
	var bottom_target = targets.get("next") if targets.has("next") else targets.get("wrap_next")
	ReactiveBoxContainerBase.set_focus_neighbor(child, top_target, "top")
	ReactiveBoxContainerBase.set_focus_neighbor(child, bottom_target, "bottom")

## Applies neighbor properties to inner first/last of enterable containers for vertical navigation.
func _apply_neighbors_to_inner(first_in: Control, last_in: Control, targets: Dictionary) -> void:
	if first_in and targets.has("previous"):
		ReactiveBoxContainerBase.set_focus_neighbor(first_in, targets.previous, "top")
	if last_in and targets.has("next"):
		ReactiveBoxContainerBase.set_focus_neighbor(last_in, targets.next, "bottom")

## Configures focus neighbor properties for direct children with wrapping support.
##
## Collects direct children in scene order, then sets up focus_neighbor_top and
## focus_neighbor_bottom for each child to enable vertical navigation with optional
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

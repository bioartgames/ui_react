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

## Gets the appropriate focus target for a child control.
##
## If the child is a reactive container (ReactiveVBoxContainer or ReactiveHBoxContainer),
## returns the first or last focusable control within it. Otherwise returns the child itself.
##
## [param child]: The child control to get focus target for.
## [param get_first]: If true, returns first focusable; if false, returns last focusable.
## [return]: The focusable control to link to, or null if none found.
func _get_focusable_target(child: Control, get_first: bool) -> Control:
	# Check if child is a reactive container
	if child is ReactiveVBoxContainer or child is ReactiveHBoxContainer:
		# Find all focusable controls within the nested container
		var focusable_controls = NavigationUtils.find_focusable_controls(child, true)
		if focusable_controls.is_empty():
			# No focusable controls found, return the container itself
			return child
		
		# Return first or last focusable control
		if get_first:
			return focusable_controls[0]
		else:
			return focusable_controls[focusable_controls.size() - 1]
	
	# Not a reactive container, return the child itself
	return child

## Configures focus neighbor properties for direct children with wrapping support.
##
## Collects direct children in scene order, then sets up focus_neighbor_left and
## focus_neighbor_right for each child to enable horizontal navigation with optional
## wrapping. Nested ReactiveVBoxContainer and ReactiveHBoxContainer automatically
## link to their first/last focusable controls.
func _setup_wrapping() -> void:
	var children: Array[Control] = []
	
	# Use direct children in scene order
	for child in get_children():
		if child is Control:
			children.append(child as Control)
	
	# Need at least 2 children for wrapping to make sense
	if children.size() < 2:
		return
	
	# Set up focus neighbors for horizontal navigation
	for i in range(children.size()):
		var current = children[i]
		
		# Resolve left and right targets (previous sibling's last, next sibling's first, or wrap)
		var left_target: Control = null
		var right_target: Control = null
		if i > 0:
			left_target = _get_focusable_target(children[i - 1], false)
		elif wrap_horizontal:
			left_target = _get_focusable_target(children[children.size() - 1], false)
		if i < children.size() - 1:
			right_target = _get_focusable_target(children[i + 1], true)
		elif wrap_horizontal:
			right_target = _get_focusable_target(children[0], true)

		# Set neighbors on the direct child
		if left_target:
			current.focus_neighbor_left = current.get_path_to(left_target)
		else:
			current.focus_neighbor_left = NodePath("")
		if right_target:
			current.focus_neighbor_right = current.get_path_to(right_target)
		else:
			current.focus_neighbor_right = NodePath("")

		# For enterable containers, also set inner first/last so focus can wrap out to HBox siblings
		if current is ReactiveVBoxContainer or current is ReactiveHBoxContainer:
			var first_in := _get_focusable_target(current, true)
			var last_in := _get_focusable_target(current, false)
			if first_in and first_in != current and left_target:
				first_in.focus_neighbor_left = first_in.get_path_to(left_target)
			if last_in and last_in != current and right_target:
				last_in.focus_neighbor_right = last_in.get_path_to(right_target)
	
	# Set initial focus if focus_on_ready is enabled
	if focus_on_ready:
		var initial_focus: Control = null
		if default_focus and not default_focus.is_empty():
			initial_focus = get_node_or_null(default_focus) as Control
		if not initial_focus and not children.is_empty():
			# Fallback to first child
			initial_focus = children[0]
		
		if initial_focus and initial_focus.focus_mode != Control.FOCUS_NONE:
			initial_focus.grab_focus()

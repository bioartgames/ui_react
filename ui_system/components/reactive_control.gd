## Base reactive component class.
## Provides unified binding system (one-way and two-way) via ReactiveBindingManager.
extends Control
class_name ReactiveControl

## Array of bindings for this component.
@export var bindings: Array[ReactiveBinding] = []

## Array of action bindings for this component.
@export var action_bindings: Array[ReactiveActionBinding] = []

## Array of animations for this component (configurable in editor).
@export var animations: Array[ReactiveAnimation] = []

## Optional navigation group name to assign this component to.
@export var navigation_group: String = ""

## Local focus order (used if not in a navigation group).
@export var local_focus_order: Array[NodePath] = []

## Binding manager (RefCounted) that handles all binding logic.
var _binding_manager: ReactiveBindingManager = null

## Animation manager (RefCounted) that handles all animation logic.
var _animation_manager: ReactiveAnimationManager = null

## Focus manager (RefCounted) for local focus management (if not in a group).
var _focus_manager: ReactiveFocusManager = null

func _ready() -> void:
	# Create and setup binding manager
	_binding_manager = ReactiveBindingManager.new()
	_binding_manager.setup(self, bindings)
	
	# Create and setup animation manager
	_animation_manager = ReactiveAnimationManager.new()
	_animation_manager.setup(self)
	
	# Setup navigation
	_setup_navigation()

	# Setup accessibility
	_setup_accessibility()

## Sets up navigation system.
func _setup_navigation() -> void:
	# Make control focusable
	focus_mode = Control.FOCUS_ALL
	
	# If assigned to a navigation group, register with ReactiveNavigation
	if not navigation_group.is_empty():
		var nav = _get_navigation_singleton()
		if nav != null:
			nav.register_control(self, navigation_group)
	else:
		# Use local focus manager
		_focus_manager = ReactiveFocusManager.new()
		_focus_manager.setup(self)
		if not local_focus_order.is_empty():
			_focus_manager.set_focus_order(local_focus_order, true)

## Gets the ReactiveNavigation singleton if available.
func _get_navigation_singleton() -> ReactiveNavigation:
	# Try to get from autoload
	if Engine.has_singleton("ReactiveNavigation"):
		return Engine.get_singleton("ReactiveNavigation") as ReactiveNavigation
	
	# Try to find in scene tree
	var root = get_tree().root
	if root != null:
		return root.find_child("ReactiveNavigation", true, false) as ReactiveNavigation
	
	return null

func _exit_tree() -> void:
	# Unregister from navigation group if assigned
	if not navigation_group.is_empty():
		var nav = _get_navigation_singleton()
		if nav != null:
			nav.unregister_control(self, navigation_group)
	
	# Cleanup binding manager
	if _binding_manager:
		_binding_manager.cleanup()
		_binding_manager = null
	
	# Cleanup animation manager
	if _animation_manager:
		_animation_manager.cleanup()
		_animation_manager = null
	
	# Cleanup focus manager
	if _focus_manager:
		_focus_manager.cleanup()
		_focus_manager = null

## Executes all action bindings.
## Called by components that trigger actions (e.g., ReactiveButton on pressed).
func execute_actions() -> void:
	for action_binding in action_bindings:
		if action_binding == null:
			continue
		action_binding.execute()

## Plays an animation forward on this component.
## Returns true if successful, false otherwise.
func play_animation(animation: ReactiveAnimation, forward: bool = true) -> bool:
	if _animation_manager:
		return _animation_manager.play_animation(animation, forward)
	return false

## Plays an animation group on this component.
## Returns true if successful, false otherwise.
func play_animation_group(group: AnimationGroup, forward: bool = true) -> bool:
	if _animation_manager:
		return _animation_manager.play_animation_group(group, forward)
	return false

## Stops a specific animation.
func stop_animation(animation: ReactiveAnimation) -> void:
	if _animation_manager:
		_animation_manager.stop_animation(animation)

## Stops all active animations.
func stop_all_animations() -> void:
	if _animation_manager:
		_animation_manager.stop_all_animations()

## Moves focus in the specified direction.
## Delegates to ReactiveFocusManager (local or navigation group).
## Returns true if focus was moved, false otherwise.
func move_focus(direction: String) -> bool:
	# If in a navigation group, delegate to ReactiveNavigation
	if not navigation_group.is_empty():
		var nav = _get_navigation_singleton()
		if nav != null:
			return nav.move_focus(direction)
	
	# Otherwise, use local focus manager
	if _focus_manager:
		return _focus_manager.move_focus(direction)
	
	return false

## Sets the local focus order (for components not in a navigation group).
func set_local_focus_order(order: Array[NodePath], wrap_around: bool = true) -> void:
	local_focus_order = order.duplicate()
	if _focus_manager:
		_focus_manager.set_focus_order(local_focus_order, wrap_around)

## Sets up accessibility features.
## Uses native Control properties (accessibility_description and accessibility_label exist in Godot 4.5).
func _setup_accessibility() -> void:
	# Native Control properties are already available in Godot 4.5
	# They can be set directly in the editor or via code
	# No additional setup needed - Control class handles them automatically
	pass


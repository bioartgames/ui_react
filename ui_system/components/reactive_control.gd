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

## Binding manager (RefCounted) that handles all binding logic.
var _binding_manager: ReactiveBindingManager = null

## Animation manager (RefCounted) that handles all animation logic.
var _animation_manager: ReactiveAnimationManager = null

func _ready() -> void:
	# Create and setup binding manager
	_binding_manager = ReactiveBindingManager.new()
	_binding_manager.setup(self, bindings)
	
	# Create and setup animation manager
	_animation_manager = ReactiveAnimationManager.new()
	_animation_manager.setup(self)

func _exit_tree() -> void:
	# Cleanup binding manager
	if _binding_manager:
		_binding_manager.cleanup()
		_binding_manager = null
	
	# Cleanup animation manager
	if _animation_manager:
		_animation_manager.cleanup()
		_animation_manager = null

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


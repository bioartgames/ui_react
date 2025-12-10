## Animation orchestration manager (RefCounted).
## Handles all animation logic, Tween lifecycle, active animations, and cleanup.
class_name ReactiveAnimationManager
extends RefCounted

## The owner Control that this manager is attached to.
var _owner: Control = null

## Active Tweens created by animations.
var _active_tweens: Array[Tween] = []

## Currently playing animations (for stopping).
var _active_animations: Dictionary = {}  # Dictionary[ReactiveAnimation, Tween]

## Loop tracking for animations (Dictionary[ReactiveAnimation, int]).
var _animation_loops: Dictionary = {}  # Dictionary[ReactiveAnimation, int]

## Sets up the animation manager with the owner Control.
func setup(owner: Control) -> void:
	_owner = owner

## Plays an animation forward on the owner Control.
## Returns true if successful, false otherwise.
func play_animation(animation: ReactiveAnimation, forward: bool = true, reset_loop: bool = true) -> bool:
	if _owner == null:
		return false
	if animation == null:
		return false
	
	# Reset loop count if requested (first play or explicit reset)
	if reset_loop:
		_animation_loops[animation] = 0
	
	# Stop animation if already playing (unless we're looping)
	if _active_animations.has(animation) and reset_loop:
		stop_animation(animation)
	
	# Play animation
	var tween: Tween = null
	if forward:
		tween = animation.play_forward(_owner, self)
	else:
		tween = animation.play_backward(_owner, self)
	
	if tween == null:
		return false
	
	# Track tween and animation
	_active_tweens.append(tween)
	_active_animations[animation] = tween
	
	# Connect tween finished signal to cleanup
	if tween.finished.is_connected(_on_tween_finished):
		tween.finished.disconnect(_on_tween_finished)
	tween.finished.connect(_on_tween_finished.bind(animation, tween))
	
	return true

## Gets the current loop count for an animation.
func get_loop_count(animation: ReactiveAnimation) -> int:
	if _animation_loops.has(animation):
		return _animation_loops[animation]
	return 0

## Increments the loop count for an animation.
func increment_loop_count(animation: ReactiveAnimation) -> void:
	if not _animation_loops.has(animation):
		_animation_loops[animation] = 0
	_animation_loops[animation] += 1

## Checks if an animation should continue looping.
func should_continue_looping(animation: ReactiveAnimation) -> bool:
	if not animation.loop:
		return false
	
	var current_loop = get_loop_count(animation)
	if animation.loop_count == -1:
		return true  # Infinite loop
	return current_loop < animation.loop_count

## Plays an animation group forward or backward.
## Returns true if successful, false otherwise.
func play_animation_group(group: AnimationGroup, forward: bool = true) -> bool:
	if _owner == null:
		return false
	if group == null:
		return false
	
	var tweens: Array[Tween] = []
	if forward:
		tweens = group.play_forward(_owner, self)
	else:
		tweens = group.play_backward(_owner, self)
	
	if tweens.is_empty():
		return false
	
	# Track all tweens
	for tween in tweens:
		if tween != null:
			_active_tweens.append(tween)
			# Connect cleanup
			if tween.finished.is_connected(_on_tween_finished):
				tween.finished.disconnect(_on_tween_finished)
			tween.finished.connect(_on_tween_finished.bind(null, tween))
	
	return true

## Stops a specific animation.
func stop_animation(animation: ReactiveAnimation) -> void:
	if animation == null:
		return
	
	if _active_animations.has(animation):
		var tween = _active_animations[animation]
		if tween != null and is_instance_valid(tween):
			tween.kill()
		_active_animations.erase(animation)
		_active_tweens.erase(tween)
	
	# Clear loop tracking
	_animation_loops.erase(animation)

## Stops all active animations.
func stop_all_animations() -> void:
	for animation in _active_animations.keys():
		stop_animation(animation)

## Called when a tween finishes (for cleanup).
func _on_tween_finished(animation: ReactiveAnimation, tween: Tween) -> void:
	if tween != null:
		_active_tweens.erase(tween)
	if animation != null:
		_active_animations.erase(animation)

## Cleans up all animations and tweens.
func cleanup() -> void:
	# Stop all animations
	stop_all_animations()
	
	# Cleanup all tweens via ReactiveLifecycleManager
	ReactiveLifecycleManager.cleanup_tweens(_active_tweens)
	
	# Clear references
	_owner = null
	_active_animations.clear()
	_animation_loops.clear()


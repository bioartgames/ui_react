## Container for multiple animations that can play in sequence or parallel.
## Used to group related animations together.
@icon("res://icon.svg")
class_name AnimationGroup
extends Resource

## Execution mode enum: sequence or parallel.
enum Mode {
	SEQUENCE,  ## Play animations one after another
	PARALLEL   ## Play animations simultaneously
}

## Animations in this group.
@export var animations: Array[ReactiveAnimation] = []

## Execution mode for this group.
@export var mode: Mode = Mode.SEQUENCE

## Plays all animations in the group on the target Control.
## Returns the created Tweens (managed by ReactiveAnimationManager).
func play_forward(target: Control, manager: ReactiveAnimationManager) -> Array[Tween]:
	if target == null or manager == null:
		return []
	
	var tweens: Array[Tween] = []
	
	if mode == Mode.PARALLEL:
		# Play all animations simultaneously
		for anim in animations:
			if anim != null:
				var tween = anim.play_forward(target, manager)
				if tween != null:
					tweens.append(tween)
	else:
		# Play animations in sequence
		# Calculate total duration and chain via callbacks
		if animations.is_empty():
			return []
		
		# Play first animation
		var first_anim = animations[0]
		if first_anim != null:
			var first_tween = first_anim.play_forward(target, manager)
			if first_tween != null:
				tweens.append(first_tween)
				
				# Chain remaining animations via callback
				var remaining_anims = animations.slice(1)
				if not remaining_anims.is_empty():
					first_tween.finished.connect(func():
						_play_sequence_forward(remaining_anims, target, manager, tweens)
					)
	
	return tweens

## Helper to play remaining animations in sequence (forward).
func _play_sequence_forward(anims: Array, target: Control, manager: ReactiveAnimationManager, tweens: Array) -> void:
	if anims.is_empty():
		return
	
	var anim = anims[0] as ReactiveAnimation
	if anim == null:
		return
	
	var tween = anim.play_forward(target, manager)
	if tween != null:
		tweens.append(tween)
		
		# Calculate duration
		var duration = 0.0
		for step in anim.steps:
			if step != null:
				duration += step.delay + step.duration
		
		# Chain next animation
		var remaining = anims.slice(1)
		if not remaining.is_empty():
			tween.finished.connect(func():
				_play_sequence_forward(remaining, target, manager, tweens)
			)

## Plays all animations in the group backward on the target Control.
## Returns the created Tweens (managed by ReactiveAnimationManager).
func play_backward(target: Control, manager: ReactiveAnimationManager) -> Array[Tween]:
	if target == null or manager == null:
		return []
	
	var tweens: Array[Tween] = []
	
	if mode == Mode.PARALLEL:
		# Play all animations simultaneously (backward)
		for anim in animations:
			if anim != null:
				var tween = anim.play_backward(target, manager)
				if tween != null:
					tweens.append(tween)
	else:
		# Play animations in reverse sequence
		# Start with last animation and work backwards
		if animations.is_empty():
			return []
		
		var reversed_anims = animations.duplicate()
		reversed_anims.reverse()
		
		# Play first (which is last) animation
		var first_anim = reversed_anims[0]
		if first_anim != null:
			var first_tween = first_anim.play_backward(target, manager)
			if first_tween != null:
				tweens.append(first_tween)
				
				# Chain remaining animations via callback
				var remaining_anims = reversed_anims.slice(1)
				if not remaining_anims.is_empty():
					first_tween.finished.connect(func():
						_play_sequence_backward(remaining_anims, target, manager, tweens)
					)
	
	return tweens

## Helper to play remaining animations in sequence (backward).
func _play_sequence_backward(anims: Array, target: Control, manager: ReactiveAnimationManager, tweens: Array) -> void:
	if anims.is_empty():
		return
	
	var anim = anims[0] as ReactiveAnimation
	if anim == null:
		return
	
	var tween = anim.play_backward(target, manager)
	if tween != null:
		tweens.append(tween)
		
		# Calculate duration
		var duration = 0.0
		for step in anim.steps:
			if step != null:
				duration += step.delay + step.duration
		
		# Chain next animation
		var remaining = anims.slice(1)
		if not remaining.is_empty():
			tween.finished.connect(func():
				_play_sequence_backward(remaining, target, manager, tweens)
			)

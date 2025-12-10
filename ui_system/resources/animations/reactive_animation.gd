## Animation resource that defines a sequence of animation steps.
## Supports forward/backward playback, loops, and chaining.
@icon("res://icon.svg")
class_name ReactiveAnimation
extends Resource

## Steps to execute in this animation.
@export var steps: Array[AnimationStep] = []

## Whether to loop the animation.
@export var loop: bool = false

## Number of loops (-1 = infinite).
@export var loop_count: int = -1

## Animations to chain/play when this completes.
@export var on_complete: Array[ReactiveAnimation] = []

## Events to trigger at animation start.
@export var start_events: Array[AnimationEvent] = []

## Events to trigger at animation complete.
@export var complete_events: Array[AnimationEvent] = []

## Plays the animation forward on the target Control.
## Returns the created Tween (managed by ReactiveAnimationManager).
func play_forward(target: Control, manager: ReactiveAnimationManager) -> Tween:
	if target == null or manager == null:
		return null
	
	# Create Tween
	var tween = target.create_tween()
	if tween == null:
		return null
	
	# Trigger start events
	_trigger_events(start_events, target, "animation_start")
	
	# Play steps in sequence
	var step_start_time = 0.0
	
	for step in steps:
		if step == null:
			continue
		
		# Get start and end values
		var start_val = step.get_start_value(target)
		var end_val = step.get_end_value(target)
		
		# Trigger step start events
		var step_context = AnimationEventContext.create(target, self, "step_start", step)
		for event in step.events:
			if event != null:
				step_context.event_type = "step_start"
				event.trigger(step_context)
		
		# Calculate actual start time with delay
		var actual_start_time = step_start_time + step.delay
		
		# Set initial value if needed
		if actual_start_time == 0.0:
			step.set_property_value(target, step.target_property, start_val)
		
		# Create tween for this step
		var step_tween = tween.tween_property(
			target,
			step.target_property,
			end_val,
			step.duration
		)
		step_tween.set_delay(actual_start_time)
		step_tween.set_ease(step.easing)
		
		# Trigger step complete events when step finishes
		var step_complete_time = actual_start_time + step.duration
		tween.tween_callback(func():
			var complete_context = AnimationEventContext.create(target, self, "step_complete", step)
			for event in step.events:
				if event != null:
					complete_context.event_type = "step_complete"
					event.trigger(complete_context)
		).set_delay(step_complete_time)
		
		# Update step start time for next step
		step_start_time = step_complete_time
	
	# After all steps complete, handle looping and chaining
	var total_duration = step_start_time
	tween.tween_callback(func():
		# Increment loop count
		manager.increment_loop_count(self)
		
		# Check if we should loop
		if manager.should_continue_looping(self):
			# Loop again by creating a new animation (don't reset loop count)
			manager.play_animation(self, true, false)
			return
		
		# Animation complete
		_trigger_events(complete_events, target, "animation_complete")
		
		# Chain animations
		for chained_anim in on_complete:
			if chained_anim != null:
				manager.play_animation(chained_anim)
	).set_delay(total_duration)
	
	return tween

## Plays the animation backward on the target Control.
## Returns the created Tween (managed by ReactiveAnimationManager).
func play_backward(target: Control, manager: ReactiveAnimationManager) -> Tween:
	if target == null or manager == null:
		return null
	
	# Create Tween
	var tween = target.create_tween()
	if tween == null:
		return null
	
	# Trigger start events
	_trigger_events(start_events, target, "animation_start")
	
	# Calculate total duration for reverse timing
	var total_duration = 0.0
	for step in steps:
		if step != null:
			total_duration += step.delay + step.duration
	
	# Play steps in reverse order
	var step_end_time = total_duration
	
	for i in range(steps.size() - 1, -1, -1):
		var step = steps[i]
		if step == null:
			continue
		
		# Get start and end values (swapped for backward)
		var forward_start_val = step.get_start_value(target)
		var forward_end_val = step.get_end_value(target)
		
		# For backward, we animate from end to start
		var start_val = forward_end_val
		var end_val = forward_start_val
		
		# Trigger step start events
		var step_context = AnimationEventContext.create(target, self, "step_start", step)
		for event in step.events:
			if event != null:
				step_context.event_type = "step_start"
				event.trigger(step_context)
		
		# Calculate timing (backward from end)
		var step_duration = step.duration
		var step_delay = step.delay
		var step_start_time = step_end_time - step_duration - step_delay
		
		# Set initial value at start time
		if step_start_time == 0.0:
			step.set_property_value(target, step.target_property, start_val)
		else:
			# Set value at the start time via callback
			tween.tween_callback(func():
				step.set_property_value(target, step.target_property, start_val)
			).set_delay(step_start_time)
		
		# Create tween for this step (backward)
		var step_tween = tween.tween_property(
			target,
			step.target_property,
			end_val,
			step_duration
		)
		step_tween.set_delay(step_start_time)
		step_tween.set_ease(step.easing)
		
		# Trigger step complete events when step finishes
		var step_complete_time = step_start_time + step_duration
		tween.tween_callback(func():
			var complete_context = AnimationEventContext.create(target, self, "step_complete", step)
			for event in step.events:
				if event != null:
					complete_context.event_type = "step_complete"
					event.trigger(complete_context)
		).set_delay(step_complete_time)
		
		# Update step end time for next step (backward)
		step_end_time = step_start_time
	
	# After all steps complete, handle looping and chaining
	tween.tween_callback(func():
		# Increment loop count
		manager.increment_loop_count(self)
		
		# Check if we should loop
		if manager.should_continue_looping(self):
			# Loop again by creating a new animation (don't reset loop count)
			manager.play_animation(self, false, false)
			return
		
		# Animation complete
		_trigger_events(complete_events, target, "animation_complete")
		
		# Chain animations
		for chained_anim in on_complete:
			if chained_anim != null:
				manager.play_animation(chained_anim)
	).set_delay(total_duration)
	
	return tween

## Triggers a list of events with the given context.
func _trigger_events(events: Array[AnimationEvent], target: Control, event_type: String) -> void:
	for event in events:
		if event == null:
			continue
		var context = AnimationEventContext.create(target, self, event_type)
		event.trigger(context)


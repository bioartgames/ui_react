## Action configuration for triggering animations on controls.
##
## Users create this resource and assign it to ControlTargetConfig.action
## when they want to trigger animations on controls from buttons or other triggers.
##
## Example:
## [codeblock]
## var config = AnimationActionConfig.new()
## config.action = AnimationActionConfig.AnimationAction.EXPAND
## config.duration = 0.3
## config.targets = [NodePath("../AnimationTarget")]
## [/codeblock]
class_name AnimationActionConfig
extends ActionConfig

## Animation action types.
## Note: Reverse versions (SHRINK, FADE_OUT, etc.) have been removed.
## Use the reverse property instead to invert animations.
enum AnimationAction {
	EXPAND, EXPAND_X, EXPAND_Y,
	FADE_IN,
	SLIDE_FROM_LEFT, SLIDE_FROM_RIGHT, SLIDE_FROM_TOP, SLIDE_FROM_BOTTOM,
	FROM_LEFT_TO_CENTER,
	FROM_RIGHT_TO_CENTER,
	FROM_TOP_TO_CENTER,
	FROM_BOTTOM_TO_CENTER,
	BOUNCE_IN,
	ELASTIC_IN,
	ROTATE_IN,
	POP, PULSE, SHAKE,
	BREATHING, WOBBLE, FLOAT, GLOW_PULSE,
	COLOR_FLASH,
	RESET
}

## Animation action to perform.
@export var action: AnimationAction = AnimationAction.EXPAND

## Animation duration in seconds.
@export_range(0.001, 60.0) var duration: float = 0.3

## Number of repeats after the initial play (0 = play once, 1+ = play N+1 times total, -1 = infinite loop).
## For continuous animations like breathing/wobble, set to -1 for infinite.
@export_range(-1, 999) var repeat_count: int = 0


## If true, reverses/inverts the animation (e.g., EXPAND becomes SHRINK, FADE_IN becomes FADE_OUT).
## This allows you to use one animation resource for both directions, cutting resource counts in half.
## When reverse is enabled, the animation executes its opposite action using the same duration and parameters.
@export var reverse: bool = false

@export_group("Multi-Targeting")
## Array of paths to controls to animate.
## Drag and drop nodes here in the Inspector (NodePath supports drag-and-drop), or set manually.
## - Empty array: No targets (animation won't run)
## - Single element: Animates one target
## - Multiple elements: Animates multiple targets (supports stagger effect)
## Example: [NodePath("../Target1"), NodePath("../Target2")]
@export var targets: Array[NodePath] = []

## Per-target animation configs (optional).
## If empty or size=1, uses this config's action for all targets.
## If size matches targets, each target gets its own custom animation.
## Works with or without stagger - allows different animations per target.
## Example: [expand_config, fade_config, color_flash_config] for 3 targets
@export var per_target_configs: Array[AnimationActionConfig] = []

@export_group("Stagger")
## Delay between items for stagger effect (default: 0.0 = no stagger).
## Set to > 0 to enable stagger timing between targets.
## Works with any animation type when multiple targets are specified.
@export var stagger_delay: float = 0.0

## State source for toggle behavior (optional).
## When provided and auto_toggle_state is true, checks this bool to determine reveal/hide:
## - If false: executes with reverse=false (reveal)
## - If true: executes with reverse=true (hide)
## Drag a State resource here for toggle behavior.
@export var toggle_state: State = null

## If true, automatically toggles toggle_state bool after animation.
## If false, you must manually manage the bool state elsewhere.
@export var auto_toggle_state: bool = true

@export_group("Color Flash")
## Flash color for COLOR_FLASH action (default: Color.YELLOW).
@export var flash_color: Color = Color.YELLOW

## Flash intensity multiplier for COLOR_FLASH action (default: 1.5).
@export var flash_intensity: float = 1.5

@export_group("Pop")
## Overshoot amount for POP animation (default: 1.2, meaning 20% overshoot).
@export var pop_overshoot: float = 1.2

@export_group("Pulse")
## Pulse scale amount for PULSE animation (default: 1.1, meaning 10% scale increase).
@export var pulse_amount: float = 1.1

## Number of pulses for PULSE animation (default: 2).
@export var pulse_count: int = 2

@export_group("Shake")
## Shake intensity in pixels for SHAKE animation (default: 10.0).
@export var shake_intensity: float = 10.0

## Number of shakes for SHAKE animation (default: 5).
@export var shake_count: int = 5

@export_group("Rotate")
## Starting angle in degrees for ROTATE_IN animation (default: -360.0).
@export var rotate_start_angle: float = -360.0

## Applies this animation config to a single control target.
## This is the single source of truth for applying animations.
## [param owner]: The node that owns the animation (for creating tweens).
## [param target]: The control to animate.
## [return]: Signal that emits when animation completes (or empty Signal if not applicable).
func apply_to_control(owner: Node, target: Control) -> Signal:
	if not target:
		return Signal()
	
	match action:
		AnimationAction.EXPAND:
			if reverse:
				return UIAnimationUtils.animate_shrink(owner, target, duration, Vector2(-1, -1), true, true, true, repeat_count)
			else:
				return UIAnimationUtils.animate_expand(owner, target, duration, Vector2(-1, -1), true, false, false, repeat_count)
		AnimationAction.EXPAND_X:
			if reverse:
				return UIAnimationUtils.animate_shrink_x(owner, target, duration, Vector2(-1, -1), true, true, true, repeat_count)
			else:
				return UIAnimationUtils.animate_expand_x(owner, target, duration, Vector2(-1, -1), true, repeat_count)
		AnimationAction.EXPAND_Y:
			if reverse:
				return UIAnimationUtils.animate_shrink_y(owner, target, duration, Vector2(-1, -1), true, true, true, repeat_count)
			else:
				return UIAnimationUtils.animate_expand_y(owner, target, duration, Vector2(-1, -1), true, repeat_count)
		AnimationAction.FADE_IN:
			if reverse:
				return UIAnimationUtils.animate_fade_out(owner, target, duration, true, true, repeat_count)
			else:
				return UIAnimationUtils.animate_fade_in(owner, target, duration, true, repeat_count)
		AnimationAction.SLIDE_FROM_LEFT:
			if reverse:
				return UIAnimationUtils.animate_slide_to_left(owner, target, 8.0, duration, true)
			else:
				return UIAnimationUtils.animate_slide_from_left(owner, target, 8.0, duration, true)
		AnimationAction.SLIDE_FROM_RIGHT:
			if reverse:
				return UIAnimationUtils.animate_slide_to_right(owner, target, 8.0, duration, true)
			else:
				return UIAnimationUtils.animate_slide_from_right(owner, target, 8.0, duration, true)
		AnimationAction.SLIDE_FROM_TOP:
			if reverse:
				return UIAnimationUtils.animate_slide_to_top(owner, target, duration, true)
			else:
				return UIAnimationUtils.animate_slide_from_top(owner, target, 8.0, duration, true)
		AnimationAction.SLIDE_FROM_BOTTOM:
			if reverse:
				return UIAnimationUtils.animate_slide_to_bottom(owner, target, duration, true)
			else:
				return UIAnimationUtils.animate_slide_from_bottom(owner, target, 8.0, duration, true)
		AnimationAction.FROM_LEFT_TO_CENTER:
			if reverse:
				return UIAnimationUtils.animate_from_center_to_left(owner, target, duration, true)
			else:
				return UIAnimationUtils.animate_from_left_to_center(owner, target, duration, true)
		AnimationAction.FROM_RIGHT_TO_CENTER:
			if reverse:
				return UIAnimationUtils.animate_from_center_to_right(owner, target, duration, true)
			else:
				return UIAnimationUtils.animate_from_right_to_center(owner, target, duration, true)
		AnimationAction.FROM_TOP_TO_CENTER:
			if reverse:
				return UIAnimationUtils.animate_from_center_to_top(owner, target, duration, true)
			else:
				return UIAnimationUtils.animate_from_top_to_center(owner, target, duration, true)
		AnimationAction.FROM_BOTTOM_TO_CENTER:
			if reverse:
				return UIAnimationUtils.animate_from_center_to_bottom(owner, target, duration, true)
			else:
				return UIAnimationUtils.animate_from_bottom_to_center(owner, target, duration, true)
		AnimationAction.BOUNCE_IN:
			if reverse:
				return UIAnimationUtils.animate_bounce_out(owner, target, duration, Vector2(-1, -1), true, true, true, repeat_count)
			else:
				return UIAnimationUtils.animate_bounce_in(owner, target, duration, Vector2(-1, -1), true)
		AnimationAction.ELASTIC_IN:
			if reverse:
				return UIAnimationUtils.animate_elastic_out(owner, target, duration, Vector2(-1, -1), true, true, true, repeat_count)
			else:
				return UIAnimationUtils.animate_elastic_in(owner, target, duration, Vector2(-1, -1), true)
		AnimationAction.ROTATE_IN:
			if reverse:
				return UIAnimationUtils.animate_rotate_out(owner, target, duration, 360.0, true, true, true)
			else:
				return UIAnimationUtils.animate_rotate_in(owner, target, duration, rotate_start_angle, true, repeat_count)
		AnimationAction.POP:
			return UIAnimationUtils.animate_pop(owner, target, duration, pop_overshoot, Vector2(-1, -1), true, repeat_count)
		AnimationAction.PULSE:
			return UIAnimationUtils.animate_pulse(owner, target, duration, pulse_amount, pulse_count, Vector2(-1, -1), true, repeat_count)
		AnimationAction.SHAKE:
			return UIAnimationUtils.animate_shake(owner, target, duration, shake_intensity, shake_count, true, repeat_count)
		AnimationAction.BREATHING:
			return UIAnimationUtils.animate_breathing(owner, target, duration, repeat_count)
		AnimationAction.WOBBLE:
			return UIAnimationUtils.animate_wobble(owner, target, duration, repeat_count)
		AnimationAction.FLOAT:
			return UIAnimationUtils.animate_float(owner, target, duration, repeat_count)
		AnimationAction.GLOW_PULSE:
			return UIAnimationUtils.animate_glow_pulse(owner, target, duration, repeat_count)
		AnimationAction.COLOR_FLASH:
			return UIAnimationUtils.animate_color_flash(owner, target, flash_color, duration, flash_intensity, true)
		AnimationAction.RESET:
			# Reset requires storing initial state - for now, just reset to normal
			UIAnimationUtils.reset_control_to_normal(target)
			return Signal()
		_:
			push_warning("AnimationActionConfig: Unsupported animation action %d" % action)
			return Signal()

## Applies this action to the given target control.
## [param owner]: The node that owns the target config (unused, we use targets instead).
## [param target]: The control component (unused, we use targets instead).
## [param is_on]: Optional boolean state (unused for animations).
## Returns true if the action was applied successfully, false otherwise.
func apply(owner: Node, _target: Control, _is_on: bool = true) -> bool:
	# Resolve targets from targets array
	var resolved_targets: Array[Control] = []
	for path in targets:
		var node = owner.get_node_or_null(path)
		if node is Control:
			resolved_targets.append(node as Control)
	
	if resolved_targets.size() == 0:
		push_warning("AnimationActionConfig: No valid targets found. Check targets array.")
		return false
	
	# Determine if we should reveal or hide based on toggle_state or reverse flag
	var should_reveal: bool = not reverse
	if toggle_state != null and toggle_state is State:
		var state_bool = toggle_state as State
		should_reveal = not bool(state_bool.value)  # Reveal if currently hidden
	
	# Multi-target with stagger
	if resolved_targets.size() > 1 and stagger_delay > 0:
		# Prepare animation configs for each target
		var configs: Array[AnimationActionConfig] = []
		
		# Use per_target_configs if provided and matches target count, otherwise use this config for all
		if per_target_configs.size() == resolved_targets.size():
			# Create copies to avoid modifying original configs
			for orig_config in per_target_configs:
				var config = AnimationActionConfig.new()
				config.action = orig_config.action
				config.duration = orig_config.duration
				config.repeat_count = orig_config.repeat_count
				config.reverse = orig_config.reverse
				config.flash_color = orig_config.flash_color
				config.flash_intensity = orig_config.flash_intensity
				config.pop_overshoot = orig_config.pop_overshoot
				config.pulse_amount = orig_config.pulse_amount
				config.pulse_count = orig_config.pulse_count
				config.shake_intensity = orig_config.shake_intensity
				config.shake_count = orig_config.shake_count
				config.rotate_start_angle = orig_config.rotate_start_angle
				configs.append(config)
		else:
			# Use this config for all targets (or first per_target_config if only one provided)
			var base_config: AnimationActionConfig = self
			if per_target_configs.size() == 1:
				base_config = per_target_configs[0]
			
			for i in range(resolved_targets.size()):
				# Create a copy of the config for each target
				var config = AnimationActionConfig.new()
				config.action = base_config.action
				config.duration = base_config.duration
				config.repeat_count = base_config.repeat_count
				config.reverse = base_config.reverse
				config.flash_color = base_config.flash_color
				config.flash_intensity = base_config.flash_intensity
				config.pop_overshoot = base_config.pop_overshoot
				config.pulse_amount = base_config.pulse_amount
				config.pulse_count = base_config.pulse_count
				config.shake_intensity = base_config.shake_intensity
				config.shake_count = base_config.shake_count
				config.rotate_start_angle = base_config.rotate_start_angle
				configs.append(config)
		
		# Set reverse on all configs based on should_reveal
		for config in configs:
			config.reverse = not should_reveal
		
		# Execute stagger animation with per-target configs
		UIAnimationUtils.animate_stagger_multi(owner, resolved_targets, stagger_delay, configs)
		
		# Update toggle state if enabled
		if toggle_state != null and toggle_state is State and auto_toggle_state:
			var state_bool = toggle_state as State
			state_bool.set_value(should_reveal)
		
		return true
	
	# Single target or multi-target without stagger
	for i in range(resolved_targets.size()):
		var target_node = resolved_targets[i]
		if not target_node:
			continue
		
		# Get config for this target (create copy to avoid modifying original)
		var base_config: AnimationActionConfig = self
		if per_target_configs.size() > i:
			base_config = per_target_configs[i]
		
		# Create a copy with reverse set based on should_reveal
		var config = AnimationActionConfig.new()
		config.action = base_config.action
		config.duration = base_config.duration
		config.repeat_count = base_config.repeat_count
		config.reverse = not should_reveal
		config.flash_color = base_config.flash_color
		config.flash_intensity = base_config.flash_intensity
		config.pop_overshoot = base_config.pop_overshoot
		config.pulse_amount = base_config.pulse_amount
		config.pulse_count = base_config.pulse_count
		config.shake_intensity = base_config.shake_intensity
		config.shake_count = base_config.shake_count
		config.rotate_start_angle = base_config.rotate_start_angle
		
		# Apply animation (returns Signal, but we can't await in Resource methods)
		config.apply_to_control(owner, target_node)
	
	return true

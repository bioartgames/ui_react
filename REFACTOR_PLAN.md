# AnimationTarget Consolidation Refactor Plan

## Overview
Consolidate `AnimationActionConfig`, `AnimationParallelActionConfig`, `AnimationSequenceActionConfig`, and stagger functionality into a single unified `AnimationTarget` resource. This eliminates complexity, reduces verbosity, and provides a single resource type for all animation configurations.

## Core Principle
**Single Responsibility**: `AnimationTarget` becomes the one-stop resource for all animation configurations (single, multiple, stagger, parallel, sequential, and nested combinations).

## Files to Modify
1. `scripts/utilities/animation_target.gd` - Extend with new capabilities
2. `scripts/anim/animation_utilities.gd` - Update stagger functions to work with AnimationTarget
3. `scripts/anim/animation_action_config.gd` - **DELETE** (functionality moved to AnimationTarget)
4. `scripts/anim/animation_parallel_action_config.gd` - **DELETE** (functionality moved to AnimationTarget)
5. `scripts/anim/animation_sequence_action_config.gd` - **DELETE** (functionality moved to AnimationTarget)

## Files to Check (May Need Updates)
- Any files that reference `ControlTargetConfig` or use the old config classes
- Documentation files mentioning the old config system

## Implementation Phases

### Phase 1: Extend AnimationTarget with New Properties
**Goal**: Add properties for multiple targets, stagger, parallel, and sequence support

#### Step 1.1: Add Execution Mode Enum
**Location**: After `enum Easing` (around line 50)
```gdscript
## Execution mode for this animation target.
enum ExecutionMode {
	SINGLE,      # Single animation on single target (default, current behavior)
	MULTI,       # Same animation on multiple targets (with optional stagger)
	PARALLEL,    # Multiple different animations on same target simultaneously
	SEQUENCE     # Multiple animations on same target sequentially
}
```

#### Step 1.2: Add Multi-Target Support Properties
**Location**: After `@export var target: NodePath = NodePath()` (around line 58)
```gdscript
## ============================================
## MULTI-TARGET & STAGGER SUPPORT
## ============================================

## Execution mode for this animation target.
## SINGLE: One animation on one target (uses 'target' field)
## MULTI: Same animation on multiple targets (uses 'targets' array, supports stagger)
## PARALLEL: Multiple animations on same target simultaneously (uses 'parallel' array)
## SEQUENCE: Multiple animations on same target sequentially (uses 'sequence' array)
@export var execution_mode: ExecutionMode = ExecutionMode.SINGLE

## Multiple targets for MULTI mode (stagger support).
## If execution_mode is MULTI and this array has items, animates all targets with stagger timing.
## If empty and execution_mode is MULTI, falls back to single 'target' field.
## Drag and drop nodes here in the Inspector (NodePath supports drag-and-drop).
@export var targets: Array[NodePath] = []

## Delay between targets for stagger effect (only used when execution_mode is MULTI and targets.size() > 1).
## Set to > 0 to enable stagger timing between targets (default: 0.0 = no stagger).
@export_range(0.0, 10.0) var stagger_delay: float = 0.0
```

#### Step 1.3: Add Parallel Support Properties
**Location**: After stagger properties (around line 80)
```gdscript
## ============================================
## PARALLEL ANIMATION SUPPORT
## ============================================

## Child animations to execute in parallel (only used when execution_mode is PARALLEL).
## All animations in this array run simultaneously on the same target.
## Each child AnimationTarget can have its own animation type, duration, and settings.
## Supports nested structures (parallel groups can contain sequences, etc.).
@export var parallel: Array[AnimationTarget] = []
```

#### Step 1.4: Add Sequence Support Properties
**Location**: After parallel properties (around line 90)
```gdscript
## ============================================
## SEQUENTIAL ANIMATION SUPPORT
## ============================================

## Child animations to execute sequentially (only used when execution_mode is SEQUENCE).
## Animations in this array run one after another on the same target.
## Each child AnimationTarget can have its own animation type, duration, and settings.
## Supports nested structures (sequences can contain parallel groups, etc.).
@export var sequence: Array[AnimationTarget] = []

## Delays in seconds between sequence steps (parallel to sequence array).
## If delays array is shorter than sequence, missing delays default to 0.0.
## First delay is before the first animation, subsequent delays are between animations.
## Example: [0.0, 0.3, 0.2] means: wait 0.0s, play anim1, wait 0.3s, play anim2, wait 0.2s, play anim3
@export var sequence_delays: Array[float] = []
```

#### Step 1.5: Add Initial Setup Property
**Location**: After sequence properties (around line 100)
```gdscript
## ============================================
## INITIAL STATE SETUP
## ============================================

## Property values to set before animation starts (Dictionary of property: value pairs).
## Common properties: "scale", "modulate", "visible", "position", etc.
## Only used for PARALLEL and SEQUENCE modes to set up initial state.
## Example: {"scale": Vector2.ZERO, "modulate": Color(1, 1, 1, 0), "visible": true}
@export var initial_setup: Dictionary = {}
```

### Phase 2: Refactor apply() Method to Support All Modes
**Goal**: Update `apply()` method to handle SINGLE, MULTI, PARALLEL, and SEQUENCE modes

#### Step 2.1: Add Mode Detection Logic
**Location**: Start of `apply()` method (after line 138)
```gdscript
func apply(owner: Node) -> Signal:
	# Handle different execution modes
	match execution_mode:
		ExecutionMode.SINGLE:
			return _apply_single(owner)
		ExecutionMode.MULTI:
			return _apply_multi(owner)
		ExecutionMode.PARALLEL:
			return _apply_parallel(owner)
		ExecutionMode.SEQUENCE:
			return _apply_sequence(owner)
		_:
			push_warning("AnimationTarget: Invalid execution mode %d" % execution_mode)
			return Signal()
```

#### Step 2.2: Extract Single Animation Logic
**Location**: After `apply()` method
```gdscript
## Applies single animation to single target (original behavior).
## [param owner]: The node that owns the animation.
## [return]: Signal that emits when animation completes.
func _apply_single(owner: Node) -> Signal:
	if target.is_empty():
		return Signal()
	
	var target_node = owner.get_node_or_null(target)
	if not target_node or not (target_node is Control):
		return Signal()
	
	var control_target = target_node as Control
	
	# Convert Easing enum to Tween.EASE_* constant
	var tween_easing: int = _get_tween_easing()
	
	# Apply animation (existing match statement logic)
	return _execute_animation(owner, control_target, tween_easing)
```

#### Step 2.3: Add Multi-Target with Stagger Logic
**Location**: After `_apply_single()` method
```gdscript
## Applies same animation to multiple targets with optional stagger.
## [param owner]: The node that owns the animation.
## [return]: Signal that emits when all animations complete.
func _apply_multi(owner: Node) -> Signal:
	# Resolve targets
	var resolved_targets: Array[Control] = []
	
	# Use targets array if available, otherwise fall back to single target
	if targets.size() > 0:
		for path in targets:
			var node = owner.get_node_or_null(path)
			if node is Control:
				resolved_targets.append(node as Control)
	else:
		# Fall back to single target
		var target_node = owner.get_node_or_null(target)
		if target_node is Control:
			resolved_targets.append(target_node as Control)
	
	if resolved_targets.size() == 0:
		push_warning("AnimationTarget: No valid targets found for MULTI mode")
		return Signal()
	
	# Single target: just apply normally
	if resolved_targets.size() == 1:
		return _apply_single(owner)
	
	# Multiple targets with stagger
	if stagger_delay > 0.0:
		# Use stagger animation utility
		return _apply_stagger(owner, resolved_targets)
	else:
		# Multiple targets without stagger: apply to all simultaneously
		return _apply_parallel_targets(owner, resolved_targets)
```

#### Step 2.4: Add Stagger Helper Method
**Location**: After `_apply_multi()` method
```gdscript
## Applies animation to multiple targets with stagger timing.
## [param owner]: The node that owns the animation.
## [param targets]: Array of controls to animate.
## [return]: Signal that emits when all stagger animations complete.
func _apply_stagger(owner: Node, targets: Array[Control]) -> Signal:
	# Create AnimationActionConfig-like structure for stagger utility
	# Convert this AnimationTarget to parameters that animate_stagger expects
	var tween_easing: int = _get_tween_easing()
	
	# Create a temporary config structure for stagger
	# Since we're removing AnimationActionConfig, we need to adapt the stagger function
	# Option A: Update animate_stagger to accept AnimationTarget directly
	# Option B: Create a helper that converts AnimationTarget to stagger parameters
	
	# For now, we'll update animate_stagger to work with AnimationTarget
	return UIAnimationUtils.animate_stagger_from_target(owner, targets, stagger_delay, self)
```

#### Step 2.5: Add Parallel Execution Logic
**Location**: After `_apply_stagger()` method
```gdscript
## Applies multiple animations in parallel on the same target.
## [param owner]: The node that owns the animations.
## [return]: Signal that emits when all parallel animations complete.
func _apply_parallel(owner: Node) -> Signal:
	if parallel.size() == 0:
		push_warning("AnimationTarget: PARALLEL mode requires at least one animation in parallel array")
		return Signal()
	
	# Resolve target
	var target_node = owner.get_node_or_null(target)
	if not target_node or not (target_node is Control):
		push_warning("AnimationTarget: Invalid target for PARALLEL mode")
		return Signal()
	
	var control_target = target_node as Control
	
	# Apply initial setup if provided
	_apply_initial_setup(control_target)
	
	# Start all parallel animations
	var signals: Array[Signal] = []
	for child_target in parallel:
		if child_target != null:
			var signal_result = child_target.apply(owner)
			if signal_result is Signal:
				signals.append(signal_result)
	
	# Wait for all to complete
	if signals.size() > 0:
		return _wait_for_all_signals(owner, signals)
	else:
		return Signal()
```

#### Step 2.6: Add Sequence Execution Logic
**Location**: After `_apply_parallel()` method
```gdscript
## Applies multiple animations sequentially on the same target.
## [param owner]: The node that owns the animations.
## [return]: Signal that emits when sequence completes.
func _apply_sequence(owner: Node) -> Signal:
	if sequence.size() == 0:
		push_warning("AnimationTarget: SEQUENCE mode requires at least one animation in sequence array")
		return Signal()
	
	# Resolve target
	var target_node = owner.get_node_or_null(target)
	if not target_node or not (target_node is Control):
		push_warning("AnimationTarget: Invalid target for SEQUENCE mode")
		return Signal()
	
	var control_target = target_node as Control
	
	# Apply initial setup if provided
	_apply_initial_setup(control_target)
	
	# Create sequence using AnimationSequence utility
	var anim_sequence = AnimationSequence.create()
	
	# Add each animation step with optional delays
	for i in range(sequence.size()):
		var child_target = sequence[i]
		if child_target != null:
			# Add the animation step
			anim_sequence.add(func(): return child_target.apply(owner))
		
		# Add delay after this animation (if specified)
		var delay = 0.0
		if i < sequence_delays.size():
			delay = sequence_delays[i]
		
		if delay > 0.0:
			anim_sequence.add(func(): return UIAnimationUtils.delay(owner, delay))
	
	# Execute sequence asynchronously
	var helper = _SequenceHelper.new()
	owner.add_child(helper)
	helper.execute_sequence(anim_sequence)
	return helper.sequence_finished
```

#### Step 2.7: Extract Animation Execution Logic
**Location**: After sequence logic
```gdscript
## Executes a single animation on a control (extracted from original apply() method).
## [param owner]: The node that owns the animation.
## [param control_target]: The control to animate.
## [param tween_easing]: The easing type (Tween.EASE_* constant).
## [return]: Signal that emits when animation completes.
func _execute_animation(owner: Node, control_target: Control, tween_easing: int) -> Signal:
	match animation:
		AnimationAction.EXPAND:
			if reverse:
				return UIAnimationUtils.animate_shrink(owner, control_target, duration, pivot_offset, true, true, true, repeat_count, tween_easing)
			else:
				return UIAnimationUtils.animate_expand(owner, control_target, duration, pivot_offset, true, false, false, repeat_count, tween_easing)
		# ... (rest of existing match statement)
		_:
			push_warning("AnimationTarget: Unsupported animation type %d" % animation)
			return Signal()
```

#### Step 2.8: Add Helper Methods
**Location**: After `_execute_animation()` method
```gdscript
## Converts Easing enum to Tween.EASE_* constant.
## [return]: Tween easing constant.
func _get_tween_easing() -> int:
	match easing:
		Easing.EASE_IN:
			return Tween.EASE_IN
		Easing.EASE_OUT:
			return Tween.EASE_OUT
		Easing.EASE_IN_OUT:
			return Tween.EASE_IN_OUT
		Easing.EASE_OUT_IN:
			return Tween.EASE_OUT_IN
		_:
			return Tween.EASE_OUT

## Applies initial setup properties to a control.
## [param control]: The control to set up.
func _apply_initial_setup(control: Control) -> void:
	for property in initial_setup:
		if control.has(property):
			control.set(property, initial_setup[property])
		else:
			push_warning("AnimationTarget: Control '%s' does not have property '%s'" % [control.name, property])

## Waits for all signals to complete (for parallel execution).
## [param owner]: The node to attach helper to.
## [param signals]: Array of signals to wait for.
## [return]: Signal that emits when all signals complete.
func _wait_for_all_signals(owner: Node, signals: Array[Signal]) -> Signal:
	var helper = _ParallelWaitHelper.new()
	owner.add_child(helper)
	helper.wait_for_all(signals)
	return helper.all_finished

## Applies animation to multiple targets simultaneously (no stagger).
## [param owner]: The node that owns the animation.
## [param targets]: Array of controls to animate.
## [return]: Signal that emits when all animations complete.
func _apply_parallel_targets(owner: Node, targets: Array[Control]) -> Signal:
	var signals: Array[Signal] = []
	var tween_easing: int = _get_tween_easing()
	
	for control_target in targets:
		var signal_result = _execute_animation(owner, control_target, tween_easing)
		if signal_result is Signal:
			signals.append(signal_result)
	
	if signals.size() > 0:
		return _wait_for_all_signals(owner, signals)
	else:
		return Signal()
```

#### Step 2.9: Add Helper Classes
**Location**: End of AnimationTarget class (after all methods)
```gdscript
## Helper node for executing animation sequences asynchronously.
class _SequenceHelper extends Node:
	var sequence_finished = Signal()
	
	func execute_sequence(sequence: AnimationSequence) -> void:
		await sequence.play()
		sequence_finished.emit()
		queue_free()

## Helper node for waiting for multiple parallel animations to complete.
class _ParallelWaitHelper extends Node:
	var all_finished = Signal()
	
	func wait_for_all(signals: Array[Signal]) -> void:
		for signal_item in signals:
			await signal_item
		all_finished.emit()
		queue_free()
```

### Phase 3: Update Animation Utilities for Stagger
**Goal**: Update stagger functions to work with AnimationTarget instead of AnimationActionConfig

#### Step 3.1: Add New Stagger Function
**Location**: `scripts/anim/animation_utilities.gd` - After `animate_stagger_multi()` function
```gdscript
## Animates multiple controls with a stagger effect using AnimationTarget configuration.
## This is the unified stagger function that works with AnimationTarget resources.
## [param source_node]: The node to create tweens from (usually self).
## [param targets]: Array of controls to animate.
## [param delay_between]: Delay between each target animation in seconds.
## [param animation_target]: AnimationTarget resource that defines the animation to apply.
## [return]: Signal that emits when all stagger animations complete.
static func animate_stagger_from_target(source_node: Node, targets: Array[Control], delay_between: float, animation_target: AnimationTarget) -> Signal:
	if not source_node or targets.size() == 0:
		push_warning("UIAnimationUtils: Invalid source_node or empty targets for animate_stagger_from_target")
		return Signal()
	
	if not animation_target:
		push_warning("UIAnimationUtils: animate_stagger_from_target requires animation_target")
		return Signal()
	
	# Stop any existing stagger animations first
	stop_stagger_animations(source_node, targets)
	
	# Create helper node for stagger execution
	var helper = _StaggerHelper.new()
	source_node.add_child(helper)
	helper.set_meta("_is_stagger_helper", true)
	helper.set_meta("_stagger_type", "stagger")
	
	# Execute stagger using AnimationTarget's single animation logic
	helper.execute_stagger_from_target(source_node, targets, delay_between, animation_target)
	
	return helper.stagger_finished
```

#### Step 3.2: Update _StaggerHelper Class
**Location**: `scripts/anim/animation_utilities.gd` - Inside `_StaggerHelper` class

**DRY Approach**: Instead of duplicating animation execution logic, use AnimationTarget's `_execute_animation()` method directly. However, since `_execute_animation()` is a private method, we need to either:
- Make it public/static, OR
- Create a public wrapper method in AnimationTarget

**Recommended Solution**: Add a public static method to AnimationTarget for executing animations (following DRY).

**Add to AnimationTarget** (after `_execute_animation()` method):
```gdscript
## Public static method to execute animation (for use by stagger and other utilities).
## This allows external code to execute animations without duplicating logic.
## [param owner]: The node that owns the animation.
## [param control_target]: The control to animate.
## [param animation]: The animation action to perform.
## [param duration]: Animation duration.
## [param repeat_count]: Number of repeats.
## [param tween_easing]: Tween easing constant.
## [param reverse]: Whether to reverse the animation.
## [param pivot_offset]: Pivot offset for scaling/rotation.
## [param animation_target]: AnimationTarget resource for animation-specific parameters.
## [return]: Signal that emits when animation completes.
static func execute_animation_static(owner: Node, control_target: Control, animation: AnimationAction, duration: float, repeat_count: int, tween_easing: int, reverse: bool, pivot_offset: Vector2, animation_target: AnimationTarget) -> Signal:
	# Use the animation_target's parameters for animation-specific settings
	var rotate_start_angle = animation_target.rotate_start_angle
	var pop_overshoot = animation_target.pop_overshoot
	var pulse_amount = animation_target.pulse_amount
	var pulse_count = animation_target.pulse_count
	var shake_intensity = animation_target.shake_intensity
	var shake_count = animation_target.shake_count
	var flash_color = animation_target.flash_color
	var flash_intensity = animation_target.flash_intensity
	
	match animation:
		AnimationAction.EXPAND:
			if reverse:
				return UIAnimationUtils.animate_shrink(owner, control_target, duration, pivot_offset, true, true, true, repeat_count, tween_easing)
			else:
				return UIAnimationUtils.animate_expand(owner, control_target, duration, pivot_offset, true, false, false, repeat_count, tween_easing)
		# ... (rest of match statement, same as _execute_animation)
		_:
			push_warning("AnimationTarget: Unsupported animation type %d" % animation)
			return Signal()
```

**Update _StaggerHelper**:
```gdscript
## Executes stagger animation using AnimationTarget.
## [param source_node]: The node to create tweens from.
## [param targets]: Array of controls to animate.
## [param delay_between]: Delay between each target.
## [param animation_target]: AnimationTarget resource defining the animation.
func execute_stagger_from_target(source_node: Node, targets: Array[Control], delay_between: float, animation_target: AnimationTarget) -> void:
	if targets.size() == 0 or not animation_target:
		stagger_finished.emit()
		queue_free()
		return
	
	# Get animation parameters from AnimationTarget
	var tween_easing: int = _get_tween_easing_from_target(animation_target)
	var duration = animation_target.duration
	var repeat_count = animation_target.repeat_count
	var animation = animation_target.animation
	var reverse = animation_target.reverse
	var pivot_offset = animation_target.pivot_offset
	
	# Calculate total delay
	var total_delay = delay_between * (targets.size() - 1)
	var signals: Array[Signal] = []
	
	# Start animations with stagger
	for i in range(targets.size()):
		var target = targets[i]
		if not is_instance_valid(target):
			continue
		
		var delay_time = delay_between * i
		
		# Create delayed animation
		if delay_time > 0.0:
			# Use a helper to delay and then execute
			await get_tree().create_timer(delay_time).timeout
		
		if is_instance_valid(target):
			var signal_result = AnimationTarget.execute_animation_static(source_node, target, animation, duration, repeat_count, tween_easing, reverse, pivot_offset, animation_target)
			if signal_result is Signal:
				signals.append(signal_result)
	
	# Wait for all animations to complete
	# Calculate max time: last animation starts at total_delay and runs for duration
	var max_time = total_delay + duration
	await get_tree().create_timer(max_time).timeout
	
	# Also wait for all signals to ensure completion
	for sig in signals:
		await sig
	
	stagger_finished.emit()
	queue_free()

## Helper to get tween easing from AnimationTarget.
func _get_tween_easing_from_target(animation_target: AnimationTarget) -> int:
	match animation_target.easing:
		AnimationTarget.Easing.EASE_IN:
			return Tween.EASE_IN
		AnimationTarget.Easing.EASE_OUT:
			return Tween.EASE_OUT
		AnimationTarget.Easing.EASE_IN_OUT:
			return Tween.EASE_IN_OUT
		AnimationTarget.Easing.EASE_OUT_IN:
			return Tween.EASE_OUT_IN
		_:
			return Tween.EASE_OUT
```

**Note**: This approach follows DRY by reusing AnimationTarget's animation execution logic instead of duplicating it.

### Phase 4: Remove Old Config Classes
**Goal**: Delete obsolete config classes and update all references

#### Step 4.1: Delete AnimationActionConfig File
**Location**: `scripts/anim/animation_action_config.gd`
**Action**: Delete entire file

#### Step 4.2: Delete AnimationParallelActionConfig File
**Location**: `scripts/anim/animation_parallel_action_config.gd`
**Action**: Delete entire file

#### Step 4.3: Delete AnimationSequenceActionConfig File
**Location**: `scripts/anim/animation_sequence_action_config.gd`
**Action**: Delete entire file

#### Step 4.4: Remove Old Stagger Functions
**Location**: `scripts/anim/animation_utilities.gd`
**Action**: Delete `animate_stagger()` and `animate_stagger_multi()` functions entirely

**Rationale**: These functions depend on `AnimationActionConfig` which is being removed. The new `animate_stagger_from_target()` function replaces this functionality using `AnimationTarget`.

**Files to delete**:
- `animate_stagger()` function (around line 1954)
- `animate_stagger_multi()` function (around line 1997)
- Update `_StaggerHelper.execute_stagger()` and `execute_stagger_multi()` methods to use AnimationTarget instead

**Note**: The `_StaggerHelper` class will be updated in Phase 3 to work with AnimationTarget, so the old methods can be removed.

### Phase 4: Remove Old Config Classes and Functions
**Goal**: Delete obsolete config classes and update all references

#### Step 4.1: Delete AnimationActionConfig File
**Location**: `scripts/anim/animation_action_config.gd`
**Action**: Delete entire file

#### Step 4.2: Delete AnimationParallelActionConfig File
**Location**: `scripts/anim/animation_parallel_action_config.gd`
**Action**: Delete entire file

#### Step 4.3: Delete AnimationSequenceActionConfig File
**Location**: `scripts/anim/animation_sequence_action_config.gd`
**Action**: Delete entire file

#### Step 4.4: Remove Old Stagger Functions
**Location**: `scripts/anim/animation_utilities.gd`
**Action**: Delete `animate_stagger()` and `animate_stagger_multi()` functions entirely

**Rationale**: These functions depend on `AnimationActionConfig` which is being removed. The new `animate_stagger_from_target()` function replaces this functionality using `AnimationTarget`.

**Files to delete**:
- `animate_stagger()` function (around line 1954)
- `animate_stagger_multi()` function (around line 1997)
- Update `_StaggerHelper.execute_stagger()` and `execute_stagger_multi()` methods - these can be removed or updated to use AnimationTarget

**Note**: The `_StaggerHelper` class will be updated in Phase 3 to work with AnimationTarget, so the old methods can be removed.

### Phase 5: Update Documentation and Cleanup
**Goal**: Update class documentation and remove references to old configs

#### Step 5.1: Update AnimationTarget Class Documentation
**Location**: Top of `scripts/utilities/animation_target.gd`
```gdscript
## Unified animation target configuration (no resource file needed).
## All properties are configured directly in the Inspector with dropdown menus.
##
## Supports four execution modes:
## - SINGLE: One animation on one target (default, original behavior)
## - MULTI: Same animation on multiple targets with optional stagger timing
## - PARALLEL: Multiple different animations on same target simultaneously
## - SEQUENCE: Multiple animations on same target sequentially
##
## Supports nested structures: parallel groups can contain sequences, sequences can contain parallel groups, etc.
##
## Example (Stagger):
##   execution_mode = MULTI
##   targets = [NodePath("../Label1"), NodePath("../Label2"), NodePath("../Label3")]
##   stagger_delay = 0.1
##   animation = FADE_IN
##
## Example (Parallel):
##   execution_mode = PARALLEL
##   target = NodePath("../Panel")
##   parallel = [expand_anim, fade_anim, slide_anim]
##
## Example (Sequence):
##   execution_mode = SEQUENCE
##   target = NodePath("../Panel")
##   sequence = [expand_anim, fade_anim, color_flash_anim]
##   sequence_delays = [0.0, 0.3, 0.2]
##
## Example (Nested):
##   execution_mode = SEQUENCE
##   target = NodePath("../Panel")
##   sequence = [expand_anim, parallel_group, fade_anim]
##   # where parallel_group has execution_mode = PARALLEL with its own parallel array
```

#### Step 5.2: Remove References to Old Configs
**Location**: Any documentation files, comments, or examples
**Action**: Search and replace references to old config classes with AnimationTarget examples

### Phase 6: Testing and Validation
**Goal**: Verify all execution modes work correctly

#### Step 6.1: Test Single Mode
- Verify existing single-target animations still work
- Test all animation types

#### Step 6.2: Test Multi Mode
- Test multiple targets without stagger
- Test multiple targets with stagger
- Test with different animation types

#### Step 6.3: Test Parallel Mode
- Test parallel animations on same target
- Test nested parallel (parallel within parallel)
- Test parallel with different animation types

#### Step 6.4: Test Sequence Mode
- Test sequential animations
- Test sequence with delays
- Test nested sequence (sequence within sequence)

#### Step 6.5: Test Mixed Nested Structures
- Test sequence containing parallel group
- Test parallel group containing sequence
- Test complex nested combinations

## SOLID/DRY Principles

### Single Responsibility
- **AnimationTarget**: Handles all animation configuration (single responsibility)
- **Helper classes**: Each helper has one job (_SequenceHelper, _ParallelWaitHelper, _StaggerHelper)

### Open/Closed
- **Extensible**: New execution modes can be added via enum without modifying existing code
- **Closed**: Existing single-mode behavior remains unchanged

### Liskov Substitution
- **Consistent API**: All execution modes use the same `apply()` method signature
- **Polymorphic**: Can be used anywhere AnimationTarget is expected

### Interface Segregation
- **Clean separation**: Execution mode logic separated into dedicated methods
- **No forced dependencies**: Users only configure what they need

### Dependency Inversion
- **Abstraction**: Depends on AnimationSequence utility, not concrete implementations
- **Flexible**: Can work with any Control target

### DRY (Don't Repeat Yourself)
- **Shared logic**: Animation execution extracted to `_execute_animation()`
- **Reusable helpers**: Helper classes used across execution modes
- **Single source**: One resource type instead of four

## Risk Mitigation

### Minimal Risk Approach
1. **Incremental changes**: Each phase builds on previous phase
2. **Preserve existing behavior**: SINGLE mode maintains exact current behavior
3. **Clear separation**: New modes isolated in separate methods
4. **Comprehensive testing**: Each mode tested independently before moving to next

### Validation Points
- After Phase 1: Verify Inspector shows new properties correctly
- After Phase 2: Verify SINGLE mode still works (regression test)
- After Phase 3: Verify MULTI mode works with stagger
- After Phase 4: Verify no compilation errors after deletions
- After Phase 5: Verify documentation is accurate
- After Phase 6: Verify all modes work in isolation and combination

## Implementation Order

1. **Phase 1**: Extend AnimationTarget with new properties (no behavior changes)
2. **Phase 2**: Refactor apply() method (preserve SINGLE mode, add new modes)
3. **Phase 3**: Update animation utilities for stagger (add new function)
4. **Phase 4**: Remove old config classes (clean deletion)
5. **Phase 5**: Update documentation (clarify new unified system)
6. **Phase 6**: Testing and validation (ensure all modes work)

## Benefits

### User Experience
- **Single resource type**: One AnimationTarget instead of four different configs
- **Simpler workflow**: All animation configuration in one place
- **Nested support**: Complex animations without external scripting
- **Inspector-friendly**: All configuration through Inspector dropdowns

### Code Quality
- **Reduced complexity**: Fewer classes to maintain
- **DRY compliance**: No duplicate animation execution logic
- **SOLID adherence**: Clear separation of concerns
- **Maintainability**: Single source of truth for animation configuration

### System Architecture
- **Unified API**: Consistent interface across all animation types
- **Extensible**: Easy to add new execution modes in future
- **Clean codebase**: No legacy config classes cluttering the system

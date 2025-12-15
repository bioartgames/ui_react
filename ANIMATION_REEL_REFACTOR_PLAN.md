# Animation Reel/Clip Refactor Plan

## ✅ REFACTOR COMPLETED

**Status**: All phases implemented successfully. The animation system has been refactored from `AnimationTarget` to `AnimationReel` and `AnimationClip` system.

**Key Improvements**:
- Cleaner Inspector UI with separate animation clips and reels
- Automatic execution mode detection (single/multi/sequence)
- Per-clip timing controls (delay, stagger, respect_disabled)
- Better separation of concerns between data (AnimationClip) and execution (AnimationReel)

**Files Created**:
- `scripts/utilities/animation_clip.gd` - Animation data and execution
- `scripts/utilities/animation_reel.gd` - Animation orchestration

**Files Updated**:
- All 11 reactive component files updated to use AnimationReel
- `scripts/anim/animation_utilities.gd` - Added AnimationClip stagger support

**Files Removed**:
- `scripts/utilities/animation_target.gd` - Replaced by AnimationReel/AnimationClip

---

## Overview
✅ **COMPLETED**: Refactored from `AnimationTarget` system to `AnimationReel` and `AnimationClip` system. This provides a cleaner Inspector UI while maintaining all functionality and flexibility.

## Design Decisions & Clarifications Needed

### ✅ Resolved Design Decisions
1. ✅ **COMPLETED**: Top-level structure: `animations: Array[AnimationReel]` replaces `animation_targets: Array[AnimationTarget]`
2. **Triggers**: Only at reel level (Option C)
3. **Targets**: `Array[NodePath]` at reel level (moved from clip level)
4. **Stagger vs Delay**: 
   - `stagger`: For multi-target animations (delay between targets)
   - `delay`: For sequences or general delay before animation starts
5. **Execution mode**: Automatic detection (no mode selection)
   - Single clip, single target → SINGLE
   - Single clip, multiple targets → MULTI (with stagger if stagger > 0)
   - Multiple clips → SEQUENCE (using each clip's delay)

### ⚠️ Design Decisions Requiring Clarification

1. **Target Validation**: 
   - **Question**: Should validation check that reel has at least one target, or allow empty targets (for clips that might use a different target system)?
   - **Proposed**: Require at least one target in reel for validation to pass

2. **Stagger Behavior**:
   - **Question**: If a reel has multiple targets and multiple clips, should stagger apply per-clip (each clip staggers across targets) or globally?
   - **Proposed**: Stagger is per-clip property, only used when reel has multiple targets. Each clip can have its own stagger value.

3. **Delay Behavior in Sequences**:
   - **Question**: When multiple clips exist, should delay be "before this clip starts" or "after previous clip finishes"?
   - **Proposed**: Delay is "before this clip starts" (first clip's delay is before it, subsequent delays are after previous clip finishes)

4. **Empty Clips Array**:
   - **Question**: Should a reel with no clips be valid? What should happen?
   - **Proposed**: Allow empty clips array, but skip execution (no-op)

5. **Respect Disabled**:
   - **Question**: If a clip has `respect_disabled = true` but the reel's owner control is disabled, should we skip just that clip or the entire reel?
   - **Proposed**: Skip only that clip, continue with other clips in the reel

6. **Target Resolution**:
   - **Question**: Should all targets in a reel be validated upfront, or lazily when clips execute?
   - **Proposed**: Validate all targets upfront in `_validate_animation_reels()`, filter out invalid ones

## Files to Create
1. `scripts/utilities/animation_clip.gd` - New AnimationClip resource class
2. `scripts/utilities/animation_reel.gd` - New AnimationReel resource class

## Files to Modify
1. All reactive component files (11 files):
   - `scripts/reactive/reactive_button.gd`
   - `scripts/reactive/reactive_check_box.gd`
   - `scripts/reactive/reactive_item_list.gd`
   - `scripts/reactive/reactive_label.gd`
   - `scripts/reactive/reactive_line_edit.gd`
   - `scripts/reactive/reactive_option_button.gd`
   - `scripts/reactive/reactive_progress_bar.gd`
   - `scripts/reactive/reactive_slider.gd`
   - `scripts/reactive/reactive_spin_box.gd`
   - `scripts/reactive/reactive_tab_container.gd`
   - Any other reactive components using AnimationTarget

## Files to Delete
1. `scripts/utilities/animation_target.gd` - Replaced by AnimationReel/AnimationClip

## Implementation Phases

### Phase 1: Create AnimationClip Resource Class
**Goal**: Create the new AnimationClip resource with all animation properties

#### Step 1.1: Create AnimationClip File
**Location**: `scripts/utilities/animation_clip.gd` (new file)

**Content**: Create AnimationClip class with:
- AnimationAction enum (copy from AnimationTarget)
- Easing enum (copy from AnimationTarget)
- Animation type property (dropdown)
- Delay property (for sequences)
- Stagger property (for multi-target)
- Duration, easing, repeat_count, reverse, respect_disabled, pivot_offset
- All animation-specific properties (rotate_start_angle, pop_overshoot, pulse_amount, etc.)
- Method to execute animation: `execute(owner: Node, target: Control, tween_easing: int) -> Signal`

#### Step 1.2: Add Animation Execution Logic
**Location**: Inside AnimationClip class

**Content**: Add `execute()` method that:
- Takes owner, target Control, and tween_easing
- Matches on animation type
- Calls appropriate UIAnimationUtils function
- Returns Signal from animation

**Note**: This is similar to `_execute_animation()` from AnimationTarget, but as a public method.

### Phase 2: Create AnimationReel Resource Class
**Goal**: Create AnimationReel class that contains clips and handles execution

#### Step 2.1: Create AnimationReel File
**Location**: `scripts/utilities/animation_reel.gd` (new file)

**Content**: Create AnimationReel class with:
- Trigger enum (copy from AnimationTarget)
- Trigger property (dropdown)
- Targets array (Array[NodePath])
- Animations array (Array[AnimationClip])
- Method to apply reel: `apply(owner: Node) -> Signal`

#### Step 2.2: Add Automatic Execution Mode Detection
**Location**: Inside AnimationReel's `apply()` method

**Logic**:
```gdscript
func apply(owner: Node) -> Signal:
    if animations.size() == 0:
        return Signal()  # No-op if no clips
    
    if targets.size() == 0:
        push_warning("AnimationReel: No targets specified")
        return Signal()
    
    # Resolve all targets
    var resolved_targets: Array[Control] = []
    for path in targets:
        var node = owner.get_node_or_null(path)
        if node is Control:
            resolved_targets.append(node as Control)
    
    if resolved_targets.size() == 0:
        push_warning("AnimationReel: No valid targets found")
        return Signal()
    
    # Automatic mode detection
    if animations.size() == 1:
        # Single clip
        if resolved_targets.size() == 1:
            # SINGLE: One clip, one target
            return _apply_single(owner, resolved_targets[0], animations[0])
        else:
            # MULTI: One clip, multiple targets (with stagger if stagger > 0)
            return _apply_multi(owner, resolved_targets, animations[0])
    else:
        # SEQUENCE: Multiple clips (run sequentially)
        return _apply_sequence(owner, resolved_targets, animations)
```

#### Step 2.3: Add Execution Methods
**Location**: Inside AnimationReel class

**Methods to add**:
- `_apply_single(owner: Node, target: Control, clip: AnimationClip) -> Signal`
- `_apply_multi(owner: Node, targets: Array[Control], clip: AnimationClip) -> Signal`
- `_apply_sequence(owner: Node, targets: Array[Control], clips: Array[AnimationClip]) -> Signal`

**Implementation details**:
- `_apply_single`: Resolve target, get tween_easing from clip, call clip.execute()
- `_apply_multi`: Use stagger if clip.stagger > 0, otherwise apply to all targets simultaneously
- `_apply_sequence`: Use AnimationSequence, add each clip with its delay, handle multiple targets (apply sequence to each target? or first target only?)

**⚠️ Design Question for Sequence with Multiple Targets**:
- If reel has multiple targets and multiple clips, should sequence:
  - Option A: Run sequence on first target only
  - Option B: Run sequence on all targets simultaneously (each target gets the same sequence)
  - Option C: Run sequence on all targets with stagger (stagger between targets, then sequence within each target)
- **Proposed**: Option B (sequence runs on all targets simultaneously)

### Phase 3: Update Reactive Components
**Goal**: Replace AnimationTarget usage with AnimationReel

#### Step 3.1: Update Export Property
**Location**: All reactive component files

**Change**:
```gdscript
# OLD:
@export var animation_targets: Array[AnimationTarget] = []

# NEW:
@export var animations: Array[AnimationReel] = []
```

#### Step 3.2: Update Validation Method
**Location**: All reactive component files

**Change method name and logic**:
```gdscript
# OLD:
func _validate_animation_targets() -> void:
    var valid_targets: Array[AnimationTarget] = []
    for anim_target in animation_targets:
        # Validate target NodePath
        # Track triggers
    animation_targets = valid_targets

# NEW:
func _validate_animation_reels() -> void:
    var valid_reels: Array[AnimationReel] = []
    var has_trigger_X = false  # Track which triggers are used
    
    for reel in animations:
        if reel == null:
            continue
        
        # Validate targets array (at least one target required)
        if reel.targets.size() == 0:
            push_warning("ReactiveX '%s': AnimationReel has no targets. Add at least one target NodePath." % name)
            continue
        
        # Validate all targets resolve to Controls
        var has_valid_target = false
        for path in reel.targets:
            var node = get_node_or_null(path)
            if node is Control:
                has_valid_target = true
                break
        
        if not has_valid_target:
            push_warning("ReactiveX '%s': AnimationReel has no valid targets. Check NodePaths." % name)
            continue
        
        valid_reels.append(reel)
        
        # Track which triggers we need to connect
        match reel.trigger:
            AnimationReel.Trigger.TEXT_CHANGED:
                has_trigger_text_changed = true
            # ... etc for all triggers
    
    animations = valid_reels
    
    # Connect signals based on triggers
    # (same logic as before, but using AnimationReel.Trigger)
```

#### Step 3.3: Update Trigger Methods
**Location**: All reactive component files

**Change**:
```gdscript
# OLD:
func _trigger_animations(trigger_type: AnimationTarget.Trigger) -> void:
    for anim_target in animation_targets:
        if anim_target.trigger != trigger_type:
            continue
        if anim_target.respect_disabled and disabled:
            continue
        anim_target.apply(self)

# NEW:
func _trigger_animations(trigger_type: AnimationReel.Trigger) -> void:
    for reel in animations:
        if reel == null:
            continue
        if reel.trigger != trigger_type:
            continue
        # Note: respect_disabled is now per-clip, not per-reel
        reel.apply(self)
```

**⚠️ Design Question**: Should we check `respect_disabled` at reel level or clip level?
- **Proposed**: Check at clip level inside reel's apply() method, skip individual clips that have respect_disabled=true when owner is disabled

#### Step 3.4: Update Method Calls
**Location**: All reactive component files

**Changes**:
- `_validate_animation_targets()` → `_validate_animation_reels()`
- `AnimationTarget.Trigger.X` → `AnimationReel.Trigger.X`
- Update all trigger connection logic to use new enum

### Phase 4: Update AnimationReel Execution Logic
**Goal**: Implement proper execution for single, multi, and sequence modes

#### Step 4.1: Implement _apply_single
**Location**: `scripts/utilities/animation_reel.gd`

**Implementation**:
```gdscript
func _apply_single(owner: Node, target: Control, clip: AnimationClip) -> Signal:
    # Get tween easing from clip
    var tween_easing: int = _get_tween_easing_from_clip(clip)
    
    # Check respect_disabled
    if clip.respect_disabled and owner.has_method("is_disabled") and owner.is_disabled():
        return Signal()  # Skip if disabled
    
    # Execute clip animation
    return clip.execute(owner, target, tween_easing)
```

#### Step 4.2: Implement _apply_multi
**Location**: `scripts/utilities/animation_reel.gd`

**Implementation**:
```gdscript
func _apply_multi(owner: Node, targets: Array[Control], clip: AnimationClip) -> Signal:
    if targets.size() == 1:
        return _apply_single(owner, targets[0], clip)
    
    # Check respect_disabled
    if clip.respect_disabled and owner.has_method("is_disabled") and owner.is_disabled():
        return Signal()
    
    # Use stagger if clip.stagger > 0
    if clip.stagger > 0.0:
        return _apply_multi_stagger(owner, targets, clip)
    else:
        # Apply to all targets simultaneously
        return _apply_multi_parallel(owner, targets, clip)
```

#### Step 4.3: Implement Stagger and Parallel Multi-Target
**Location**: `scripts/utilities/animation_reel.gd`

**Add methods**:
- `_apply_multi_stagger(owner: Node, targets: Array[Control], clip: AnimationClip) -> Signal`
- `_apply_multi_parallel(owner: Node, targets: Array[Control], clip: AnimationClip) -> Signal`

**Implementation**:
- `_apply_multi_stagger`: Use `UIAnimationUtils.animate_stagger_from_target()` or create custom stagger logic
- `_apply_multi_parallel`: Apply clip to all targets, wait for all signals

#### Step 4.4: Implement _apply_sequence
**Location**: `scripts/utilities/animation_reel.gd`

**⚠️ Design Question**: When reel has multiple targets and multiple clips:
- Should sequence run on all targets simultaneously (each target gets same sequence)?
- Or should sequence run on first target only?

**Proposed Implementation** (Option: All targets simultaneously):
```gdscript
func _apply_sequence(owner: Node, targets: Array[Control], clips: Array[AnimationClip]) -> Signal:
    # Create sequence for each target (all run simultaneously)
    var all_signals: Array[Signal] = []
    
    for target in targets:
        var anim_sequence = AnimationSequence.create()
        
        for clip in clips:
            # Check respect_disabled per clip
            if clip.respect_disabled and owner.has_method("is_disabled") and owner.is_disabled():
                continue  # Skip this clip
            
            # Add delay if specified
            if clip.delay > 0.0:
                anim_sequence.add(func(): return UIAnimationUtils.delay(owner, clip.delay))
            
            # Add animation
            var tween_easing = _get_tween_easing_from_clip(clip)
            anim_sequence.add(func(): return clip.execute(owner, target, tween_easing))
        
        # Execute sequence for this target
        var helper = _SequenceHelper.new()
        owner.add_child(helper)
        helper.execute_sequence(anim_sequence)
        all_signals.append(helper.sequence_finished)
    
    # Wait for all sequences to complete
    if all_signals.size() > 0:
        return _wait_for_all_signals(owner, all_signals)
    else:
        return Signal()
```

#### Step 4.5: Add Helper Methods
**Location**: `scripts/utilities/animation_reel.gd`

**Add**:
- `_get_tween_easing_from_clip(clip: AnimationClip) -> int`
- `_wait_for_all_signals(owner: Node, signals: Array[Signal]) -> Signal`
- `_SequenceHelper` class (copy from AnimationTarget)

### Phase 5: Update AnimationClip to Use Stagger Utility
**Goal**: Ensure AnimationClip works with existing stagger utilities

#### Step 5.1: Check Stagger Utility Compatibility
**Location**: `scripts/anim/animation_utilities.gd`

**Action**: Verify `animate_stagger_from_target()` can work with AnimationClip, or create new utility function

**Note**: Current `animate_stagger_from_target()` expects `AnimationTarget`. We may need:
- Option A: Create `animate_stagger_from_clip()` function
- Option B: Make AnimationClip compatible with existing function
- Option C: Refactor stagger utility to accept a more generic interface

**Proposed**: Option A - Create new function `animate_stagger_from_clip()` that works with AnimationClip

#### Step 5.2: Create Stagger Utility for AnimationClip
**Location**: `scripts/anim/animation_utilities.gd`

**Add function**:
```gdscript
static func animate_stagger_from_clip(source_node: Node, targets: Array[Control], delay_between: float, clip: AnimationClip) -> Signal:
    # Similar to animate_stagger_from_target, but uses AnimationClip
    # Use AnimationClip.execute() for each target with stagger timing
```

### Phase 6: Remove Old AnimationTarget
**Goal**: Delete AnimationTarget and clean up references

#### Step 6.1: Delete AnimationTarget File
**Location**: `scripts/utilities/animation_target.gd`
**Action**: Delete entire file

#### Step 6.2: Remove AnimationTarget References
**Location**: All files
**Action**: Search and verify no remaining references to AnimationTarget class

#### Step 6.3: Update Documentation
**Location**: Any documentation files
**Action**: Update references from AnimationTarget to AnimationReel/AnimationClip

### Phase 7: Testing and Validation
**Goal**: Verify all execution modes work correctly

#### Step 7.1: Test Single Clip, Single Target
- Verify single animation works
- Test all animation types
- Test respect_disabled

#### Step 7.2: Test Single Clip, Multiple Targets
- Test without stagger (parallel)
- Test with stagger
- Test different animation types

#### Step 7.3: Test Multiple Clips (Sequence)
- Test sequence with delays
- Test sequence with multiple targets
- Test respect_disabled per clip

#### Step 7.4: Test Triggers
- Test all trigger types work
- Test trigger validation
- Test signal connections

## Implementation Order

1. **Phase 1**: Create AnimationClip resource (foundation)
2. **Phase 2**: Create AnimationReel resource (container and execution)
3. **Phase 3**: Update reactive components (integration)
4. **Phase 4**: Complete execution logic (functionality)
5. **Phase 5**: Update stagger utilities (compatibility)
6. **Phase 6**: Remove old code (cleanup)
7. **Phase 7**: Testing (validation)

## Risk Mitigation

### Potential Issues
1. **Stagger utility compatibility**: May need new function or refactor
2. **Sequence with multiple targets**: Need to clarify behavior
3. **Respect disabled logic**: Need to handle at clip level, not reel level
4. **Target validation**: Need to validate all targets upfront

### Validation Points
- After Phase 1: Verify AnimationClip can execute all animation types
- After Phase 2: Verify AnimationReel can detect modes and route correctly
- After Phase 3: Verify reactive components compile and validate correctly
- After Phase 4: Verify all execution modes work
- After Phase 5: Verify stagger works with new system
- After Phase 6: Verify no compilation errors
- After Phase 7: Verify all functionality works end-to-end

## Notes

- No backward compatibility needed (per user preference)
- All existing AnimationTarget functionality must be preserved
- Inspector UI should be cleaner and more intuitive
- Automatic mode detection removes need for execution mode selection

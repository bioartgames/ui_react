# Detailed Phased Plan: Unified Original State System for All Animations

## Overview
Refactor the animation system to use a unified original state snapshot that is locked when the first animation starts and only unlocked/restored when all animations complete. This prevents drift in position, scale, color, rotation, and all other animatable properties when multiple animations overlap. The reset animation will restore ALL properties to their original state.

## Files to Modify
1. `scripts/anim/animation_utilities.gd` - Core animation functions and infrastructure
2. `scripts/utilities/animation_target.gd` - AnimationTarget RESET case
3. `scripts/anim/animation_action_config.gd` - RESET case
4. `scripts/utilities/animation_config.gd` - RESET case

## Files That Call Animation Functions (No Changes Needed - API Compatible)
- `scripts/anim/animation_parallel_action_config.gd`
- `scripts/anim/animation_sequence_action_config.gd`

---

## PHASE 1: Replace Position System with Unified Snapshot System

### File: `scripts/anim/animation_utilities.gd`

### Step 1.1: Remove Old Position Tracking
**Location:** Remove the `_saved_positions` static variable declaration that appears after the `PIVOT_CENTER_MULTIPLIER` constant and before the `get_node_center` function

**Code to Remove:**
```gdscript
## Tracks saved positions per target control for preserve_position feature.
## Key: Control node (object ID), Value: Vector2 saved position
static var _saved_positions: Dictionary = {}
```

### Step 1.2: Add Unified Snapshot Tracking Infrastructure
**Location:** After the `PIVOT_CENTER_MULTIPLIER` constant, before the `get_node_center` function

**New Code:**
```gdscript
## Tracks unified original state snapshots per target control.
## This snapshot is locked when the first animation starts and only unlocked
## when all animations complete. Contains position, scale, modulate, rotation, pivot_offset, and visible.
## Key: Control node (object ID), Value: ControlStateSnapshot
static var _unified_original_snapshots: Dictionary = {}

## Tracks active animation count per target control.
## When count reaches 0, the unified snapshot is restored and unlocked.
## Key: Control node (object ID), Value: int (active animation count)
static var _active_animation_count: Dictionary = {}
```

### Step 1.3: Add Helper Functions for Unified Snapshot Management
**Location:** After the `restore_control_state` function, before the `reset_control_to_normal` function

**New Functions to Add:**
```gdscript
## Acquires the unified original snapshot for a target control.
## If no unified snapshot exists, saves the current state and locks it.
## Increments the active animation counter.
## Interrupts all active tweens on animatable properties before snapshotting.
## [param source_node]: The node to create interrupt tweens from.
## [param target]: The control to acquire unified snapshot for.
## [return]: The unified original snapshot (ControlStateSnapshot).
static func _acquire_unified_snapshot(source_node: Node, target: Control) -> ControlStateSnapshot:
	if not target:
		return null
	
	# If unified snapshot doesn't exist, save current state and initialize counter
	if not _unified_original_snapshots.has(target):
		# Interrupt all active tweens on animatable properties to get accurate current state
		var interrupt_tween = source_node.create_tween()
		if interrupt_tween:
			# Interrupt position tweens
			interrupt_tween.tween_property(target, "position", target.position, 0.0)
			# Interrupt scale tweens
			interrupt_tween.tween_property(target, "scale", target.scale, 0.0)
			# Interrupt modulate/color tweens
			interrupt_tween.tween_property(target, "modulate", target.modulate, 0.0)
			# Interrupt rotation tweens
			interrupt_tween.tween_property(target, "rotation_degrees", target.rotation_degrees, 0.0)
			interrupt_tween.kill()
		
		# Create snapshot of current state
		var new_snapshot = snapshot_control_state(target)
		if not new_snapshot:
			# If snapshot creation failed, push warning and return null
			push_warning("UIAnimationUtils._acquire_unified_snapshot(): Failed to create snapshot for target '%s'" % target.name)
			return null
		_unified_original_snapshots[target] = new_snapshot
		_active_animation_count[target] = 0
	
	# Increment active animation counter
	_active_animation_count[target] = _active_animation_count[target] + 1
	
	return _unified_original_snapshots[target]

## Releases the unified original snapshot for a target control.
## Decrements the active animation counter.
## If counter reaches 0, restores all properties from snapshot and unlocks it.
## [param target]: The control to release unified snapshot for.
## [param restore_immediately]: If true, immediately restores state when counter reaches 0 (default: true).
## [return]: true if state was restored, false otherwise.
static func _release_unified_snapshot(target: Control, restore_immediately: bool = true) -> bool:
	if not target:
		return false
	
	if not _active_animation_count.has(target):
		return false
	
	# Decrement counter
	_active_animation_count[target] = _active_animation_count[target] - 1
	
	# If counter reached 0, restore state and unlock
	if _active_animation_count[target] <= 0:
		if _unified_original_snapshots.has(target):
			var snapshot = _unified_original_snapshots[target]
			if snapshot and restore_immediately:
				restore_control_state(target, snapshot)
			# Clean up tracking dictionaries
			_unified_original_snapshots.erase(target)
			_active_animation_count.erase(target)
			return true
	
	return false

## Gets the unified original snapshot for a target without acquiring it.
## Returns null if no unified snapshot exists.
## [param target]: The control to get unified snapshot for.
## [return]: The unified original snapshot, or null if not set.
static func _get_unified_snapshot(target: Control) -> ControlStateSnapshot:
	if not target:
		return null
	
	if _unified_original_snapshots.has(target):
		return _unified_original_snapshots[target]
	
	return null

## Manually clears the unified snapshot system for a target.
## Useful for edge cases or manual cleanup.
## [param target]: The control to clear unified snapshot for.
static func _clear_unified_snapshot(target: Control) -> void:
	if not target:
		return
	
	_unified_original_snapshots.erase(target)
	_active_animation_count.erase(target)
```

---

## PHASE 2: Create Comprehensive Reset Animation Function

### File: `scripts/anim/animation_utilities.gd`

### Step 2.1: Add animate_reset_all Function
**Location:** After the `animate_float` function, before the `animate_glow_pulse` function

**New Function:**
```gdscript
## Animates a control back to its unified original state (all properties).
## If no unified snapshot exists, uses current state (no animation).
## This function can be added to animation chains to explicitly restore all properties.
## Restores: position, scale, modulate (color + alpha), rotation, pivot_offset, and visible.
## [param source_node]: The node to create the tween from (usually self).
## [param target]: The control node to animate.
## [param duration]: Duration of the reset animation in seconds (default: 0.3).
## [param easing]: Easing type for the animation (default: EASE_OUT).
## [param clear_unified_after]: If true, clears unified snapshot after reset (default: true).
## [return]: Signal that emits when animation finishes.
static func animate_reset_all(source_node: Node, target: Control, duration: float = 0.3, easing: int = Tween.EASE_OUT, clear_unified_after: bool = true) -> Signal:
	if not source_node or not target:
		push_warning("UIAnimationUtils: Invalid source_node or target for animate_reset_all")
		return Signal()
	
	# Get the unified original snapshot (or current state if not set)
	var snapshot: ControlStateSnapshot
	if _unified_original_snapshots.has(target):
		snapshot = _unified_original_snapshots[target]
	else:
		# No unified snapshot, use current state (no animation needed)
		return Signal()
	
	# Validate snapshot exists and is valid
	if not snapshot:
		push_warning("UIAnimationUtils.animate_reset_all(): Unified snapshot exists but is null for target '%s'" % target.name)
		return Signal()
	
	# If duration is 0, perform instant reset
	if duration <= 0.0:
		restore_control_state(target, snapshot)
		if clear_unified_after:
			_clear_unified_snapshot(target)
		# Return an empty signal (caller can't await it, but it's consistent with API)
		# For instant reset, the work is done synchronously
		return Signal()
	
	# Create independent tweens for each property to animate them in parallel
	# This is the Godot 4 approach since set_parallel() is no longer supported
	var tween_position = source_node.create_tween()
	var tween_scale = source_node.create_tween()
	var tween_modulate = source_node.create_tween()
	var tween_rotation = source_node.create_tween()
	
	# Validate all tweens were created successfully
	if not tween_position or not tween_scale or not tween_modulate or not tween_rotation:
		push_warning("UIAnimationUtils.animate_reset_all(): Failed to create one or more tweens for target '%s'" % target.name)
		# Clean up any successfully created tweens
		if tween_position:
			tween_position.kill()
		if tween_scale:
			tween_scale.kill()
		if tween_modulate:
			tween_modulate.kill()
		if tween_rotation:
			tween_rotation.kill()
		return Signal()
	
	# Animate all properties in parallel using independent tweens
	tween_position.tween_property(target, 'position', snapshot.position, duration).set_trans(Tween.TRANS_SINE).set_ease(easing)
	tween_scale.tween_property(target, 'scale', snapshot.scale, duration).set_trans(Tween.TRANS_SINE).set_ease(easing)
	tween_modulate.tween_property(target, 'modulate', snapshot.modulate, duration).set_trans(Tween.TRANS_SINE).set_ease(easing)
	tween_rotation.tween_property(target, 'rotation_degrees', snapshot.rotation_degrees, duration).set_trans(Tween.TRANS_SINE).set_ease(easing)
	
	# Use position tween's finished signal as the primary completion signal
	# All tweens will complete at the same time since they have the same duration
	var t = tween_position
	
	# Set non-animated properties immediately (pivot_offset and visible don't animate smoothly)
	target.pivot_offset = snapshot.pivot_offset
	target.visible = snapshot.visible
	
	# Connect to completion to optionally clear unified snapshot
	if clear_unified_after:
		t.finished.connect(func():
			_clear_unified_snapshot(target)
		, CONNECT_ONE_SHOT)
	
	return t.finished
```

---

## PHASE 3: Refactor animate_shake Function

### File: `scripts/anim/animation_utilities.gd`

### Step 3.1: Replace animate_shake Function
**Location:** Replace the entire `animate_shake` function (find it by searching for the function signature: `static func animate_shake`)

**New Function:**
```gdscript
static func animate_shake(source_node: Node, target: Control, speed := 0.5, intensity: float = 10.0, shake_count: int = 5, auto_visible: bool = false, repeat_count: int = 0, easing: int = Tween.EASE_OUT, preserve_position: bool = false) -> Signal:
	if not source_node or not target:
		push_warning("UIAnimationUtils: Invalid source_node or target for animate_shake")
		return Signal()
	
	# Handle position preservation: use unified snapshot system
	var saved_position: Vector2 = Vector2.ZERO
	var using_unified_snapshot: bool = false
	
	if preserve_position:
		# Acquire unified snapshot (saves if first, increments counter)
		var snapshot = _acquire_unified_snapshot(source_node, target)
		if snapshot:
			saved_position = snapshot.position
			using_unified_snapshot = true
		else:
			# Fallback to current position if snapshot failed (null snapshot or acquisition failed)
			push_warning("UIAnimationUtils.animate_shake(): Failed to acquire unified snapshot for target '%s', using current position" % target.name)
			saved_position = target.position
	else:
		# Not preserving position, use current position
		saved_position = target.position
	
	var animation_callable = func() -> Signal:
		if auto_visible:
			target.visible = true
		
		# Use saved position (unified if preserving, otherwise current)
		var original_position = saved_position
		var t = source_node.create_tween()
		if not t:
			push_warning("UIAnimationUtils: Failed to create tween")
			return Signal()
		
		var shake_duration = speed / shake_count
		
		# Create shake movements
		for i in range(shake_count):
			var offset_x = intensity * (1.0 if i % 2 == 0 else -1.0)
			var y_index = int(i * 0.5)
			var offset_y = intensity * 0.5 * (1.0 if y_index % 2 == 0 else -1.0)
			t.tween_property(target, 'position', original_position + Vector2(offset_x, offset_y), shake_duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(easing)
			t.tween_property(target, 'position', original_position, shake_duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(easing)
		
		return t.finished
	
	var result_signal: Signal
	if repeat_count != 0:
		result_signal = _loop_animation(source_node, target, animation_callable, repeat_count)
	else:
		result_signal = animation_callable.call()
	
	# Connect to final completion to release unified snapshot
	if preserve_position and using_unified_snapshot:
		result_signal.connect(func(): 
			_release_unified_snapshot(target, true)
		, CONNECT_ONE_SHOT)
	
	return result_signal
```

**Key Changes:**
- Removed old `_saved_positions` dictionary usage
- Uses `_acquire_unified_snapshot()` instead
- Uses `_release_unified_snapshot()` for cleanup
- Removed manual dictionary manipulation

---

## PHASE 4: Refactor animate_float Function

### File: `scripts/anim/animation_utilities.gd`

### Step 4.1: Replace animate_float Function
**Location:** Replace the entire `animate_float` function (find it by searching for the function signature: `static func animate_float`)

**New Function:**
```gdscript
static func animate_float(source_node: Node, target: Control, duration: float = 2.0, repeat_count: int = -1, easing: int = Tween.EASE_OUT, float_distance: float = 10.0, auto_visible: bool = false, preserve_position: bool = false) -> Signal:
	if not source_node or not target:
		push_warning("UIAnimationUtils: Invalid source_node or target for animate_float")
		return Signal()
	
	if auto_visible:
		target.visible = true
	
	# Handle position preservation: use unified snapshot system
	var saved_position: Vector2 = Vector2.ZERO
	var using_unified_snapshot: bool = false
	
	if preserve_position:
		# Acquire unified snapshot (saves if first, increments counter)
		var snapshot = _acquire_unified_snapshot(source_node, target)
		if snapshot:
			saved_position = snapshot.position
			using_unified_snapshot = true
		else:
			# Fallback to current position if snapshot failed (null snapshot or acquisition failed)
			push_warning("UIAnimationUtils.animate_float(): Failed to acquire unified snapshot for target '%s', using current position" % target.name)
			saved_position = target.position
	else:
		# Not preserving position, use current position
		saved_position = target.position
	
	var animation_callable = func() -> Signal:
		var t = source_node.create_tween()
		if not t:
			push_warning("UIAnimationUtils: Failed to create tween")
			return Signal()
		
		# Use saved position (unified if preserving, otherwise current)
		var original_position = saved_position
		
		# Move up
		t.tween_property(target, 'position:y', original_position.y - float_distance, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(easing)
		# Move down
		t.tween_property(target, 'position:y', original_position.y, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(easing)
		
		return t.finished
	
	var result_signal = _loop_animation(source_node, target, animation_callable, repeat_count)
	
	# Connect to final completion to release unified snapshot
	if preserve_position and using_unified_snapshot:
		result_signal.connect(func(): 
			_release_unified_snapshot(target, true)
		, CONNECT_ONE_SHOT)
	
	return result_signal
```

**Key Changes:**
- Removed old `_saved_positions` dictionary usage
- Uses `_acquire_unified_snapshot()` instead
- Uses `_release_unified_snapshot()` for cleanup
- Removed manual dictionary manipulation

---

## PHASE 5: Update RESET Animation to Use Comprehensive Reset

### File: `scripts/utilities/animation_target.gd`

### Step 5.1: Update RESET Case to Use Comprehensive Reset
**Location:** In the `apply()` function's match statement (find it by searching for `match animation:`), replace the `RESET` case

**Current Code:**
```gdscript
		AnimationAction.RESET:
			UIAnimationUtils.reset_control_to_normal(control_target)
			return Signal()
```

**New Code:**
```gdscript
		AnimationAction.RESET:
			# Use comprehensive reset with duration=0 for instant reset
			# This resets all properties (position, scale, modulate, rotation, pivot_offset, visible)
			# using the unified snapshot system
			return UIAnimationUtils.animate_reset_all(owner, control_target, 0.0, tween_easing, true)
```

### Step 5.2: Update Other Animation Config Files

**File: `scripts/anim/animation_action_config.gd`**
- **Location:** In the execute function's match statement (find it by searching for the match statement that handles `AnimationAction.RESET`)
- **Action:** Replace RESET case:
```gdscript
		AnimationAction.RESET:
			# Use comprehensive reset with duration=0 for instant reset
			# This resets all properties using the unified snapshot system
			return UIAnimationUtils.animate_reset_all(owner, target, 0.0, 0, true)
```

**File: `scripts/utilities/animation_config.gd`**
- **Location:** In the execute/apply function's match statement (find it by searching for the match statement that handles `AnimationAction.RESET`)
- **Action:** Replace RESET case if it exists:
```gdscript
		AnimationAction.RESET:
			# Use comprehensive reset with duration=0 for instant reset
			# This resets all properties using the unified snapshot system
			return UIAnimationUtils.animate_reset_all(owner, target, 0.0, 0, true)
```

---

## PHASE 6: Extend Unified System to Other Property-Modifying Animations

### File: `scripts/anim/animation_utilities.gd`

### Step 6.1: Update animate_color_flash to Use Unified System
**Location:** Replace the entire `animate_color_flash` function (find it by searching for the function signature: `static func animate_color_flash`)

**Current Issue:** `animate_color_flash` uses metadata (`_original_modulate`) instead of unified system.

**Action:** Update to use unified snapshot system for consistency. This ensures color flash works with the comprehensive reset.

**New Implementation:**
```gdscript
static func animate_color_flash(source_node: Node, target: Control, flash_color: Color = Color.YELLOW, duration: float = 0.2, flash_intensity: float = 1.5, auto_visible: bool = false, easing: int = Tween.EASE_OUT) -> Signal:
	if not source_node or not target:
		push_warning("UIAnimationUtils: Invalid source_node or target for animate_color_flash")
		return Signal()
	
	if auto_visible:
		target.visible = true
	
	# Use unified snapshot system for consistency
	var snapshot = _acquire_unified_snapshot(source_node, target)
	var original_modulate: Color
	if snapshot:
		original_modulate = snapshot.modulate
	else:
		# Fallback to current modulate if snapshot failed (null snapshot or acquisition failed)
		push_warning("UIAnimationUtils.animate_color_flash(): Failed to acquire unified snapshot for target '%s', using current modulate" % target.name)
		original_modulate = target.modulate
	
	# Kill any existing tweens on modulate by creating a zero-duration tween
	# This interrupts any active flash animations before starting a new one
	var interrupt_tween = source_node.create_tween()
	if interrupt_tween:
		interrupt_tween.tween_property(target, "modulate", target.modulate, 0.0)
		interrupt_tween.kill()
	
	var flash_modulate = Color(
		flash_color.r * flash_intensity,
		flash_color.g * flash_intensity,
		flash_color.b * flash_intensity,
		original_modulate.a
	)
	
	var t = source_node.create_tween()
	if not t:
		push_warning("UIAnimationUtils: Failed to create tween")
		return Signal()
	
	# Flash to color
	t.tween_property(target, 'modulate', flash_modulate, duration * 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(easing)
	# Flash back to original (using the stored original from snapshot)
	t.tween_property(target, 'modulate', original_modulate, duration * 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(easing)
	
	# Connect to completion to release unified snapshot
	t.finished.connect(func(): 
		_release_unified_snapshot(target, true)
	, CONNECT_ONE_SHOT)
	
	return t.finished
```

**Key Changes:**
- Removed metadata-based `_original_modulate` storage
- Uses `_acquire_unified_snapshot()` for consistency
- Releases snapshot on completion
- Works seamlessly with comprehensive reset

### Step 6.2: Add Public Cleanup Function
**Location:** After `animate_reset_all` function

**New Function:**
```gdscript
## Manually clears the unified snapshot system for a target control.
## Useful for edge cases where animations are stopped manually or nodes are freed.
## This should be called if a control is removed from the scene while animations are active.
## [param target]: The control to clear unified snapshot for.
static func clear_unified_snapshot_for_target(target: Control) -> void:
	if not target:
		return
	
	_clear_unified_snapshot(target)
```

---

## PHASE 7: Handle Edge Cases

### File: `scripts/anim/animation_utilities.gd`

### Step 7.1: Update _loop_animation for Infinite Loops
**Location:** Check the `_loop_animation` function (find it by searching for `static func _loop_animation`)
**Action:** No changes needed - the unified snapshot system works with infinite loops because `_release_unified_snapshot` is only called when the animation signal completes, which for infinite loops happens when manually stopped.

### Step 7.2: Add Node Cleanup on Tree Exiting (Optional Enhancement)
**Location:** This would require adding a signal connection system, which may be complex. For now, manual cleanup via `clear_unified_snapshot_for_target()` is sufficient.

**Note:** If nodes are freed while animations are active, the dictionaries will contain stale references. This is acceptable as they will be garbage collected. For production, consider adding automatic cleanup via `tree_exiting` signal, but this is optional.

---

## PHASE 8: Testing and Verification

### Test Cases to Verify

#### Test 1: Single Animation with preserve_position=true
**Steps:**
1. Create a Control at position (100, 100), scale (1, 1), modulate white
2. Call `animate_shake` with `preserve_position=true`
3. Wait for animation to complete
4. **Expected:** Control returns to (100, 100), all other properties unchanged

#### Test 2: Overlapping Float Animations
**Steps:**
1. Create a Control at position (100, 100)
2. Call `animate_float` with `preserve_position=true`, `repeat_count=-1` (infinite)
3. Immediately call `animate_float` again with `preserve_position=true`
4. Stop both animations
5. **Expected:** Control returns to (100, 100), no drift

#### Test 3: Overlapping Shake and Float
**Steps:**
1. Create a Control at position (100, 100)
2. Call `animate_shake` with `preserve_position=true`
3. While shake is running, call `animate_float` with `preserve_position=true`
4. Wait for both to complete
5. **Expected:** Control returns to (100, 100), no drift

#### Test 4: Comprehensive Reset with Multiple Properties
**Steps:**
1. Create a Control at position (100, 100), scale (1, 1), modulate white, rotation 0
2. Call `animate_expand` (modifies scale)
3. Call `animate_rotate_in` (modifies rotation)
4. Call `animate_color_flash` (modifies modulate)
5. Call RESET animation (using AnimationTarget with RESET action)
6. **Expected:** All properties instantly restore to original values

#### Test 5: Animation Chain with RESET
**Steps:**
1. Create a Control at position (100, 100), scale (1, 1), modulate white
2. Call `animate_float` with `preserve_position=true`
3. Chain RESET animation after float (using AnimationTarget with RESET action)
4. **Expected:** Control instantly resets to original position, scale, color, rotation

#### Test 6: preserve_position=false (No Unified Snapshot)
**Steps:**
1. Create a Control at position (100, 100)
2. Call `animate_float` with `preserve_position=false`
3. **Expected:** Control can drift (old behavior maintained)

#### Test 7: Multiple Rapid Clicks (Stress Test)
**Steps:**
1. Create a Control at position (100, 100)
2. Rapidly click 10 times, each triggering `animate_shake` with `preserve_position=true`
3. Wait for all animations to complete
4. **Expected:** Control returns to (100, 100), counter properly managed

#### Test 8: Infinite Loop Animation
**Steps:**
1. Create a Control at position (100, 100)
2. Call `animate_float` with `preserve_position=true`, `repeat_count=-1`
3. Let it run for 5 seconds
4. Manually stop the animation (if possible) or let it continue
5. **Expected:** Unified snapshot remains locked until animation stops

#### Test 9: Color Flash with Reset
**Steps:**
1. Create a Control with modulate Color.WHITE
2. Call `animate_color_flash` (flashes to yellow, then back)
3. Call RESET animation immediately after (using AnimationTarget with RESET action)
4. **Expected:** Modulate instantly returns to original white color

#### Test 10: Multiple Property Modifications
**Steps:**
1. Create a Control at position (100, 100), scale (1, 1), modulate white, rotation 0
2. Call `animate_expand` (changes scale)
3. While expanding, call `animate_rotate_in` (changes rotation)
4. While rotating, call `animate_color_flash` (changes modulate)
5. Call RESET animation (using AnimationTarget with RESET action)
6. **Expected:** All properties instantly restore to original values

---

## PHASE 9: Documentation Updates

### File: `scripts/anim/animation_utilities.gd`

### Step 9.1: Update Function Documentation
**Location:** Update docstrings for `animate_shake` and `animate_float`

**For animate_shake:**
Find the function documentation block (the comment block immediately before `static func animate_shake`) and add to it:
```
## Note: When preserve_position=true, this function uses a unified snapshot system.
## Multiple overlapping animations will share the same original state reference,
## ensuring the control returns to its starting state when all animations complete.
```

**For animate_float:**
Find the function documentation block (the comment block immediately before `static func animate_float`) and add to it:
```
## Note: When preserve_position=true, this function uses a unified snapshot system.
## Multiple overlapping animations will share the same original state reference,
## ensuring the control returns to its starting state when all animations complete.
```

### Step 9.2: Document animate_reset_all
**Location:** The function already has documentation, ensure it's complete (see Phase 2)

### Step 9.3: Update reset_control_to_normal Documentation
**Location:** Find the function documentation block (the comment block immediately before `static func reset_control_to_normal`)

**Current:**
```gdscript
## Resets a control to "normal" state (scale=1, modulate.a=1, rotation=0).
## Does not reset position as that is usually intentional.
```

**New:**
```gdscript
## Resets a control to "normal" state (scale=1, modulate.a=1, rotation=0).
## Does not reset position as that is usually intentional.
## NOTE: This function is no longer used by the RESET animation action.
## The RESET animation action now uses animate_reset_all() with duration=0
## for comprehensive reset of all properties including position.
## This function may still be used elsewhere in the codebase.
```

---

## Implementation Order Summary

1. **Phase 1:** Replace position system with unified snapshot infrastructure
2. **Phase 2:** Create `animate_reset_all` function
3. **Phase 3:** Refactor `animate_shake` to use unified system
4. **Phase 4:** Refactor `animate_float` to use unified system
5. **Phase 5:** Update RESET to use comprehensive reset (duration=0)
6. **Phase 6:** Extend unified system to color flash (optional but recommended)
7. **Phase 7:** Handle edge cases
8. **Phase 8:** Test thoroughly
9. **Phase 9:** Update documentation

---

## Estimated Implementation Time

- Phase 1: 45 minutes (infrastructure replacement)
- Phase 2: 30 minutes (comprehensive reset function)
- Phase 3: 20 minutes (refactor shake)
- Phase 4: 20 minutes (refactor float)
- Phase 5: 15 minutes (RESET case updates)
- Phase 6: 30 minutes (color flash update)
- Phase 7: 15 minutes (edge cases)
- Phase 8: 90 minutes (comprehensive testing)
- Phase 9: 20 minutes (documentation)

**Total: ~4.5 hours**

---

## Key Benefits of This Refactor

1. **No Positional Drift:** Unified snapshot ensures all animations reference the same original state
2. **Comprehensive Reset:** RESET animation now restores all properties (position, scale, modulate, rotation, pivot_offset, visible)
3. **Consistent System:** All property-modifying animations can use the same unified system
4. **Clean Codebase:** No legacy code, no backward compatibility cruft
5. **Future-Proof:** Easy to extend to other property-modifying animations
6. **User Control:** Users can choose to use reset animation or let properties drift

---

## Migration Notes

- All existing code calling `animate_shake` and `animate_float` will continue to work
- The `preserve_position` parameter behavior is enhanced but API-compatible
- **RESET animation behavior changed:** Now performs comprehensive reset of all properties (position, scale, modulate, rotation, pivot_offset, visible) instead of just scale, modulate.a, and rotation. Uses unified snapshot system.
- `_saved_positions` dictionary is completely removed
- `reset_control_to_normal()` function exists but RESET animation no longer uses it (uses `animate_reset_all()` instead)
- No migration needed for existing code - API remains compatible, but RESET behavior is enhanced

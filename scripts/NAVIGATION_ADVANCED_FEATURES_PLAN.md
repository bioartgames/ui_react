t t t## Navigation Advanced Features – Implementation Plan

This document defines a **concrete, phased plan** for implementing the two advanced navigation features that are currently exported but not implemented:

1. **`auto_disable_child_focus`** – Automatically disables focus on children of `root_control`
2. **`respect_custom_neighbors`** – Respects Godot's `focus_neighbor_*` properties for custom navigation paths

The plan follows existing patterns used by `ReactiveUINavigator`, `NavigationConfig`, `NavigationUtils`, and `UIAnimationUtils`.

---

## Phase 0 – Scope, Goals, and Constraints

### 0.1 Goals

- **Complete `auto_disable_child_focus` implementation**:
  - When enabled, automatically disable focus on all children of `root_control` during `_ready()`
  - Reuse existing `UIAnimationUtils.disable_focus_on_children()` function
  - Add editor validation to ensure `root_control` is set when this option is enabled
  - Keep navigation "flat" (only top-level controls are focusable)

- **Implement `respect_custom_neighbors` feature**:
  - When enabled, check Control's `focus_neighbor_*` properties before using automatic navigation
  - Custom neighbors take priority over ordered controls and position-based heuristics
  - Add utility functions to `NavigationUtils` for reusable logic
  - Add editor validation for custom neighbor paths
  - Support all four directions (top, bottom, left, right)

### 0.2 Non-Goals

- **No changes to existing navigation behavior** when features are disabled (backward compatible)
- **No new dependencies** – reuse existing utilities and patterns
- **No performance optimizations** beyond what's necessary (custom neighbor check is O(1))
- **No UI for configuring custom neighbors** – uses Godot's built-in Inspector properties

### 0.3 Design Principles

- **Single Responsibility Principle**: Each utility function has one clear purpose
- **Open/Closed Principle**: Features extend behavior via config flags, not code changes
- **DRY**: Reuse existing `UIAnimationUtils.disable_focus_on_children()` function
- **Consistency**: Follow existing patterns in `NavigationUtils` and `ReactiveUINavigator`

### 0.4 Files to Modify

The following files will be modified:

- **Navigation utilities**:
  - `scripts/utilities/navigation_utils.gd` – Add custom neighbor utility functions

- **Navigation navigator**:
  - `scripts/reactive/reactive_ui_navigator.gd` – Integrate both features

- **Documentation**:
  - `docs/NAVIGATION_SYSTEM.md` – Update with feature documentation

---

## Phase 1 – Implement `auto_disable_child_focus` Feature

**Objective**: Complete the implementation of `auto_disable_child_focus` by integrating the existing utility function and adding validation.

### 1.1 Integrate `UIAnimationUtils.disable_focus_on_children()` in `_ready()`

**File**: `scripts/reactive/reactive_ui_navigator.gd`

**Location**: Lines 99-102 (in `_ready()` method)

**Task**: Replace the TODO placeholder with actual implementation

- [ ] **1.1.1** Locate the TODO comment at lines 99-102
- [ ] **1.1.2** Replace the placeholder code with:
  ```gdscript
  # Optionally apply auto_disable_child_focus
  if nav_config and nav_config.auto_disable_child_focus and root_control:
      UIAnimationUtils.disable_focus_on_children(root_control)
  ```
- [ ] **1.1.3** Verify the import/class reference is available (should be automatic in Godot)
- [ ] **1.1.4** Test that the code compiles without errors

**Acceptance Criteria**:
- Code compiles successfully
- No runtime errors when `auto_disable_child_focus` is enabled
- Children of `root_control` have `focus_mode` set to `FOCUS_NONE` after `_ready()`

### 1.2 Add Editor Validation for `auto_disable_child_focus`

**File**: `scripts/reactive/reactive_ui_navigator.gd`

**Location**: In `_validate_nav_config()` method (after line 153)

**Task**: Add validation warning when `auto_disable_child_focus` is enabled but `root_control` is not set

- [ ] **1.2.1** Locate the `_validate_nav_config()` method
- [ ] **1.2.2** Find the end of existing validation checks (after `ordered_controls` validation)
- [ ] **1.2.3** Add the following validation code:
  ```gdscript
  # Check auto_disable_child_focus requires root_control
  if nav_config.auto_disable_child_focus:
      if not nav_config.root_control or nav_config.root_control.is_empty():
          push_warning("ReactiveUINavigator: auto_disable_child_focus requires root_control to be set")
  ```
- [ ] **1.2.4** Verify the warning appears in the editor when condition is met

**Acceptance Criteria**:
- Warning appears in editor output when `auto_disable_child_focus` is true and `root_control` is empty
- No warning appears when `root_control` is set
- Validation only runs in editor (uses `Engine.is_editor_hint()` check)

### 1.3 Test `auto_disable_child_focus` Feature

**Task**: Create test scenario and verify functionality

- [ ] **1.3.1** Create a test scene with:
  - A `ReactiveUINavigator` node
  - A `NavigationConfig` resource with `root_control` set to a container
  - Multiple child controls within the container
  - `auto_disable_child_focus` set to `true`
- [ ] **1.3.2** Run the scene and verify:
  - Children of `root_control` have `focus_mode == FOCUS_NONE`
  - `root_control` itself can still receive focus (if it's a Control)
  - Navigation only works on top-level controls
- [ ] **1.3.3** Test with `auto_disable_child_focus` set to `false`:
  - Children retain their original `focus_mode` values
  - Navigation works normally

**Acceptance Criteria**:
- Feature works as expected when enabled
- Feature does not affect behavior when disabled
- No regressions in existing navigation functionality

---

## Phase 2 – Add Custom Neighbor Utility Functions

**Objective**: Add reusable utility functions to `NavigationUtils` for working with custom focus neighbors.

### 2.1 Add `get_custom_focus_neighbor()` Function

**File**: `scripts/utilities/navigation_utils.gd`

**Location**: After existing functions (after `find_closest_in_direction()`)

**Task**: Implement function to get custom focus neighbor for a direction

- [ ] **2.1.1** Open `scripts/utilities/navigation_utils.gd`
- [ ] **2.1.2** Locate the end of the `find_closest_in_direction()` function
- [ ] **2.1.3** Add the following function:
  ```gdscript
  ## Gets the custom focus neighbor for a control in the given direction.
  ## Returns the control specified by focus_neighbor_* properties, or null if not set.
  ## [param control]: The control to get neighbor for.
  ## [param direction]: Direction vector (normalized or not).
  ## [return]: The neighbor control, or null if not configured.
  static func get_custom_focus_neighbor(control: Control, direction: Vector2) -> Control:
      if not control:
          return null
      
      # Normalize direction to determine which neighbor property to check
      var normalized_dir = direction.normalized()
      var threshold = 0.5  # Threshold for diagonal detection
      
      # Determine primary direction (prioritize larger component)
      if abs(normalized_dir.y) > abs(normalized_dir.x):
          # Vertical movement
          if normalized_dir.y < -threshold:  # Up
              return control.get_focus_neighbor(Control.FOCUS_TOP) as Control
          elif normalized_dir.y > threshold:  # Down
              return control.get_focus_neighbor(Control.FOCUS_BOTTOM) as Control
      else:
          # Horizontal movement
          if normalized_dir.x < -threshold:  # Left
              return control.get_focus_neighbor(Control.FOCUS_LEFT) as Control
          elif normalized_dir.x > threshold:  # Right
              return control.get_focus_neighbor(Control.FOCUS_RIGHT) as Control
      
      return null
  ```
- [ ] **2.1.4** Verify the function compiles without errors
- [ ] **2.1.5** Test the function with various direction vectors:
  - `Vector2.UP` → should check `FOCUS_TOP`
  - `Vector2.DOWN` → should check `FOCUS_BOTTOM`
  - `Vector2.LEFT` → should check `FOCUS_LEFT`
  - `Vector2.RIGHT` → should check `FOCUS_RIGHT`
  - `Vector2(0.7, 0.3)` → should prioritize horizontal (RIGHT)
  - `Vector2(0.3, 0.7)` → should prioritize vertical (DOWN)

**Acceptance Criteria**:
- Function compiles successfully
- Returns correct neighbor for each direction
- Returns `null` when no neighbor is set
- Handles `null` control input gracefully

### 2.2 Add `has_custom_focus_neighbors()` Function

**File**: `scripts/utilities/navigation_utils.gd`

**Location**: After `get_custom_focus_neighbor()` function

**Task**: Implement function to check if a control has any custom neighbors configured

- [ ] **2.2.1** Locate the end of `get_custom_focus_neighbor()` function
- [ ] **2.2.2** Add the following function:
  ```gdscript
  ## Checks if a control has custom focus neighbors configured.
  ## [param control]: The control to check.
  ## [return]: true if any focus_neighbor_* property is set.
  static func has_custom_focus_neighbors(control: Control) -> bool:
      if not control:
          return false
      
      # Check all four directions
      return (
          control.get_focus_neighbor(Control.FOCUS_TOP) != null or
          control.get_focus_neighbor(Control.FOCUS_BOTTOM) != null or
          control.get_focus_neighbor(Control.FOCUS_LEFT) != null or
          control.get_focus_neighbor(Control.FOCUS_RIGHT) != null
      )
  ```
- [ ] **2.2.3** Verify the function compiles without errors
- [ ] **2.2.4** Test the function:
  - Returns `false` for control with no neighbors set
  - Returns `true` when any neighbor is set
  - Returns `false` for `null` input

**Acceptance Criteria**:
- Function compiles successfully
- Correctly detects when neighbors are configured
- Returns `false` for controls without custom neighbors
- Handles `null` input gracefully

### 2.3 Test Utility Functions

**Task**: Create unit tests or manual verification of utility functions

- [ ] **2.3.1** Create a test scene with controls that have custom neighbors set
- [ ] **2.3.2** Test `get_custom_focus_neighbor()`:
  - Set `focus_neighbor_bottom` on a button
  - Call function with `Vector2.DOWN`
  - Verify it returns the correct neighbor control
- [ ] **2.3.3** Test `has_custom_focus_neighbors()`:
  - Check control without neighbors → returns `false`
  - Set a neighbor → returns `true`
  - Clear neighbor → returns `false`

**Acceptance Criteria**:
- Both utility functions work correctly
- Functions handle edge cases (null, empty, etc.)
- No errors or warnings in console

---

## Phase 3 – Integrate Custom Neighbors into Navigation Logic

**Objective**: Modify `_find_next_focusable_control()` to check custom neighbors when `respect_custom_neighbors` is enabled.

### 3.1 Modify `_find_next_focusable_control()` Method

**File**: `scripts/reactive/reactive_ui_navigator.gd`

**Location**: Lines 576-591 (the `_find_next_focusable_control()` method)

**Task**: Add custom neighbor check at the beginning of the method

- [ ] **3.1.1** Locate the `_find_next_focusable_control()` method
- [ ] **3.1.2** Find the current implementation (starts around line 577)
- [ ] **3.1.3** Replace the method with the following implementation:
  ```gdscript
  ## Finds the next focusable control in the given direction.
  func _find_next_focusable_control(direction: Vector2) -> Control:
      if not _current_focus_owner or not nav_config:
          return null

      # Check custom neighbors first if enabled
      if nav_config.respect_custom_neighbors and _current_focus_owner:
          var custom_neighbor = NavigationUtils.get_custom_focus_neighbor(_current_focus_owner, direction)
          if custom_neighbor:
              # Validate the custom neighbor is within scope and visible
              if _is_control_visible(custom_neighbor):
                  var candidates = _get_focusable_candidates()
                  if custom_neighbor in candidates:
                      return custom_neighbor
                  # If not in candidates but is valid, still allow it
                  # (custom neighbors can override scope restrictions)
                  if custom_neighbor.focus_mode != Control.FOCUS_NONE:
                      return custom_neighbor

      var candidates = _get_focusable_candidates()

      if candidates.is_empty():
          return null

      # If ordered controls are specified, use that logic
      if not nav_config.ordered_controls.is_empty():
          return _find_next_in_ordered_list(direction)

      # Otherwise use directional heuristics
      return _find_next_by_position(direction, candidates)
  ```
- [ ] **3.1.4** Verify the code compiles without errors
- [ ] **3.1.5** Verify imports are correct (NavigationUtils should be available)

**Acceptance Criteria**:
- Code compiles successfully
- Method signature remains unchanged (backward compatible)
- Custom neighbor check happens before other navigation logic
- Falls back to existing logic when custom neighbor is not set

### 3.2 Test Custom Neighbor Integration

**Task**: Create test scenarios to verify custom neighbors work correctly

- [ ] **3.2.1** Create a test scene with:
  - A `ReactiveUINavigator` node
  - A `NavigationConfig` with `respect_custom_neighbors = true`
  - Multiple buttons arranged in a layout
  - Set `focus_neighbor_bottom` on Button1 to point to Button3 (skipping Button2)
- [ ] **3.2.2** Test navigation:
  - Focus Button1
  - Press down arrow
  - Verify focus moves to Button3 (not Button2)
- [ ] **3.2.3** Test with `respect_custom_neighbors = false`:
  - Same scene, but feature disabled
  - Verify focus moves to Button2 (normal behavior)
- [ ] **3.2.4** Test custom neighbor outside scope:
  - Set a custom neighbor that's outside `root_control`
  - Verify it still works (custom neighbors override scope)
- [ ] **3.2.5** Test with ordered controls:
  - Set up `ordered_controls` array
  - Set a custom neighbor that's not in the ordered list
  - Verify custom neighbor takes priority

**Acceptance Criteria**:
- Custom neighbors work correctly when enabled
- Custom neighbors take priority over ordered controls
- Custom neighbors take priority over position-based navigation
- Feature does not affect behavior when disabled
- Custom neighbors can override scope restrictions

---

## Phase 4 – Add Editor Validation for Custom Neighbors

**Objective**: Add validation warnings in the editor for invalid custom neighbor paths.

### 4.1 Add Helper Method `_focus_dir_to_string()`

**File**: `scripts/reactive/reactive_ui_navigator.gd`

**Location**: After `_validate_nav_config()` method (around line 160)

**Task**: Add helper method to convert focus direction enum to string

- [ ] **4.1.1** Locate the end of `_validate_nav_config()` method
- [ ] **4.1.2** Add the following helper method:
  ```gdscript
  ## Helper to convert focus direction enum to string for warnings.
  func _focus_dir_to_string(dir: int) -> String:
      match dir:
          Control.FOCUS_TOP: return "top"
          Control.FOCUS_BOTTOM: return "bottom"
          Control.FOCUS_LEFT: return "left"
          Control.FOCUS_RIGHT: return "right"
          _: return "unknown"
  ```
- [ ] **4.1.3** Verify the method compiles without errors

**Acceptance Criteria**:
- Method compiles successfully
- Returns correct string for each direction enum
- Handles unknown enum values gracefully

### 4.2 Add Custom Neighbor Validation to `_validate_nav_config()`

**File**: `scripts/reactive/reactive_ui_navigator.gd`

**Location**: In `_validate_nav_config()` method (after existing validations)

**Task**: Add validation for custom neighbors when feature is enabled

- [ ] **4.2.1** Locate the `_validate_nav_config()` method
- [ ] **4.2.2** Find where to add new validation (after `ordered_controls` validation, before method end)
- [ ] **4.2.3** Add the following validation code:
  ```gdscript
  # Validate custom neighbors if enabled
  if nav_config.respect_custom_neighbors:
      # Check if root_control has custom neighbors (if it's a Control)
      if nav_config.root_control:
          var root_node = get_node_or_null(nav_config.root_control)
          if root_node is Control:
              var root_control = root_node as Control
              if NavigationUtils.has_custom_focus_neighbors(root_control):
                  # Validate each neighbor exists and is a Control
                  for focus_dir in [Control.FOCUS_TOP, Control.FOCUS_BOTTOM, Control.FOCUS_LEFT, Control.FOCUS_RIGHT]:
                      var neighbor_path = root_control.get_focus_neighbor(focus_dir)
                      if neighbor_path:
                          var neighbor = get_node_or_null(neighbor_path)
                          if not neighbor:
                              push_warning("ReactiveUINavigator: focus_neighbor_%s path '%s' does not exist" % [
                                  _focus_dir_to_string(focus_dir), neighbor_path
                              ])
                          elif not (neighbor is Control):
                              push_warning("ReactiveUINavigator: focus_neighbor_%s must point to a Control node, got %s" % [
                                  _focus_dir_to_string(focus_dir), neighbor.get_class()
                              ])
      
      # Also check default_focus if it's a Control with custom neighbors
      if nav_config.default_focus:
          var default_node = get_node_or_null(nav_config.default_focus)
          if default_node is Control:
              var default_control = default_node as Control
              if NavigationUtils.has_custom_focus_neighbors(default_control):
                  for focus_dir in [Control.FOCUS_TOP, Control.FOCUS_BOTTOM, Control.FOCUS_LEFT, Control.FOCUS_RIGHT]:
                      var neighbor_path = default_control.get_focus_neighbor(focus_dir)
                      if neighbor_path:
                          var neighbor = get_node_or_null(neighbor_path)
                          if not neighbor:
                              push_warning("ReactiveUINavigator: default_focus has invalid focus_neighbor_%s path '%s'" % [
                                  _focus_dir_to_string(focus_dir), neighbor_path
                              ])
                          elif not (neighbor is Control):
                              push_warning("ReactiveUINavigator: default_focus has invalid focus_neighbor_%s type (got %s)" % [
                                  _focus_dir_to_string(focus_dir), neighbor.get_class()
                              ])
  ```
- [ ] **4.2.4** Verify the code compiles without errors
- [ ] **4.2.5** Test validation in editor:
  - Set an invalid neighbor path → should show warning
  - Set a valid neighbor path → should show no warning
  - Set neighbor to non-Control node → should show warning

**Acceptance Criteria**:
- Code compiles successfully
- Warnings appear in editor when custom neighbors are invalid
- No warnings appear when custom neighbors are valid
- Validation only runs in editor (uses existing `Engine.is_editor_hint()` check)
- Validation checks both `root_control` and `default_focus` if they have custom neighbors

### 4.3 Test Editor Validation

**Task**: Verify validation warnings appear correctly

- [ ] **4.3.1** Create a test scene with invalid custom neighbor paths
- [ ] **4.3.2** Enable `respect_custom_neighbors` in NavigationConfig
- [ ] **4.3.3** Verify warnings appear in editor output:
  - Invalid path → warning shows
  - Non-Control node → warning shows
  - Valid path → no warning
- [ ] **4.3.4** Test with `respect_custom_neighbors = false`:
  - No validation should run
  - No warnings should appear

**Acceptance Criteria**:
- Validation warnings appear correctly
- Warnings are clear and actionable
- No false positives
- Validation only runs when feature is enabled

---

## Phase 5 – Update Documentation

**Objective**: Update the navigation system documentation to include both new features.

### 5.1 Update Configuration Options Table

**File**: `docs/NAVIGATION_SYSTEM.md`

**Location**: In "Configuration Options" section, "NavigationConfig" table (around line 72)

**Task**: Update the table to include descriptions for the new features

- [ ] **5.1.1** Locate the NavigationConfig table in the documentation
- [ ] **5.1.2** Find the row for `respect_custom_neighbors` (should already exist but may have placeholder text)
- [ ] **5.1.3** Update the description to:
  ```
  | `respect_custom_neighbors` | When true, uses Control's focus_neighbor_* properties for navigation. Custom neighbors take priority over automatic navigation (ordered controls and position-based heuristics). |
  ```
- [ ] **5.1.4** Find the row for `auto_disable_child_focus`
- [ ] **5.1.5** Update the description to:
  ```
  | `auto_disable_child_focus` | When true, disables focus on all children of root_control during initialization, keeping navigation flat. Useful for tab containers where only top-level items should be focusable. |
  ```

**Acceptance Criteria**:
- Table entries are updated with accurate descriptions
- Descriptions are clear and concise
- Formatting matches existing table style

### 5.2 Add Custom Neighbors Section

**File**: `docs/NAVIGATION_SYSTEM.md`

**Location**: After "Navigation Behaviors" section (around line 122)

**Task**: Add a new section explaining custom neighbors feature

- [ ] **5.2.1** Locate the end of "Navigation Behaviors" section
- [ ] **5.2.2** Add a new section:
  ```markdown
  ### Custom Focus Neighbors

  When `respect_custom_neighbors` is enabled, the navigator will check each control's `focus_neighbor_*` properties before using automatic navigation. This allows you to:

  - Override automatic navigation for specific controls
  - Create custom navigation paths (e.g., skip intermediate controls)
  - Define navigation that doesn't follow visual layout
  - Override scope restrictions (custom neighbors can point outside `root_control`)

  **Priority Order:**
  1. Custom neighbors (if `respect_custom_neighbors` is enabled)
  2. Ordered controls (if `ordered_controls` array is set)
  3. Position-based heuristics (default)

  **Example:**
  ```gdscript
  # In Godot editor, set focus_neighbor_bottom on Button1 to point to Button3
  # This skips Button2 when navigating down from Button1
  button1.focus_neighbor_bottom = NodePath("../Button3")
  
  # Configure navigator to respect custom neighbors
  config.respect_custom_neighbors = true
  ```

  **Note:** Custom neighbors are validated in the editor and must point to valid Control nodes. Invalid paths will show warnings.
  ```
- [ ] **5.2.3** Verify formatting is correct
- [ ] **5.2.4** Verify code example is accurate

**Acceptance Criteria**:
- Section is added with clear explanation
- Examples are accurate and helpful
- Formatting matches existing documentation style
- Priority order is clearly explained

### 5.3 Add Auto-Disable Child Focus Section

**File**: `docs/NAVIGATION_SYSTEM.md`

**Location**: After "Custom Focus Neighbors" section

**Task**: Add a new section explaining auto-disable child focus feature

- [ ] **5.3.1** Locate the end of "Custom Focus Neighbors" section
- [ ] **5.3.2** Add a new section:
  ```markdown
  ### Auto-Disable Child Focus

  When `auto_disable_child_focus` is enabled, the navigator automatically sets `focus_mode = FOCUS_NONE` on all children of `root_control` during initialization. This creates a "flat" navigation structure where only top-level controls are focusable.

  **Use Cases:**
  - Tab containers where you want to navigate between tabs, not their contents
  - Panel containers where only the panel itself should be focusable
  - Complex nested UIs where you want to restrict navigation scope

  **Example:**
  ```gdscript
  # Configure for tab container navigation
  config.root_control = NodePath("../TabContainer")
  config.auto_disable_child_focus = true
  
  # Now only the tab buttons are focusable, not the tab content panels
  ```

  **Note:** This feature requires `root_control` to be set. A warning will appear in the editor if `root_control` is not set when this option is enabled.
  ```
- [ ] **5.3.3** Verify formatting is correct
- [ ] **5.3.4** Verify examples are accurate

**Acceptance Criteria**:
- Section is added with clear explanation
- Use cases are helpful
- Examples are accurate
- Formatting matches existing documentation style

### 5.4 Update Troubleshooting Section

**File**: `docs/NAVIGATION_SYSTEM.md`

**Location**: In "Troubleshooting" section (around line 228)

**Task**: Add troubleshooting tips for the new features

- [ ] **5.4.1** Locate the "Troubleshooting" section
- [ ] **5.4.2** Find the "Common Issues" subsection
- [ ] **5.4.3** Add new troubleshooting items:
  ```markdown
  4. **Custom neighbors not working**
     - Verify `respect_custom_neighbors` is enabled in NavigationConfig
     - Check that `focus_neighbor_*` properties are set correctly in Inspector
     - Verify neighbor paths point to valid Control nodes
     - Check editor warnings for invalid paths

  5. **Children still focusable with auto_disable_child_focus enabled**
     - Verify `root_control` is set correctly
     - Check that children are direct descendants of `root_control`
     - Ensure `auto_disable_child_focus` is enabled in NavigationConfig
     - Check editor warnings for missing `root_control`
  ```
- [ ] **5.4.4** Verify formatting matches existing troubleshooting items

**Acceptance Criteria**:
- Troubleshooting items are added
- Items are clear and actionable
- Formatting matches existing style

---

## Phase 6 – Integration Testing

**Objective**: Test both features together and verify no regressions.

### 6.1 Test Feature Interaction

**Task**: Test scenarios where both features are used together

- [ ] **6.1.1** Create a test scene with:
  - `auto_disable_child_focus = true`
  - `respect_custom_neighbors = true`
  - Custom neighbors set on some controls
- [ ] **6.1.2** Verify:
  - Children are disabled correctly
  - Custom neighbors still work
  - No conflicts between features
- [ ] **6.1.3** Test edge case:
  - Custom neighbor points to a disabled child
  - Verify behavior (should still work, as custom neighbors override restrictions)

**Acceptance Criteria**:
- Both features work together correctly
- No conflicts or unexpected behavior
- Edge cases are handled gracefully

### 6.2 Regression Testing

**Task**: Verify existing navigation functionality still works

- [ ] **6.2.1** Test with both features disabled:
  - Ordered controls navigation
  - Position-based navigation
  - Default focus behavior
  - Submit/cancel actions
- [ ] **6.2.2** Test with only `auto_disable_child_focus` enabled:
  - Verify existing navigation still works
  - Verify children are disabled
- [ ] **6.2.3** Test with only `respect_custom_neighbors` enabled:
  - Verify existing navigation still works
  - Verify custom neighbors work
- [ ] **6.2.4** Test all navigation modes:
  - INPUT_MAP mode
  - STATE_DRIVEN mode
  - BOTH mode (if applicable)

**Acceptance Criteria**:
- No regressions in existing functionality
- All navigation modes work correctly
- Features work independently and together

### 6.3 Performance Testing

**Task**: Verify no significant performance impact

- [ ] **6.3.1** Test with large UI (100+ controls):
  - Measure navigation performance
  - Check for any slowdowns
- [ ] **6.3.2** Test custom neighbor lookup:
  - Should be O(1) operation
  - No noticeable delay
- [ ] **6.3.3** Test `auto_disable_child_focus` initialization:
  - Should complete quickly even with many children
  - No frame drops during `_ready()`

**Acceptance Criteria**:
- No significant performance impact
- Custom neighbor lookup is fast
- Initialization completes quickly

---

## Phase 7 – Final Review and Cleanup

**Objective**: Review implementation, clean up code, and ensure consistency.

### 7.1 Code Review

**Task**: Review all changes for consistency and quality

- [ ] **7.1.1** Review `navigation_utils.gd` changes:
  - Functions follow existing patterns
  - Documentation is complete
  - Error handling is appropriate
- [ ] **7.1.2** Review `reactive_ui_navigator.gd` changes:
  - Integration follows existing patterns
  - Validation is consistent
  - Code is readable and maintainable
- [ ] **7.1.3** Check for code duplication:
  - No repeated logic
  - Utilities are reused where appropriate
- [ ] **7.1.4** Verify naming conventions:
  - Function names are clear
  - Variable names are descriptive
  - Matches existing codebase style

**Acceptance Criteria**:
- Code follows project patterns
- No code duplication
- Naming is consistent
- Code is maintainable

### 7.2 Documentation Review

**Task**: Review documentation for accuracy and completeness

- [ ] **7.2.1** Review `NAVIGATION_SYSTEM.md` updates:
  - Information is accurate
  - Examples work correctly
  - Formatting is consistent
- [ ] **7.2.2** Check for missing information:
  - All features are documented
  - Edge cases are mentioned
  - Troubleshooting covers common issues
- [ ] **7.2.3** Verify code examples:
  - Examples compile
  - Examples demonstrate features correctly

**Acceptance Criteria**:
- Documentation is complete and accurate
- Examples are correct
- No missing information

### 7.3 Final Testing

**Task**: Run comprehensive final tests

- [ ] **7.3.1** Run all test scenarios from previous phases
- [ ] **7.3.2** Test in different Godot versions (if applicable)
- [ ] **7.3.3** Test with various UI layouts:
  - Simple layouts
  - Complex nested layouts
  - Dynamic UI changes
- [ ] **7.3.4** Verify no console errors or warnings (except expected validation warnings)

**Acceptance Criteria**:
- All tests pass
- No unexpected errors or warnings
- Features work in various scenarios

---

## Completion Checklist

Use this checklist to track overall progress:

### Phase 1 – `auto_disable_child_focus` Feature
- [ ] All tasks in Phase 1 completed
- [ ] Feature works correctly
- [ ] Validation works correctly
- [ ] Tests pass

### Phase 2 – Custom Neighbor Utilities
- [ ] All tasks in Phase 2 completed
- [ ] Utility functions work correctly
- [ ] Tests pass

### Phase 3 – Custom Neighbor Integration
- [ ] All tasks in Phase 3 completed
- [ ] Integration works correctly
- [ ] Tests pass

### Phase 4 – Editor Validation
- [ ] All tasks in Phase 4 completed
- [ ] Validation works correctly
- [ ] Tests pass

### Phase 5 – Documentation
- [ ] All tasks in Phase 5 completed
- [ ] Documentation is complete
- [ ] Examples are accurate

### Phase 6 – Integration Testing
- [ ] All tasks in Phase 6 completed
- [ ] All tests pass
- [ ] No regressions

### Phase 7 – Final Review
- [ ] All tasks in Phase 7 completed
- [ ] Code review complete
- [ ] Documentation review complete
- [ ] Final tests pass

---

## Notes

- All code changes should maintain backward compatibility
- Features should be opt-in (disabled by default)
- Validation warnings should be helpful and actionable
- Performance should not be significantly impacted
- Code should follow existing project patterns and style

---

**Last Updated**: [Date when plan is created]
**Status**: In Progress
**Current Phase**: Phase 0


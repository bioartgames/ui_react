## ReactiveGridContainer – Design & Implementation Plan

This document defines a **concrete, phased plan** for adding a `ReactiveGridContainer` control that follows existing patterns used by the `reactive_*` controls and the navigation/animation systems.

The plan is **design-only**; no code is implemented yet.

---

## Phase 0 – Scope, Goals, and Constraints

### 0.1 Goals

- **Add** a `ReactiveGridContainer` control that:
  - Extends Godot’s `GridContainer`.
  - Binds its **contents and selection** to `State` resources.
  - Is suitable for inventory/equipment style UIs (grids of items/slots).
  - Integrates with:
	- The **reactive state system** (`State` resources).
	- The **animation system** (`AnimationReel`, `AnimationClip`, triggers, control type hints).
	- The existing **navigation system** (`ReactiveUINavigator`, `NavigationConfig`, etc.) for controller/keyboard navigation.
  - Matches the semantics of other reactive controls (`ReactiveItemList`, `ReactiveTabContainer`) as closely as possible.

### 0.2 Non‑Goals

- **No drag & drop** implementation:
  - Mouse-based “press–drag–drop” interactions are explicitly **out of scope**.
  - The focus is on **controller/keyboard navigation** and actions, not pointer dragging.
- No new generic collection/state system beyond what `State` already provides.
- No full “inventory logic” (stacking, weight, filters, etc.) – this is a **UI binding/control**, not game logic.

### 0.3 Controller Navigation vs Drag & Drop

- **Controller navigation** (what we care about):
  - Moving **focus/selection** between grid cells using d-pad, analog sticks, or keyboard arrows.
  - Confirm/cancel actions on the **currently focused** cell.
  - Optional “move/swap” operations initiated by button presses (e.g., select a source slot, move focus, choose a target slot, confirm to swap).
  - This is modeled as:
	- Focus management (handled by `ReactiveUINavigator` + Godot focus system).
	- Selection/command handling (slots reacting to `submit`/`cancel` commands).

- **Drag and drop** (what we do NOT care about here):
  - Click/press on a slot, **dragging** the pointer while holding a button, then releasing to drop.
  - Mouse-motion–based visual dragging of item icons.

Controller-based “move/swap” behavior is **not** considered drag & drop in this plan; it is treated as an optional higher-level interaction built on top of selection and navigation.

### 0.4 Files and Types to Introduce

The following new scripts/resources will be introduced:

- **Grid control**:
  - `scripts/reactive/reactive_grid_container.gd`
	- `@tool`
	- `extends GridContainer`
	- `class_name ReactiveGridContainer`

- **Grid configuration resource**:
  - `scripts/reactive/grid_container_config.gd`
	- `extends Resource`
	- `class_name GridContainerConfig`

- **Optional per-cell helper (if needed)**:
  - `scripts/reactive/reactive_grid_slot.gd`
	- `extends Control` (or `Button` depending on design)
	- `class_name ReactiveGridSlot`

No new animation utilities or state types are required; the grid will reuse the existing systems.

---

## Phase 1 – Data Model & Core Types ✅ **IMPLEMENTED**

**Objective**: Define the data model and core types for `ReactiveGridContainer` and its configuration, without implementing full behavior.

### 1.1 `GridContainerConfig` resource

Create `GridContainerConfig` to describe how the grid should render and behave:

- File: `scripts/reactive/grid_container_config.gd`
- Base:

```gdscript
extends Resource
class_name GridContainerConfig
```

- Exported properties (initial set):
  - `@export var cell_scene: PackedScene`
	- The scene to instantiate for each cell (e.g., an item slot).
	- Each instance is expected to conform to a simple “cell contract” (see Phase 2.3).
  - `@export var columns_override: int = 0`
	- `0` means use `GridContainer.columns`.
	- `> 0` allows the config to override the number of columns if desired.
  - `@export var allow_empty_cells: bool = true`
	- If false, cells are only created for actual items.
	- If true, grid can render empty slots up to a target size (see Phase 2.2).
  - `@export var target_cell_count: int = 0`
	- `0` means “size matches item count”.
	- `> 0` means pad with empty cells up to `target_cell_count`.

### 1.2 `ReactiveGridContainer` core API

Create the class skeleton:

```gdscript
@tool
extends GridContainer
class_name ReactiveGridContainer
```

Exported properties:

- `@export var items_state: State`
  - `items_state.value` is expected to be an `Array` (or `null`).
  - Each element represents one grid item “view model” (type defined in Phase 2).
  - The `State` itself is untyped (Variant-based) just like the rest of the system; this control
	MUST treat `items_state.value` as a read-only array of item descriptors and never attempt
	to enforce or mutate game logic (e.g., stacking rules) directly.
- `@export var selection_state: State`
  - Optional.
  - If present, holds the **selected index** (int) or `null` for “no selection”.
  - Future extension: support an `Array[int]` for multi-selection; initial version uses a single index.
- `@export var grid_config: GridContainerConfig`
  - Optional; if null, grid falls back to defaults (e.g., a hard-coded cell scene or error message).
- `@export var animations: Array[AnimationReel] = []`
  - Optional animation reels attached to the grid itself (e.g., grid-level hover, selection change).

Internal fields:

- `var _current_cells: Array[Control] = []`
  - Holds references to instantiated cell controls for indexing and cleanup.
- `var _is_initializing: bool = true`
  - Used to avoid firing certain reactions/animations during initial population.
- `var _suppress_state_updates: bool = false`
  - Guards against feedback loops when updating `selection_state` from grid events.

### 1.3 `ReactiveGridSlot` (optional cell helper)

Depending on how many behaviors we want to standardize per cell, introduce `ReactiveGridSlot`:

```gdscript
extends Control
class_name ReactiveGridSlot
```

Potential responsibilities (to be decided in Phase 2/3):

- Receive an “item view model” and render it (icon, name, stack count, etc.).
- Expose a simple API for:
  - `set_selected(is_selected: bool)`
  - `set_highlighted(is_highlighted: bool)`
  - `set_disabled(is_disabled: bool)`
- Optionally integrate with `AnimationReel` on the slot itself.

Alternatively, the project can decide that `cell_scene` needs only to expose a small set of signals/properties and not use a dedicated slot base class; this decision will be finalized in Phase 2.3.

---

## Phase 2 – Items Binding & Cell Instantiation ✅ **IMPLEMENTED**

**Objective**: Implement how `ReactiveGridContainer` binds to `items_state` and turns array data into instantiated cells.

### 2.1 Item “view model” contract

Define how each element in `items_state.value` is interpreted. For v1:

- `items_state.value` MUST be:
  - `null` or not an Array → treated as empty (`[]`).
  - `Array` → each element is an **item descriptor**.

- Each item descriptor can be:
  - A `Dictionary` with standard keys (recommended), e.g.:
	- `"id": Variant` (optional identifier).
	- `"icon": Texture2D` (optional).
	- `"name": String` (optional).
	- `"count": int` (optional).
	- `"disabled": bool` (optional).
  - A custom `Resource` (e.g., `ItemViewModel`) – allowed but interpreted via a helper function.

`ReactiveGridContainer` will not enforce a specific schema but **will**:

- Pass the item descriptor to each cell via a method or signal (e.g., `set_item(data: Variant)`).
- Treat `null` or missing entries as “empty slots” (depending on `allow_empty_cells` and `target_cell_count`).

### 2.2 Reacting to `items_state` changes

`ReactiveGridContainer` MUST:

- Implement `_ready()` following the pattern used by other reactive controls:
  - In editor mode (`Engine.is_editor_hint()`): Only call `_validate_animation_reels()` to enable trigger filtering in the Inspector.
  - At runtime: Connect to state signals, perform initial sync, validate animation reels, and schedule initialization completion.
- Connect to `items_state.value_changed` in `_ready()` when `items_state` is set.
- Implement `_on_items_state_changed(new_value: Variant, _old_value: Variant)`:
  - Normalize `new_value` to an `Array` using a helper `_normalize_items(value: Variant) -> Array`.
  - Rebuild the grid contents using `_rebuild_cells(items: Array)`.

Implementation sketch:

```gdscript
func _ready() -> void:
	if Engine.is_editor_hint():
		# In the editor, only validate reels so trigger options are filtered.
		_validate_animation_reels()
		return
	
	# Connect to items_state
	if items_state:
		items_state.value_changed.connect(_on_items_state_changed)
		_on_items_state_changed(items_state.value, items_state.value)
	
	# Connect to selection_state (if configured)
	if selection_state:
		selection_state.value_changed.connect(_on_selection_state_changed)
		_on_selection_state_changed(selection_state.value, selection_state.value)
	
	_validate_animation_reels()
	# Finish initialization after all signals are processed
	call_deferred("_finish_initialization")

func _on_items_state_changed(new_value: Variant, _old_value: Variant) -> void:
	var items := _normalize_items(new_value)
	_rebuild_cells(items)
	# Trigger VALUE_CHANGED animations if configured (after _is_initializing check)
	if not _is_initializing:
		_on_trigger_value_changed()
```

### 2.3 `_rebuild_cells` behavior

`_rebuild_cells(items: Array)` MUST:

- Clear existing cells:
  - Remove all child nodes created for previous items.
  - Clear `_current_cells`.
- Determine **target cell count**:
  - Start with `items.size()`.
  - If `grid_config` is set:
	- If `grid_config.target_cell_count > 0`, use `max(items.size(), grid_config.target_cell_count)`.
	- Else, use `items.size()`.
- For `i` in `0 .. target_cell_count - 1`:
  - Determine `item_data`:
	- If `i < items.size()`: `item_data = items[i]`.
	- Else: `item_data = null` (represents an empty slot).
  - Instantiate a cell via `_create_cell(item_data, i)` (see below).
  - Add as child of the grid and append to `_current_cells`.

`_create_cell(item_data: Variant, index: int) -> Control` MUST:

- Determine `cell_scene`:
  - Prefer `grid_config.cell_scene` if set.
  - Otherwise, log a warning and skip cell creation.
- Instantiate `cell_scene` and cast to `Control`.
- Set a standard interface on the cell:
  - If cell has method `set_item(data: Variant, index: int)`, call it.
  - If cell has method `set_selected(is_selected: bool)`, immediately set based on `selection_state` (see Phase 3.2).
- Optionally connect cell signals (e.g., `pressed`, `focus_entered`) for selection and animations (see Phase 3).

> **Implementation note (SRP / no game logic):**  
> `_rebuild_cells` and `_create_cell` MUST remain focused on **UI binding only**. They may
> instantiate cells, pass item descriptors, and wire signals, but they MUST NOT implement
> inventory rules (stacking, swapping, filtering, capacity checks, etc.). Game logic remains
> in higher-level systems that manipulate `items_state.value`.

### 2.4 Handling null or invalid `State` references

`ReactiveGridContainer` MUST handle gracefully:

- `items_state == null` → treat as empty grid; no errors.
- `items_state.value` not an `Array` → treat as empty grid but log a warning once (e.g., in `_normalize_items`).
- Changing `items_state` at runtime → disconnect from old, connect to new, and rebuild.

---

## Phase 3 – Selection, Navigation, and Controller Support ✅ **IMPLEMENTED**

**Objective**: Integrate with `selection_state` and the existing navigation system to support controller/keyboard movement and selection, without drag & drop.

### 3.1 Selection model

For v1, selection will be **single-index**:

- `selection_state.value`:
  - `null` → no selection.
  - `int` → index of the selected item/cell (0-based, matching `_current_cells`).
- `ReactiveGridContainer` MUST:
  - On selection changes, update visual selection state of the corresponding cell (if it implements `set_selected`).
  - When a cell is “activated” (e.g., via submit), update `selection_state` accordingly (if configured).

Selection update flow:

- From state → UI:
  - Implement `_on_selection_state_changed(new_value: Variant, _old_value: Variant)`:
	- Normalize to `int` or `null`.
	- Iterate `_current_cells` and call `set_selected(i == selected_index)` on cells that implement it.
	- Do this only when `_suppress_state_updates` is false.
	- Trigger `SELECTION_CHANGED` animations if configured (after `_is_initializing` check).

- From UI → state:
  - When a cell is "activated" (e.g., button press, submit from navigator), call `_select_index(index: int)`:

```gdscript
func _on_selection_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _suppress_state_updates:
		return
	
	var selected_index: int = -1
	if new_value is int:
		selected_index = int(new_value)
	elif new_value == null:
		selected_index = -1
	
	# Update cell selection states
	for i in range(_current_cells.size()):
		var cell = _current_cells[i]
		if cell and cell.has_method("set_selected"):
			cell.set_selected(i == selected_index)
	
	# Trigger SELECTION_CHANGED animations if configured
	if not _is_initializing:
		_on_trigger_selection_changed()

func _select_index(index: int) -> void:
	if selection_state == null:
		return
	_suppress_state_updates = true
	selection_state.set_value(index)
	_suppress_state_updates = false
```

### 3.2 Integration with `ReactiveUINavigator`

`ReactiveGridContainer` does not replace the navigator; it **cooperates**:

- Each cell is a `Control` that can receive focus.
- `ReactiveUINavigator` (already implemented elsewhere) handles:
  - Moving focus between controls based on direction input.
  - Raising submit/cancel events for the focused control.

`ReactiveGridContainer` MUST:

- Ensure all instantiated cells are focusable (e.g., `focus_mode = FOCUS_ALL` on cell root or child).
- Optionally:
  - On `focus_entered` of a cell, update `selection_state` (to have focus == selection), or
  - Only update selection on explicit submit; this behavior can be made configurable via a boolean export, e.g.:
	- `@export var select_on_focus: bool = false`
	- `@export var select_on_submit: bool = true`

### 3.3 Controller “move/swap” behavior (optional extension)

For now, **full item moving/swapping via controller is optional** and will be treated as a future extension:

- Potential approach:
  - Add a `move_mode_state: State` (bool) and `move_source_index_state: State` (int or null).
  - When the player presses a “pick up/move” action:
	- If not in move mode: enter move mode and record current selection as source index.
	- Move focus/selection using normal navigation.
	- On second press: perform a swap or move in `items_state.value`, then exit move mode.
- This logic is **not** part of the initial grid implementation but the design should not prevent it.

### 3.4 Cell activation and callbacks

When a cell is activated (via mouse click or controller submit), `ReactiveGridContainer` SHOULD:

- Update `selection_state` if configured.
- Optionally:
  - Emit a signal on the grid, e.g.:

```gdscript
signal cell_activated(index: int, item_data: Variant, cell: Control)
```

This signal gives higher-level game code a hook to open details, equip an item, etc., without embedding game logic in the UI control.

---

## Phase 4 – Animation Integration ✅ **IMPLEMENTED**

**Objective**: Integrate `ReactiveGridContainer` with the animation system in a way consistent with other reactive controls.

### 4.1 Grid-level animations

- `ReactiveGridContainer`'s own `animations: Array[AnimationReel]` can be used for:
  - HOVER_ENTER/EXIT on the overall grid (when it gains/loses focus as a whole).
  - SELECTION_CHANGED when the selected cell index changes (already available in `AnimationReel.Trigger`).
  - VALUE_CHANGED when `items_state.value` changes (already available in `AnimationReel.Trigger`, optional for v1).
- For v1, the basic triggers to support:
  - `HOVER_ENTER` / `HOVER_EXIT` at the grid level (when mouse enters/exits the grid area).
  - `SELECTION_CHANGED` when `selection_state` changes (if `selection_state` is configured).

### 4.2 Animation validation and control type hint

`ReactiveGridContainer` MUST implement `_validate_animation_reels()` following the pattern used by other reactive controls:

```gdscript
func _validate_animation_reels() -> void:
	var result = AnimationReel.validate_for_control(self, animations)
	animations = result.valid_reels

	# Set control context on each reel for Inspector filtering
	var control_type = _get_control_type_hint()
	for reel in animations:
		if reel:
			reel.control_type_context = control_type

	# Control-specific signal connections (stays in class)
	var has_selection_changed_targets = result.trigger_map.get(AnimationReel.Trigger.SELECTION_CHANGED, false)
	var has_hover_enter_targets = result.trigger_map.get(AnimationReel.Trigger.HOVER_ENTER, false)
	var has_hover_exit_targets = result.trigger_map.get(AnimationReel.Trigger.HOVER_EXIT, false)
	var has_value_changed_targets = result.trigger_map.get(AnimationReel.Trigger.VALUE_CHANGED, false)

	# Connect signals based on which triggers are used
	if has_selection_changed_targets and selection_state:
		# Selection changes are handled via selection_state.value_changed
		# (connection already made in _ready())
	if has_hover_enter_targets:
		if not mouse_entered.is_connected(_on_trigger_hover_enter):
			mouse_entered.connect(_on_trigger_hover_enter)
	if has_hover_exit_targets:
		if not mouse_exited.is_connected(_on_trigger_hover_exit):
			mouse_exited.connect(_on_trigger_hover_exit)
	if has_value_changed_targets:
		# Value changes are handled via items_state.value_changed
		# (connection already made in _ready())
```

`ReactiveGridContainer` MUST implement trigger handler methods for animations:

```gdscript
## Handles SELECTION_CHANGED trigger animations.
func _on_trigger_selection_changed() -> void:
	# Skip animations during initialization
	if _is_initializing:
		return
	_trigger_animations(AnimationReel.Trigger.SELECTION_CHANGED)

## Handles HOVER_ENTER trigger animations.
func _on_trigger_hover_enter() -> void:
	_trigger_animations(AnimationReel.Trigger.HOVER_ENTER)

## Handles HOVER_EXIT trigger animations.
func _on_trigger_hover_exit() -> void:
	_trigger_animations(AnimationReel.Trigger.HOVER_EXIT)

## Handles VALUE_CHANGED trigger animations.
func _on_trigger_value_changed() -> void:
	# Skip animations during initialization
	if _is_initializing:
		return
	_trigger_animations(AnimationReel.Trigger.VALUE_CHANGED)

## Triggers animations for reels matching the specified trigger type.
## [param trigger_type]: The trigger type to match.
func _trigger_animations(trigger_type: AnimationReel.Trigger) -> void:
	if animations.is_empty():
		return
	
	# Apply animations for reels matching this trigger
	for reel in animations:
		if reel == null:
			continue
		if reel.trigger != trigger_type:
			continue
		reel.apply(self)

## Finishes initialization, allowing animations to trigger on state changes.
func _finish_initialization() -> void:
	_is_initializing = false
```

**Note**: `SELECTION_CHANGED` and `VALUE_CHANGED` animations should be triggered from the corresponding state change handlers (`_on_selection_state_changed` and `_on_items_state_changed`) after the `_is_initializing` check.

`ReactiveGridContainer` MUST implement `_get_control_type_hint()` to enable trigger filtering in the Inspector:

```gdscript
func _get_control_type_hint() -> AnimationReel.ControlTypeHint:
	return AnimationReel.ControlTypeHint.SELECTION
```

**Rationale**: For v1, `ControlTypeHint.SELECTION` provides all necessary triggers:
- `SELECTION_CHANGED` (for selection state changes)
- `HOVER_ENTER` / `HOVER_EXIT` (for grid-level hover)
- `VALUE_CHANGED` is also available if needed for items_state changes

**Future consideration**: If grid-specific triggers are added to `AnimationReel.Trigger` in the future, a new `ControlTypeHint.GRID` can be introduced. For now, `SELECTION` is sufficient and maintains consistency with `ReactiveItemList` and `ReactiveTabContainer`.

### 4.3 Cell-level animations

Cell scenes (`cell_scene`) can themselves be:

- Simple `Controls` with their own `AnimationReel` arrays, OR
- `Reactive` controls (like `ReactiveButton`) that already use `AnimationReel`.

`ReactiveGridContainer` SHOULD:

- Not enforce a particular animation contract on cells, but it MAY:
  - Optionally trigger a standard method on cells when selection changes:
    - e.g., if cell has `on_grid_selection_changed(is_selected: bool)`, call it to let the cell run its own animations.

This keeps `ReactiveGridContainer` animation-light and reuses existing reactive patterns.

---

## Phase 5 – Testing & Verification ✅ **IMPLEMENTED**

**Objective**: Verify correctness, ergonomics, and controller friendliness of `ReactiveGridContainer`.

### 5.1 Test scenes

Create at least the following test scenes:

1. `GridBasic.tscn`
   - `ReactiveGridContainer` with:
     - Simple `items_state` using an Array of Dictionaries with `"name"` only.
     - A simple `cell_scene` that shows the name as a label.
   - No animations.

2. `GridSelection.tscn`
   - `ReactiveGridContainer` + `selection_state`.
   - Cell scene that visually indicates selection (e.g., background highlight).
   - Verify selection updates from:
     - State → UI.
     - UI → State (via cell activation).

3. `GridControllerNav.tscn`
   - Combine `ReactiveGridContainer` with `ReactiveUINavigator`.
   - Configure `NavigationConfig` to include the grid root.
   - Verify d-pad/arrow navigation across cells and selection behavior.

4. `GridAnimations.tscn`
   - Attach `AnimationReel` to cells (or the grid) for hover/selection change.
   - Verify animations fire correctly.

### 5.2 Edge cases

Explicitly test:

- `items_state` being `null` or non-Array → grid empties gracefully.
- Changing the length of `items_state.value` at runtime (adding/removing items).
- `selection_state` pointing to:
  - `null` (no selection).
  - A valid index.
  - An out-of-range index (grid should clamp or treat as no selection and log a warning).
- Dynamic changes to `grid_config` (especially `cell_scene` and `target_cell_count`) at runtime or in the editor.

---

## Phase 6 – Future Extensions (Non-blocking)

The design should allow, but does not initially implement:

1. **Controller-based move/swap mode**:
   - As described in Phase 3.3, a dedicated interaction model for moving items between slots via controller input.

2. **Multi-selection**:
   - Supporting `selection_state.value` as an `Array[int]` for selecting multiple grid cells.

3. **Per-cell animation reels managed by the grid**:
   - E.g., grid-level helpers that forward selection/hover events into each cell’s `AnimationReel` more explicitly.

4. **Typed item view models**:
   - Introducing a dedicated `ItemViewModel` Resource to replace free-form Dictionaries for stronger semantics and inspector support.

These can be added in later tiers without breaking the initial API if the above plan is followed.

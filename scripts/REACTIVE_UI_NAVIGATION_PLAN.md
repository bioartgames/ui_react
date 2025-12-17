## Reactive UI Navigation – Design & Implementation Plan

This document defines a **phased plan** for adding a designer-friendly, fully Inspector-driven
navigation/input layer for the existing reactive UI system.

The goal is to provide:

- A **“just works” default navigation driver** (keyboard, mouse, gamepad via InputMap).
- A **State-driven bridge point** so teams with their own input stack can integrate cleanly.
- An **Inspector-only workflow** for designers (no per-project scripting required).

No runtime code is implemented here; this is a **design and planning document**.

---

## Phase 0 – Scope, Goals, and Constraints ✅

### 0.1 Goals

- **Zero-code default navigation**:
  - Designers can drop in a single node (e.g. `ReactiveUINavigator`) or use a prebuilt root scene
    and immediately navigate reactive UIs with keyboard/controller/mouse via Godot’s InputMap.
  - No game-specific scripts are required for basic navigation.

- **Inspector-only configuration**:
  - All setup is done via exported properties and Resources:
    - Input profiles (which actions to listen to).
    - Navigation behavior (focus strategy, default focus, ordered controls).
    - Optional State-based input bundle for advanced setups.

- **Pluggable, non-imposing design**:
  - The system must **not lock users into a single input architecture**.
  - Teams with custom input can:
    - Either use the default InputMap-based driver.
    - Or provide a small bridge that drives `State` resources the navigation system reads.

- **Integration with existing systems**:
  - Reuse `State` for reactive values and bridge points.
  - Reuse design patterns from:
    - `ReactiveButton`, `ReactiveSlider`, `ReactiveTabContainer`, etc.
    - `TabContainerConfig` + `TabContainerHelper`.
    - `AnimationReel` and `AnimationUtilities`.
  - Avoid duplicating logic where existing helpers already solve similar problems
    (e.g. focus disabling utilities).

- **Signal- and callable-friendly architecture**:
  - Leverage Godot 4.x custom signals and exported `Callable` properties so designers can
    hook navigation events to screen logic entirely from the editor while keeping navigation
    logic decoupled and reusable.

### 0.2 Non‑Goals

- No global, gameplay-wide input system:
  - We are not designing a full character or gameplay input manager.
  - Focus is **UI navigation only**.

- No full reimplementation of Godot’s focus/navigation:
  - We build **on top of** Control focus and InputMap, only layering behavior where needed.

- No animation overhaul:
  - Navigation may **trigger animations via existing mechanisms** (focus/hover events),
    but we do not extend `AnimationReel` specifically for navigation in this phase.

- No hard-coded device mapping:
  - We do not hard-code specific hardware (Xbox, DualShock, etc.).
  - Everything is based on **abstract actions** and optional State bridges.

### 0.3 Files and Types to Introduce

New scripts/resources (names subject to final refinement but consistent with existing patterns):

- **Navigation Resources**
  - `scripts/reactive/navigation_input_profile.gd`
    - `extends Resource`
    - `class_name NavigationInputProfile`
  - `scripts/reactive/navigation_state_bundle.gd`
    - `extends Resource`
    - `class_name NavigationStateBundle`
  - `scripts/reactive/navigation_config.gd`
    - `extends Resource`
    - `class_name NavigationConfig`

- **Navigation Controller Node**
  - `scripts/reactive/reactive_ui_navigator.gd`
    - `@tool`
    - `extends Node`
    - `class_name ReactiveUINavigator`

- **NavigationUtils** ✅ **IMPLEMENTED**
  - `scripts/utilities/navigation_utils.gd`
    - `extends RefCounted`
    - `class_name NavigationUtils`
    - Stateless helper functions for focus traversal, group ordering, etc.

No changes are planned to existing reactive controls beyond **optional small integrations**
in later phases (e.g. best-practices docs on focus modes).

---

## Phase 1 – High-Level Architecture & Responsibilities ✅

### 1.1 Design Principles (SOLID & DRY)

- **Single Responsibility (SRP)**:
  - `ReactiveUINavigator`:
    - Orchestrates navigation & focus for a specific UI subtree.
    - Does **not** store game logic or global input policies.
  - `NavigationInputProfile`:
    - Defines **what actions** mean “up/down/left/right/accept/cancel” for InputMap-driven mode.
  - `NavigationStateBundle`:
    - Encapsulates **input events expressed as `State` resources** (for external input systems).
  - `NavigationConfig`:
    - Encodes **layout-specific navigation rules** (default focus, ordered controls, behavior flags).
  - `NavigationUtils` (optional):
    - Pure functions for focus traversal and common checks.

- **Open/Closed Principle (OCP)**:
  - New navigation behaviors should be added by:
    - Adding new `NavigationConfig` or `NavigationInputProfile` variants.
    - Subclassing or composing new Resources.
  - Existing classes shouldn’t need modification for most extensions.

- **Liskov Substitution (LSP)**:
  - Any `NavigationInputProfile` subclass should behave as a valid profile.
  - Any `NavigationConfig` variant should be usable wherever a `NavigationConfig` is expected.

- **Interface Segregation (ISP)**:
  - Small, focused sets of exported properties:
    - Designers don’t need to fill in everything for basic use.
    - Advanced options are grouped and documented clearly.

- **Dependency Inversion (DIP)**:
  - `ReactiveUINavigator` depends on **abstract Resources** (`NavigationInputProfile`,
    `NavigationStateBundle`, `NavigationConfig`) rather than concrete game scripts.
  - External systems can provide their own Resources without the navigator knowing details.
  - High-level game or screen controllers observe navigation via **custom signals** or plug in
    small behaviors via exported `Callable` slots instead of the navigator depending directly
    on them.

### 1.2 ReactiveUINavigator – Overview

`ReactiveUINavigator` will be the primary entry point for designers:

- Responsibilities:
  - Observe input events (via InputMap **or** via `NavigationStateBundle`).
  - Decide how to interpret navigation commands:
    - Move focus up/down/left/right.
    - Trigger “submit/accept”.
    - Optionally handle “cancel/back”.
  - Apply these commands to the focused control subtree:
    - Use Godot Control focus APIs (`grab_focus`, `focus_next`, `focus_previous`, neighbors).
  - Respect `NavigationConfig` rules (default focus, ordered controls, optional custom traversal).

- Non-responsibilities:
  - It does **not** own or mutate game data beyond focus and optional UI `State` toggles.
  - It does **not** decide what game “cancel” means beyond e.g. emitting a signal.

### 1.3 Navigation Modes

`ReactiveUINavigator` exposes a simple navigation mode enum:

```gdscript
enum NavigationMode {
	NONE,
	INPUT_MAP,      # Uses NavigationInputProfile + Godot InputMap
	STATE_DRIVEN,   # Uses NavigationStateBundle only
	BOTH            # Combines both (InputMap fills State bundle, then handled uniformly)
}
```

Design:

- **INPUT_MAP**:
  - Navigator directly queries `Input.is_action_just_pressed()/pressed()` using the profile.
- **STATE_DRIVEN**:
  - Navigator only reacts to changes in the `NavigationStateBundle`’s `State` values.
- **BOTH**:
  - Reserved for the combined bridge mode described in the advanced features phase, where
    InputMap and `NavigationStateBundle` are used together.

---

## Phase 2 – Navigation Resources (Profiles, States, Config) ✅ **IMPLEMENTED**

### 2.1 NavigationInputProfile

**Objective**: Encapsulate all InputMap-related decisions in a Resource so designers can swap
profiles without code changes.

Class skeleton:

```gdscript
extends Resource
class_name NavigationInputProfile

@export_group("Actions")
@export var action_up: StringName = &"ui_up"
@export var action_down: StringName = &"ui_down"
@export var action_left: StringName = &"ui_left"
@export var action_right: StringName = &"ui_right"
@export var action_accept: StringName = &"ui_accept"
@export var action_cancel: StringName = &"ui_cancel"

@export_group("Behavior")
@export var repeat_delay: float = 0.25
@export var repeat_interval: float = 0.1
```

Key behaviors:

- Treat actions as **abstract navigation concepts**.
- Support simple repeat behavior for held D-pad/keys via the timing fields.

### 2.2 NavigationStateBundle

**Objective**: Provide a `State`-based interface for external input systems to drive navigation
without touching `ReactiveUINavigator` internals.

Class skeleton:

```gdscript
extends Resource
class_name NavigationStateBundle

@export_group("Movement")
@export var move_x: State  # -1 (left), 0, +1 (right)
@export var move_y: State  # -1 (up), 0, +1 (down)

@export_group("Actions")
@export var submit: State      # bool or edge-triggered
@export var cancel: State      # bool or edge-triggered
```

Semantics:

- `move_x` / `move_y`:
  - Typically set to −1/0/+1 by the game’s input system.
  - Navigator interprets non-zero values as directional navigation commands.

- `submit` / `cancel`:
  - Treated as **edge-triggered** booleans in the navigator:
    - Navigator reacts when value changes from `false` → `true`.

This mirrors the **reactive, State-driven design** of the existing system and forms a clean
bridge for custom input stacks.

### 2.3 NavigationConfig

**Objective**: Allow designers to define **layout-specific navigation rules** independently
from input configuration.

Class skeleton:

```gdscript
extends Resource
class_name NavigationConfig

@export_group("Scope")
@export var root_control: NodePath

@export_group("Defaults")
@export var default_focus: NodePath
@export var focus_on_ready: bool = true

@export_group("Ordering")
@export var ordered_controls: Array[NodePath] = []
@export var use_ordered_vertical: bool = true
@export var wrap_vertical: bool = false
@export var wrap_horizontal: bool = false

@export_group("Advanced")
@export var respect_custom_neighbors: bool = true
@export var restrict_to_focusable_children: bool = true
@export var auto_disable_child_focus: bool = false
```

Semantics:

- **root_control**:
  - Scope of navigation; navigator will only consider Controls under this node.

- **default_focus**:
  - Where focus is placed initially (and possibly after cancel/close).

- **ordered_controls**:
  - Optional explicit list used to determine next/previous navigation targets.
  - When empty, navigator falls back to:
    - `focus_neighbor_*` properties, then
    - Layout heuristics (position-based).

- **advanced flags**:
  - `respect_custom_neighbors`:
    - When true, if controls specify `focus_neighbor_*`, use them first.
  - `auto_disable_child_focus`:
    - When true, navigator calls into `AnimationUtilities.disable_focus_on_children`
      for certain containers to keep navigation “flat” at a given level.

### 2.4 NavigationUtils ✅ **IMPLEMENTED**

If duplication appears during implementation, introduce `NavigationUtils` to collect:

- Functions for walking the Control tree under a root and filtering focusable controls.
- Position-based heuristics to find the “closest” control in a direction.
- Helpers to apply `disable_focus_on_children` safely and idempotently.

This keeps `ReactiveUINavigator` smaller and promotes DRY.

---

## Phase 3 – ReactiveUINavigator: Core Behavior ✅ **IMPLEMENTED**

### 3.1 Class Skeleton & Exports ✅ **IMPLEMENTED**

Initial structure:

```gdscript
@tool
extends Node
class_name ReactiveUINavigator

signal focus_changed(old_focus: Control, new_focus: Control)
signal navigation_moved(direction: Vector2)
signal submit_fired(focus_owner: Control)
signal cancel_fired(focus_owner: Control)

enum NavigationMode { NONE, INPUT_MAP, STATE_DRIVEN, BOTH }

@export var mode: NavigationMode = NavigationMode.INPUT_MAP
@export var input_profile: NavigationInputProfile
@export var nav_states: NavigationStateBundle
@export var nav_config: NavigationConfig

@export_group("Callbacks")
@export var on_submit: Callable
@export var on_cancel: Callable

var _current_focus_owner: Control = null
var _is_ready: bool = false
var _repeat_state := {}  # internal structure for key repeat
```

Key events:

- `_ready()`:
  - Resolve `nav_config.root_control` and `nav_config.default_focus`.
  - Optionally apply `auto_disable_child_focus`.
  - If `focus_on_ready` is true, set initial focus.
  - Initialize any needed editor-time helpers (`@tool` support).

- `_unhandled_input(event: InputEvent)`:
  - Only active when `mode` involves `INPUT_MAP`.
  - Converts InputMap events into **abstract navigation commands**.
  - In the advanced BOTH mode (introduced in Phase 7), this handler also mirrors relevant
    InputMap events into `nav_states` to keep the bridge behavior in sync (see Phase 7.4).

### 3.2 Abstract Navigation Commands ✅ **IMPLEMENTED**

The navigator should operate on a small internal set of commands:

- `move(Vector2 dir)` – movement in UI space (e.g. up/down/left/right).
- `submit()` – activate current control.
- `cancel()` – go back or emit a signal.

Implementation outline:

```gdscript
func _handle_input_map_navigation(event: InputEvent) -> void:
	if not input_profile:
		return
	# Detect just-pressed actions via InputMap and call _queue_command_* helpers

func _process_state_navigation() -> void:
	if not nav_states:
		return
	# Read move_x/move_y/submit/cancel States and translate into the same commands
```

Internal helpers:

- `_queue_move(dir: Vector2)`
- `_queue_submit()`
- `_queue_cancel()`

These helpers update a small queue/flags processed in `_process()` or similar, to avoid
duplicating logic between input modes.

### 3.3 Focus Management ✅ **IMPLEMENTED**

Core focus behavior:

- Track the **current focus target** (`_current_focus_owner`):
  - Initialized from `nav_config.default_focus` or `get_viewport().gui_get_focus_owner()`.

- Movement logic:
  - When receiving `move(dir)`:
    1. Try `focus_neighbor_*` on the current control if `respect_custom_neighbors` is true.
    2. If neighbors are not defined or invalid:
       - If `ordered_controls` is non-empty, use it as a virtual linear list:
         - For vertical movement:
           - Move index up/down; apply wrapping if enabled.
         - For horizontal movement:
           - Either treat as separate row or similar; initially just fallback to vertical semantics.
       - Else fallback to layout-based heuristics via `NavigationUtils`:
         - For each candidate focusable control in scope:
           - Compute direction vector, consider only those within an angular cone in `dir`.
           - Choose the nearest by some distance metric.

  - If a new target is chosen:
    - Call `grab_focus()` on it.
    - Update `_current_focus_owner`.

- **Visibility-aware focus candidates** ✅ **IMPLEMENTED**:
  - When gathering candidate controls (via `NavigationConfig` and `NavigationUtils`), skip controls that are not visible (or whose ancestors are hidden), in addition to existing focusability checks (`focus_mode != FOCUS_NONE`, scope, etc.).
  - If `_current_focus_owner` becomes hidden because a control or one of its parents changed `visible` (including through future State-driven visibility bindings), immediately choose a new focus target using the existing movement heuristics or fall back to `default_focus`.
  - When starting the Phase 8 state-driven visibility & animated transitions work, explicitly verify that this behavior is already implemented; if not, implement it first so navigation correctness is in place before layering additional visibility features.

- Submit logic:
  - On `submit()`:
    - If the focused control is a `BaseButton` (including `Button`, `CheckBox`, etc.):
      - Call its `button_pressed()` or emit its built-in `pressed` signal to activate it.
    - For other control types (e.g. `OptionButton`, `ItemList` or custom controls), rely on
      Godot’s standard `ui_accept` behavior by forwarding a `ui_accept` action event through
      the GUI input system (via a small helper used consistently across the navigator).
    - After successfully handling submit:
      - Emit `submit_fired(_current_focus_owner)`.
      - If `on_submit` is a valid `Callable`, invoke it with the current focus owner as an argument:
        - This allows per-screen “when user confirms here, do X” behaviors without subclassing.

- Cancel logic:
  - On `cancel()`:
    - Emit `cancel_fired(_current_focus_owner)` from `ReactiveUINavigator`.
    - If `on_cancel` is a valid `Callable`, invoke it with the current focus owner.
    - Optionally move focus back to `nav_config.default_focus` if configured.
    - The enclosing scene can connect to `cancel_fired` (via the Node → Signals dock) to close
      panels or perform higher-level behavior without custom scripts on the navigator itself.

### 3.4 Integration with NavigationConfig ✅ **IMPLEMENTED**

When resolving candidates:

- Only consider controls under `nav_config.root_control` if set.
- If `restrict_to_focusable_children` is true:
  - Filter by `focus_mode != FOCUS_NONE`.
- Respect `auto_disable_child_focus`:
  - Optionally call `AnimationUtilities.disable_focus_on_children(root_control)` **once**
    during setup or in an explicit helper:
    - Avoid repeated calls; ensure idempotence.

As focus targets change based on `NavigationConfig` rules, `focus_changed(old, new)` is emitted
whenever `_current_focus_owner` is updated, allowing observers (e.g. for breadcrumbs or HUD
elements) to react without additional coupling.

---

### 3.5 Signals & Callbacks Usage Guidelines ✅ **IMPLEMENTED**

To keep the design maintainable and friendly for designers:

- **Signals**:
  - Use signals (`focus_changed`, `navigation_moved`, `submit_fired`, `cancel_fired`) for
    **broad, observable events** that multiple systems may care about.
  - `navigation_moved(direction)` represents the **intent** to move in a direction (it may or may
    not result in an actual focus change), while `focus_changed(old, new)` represents the
    **result** (focus actually moved from one control to another).
  - Designers (or technical designers) wire these in the Godot editor via the Node → Signals
    dock, connecting them to methods on higher-level scene controllers.
  - Example usages in the project:
    - A menu controller connects to `cancel_fired` to close the current panel.
    - A HUD or breadcrumb widget connects to `focus_changed` to display context hints.

- **Exported Callables**:
  - Use `on_submit` and `on_cancel` as **simple, per-screen hooks** when you want a single,
    well-defined behavior without creating extra scene controller scripts.
  - Designers assign these Callables in the Inspector by picking a target node and method;
    the navigator only checks `is_valid()` and calls them when appropriate.
  - All callbacks are invoked with the current focus owner as the **first and only argument**
    in the current design, so callback methods should accept a single `Control` parameter.
  - This keeps the core navigation logic generic while still giving each screen a low-friction way
    to react to navigation without additional boilerplate.

- **Separation of concerns**:
  - Navigation logic (how to move focus, when to submit/cancel) stays inside
    `ReactiveUINavigator` and helpers.
  - Game- or app-specific responses to navigation events live:
    - In scene controller scripts connected to signals, or
    - In methods referenced by the exported `Callable` properties.
  - This separation allows you to reuse the same navigator across many screens while giving each
    screen its own behavior purely through editor wiring.

---

## Phase 4 – State-Driven Mode and Bridges

### 4.1 STATE_DRIVEN Mode

When `mode == STATE_DRIVEN`:

- `ReactiveUINavigator` ignores InputMap completely.
- It only reads `NavigationStateBundle` in `_process_state_navigation()`:
  - For each frame or at specific intervals:
    - Read `move_x.value` and `move_y.value`.
    - Detect edges on `submit.value` and `cancel.value`.
  - Translate these values into the same internal commands (`move`, `submit`, `cancel`).

Edge detection approach:

- Maintain internal copies of previous values (e.g. `_prev_submit`, `_prev_cancel`).
- Trigger actions only when:

  ```gdscript
  var submit_value := bool(nav_states.submit.value)
  if submit_value and not _prev_submit:
      _queue_submit()
  _prev_submit = submit_value
  ```

### 4.2 External Input Integration

For a team with a custom input stack:

- They can:
  - Provide a `NavigationStateBundle` and set `mode = STATE_DRIVEN`.
  - Write a single “input → nav bundle” script somewhere in their code:
    - It reads gamepad/keyboard/mouse however they like.
    - It writes to `move_x`, `move_y`, `submit`, `cancel` States.

Design ensures:

- `ReactiveUINavigator` does not care **where** values come from.
- Designers can still configure everything via Resources (bundle assigned in Inspector).

---

## Phase 5 – Editor & Designer Experience ✅ **IMPLEMENTED**

### 5.1 @tool Support ✅ **IMPLEMENTED**
- **NavigationDebugOverlay**: Implemented as `ReferenceRect` subclass for cleaner border rendering

`ReactiveUINavigator` should be `@tool`-ready where feasible:

- In the editor:
  - Validate `nav_config`:
    - Highlight missing `root_control` or `default_focus` with warnings.
  - Optionally expose a small helper method (e.g. button in the Inspector via `EditorPlugin`
    in a future phase) to:
    - Auto-populate `ordered_controls` from current children under `root_control`.

### 5.2 Inspector Grouping ✅ **IMPLEMENTED**

Use `@export_group` to mirror the clarity of existing reactive controls:

- Groupings:
  - `"Mode"`: `mode`, `nav_config`.
  - `"Input (InputMap)"`: `input_profile`.
  - `"Input (State-driven)"`: `nav_states`.
  - `"Debug"`: optional debug toggles (e.g. show focus outlines in the editor).

Aim:

- A designer opening `ReactiveUINavigator` should see **three core knobs**:
  1. Navigation mode.
  2. Which UI it controls (`NavigationConfig`).
  3. Where input comes from (`NavigationInputProfile` or `NavigationStateBundle`).

### 5.3 Documentation & Examples ✅ **IMPLEMENTED** (script documentation added, debug overlay created)

Update existing or new docs (markdown and/or Godot doc comments) to include:

- “Getting Started with Navigation” section:
  - Add `ReactiveUINavigator` to a scene.
  - Create/assign a `NavigationConfig`.
  - Use default `NavigationInputProfile`.
  - Run and test.

- “Using Custom Input Systems” section:
  - Create `NavigationStateBundle`.
  - Set `mode = STATE_DRIVEN`.
  - Example pseudo-code for writing to the bundle.

---

## Phase 6 – Testing & Verification ✅ **IMPLEMENTED**

### 6.1 Test Scenes

Create small, focused scenes to verify behavior:

1. **BasicMenu_InputMap.tscn** ✅ **IMPLEMENTED** (as `scenes/test_navigation_basic.tscn`)
   - Vertical list of `ReactiveButton`s in a `VBoxContainer`.
   - `ReactiveUINavigator` with:
     - `mode = INPUT_MAP`.
     - Default `NavigationInputProfile`.
     - Simple `NavigationConfig` (root = VBox, default_focus = first button).
   - Verify:
     - Up/down keys or gamepad D-pad move focus correctly.
     - `ui_accept` activates focused buttons.

2. **GridMenu_OrderedControls.tscn** ✅ **IMPLEMENTED** (as `scenes/test_navigation_ordered.tscn`)
   - 2x3 grid of buttons or other reactive controls.
   - `NavigationConfig` with `ordered_controls` explicitly ordered.
   - Verify:
     - Up/down/left/right move focus according to order, respect wrapping flags.

3. **StateDrivenMenu.tscn** ✅ **IMPLEMENTED** (as `scenes/test_navigation_state_driven.tscn` with test controller)
   - Same layout as Scenario 1.
   - `mode = STATE_DRIVEN` with a `NavigationStateBundle`.
   - A simple script (test harness) sets:
     - `move_y.value = -1` or `+1` on timers.
   - Verify:
     - Focus moves based purely on State changes, without InputMap.

4. **MixedTabsAndList.tscn** ✅ **IMPLEMENTED** (as `scenes/test_navigation_mixed.tscn`)
   - Combine `ReactiveTabContainer`, `ReactiveItemList`, `ReactiveButton`s.
   - Use `NavigationConfig` with `root_control` set to a higher-level container.
   - Verify that:
     - Navigation respects scope.
     - Focus doesn’t “fall into” deep children when `auto_disable_child_focus` is enabled.

### 6.2 Edge Cases

Explicitly test:

- No `nav_config` set:
  - Navigator should log a clear warning and avoid crashes.
- `default_focus` missing or invalid:
  - Navigator falls back to first focusable control.
- Mixed focus modes:
  - Some controls have `focus_mode = FOCUS_NONE`.
  - Ensure they are skipped during navigation.
- Rapid input:
  - Hold arrows or D-pad; verify repeat delay and interval behave as configured.
- State-driven edge cases:
  - `move_x` / `move_y` oscillating rapidly.
  - `submit` or `cancel` toggling too quickly; ensure edge detection holds.

---

## Phase 7 – Advanced Navigation Features (Analog, Paging, Bridge) ✅ **IMPLEMENTED**

This phase introduces more powerful navigation features on top of the core system defined in
Phases 1–6. These are still part of the main plan but should be implemented **after** the
basic INPUT_MAP and STATE_DRIVEN flows are stable.

### 7.1 Extend NavigationInputProfile for Analog Navigation ✅ **IMPLEMENTED**

Enhance `NavigationInputProfile` with analog- and diagonal-specific behavior:

```gdscript
@export_group("Analog / Diagonals")
@export var allow_diagonals: bool = false
@export var analog_deadzone: float = 0.4
```

Semantics:

- `allow_diagonals`:
  - When true, simultaneous up/down/left/right input (e.g. from a stick) can be interpreted
    as diagonal intent instead of being clamped to a single axis.
- `analog_deadzone`:
  - Minimum magnitude for analog inputs (e.g. gamepad stick) before they are treated as a
    navigation command; avoids unintentional drift.

The navigator’s input-handling helpers (`_handle_input_map_navigation`) are extended to:

- Read analog axes in addition to digital actions where available.
- Normalize analog input into a `Vector2 dir` with deadzone and diagonal rules applied, and
  then call `_queue_move(dir)` in the same way as for digital input.

### 7.2 Extend NavigationStateBundle for Page Navigation ✅ **IMPLEMENTED**

Add page navigation fields to `NavigationStateBundle` for more complex UIs (tabs, pages):

```gdscript
@export_group("Paging")
@export var page_next: State
@export var page_prev: State
```

Semantics:

- `page_next` / `page_prev`:
  - Typically toggled true momentarily when the user requests page/tab changes (e.g. bumper
    buttons, page up/down keys).
  - Navigator treats rising edges (`false` → `true`) as requests to change page with `delta` of
    +1 or −1 respectively, then resets its internal bookkeeping so they can trigger again.

In `_process_state_navigation`, extend the logic to:

- Detect edges on `page_next.value` and `page_prev.value` in the same way as
  `submit.value` / `cancel.value` (using internal previous-value bookkeeping).
- Convert them into internal `page(+1)` / `page(−1)` commands processed alongside move/submit.

### 7.3 Advanced Paging Commands, Signals & Callbacks ✅ **IMPLEMENTED**

Extend `ReactiveUINavigator` with a paging command, signal, and callbacks:

- **Command set**:
  - Extend the command set from Phase 3.2 by adding `page(int delta)` to the internal command
    API, with a helper `_queue_page(delta: int)` used by both InputMap and state-driven paths.

- **Signal**:

```gdscript
signal page_changed(delta: int, focus_owner: Control)
```

- **Callbacks**:

```gdscript
@export_group("Callbacks / Paging")
@export var on_page_next: Callable
@export var on_page_prev: Callable
```

Paging behavior:

- When processing a `page(delta)` command (e.g. from bumpers or `page_next/page_prev` States):
  - Emit `page_changed(delta, _current_focus_owner)` without directly mutating tabs or pages.
  - If `delta > 0` and `on_page_next` is valid, call `on_page_next.call(_current_focus_owner)`.
  - If `delta < 0` and `on_page_prev` is valid, call `on_page_prev.call(_current_focus_owner)`.
- High-level controllers or the callbacks themselves decide what “page change” means in a
  particular screen (e.g. switching `TabContainer.current_tab`, navigating between panels, etc.).

Signal/callback guidelines for paging:

- Use `page_changed` when several systems may need to react to page changes (e.g. analytics,
  sound, animations).
- Use `on_page_next` / `on_page_prev` when a single, screen-specific behavior is needed and you
  want to avoid creating extra controller scripts.

All paging callbacks follow the same convention as submit/cancel: they receive the current focus
owner as their single argument.

### 7.4 BOTH Mode and Default Bridge ✅ **IMPLEMENTED**

Implement the combined bridge semantics for `mode == BOTH`:

- Precondition: both `input_profile` and `nav_states` are assigned.
- Behavior:
  - Navigator serves as a **bridge** between InputMap and the `NavigationStateBundle`:
    - InputMap events are interpreted directly into commands and also mirrored into
      `nav_states` (so external systems can observe them if desired).
    - State changes in `nav_states` can also drive navigation (e.g. game replays or scripted UI).
  - This keeps behavior symmetric and avoids hidden divergence between input sources.

Implementation notes:

- `_handle_input_map_navigation`:
  - After detecting an action and queuing a command, also update the corresponding `State`
    in `nav_states` if present (e.g. toggling `submit`, `cancel`, `move_x`, `move_y`).
- `_process_state_navigation`:
  - Continues to treat `NavigationStateBundle` as a source of commands, regardless of how those
    States were set (InputMap, custom input system, replay, etc.).

This phase completes the advanced feature set while preserving the clean separation between
core navigation, Resources, and screen-specific behavior established in earlier phases.

---

## Phase 8 – Future Extensions (Non-Blocking) ✅ **IMPLEMENTED**

These ideas should **not** be implemented initially but the design should not block them:

1. **Per-container NavigationConfig overrides** ✅ **IMPLEMENTED** (via multiple scoped navigators):
   - Allow child containers to define local navigation rules (e.g. submenus) that the navigator respects when focus is inside those containers.
   - **Implementation**: Use existing `ReactiveUINavigator` + `NavigationConfig`, but allow **multiple navigators**, each scoped to a different subtree. Add a **separate `ReactiveUINavigator`** node for each submenu/panel that needs its own rules, each with its own `NavigationConfig` whose `root_control` points at that container. A higher-level screen controller is responsible for toggling which navigator is active (setting `mode` to `NONE` on inactive navigators), so `ReactiveUINavigator` itself never has to understand nested scopes.

2. **Integration with AnimationReel on focus changes** ✅ **IMPLEMENTED**:
   - Provide optional hooks or triggers for "FOCUS_GAINED" / "FOCUS_LOST" events using existing animation utilities, without baking navigation concepts into `AnimationReel`.
   - **Implementation**: Created `FocusAnimationHelper` (`scripts/utilities/focus_animation_helper.gd`, `extends Node`, `class_name FocusAnimationHelper`). It exports `@export var navigator: NodePath` (path to `ReactiveUINavigator`), `@export var focus_in_reels: Array[AnimationReel] = []`, and `@export var focus_out_reels: Array[AnimationReel] = []`. In `_ready()`, it resolves the navigator and connects to `focus_changed(old, new)`. On `focus_changed`, it applies all `focus_out_reels` to `old` (if non-null) and all `focus_in_reels` to `new` (if non-null) via `AnimationReel.apply()`. `ReactiveUINavigator` does not know anything about animations; it only emits signals.

3. **Data-driven presets** ✅ **IMPLEMENTED**:
   - Bundled `NavigationInputProfile` assets:
     - `KeyboardOnlyProfile`, `GamepadOnlyProfile`, `KeyboardAndGamepadProfile`.
   - Bundled `NavigationConfig` templates for common patterns:
     - Vertical menu, grid inventory, tabbed menu.
   - **Implementation**: Shipped as `.tres` resources under `res://navigation_presets/`. Designers can assign them directly to `input_profile` and `nav_config` without any code. No special handling in `ReactiveUINavigator` is required.

4. **State-driven conditional visibility & animated transitions** ✅ **IMPLEMENTED**:
   - Introduce optional State-driven bindings for `visible` on reactive controls (for example, a `visible_state: State` on commonly used controls) and container-level visibility of panels/tabs, using existing `State` resources as the single source of truth.
   - Integrate these bindings with `AnimationUtilities` / `AnimationCoreUtils` so that visibility edges (`false → true`, `true → false`) trigger appropriate show/hide animations instead of abrupt toggles, reusing existing `auto_visible` and snapshot/restore mechanisms.
   - Ensure `ReactiveUINavigator` continues to ignore invisible/disabled controls and gracefully re-homes focus when the focused control (or one of its ancestors) becomes hidden, so navigation always reflects what is actually on screen.
   - **Implementation**: Created `ReactiveVisibilityHelper` (`scripts/reactive/reactive_visibility_helper.gd`, `extends Node`, `class_name ReactiveVisibilityHelper`). It exports `@export var visible_state: State`, optional `@export var show_reels: Array[AnimationReel] = []`, and optional `@export var hide_reels: Array[AnimationReel] = []`. For simple controls (`ReactiveButton`, `ReactiveLabel`, etc.), add an exported `visible_state: State` and an internal `_visibility_helper: ReactiveVisibilityHelper` instance, OR use the helper as a child node (composition), wired via exported NodePath. The helper connects to `visible_state.value_changed`. On `false → true`: sets `control.visible = true`, triggers `show_reels` via `AnimationReel.apply(control)`. On `true → false`: triggers `hide_reels`, then sets `control.visible = false` (or uses `auto_visible` / snapshot APIs from animation utils). `ReactiveUINavigator` is not modified; it simply sees the resulting `visible` property and continues to ignore hidden controls via its existing visibility-aware logic.

All of these should be achievable by composing or extending the types defined in this plan,
without modifying their core behavior (preserving OCP).



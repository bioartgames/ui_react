## ReactiveRichTextLabel – Design & Implementation Plan

This document defines a **concrete, phased plan** for adding a `ReactiveRichTextLabel` control that closely follows existing patterns used by `ReactiveLabel`, other `reactive_*` controls, and the animation utilities.

The plan is **design-only**; no code is implemented yet.

---

## Phase 0 – Scope, Goals, and Constraints ✅ **COMPLETED**

### 0.1 Goals

- **Add** a `ReactiveRichTextLabel` control that:
  - Extends `RichTextLabel`.
  - Binds its displayed rich text to a `State` resource.
  - Supports **nested States** and **structured segments** (arrays/dictionaries) for rich formatting.
  - Integrates with the **existing animation system** (`AnimationReel`, `AnimationClip`, triggers, and control type hints).
  - Matches the ergonomics and semantics of `ReactiveLabel` as closely as possible.

### 0.2 Non‑Goals

- No new generic reactive system; this is a single, concrete control.
- No refactor of `State` or other existing controls.
- No automatic markup translation beyond what is explicitly described in `_to_rich_text` (see Phase 2).

### 0.3 Files and Types to Introduce

- **New script**: `scripts/reactive/reactive_rich_text_label.gd`
  - `@tool`
  - `extends RichTextLabel`
  - `class_name ReactiveRichTextLabel`

No new utility or resource types are required.

---

## Phase 1 – Class Skeleton & Basic Wiring ✅ **COMPLETED**

**Objective**: Create a new reactive control with the same structural patterns as `ReactiveLabel`, but based on `RichTextLabel`.

### 1.1 Create `ReactiveRichTextLabel` script

- File: `scripts/reactive/reactive_rich_text_label.gd`
- Class definition:

```gdscript
@tool
extends RichTextLabel
class_name ReactiveRichTextLabel
```

### 1.2 Exported properties

- Declare the following exports:

```gdscript
@export var text_state: State
@export var animations: Array[AnimationReel] = []
```

- Semantics:
  - `text_state`:
    - Holds the **source value** that drives the rich text content.
    - Must be optional (can be null); when null, the control does not try to bind or update text automatically.
  - `animations`:
    - Same semantics as other reactive controls: array of `AnimationReel` resources to trigger on events.

### 1.3 Internal state fields

Mirror `ReactiveLabel`’s internal state for consistency:

```gdscript
var _updating: bool = false
var _nested_states: Array[State] = []
var _is_initializing: bool = true
```

- `_updating`: Guards against feedback loops when setting `text` from `text_state`.
- `_nested_states`: Keeps track of State instances nested inside `text_state.value` (used for rich/structured content).
- `_is_initializing`: Used to suppress certain triggers during startup (e.g., avoid playing animations as soon as data loads).

### 1.4 `_ready()` implementation

Implement `_ready()` with **editor/runtime branching** in line with other `@tool` reactive controls:

```gdscript
func _ready() -> void:
	if Engine.is_editor_hint():
		# In the editor, only validate reels so trigger options are filtered.
		_validate_animation_reels()
		return

	if text_state:
		text_state.value_changed.connect(_on_text_state_changed)
		_on_text_state_changed(text_state.value, text_state.value)

	_validate_animation_reels()
	# Finish initialization after all signals are processed
	call_deferred("_finish_initialization")
```

- This mirrors `ReactiveLabel`:
  - In editor: only validate reels to set `control_type_context` and filter available triggers.
  - At runtime: connect to `text_state.value_changed`, do an initial sync, validate reels, then mark initialization complete later.

---

## Phase 2 – Binding Semantics & Rich Text Conversion ✅ **COMPLETED**

**Objective**: Define **exactly** how `text_state.value` is interpreted and converted into the `RichTextLabel.text` property.

### 2.1 Supported value shapes for `text_state.value`

`text_state.value` MUST be interpreted by `_on_text_state_changed` and `_to_rich_text` with the following rules:

1. **`null`**:
   - Produces an empty string.

2. **`String`**:
   - Used **directly** as the `text` for the `RichTextLabel`.
   - Assumes `bbcode_enabled = true` on the `RichTextLabel` if the user wants BBCode.
   - The control does **not** escape or sanitize the string.

3. **`State`**:
   - Treated as **nested**, and unwrapped by recursively calling `_to_rich_text(value.value)`.

4. **`Array`**:
   - Treated as a **sequence of segments** to be concatenated.
   - Each element `segment` MUST be interpreted as follows:
     - If `segment` is a `State`:
       - Process as `_to_rich_text(segment.value)` recursively.
     - If `segment` is a `String`:
       - Treated as a literal text segment (BBCode allowed).
     - If `segment` is a `Dictionary`:
       - Must contain at least the key `"text"`.
       - `"text"` can itself be:
         - `String`
         - `State`
         - `Array` (recursively processed by `_to_rich_text`).
       - Optional formatting keys:
         - `"bold": bool`
         - `"italic": bool`
         - `"underline": bool`
         - `"color": Color` or `String` (hex code like `"#ff0000"`).
         - `"size": int` (font size; used with `[font_size]` or `[size]` depending on project’s chosen BBCode).
         - `"url": String` (to wrap text in `[url]` tags).
       - Formatting MUST be applied by wrapping the rendered text in BBCode tags in the following **fixed nesting order** (outermost first):
         1. `[url]` / `[/url]`
         2. `[color]` / `[/color]`
         3. `[size]` / `[/size]` (or `[font_size]` / `[/font_size]` – see 2.3)
         4. `[b]` / `[/b]`
         5. `[i]` / `[/i]`
         6. `[u]` / `[/u]`
       - Any keys not listed above MUST be ignored (no effect).
     - Any other type:
       - Fall back to `str(segment)` and treat as plain text.

5. **Other scalar types (int, float, bool, etc.)**:
   - Converted via `str(value)` and treated as plain text.

These rules MUST be fully documented in `_to_rich_text`’s doc comment.

### 2.2 `_on_text_state_changed` implementation

Implement `_on_text_state_changed` analogous to `ReactiveLabel`, but calling `_to_rich_text`:

```gdscript
func _on_text_state_changed(new_value: Variant, old_value: Variant) -> void:
	if _updating:
		return

	_rebind_nested_states(new_value)
	var new_text := _to_rich_text(new_value)

	if text == new_text:
		return

	_updating = true
	text = new_text

	# Trigger animations if configured
	if animations.size() > 0:
		_on_trigger_text_changed(new_value, old_value)

	_updating = false
```

### 2.3 `_to_rich_text` implementation

- Mirror the structure of `ReactiveLabel._to_text`, but implement BBCode formatting.
- The exact implementation MUST:
  - Be a `func _to_rich_text(value: Variant) -> String`.
  - Implement the rules from **2.1** in a deterministic order.
  - Decide on a **single** BBCode tag for size (either `[size]` or `[font_size]`) and stick to it.
    - For consistency, choose:
      - `[size=N]` … `[/size]` (Godot’s standard RichTextLabel BBCode).
  - If `"color"` is a `Color`, use `color.to_html(false)` to get `"#rrggbb"`.
  - If `"color"` is a `String`, use it as‑is (assumed valid).

### 2.4 `_rebind_nested_states` and `_on_nested_changed`

Reuse the semantics from `ReactiveLabel`, adapted only by function names:

- `_rebind_nested_states(value: Variant)`:
  - Disconnects existing `_nested_states`.
  - Clears `_nested_states`.
  - If `value` is an `Array`:
    - Iterates each element recursively:
      - If element is a `State`, connect its `value_changed` to `_on_nested_changed` and store it in `_nested_states`.
      - If element is a `Dictionary` and its `"text"` field is a `State` or `Array`, traverse recursively and add any nested `State`s.
  - Must ensure it **never** double‑connects the same `State` instance.

- `_on_nested_changed(_new_value: Variant, _old_value: Variant)`:
  - If `text_state` is not null:
    - Call `_on_text_state_changed(text_state.value, text_state.value)` to recompute the full rich text.

Note: For simplicity and determinism, all nested `State`s MUST be treated as read-only data sources; `ReactiveRichTextLabel` never writes back to them.

---

## Phase 3 – Animation Integration

**Objective**: Integrate `ReactiveRichTextLabel` with `AnimationReel` in the same way as `ReactiveLabel`.

### 3.1 `_validate_animation_reels`

Implement `_validate_animation_reels()` exactly parallel to `ReactiveLabel`:

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
	var has_hover_enter_targets = result.trigger_map.get(AnimationReel.Trigger.HOVER_ENTER, false)
	var has_hover_exit_targets = result.trigger_map.get(AnimationReel.Trigger.HOVER_EXIT, false)

	# Connect signals based on which triggers are used
	if has_hover_enter_targets:
		if not mouse_entered.is_connected(_on_trigger_hover_enter):
			mouse_entered.connect(_on_trigger_hover_enter)
	if has_hover_exit_targets:
		if not mouse_exited.is_connected(_on_trigger_hover_exit):
			mouse_exited.connect(_on_trigger_hover_exit)
```

### 3.2 Trigger handlers

Implement the following trigger handlers, identical in behavior to `ReactiveLabel`:

```gdscript
func _on_trigger_text_changed(_new_value: Variant, _old_value: Variant) -> void:
	if _is_initializing:
		return
	_trigger_animations(AnimationReel.Trigger.TEXT_CHANGED)

func _on_trigger_hover_enter() -> void:
	_trigger_animations(AnimationReel.Trigger.HOVER_ENTER)

func _on_trigger_hover_exit() -> void:
	_trigger_animations(AnimationReel.Trigger.HOVER_EXIT)
```

### 3.3 `_trigger_animations`

Implement `_trigger_animations(trigger_type)` in the same style as `ReactiveLabel`:

```gdscript
func _trigger_animations(trigger_type) -> void:
	if animations.size() == 0:
		return

	for reel in animations:
		if reel == null:
			continue
		if reel.trigger != trigger_type:
			continue
		reel.apply(self)
```

### 3.4 `_finish_initialization`

Implement `_finish_initialization()`:

```gdscript
func _finish_initialization() -> void:
	_is_initializing = false
```

This MUST be called via `call_deferred("_finish_initialization")` in `_ready()` as specified in Phase 1.

### 3.5 Control type hint

Implement `_get_control_type_hint()` to return the label hint:

```gdscript
func _get_control_type_hint() -> AnimationReel.ControlTypeHint:
	return AnimationReel.ControlTypeHint.LABEL
```

This ensures that `AnimationReel`’s Inspector shows label-appropriate triggers (TEXT_CHANGED + HOVER) and keeps semantics in sync with `ReactiveLabel`.

---

## Phase 4 – Documentation and Inspector Polish ✅ **COMPLETED**

**Objective**: Match the documentation quality and Inspector clarity of existing reactive controls.

### 4.1 Class-level documentation

Add a class doc comment above `@tool` describing:

- What `ReactiveRichTextLabel` is.
- How it differs from `ReactiveLabel` (supports BBCode / rich formatting).
- How `text_state` is interpreted (summarize rules from Phase 2).
- How animations and triggers are configured.

### 4.2 Property documentation

Add doc comments for:

- `text_state`:
  - Explain expected value shapes (`String`, `Array`, `Dictionary`, nested `State`s).
- `animations`:
  - Same wording pattern as other reactive controls’ `animations` export.

### 4.3 Method documentation

Add GDScript doc comments (`##`) at minimum for:

- `_ready`
- `_validate_animation_reels`
- `_on_text_state_changed`
- `_rebind_nested_states`
- `_on_nested_changed`
- `_to_rich_text`
- `_trigger_animations`
- `_on_trigger_text_changed`
- `_on_trigger_hover_enter`
- `_on_trigger_hover_exit`
- `_finish_initialization`
- `_get_control_type_hint`

Each doc comment MUST describe:

- The purpose of the method.
- Any important side effects or invariants (e.g., `_updating` flag behavior, `text` changes, when animations are triggered).

---

## Phase 5 – Testing & Verification

**Objective**: Verify correctness and ergonomics of `ReactiveRichTextLabel` against concrete scenarios.

### 5.1 Test scenes

Create a small set of Godot scenes (names to be decided later, but MUST include at least):

1. `RichTextBasic.tscn`
   - `ReactiveRichTextLabel` with `text_state.value` as plain `String` containing simple BBCode.
   - No animations.

2. `RichTextSegments.tscn`
   - `ReactiveRichTextLabel` bound to a `State` whose `value` is an `Array` containing:
     - Plain strings.
     - Dictionaries with `"text"`, `"bold"`, `"color"`.
     - Nested `State`s.
   - Verify that updates to nested `State`s cause the label to update.

3. `RichTextAnimations.tscn`
   - Attach `AnimationReel` resources to `animations`.
   - Configure reels for `TEXT_CHANGED`, `HOVER_ENTER`, `HOVER_EXIT` triggers.
   - Verify that animations fire exactly when expected.

### 5.2 Edge cases

Explicitly verify:

- `text_state` is null → control does nothing (no errors).
- `text_state.value` switches between different shapes (e.g. `String` → `Array` → `Dictionary`) at runtime.
- Nested `State`s are properly disconnected and reconnected when `text_state.value` changes from one array/dictionary shape to another.
- No infinite loops when nested `State` changes (guarded by `_updating`).

---

## Phase 6 – Future Extensions (Non-blocking)

These are **optional** and NOT part of the initial implementation, but the design should not block them:

1. Support for **inline icons** (e.g., dictionaries with `"icon": Texture2D` and `"text"`).
2. Configurable BBCode escaping rules (e.g., safe plain text mode vs fully trusted BBCode).
3. Additional formatting keys in segment dictionaries (e.g., `"align"`, `"font"`, `"background_color"`), as long as they map cleanly to Godot’s RichTextLabel tags.

These can be appended to `_to_rich_text` rules with backward-compatible defaults.



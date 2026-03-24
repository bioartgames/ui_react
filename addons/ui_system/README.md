# Reactive UI System

Self-contained UI building blocks for Godot 4.x: attach **UiReact\*** scripts for two-way **UiState** binding, optional **inspector-driven animations** via **UiAnimTarget**, and a code-friendly **UiAnimUtils** tween facade—so you can build polished UI with little or no game code.

---

## The 3-step setup (repeat for every control)

1. **Attach** the matching `UiReact*` script to a native Control (Button, HSlider, Label, …).
2. **Assign** `UiState` (or optional typed `UiBoolState` / `UiFloatState` / `UiStringState` / `UiArrayState`) on the exported fields you care about (pressed/value/text/etc.).
3. **Optionally** fill `animation_targets` with `UiAnimTarget` entries to run tweens from the Inspector (no tween code).

That’s it. Game logic can read/write the same `UiState` resources; controls stay in sync.

### Inspector hints (Godot 4.x)

- **`UiAnimTarget.target` / `UiControlTargetCfg.target`**: exported as a **Control-only** node path (`@export_node_path("Control")`). The picker rejects non-`Control` nodes.
- **`UiAnimTarget` tuning numbers** (duration, repeat count, rotate angle, pop/pulse/shake/flash intensity, etc.): use **@export_range** sliders/spinboxes in the Inspector—see tooltips on each field.

---

## Quickstart

### 1) Add the addon

Copy `addons/ui_system/` into your Godot project at **`addons/ui_system/`**. Open the project and wait for import.

### 2) Run the example

Open **`res://addons/ui_system/examples/reactive_ui.tscn`** and press **Play** (or set it as **Main Scene** in **Project Settings → Application → Run**). Use the scene tree to see how states and targets are wired.

### 3) Minimal recipes (editor-first, no code required)

**Button + pressed state**

1. Add a **Button**, attach **`UiReactButton`** (`scripts/controls/ui_react_button.gd`).
2. Create a **UiState** resource (`scripts/api/models/ui_state.gd`), set `value` to `false` (or your default).
3. Assign it to **`pressed_state`** on the button.
4. Optional: assign **`disabled_state`** and/or **`animation_targets`**.

**Slider + shared value**

1. Add **HSlider**, attach **`UiReactSlider`**.
2. Create **UiState** with a numeric `value` (e.g. `50.0`).
3. Assign to **`value_state`**.

**Label + text from state**

1. Add **Label**, attach **`UiReactLabel`**.
2. Create **UiState** with `value` as **String** (or nested structure per label docs).
3. Assign to **`text_state`**.

### 4) Optional: animations from code

```gdscript
await UiAnimUtils.animate_expand(self, some_control).finished
```

**Named show/hide presets (preferred):** use `UiAnimUtils.preset(UiAnimUtils.Preset.FADE_IN, self, panel)` (enum) instead of string-based `show_animated` / `hide_animated`, which remain for older projects.

`UiAnimUtils` is **`res://addons/ui_system/scripts/api/ui_anim_utils.gd`** (global class `UiAnimUtils`).

---

## Required vs optional (by control)

| Control | Bindings (typical) | Required for “reactive” behavior |
|--------|--------------------|----------------------------------|
| **UiReactButton** | `pressed_state`, `disabled_state` | At least one state if you want sync with `UiState`; neither required for a plain Button. |
| **UiReactCheckBox** | `checked_state`, `disabled_state` | Same pattern as Button. |
| **UiReactSlider** | `value_state` | Assign `value_state` for two-way sync; else behaves like a normal slider. |
| **UiReactSpinBox** | `value_state`, `disabled_state` | `value_state` for sync; `disabled_state` optional. |
| **UiReactProgressBar** | `value_state` | `value_state` for sync from state. |
| **UiReactLineEdit** | `text_state` | `text_state` for sync. |
| **UiReactLabel** | `text_state` | `text_state` for sync. |
| **UiReactOptionButton** | `selected_state`, `disabled_state` | `selected_state` for sync (usually string item text). |
| **UiReactItemList** | `selected_state`, `disabled_state` | `selected_state` for selection sync. |
| **UiReactTabContainer** | `selected_state`, `tab_config` | `selected_state` for index sync; `tab_config` optional (dynamic tabs / per-tab states). |

**`animation_targets`** is always **optional**: leave empty if you don’t want automatic tweens.

---

## Public API (use directly)

Paths are under **`res://addons/ui_system/`**.

| Kind | Global class / area | Path |
|------|---------------------|------|
| Animation facade | `UiAnimUtils` | `scripts/api/ui_anim_utils.gd` |
| Chained animations (optional) | `UiAnimSequence` | `scripts/internal/anim/ui_anim_sequence.gd` |
| State (generic) | `UiState` | `scripts/api/models/ui_state.gd` |
| State (optional typed) | `UiBoolState`, `UiFloatState`, `UiStringState`, `UiArrayState` | `scripts/api/models/ui_*_state.gd` |
| Inspector animation row | `UiAnimTarget` | `scripts/api/models/ui_anim_target.gd` |
| Config bases | `UiTargetCfg`, `UiControlTargetCfg`, `UiTabContainerCfg` | `scripts/api/models/` |
| Attachable controls | `UiReact*` | `scripts/controls/` |

Prefer **`UiAnimUtils`** for tweens from code; prefer **`UiAnimTarget`** arrays on controls for no-code animation.

**Typed vs generic `UiState`:** `UiState` accepts any `Variant` and is the default. Use `UiBoolState` / `UiFloatState` / `UiStringState` / `UiArrayState` when you want clearer intent in the Inspector and typed helpers (`get_float_value()`, etc.). Existing scenes using `UiState` do not need to change.

---

## Used by controls (avoid importing unless advanced)

- Internal animation modules: `scripts/internal/anim/*` (runners, families, snapshot store).
- Internal react helpers: `scripts/internal/react/*` (binding utilities, tab plumbing).

These may change between template versions; **do not rely on them from game code** unless you accept maintenance cost.

---

## Common mistakes

| Symptom | Likely cause | Fix |
|--------|----------------|-----|
| Animation never plays | Empty `animation_targets`, wrong **Trigger**, or invalid **Target** NodePath | In Inspector: set Trigger, drag a **Control** onto Target, pick animation type. Check Output for warnings. |
| State doesn’t sync | `UiState` not assigned, or wrong type | Assign the exported `*_state` field; ensure `UiState.value` type matches (bool/float/String/Array as documented). |
| “Target not found” warning | NodePath not under this node | Use a path relative to the control, or drag the node into the Target field. |
| Tab arrays don’t apply | `tabs_state` / `disabled_tabs_state` / `visible_tabs_state` not an **Array** | Those `UiState` values must be `Array` (see Output warning). |

---

## Layout

| Path | Purpose |
|------|---------|
| `scripts/api/` | Public entry points (`UiAnimUtils`). |
| `scripts/api/models/` | Public resources (`UiState`, `UiAnimTarget`, configs). |
| `scripts/controls/` | Attachable **UiReact\*** scripts. |
| `scripts/internal/anim/` | Animation implementation (unstable for direct use). |
| `scripts/internal/react/` | Reactive helpers (unstable for direct use). |
| `examples/` | `reactive_ui.tscn` smoke demo. |
| `docs/` | Extra notes (e.g. migration). |
| `ui_resources/` | Sample `.tres` for the example scene. |

---

## Importing into another project

Copy the entire **`addons/ui_system/`** folder into the host project’s **`addons/`** directory, reimport, then attach scripts from **`scripts/controls/`** or call **`UiAnimUtils`** from your game code.

Extended path mapping (old tree → addon) lives in **`docs/migration.md`** if present.

---

## Optional upgrades (non-breaking)

| You have | Optional improvement |
|----------|----------------------|
| Generic `UiState` everywhere | Swap to `UiBoolState` / `UiFloatState` / `UiStringState` / `UiArrayState` where it clarifies payload type. |
| `show_animated` / `hide_animated` with strings | Prefer `UiAnimUtils.preset(...)` with `UiAnimUtils.Preset` enums. |
| Plain `NodePath` targets in mind | Inspector now restricts targets to **Control**; existing saved paths still load. |

# Reactive UI System

Self-contained UI building blocks for Godot 4.x: reactive controls, shared `UiState` resources, and a tween-based animation facade.

## Layout

| Path | Purpose |
|------|---------|
| `scripts/api/` | **Public** entry points. Call these from game code. |
| `scripts/api/models/` | **Public** resources: `UiState`, `UiAnimTarget`, tab/config types. |
| `scripts/controls/` | **Public** node scripts: attach `UiReact*` to Control nodes. |
| `scripts/internal/anim/` | Animation implementation (runners, families, helpers). **Not** part of the stable public surface. |
| `scripts/internal/react/` | Reactive binding helpers and tab plumbing. Prefer using controls + `UiState` instead of importing these. |
| `examples/` | Demo scene (`reactive_ui.tscn`) for smoke testing. |
| `docs/` | Supporting docs (migration and extended notes). |
| `ui_resources/` | Sample `.tres` resources used by the example scene. |

## Quickstart

### 1) Add the addon

Copy `addons/ui_system/` into your Godot project at the same path (`addons/ui_system/`). Open the project in the editor and wait for import to finish.

### 2) Run the example

Open `res://addons/ui_system/examples/reactive_ui.tscn` and press **Play** (or set it as the main scene in **Project Settings -> Application -> Run**).

### 3) Use a reactive control

1. Add a native control node (for example, **Button**).
2. In the **Inspector -> Script**, attach `res://addons/ui_system/scripts/controls/ui_react_button.gd` (or pick class `UiReactButton`).
3. Create a **UiState** resource and assign it to `pressed_state` / `disabled_state`.
4. Optionally add **UiAnimTarget** entries for inspector-driven animations.

### 4) Drive animations from code

```gdscript
await UiAnimUtils.animate_expand(self, some_control).finished
```

`UiAnimUtils` lives at `res://addons/ui_system/scripts/api/ui_anim_utils.gd` and is registered as global class `UiAnimUtils`.

### 5) Shared state resource

Use `res://addons/ui_system/scripts/api/models/ui_state.gd` (`UiState`) for shared state. Bind the same resource to multiple controls and/or game logic via `value_changed`.

## Public API

These are the supported surfaces for host projects. Paths below are relative to `res://addons/ui_system/`.

### Animation

| Global class | Script path | Role |
|--------------|-------------|------|
| `UiAnimUtils` | `scripts/api/ui_anim_utils.gd` | Facade for tween-based UI animations (slide, scale, fade, effects, presets, stagger, delay). |
| `UiAnimSequence` | `scripts/internal/anim/ui_anim_sequence.gd` | Optional chained animation helper (used with the facade pattern). |

Prefer calling `UiAnimUtils` from game code instead of importing individual animation internals.

### State and targets

| Global class | Script path | Role |
|--------------|-------------|------|
| `UiState` | `scripts/api/models/ui_state.gd` | Generic reactive value holder with `value_changed`. |
| `UiAnimTarget` | `scripts/api/models/ui_anim_target.gd` | Inspector-friendly animation configuration on controls. |
| `UiTargetCfg` | `scripts/api/models/ui_target_cfg.gd` | Base class for target configuration resources. |
| `UiControlTargetCfg` | `scripts/api/models/ui_control_target_cfg.gd` | Control-specific target configuration. |
| `UiTabContainerCfg` | `scripts/api/models/ui_tab_container_cfg.gd` | Bundles tab-related `UiState` bindings for `UiReactTabContainer`. |

### Controls (attach to nodes)

Scripts in `scripts/controls/`:

- `UiReactButton`, `UiReactCheckBox`, `UiReactSlider`, `UiReactSpinBox`
- `UiReactOptionButton`, `UiReactItemList`, `UiReactLineEdit`, `UiReactLabel`
- `UiReactProgressBar`, `UiReactTabContainer`

### Internal (not public API)

Do not treat these as stable contracts for host projects:

- `scripts/internal/anim/*` - animation runners, snapshot store, family implementations.
- `scripts/internal/react/*` - binding helpers, tab sync, transition animator.

They exist to support controls and the facade; paths and internals may change between releases.

## What to use in a host project

- **State**: `UiState` resources (`scripts/api/models/ui_state.gd`).
- **Animations from code**: `UiAnimUtils` (`scripts/api/ui_anim_utils.gd`).
- **Inspector-driven targets**: `UiAnimTarget` (`scripts/api/models/ui_anim_target.gd`).
- **Reactive controls**: scripts under `scripts/controls/` (e.g. `UiReactButton`, `UiReactSlider`).

Avoid depending on paths under `scripts/internal/` from game code; they may change between template versions.

## Importing this template

Copy the entire `addons/ui_system/` folder into your project’s `addons/` directory, then open Godot and let it reimport. Set your main scene or instantiate nodes from `scripts/controls/` as needed.

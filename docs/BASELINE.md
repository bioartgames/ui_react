# UI System Baseline (Refactor Contract Lock)

This document locks **serialization contracts** and **behavior expectations** before architectural refactors. Do not change enum member order without migrating saved scenes/resources.

## Engine

- Project targets Godot **4.x** (see `project.godot` `config/features`).
- Main demo scene: `scenes/reactive_ui.tscn` (referenced by `run/main_scene`).

## Critical serialization contracts

### `State` (`scripts/reactive/state.gd`)

- `value_changed(new_value, old_value)` — two arguments; order must not change.
- `set_value()` emits `value_changed` and `emit_changed()`.
- `set_silent()` updates `value` and `emit_changed()` only (no `value_changed`).

### `AnimationTarget` (`scripts/utilities/animation_target.gd`)

- `Trigger` and `AnimationAction` enums are persisted as **integer ordinals** in `.tscn` / `.tres`.
- **Do not reorder** existing enum entries; only **append** new values.
- `Easing` enum order affects Inspector defaults and serialized values.

### `AnimationTarget` subresources in scenes

- Inline `SubResource` blocks may store `trigger = N`, `animation = M` as raw integers.
- Any enum change requires re-saving scenes or a migration script.

## Smoke checklist (manual)

Run the main scene and verify:

1. **Startup**: No unexpected animations; controls match initial `State` values.
2. **Disable actions** checkbox toggles disabled state on linked controls.
3. **Slider** ↔ **ProgressBar** stay in sync; value-increase/decrease animations behave.
4. **Option button** / **Item list** / **Spin box** interactions and animations.
5. **Line edit** updates label text; focus/text-enter triggers if configured.
6. **Tab container**: switching tabs; optional tab animations do not loop or stick.

## Regression gates

- Opening `scenes/reactive_ui.tscn` in the editor: no missing script/resource errors.
- Output panel: no spike in warnings vs this baseline after each refactor phase.

## Refactor changelog (high level)

- Legacy `AnimationConfig` removed; `AnimationTarget` is the single animation model for configs.
- `ReactiveTabContainer` logic split into `TabCollectionSync`, `TabContentStateBinder`, `TabSelectionBinding`, `TabTransitionAnimator`.
- Reactive controls use `ReactiveAnimationTargetHelper.validate_and_map_triggers` and `ReactiveStateBindingHelper.deferred_finish_initialization`.

# Migration notes

## `AnimationConfig` removed

The `AnimationConfig` resource was removed. Use [AnimationTarget](res://scripts/utilities/animation_target.gd) everywhere.

- Old: `config.animation.action = AnimationConfig.AnimationAction.EXPAND`
- New: `config.animation.animation = AnimationTarget.AnimationAction.EXPAND`

[ControlTargetConfig](res://scripts/utilities/control_target_config.gd) now exposes `animation: AnimationTarget`. The `trigger` field on `AnimationTarget` is ignored when applying from `ControlTargetConfig` (only `apply_to_control` is used).

## New animation modules

- `AnimationSnapshotStore` — unified control snapshots
- `AnimationTweenFactory` — safe tweens and viewport helpers
- `AnimationDelayHelpers` — sequence delays
- `AnimationStaggerRunner` — staggered multi-control animations

`UIAnimationUtils` remains the public API and delegates to these modules.

## Tab content state callback

`ReactiveTabContainer._on_tab_content_state_changed` was updated so parameters match `Callable.bind(tab_index, property)` with `value_changed(new_value, old_value)` (bound arguments are passed first by the engine). Signature: `(tab_index: int, property: String, new_value: Variant, _old_value: Variant)`.

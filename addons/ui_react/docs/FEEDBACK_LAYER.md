# Ui React — Feedback layer (normative)

**Status:** Normative specification for **Phase P6.3** (**CB-061**) reactive feedback hooks. Runtime implementation **must** conform to this document until a superseding revision is recorded in [`CHANGELOG.md`](CHANGELOG.md) and Charter in [`ROADMAP.md`](ROADMAP.md).

**Charter (one line):** Ui React adds inspector-authored **`audio_targets`** and **`haptic_targets`** on **`UiReact*`** controls—each row is a **`Resource`**—so **non-visual sensory** reactions (one-shot **`AudioStreamPlayer.play()`** and **`Input.start_joy_vibration`**) are serializable and validator-friendly **without** owning game audio buses, streaming policy, or gameplay orchestration.

---

## 1. Purpose

**Problem:** Menus and confirmations often need click sounds and controller rumble aligned with the **same trigger vocabulary** as **`animation_targets`** / **`action_targets`**, but those cues should not be duplicated ad hoc across scripts.

**Feedback layer:** Declarative **`UiReactAudioFeedbackTarget`** / **`UiReactHapticFeedbackTarget`** rows on hosts listed in **§4**, mirroring the **when + what** shape of actions (shared **`UiAnimTarget.Trigger`** + optional **`state_watch: UiBoolState`**).

---

## 2. Boundaries vs Wiring, Action, Animation

| Layer | Declares | Must not |
|-------|----------|----------|
| **Wiring (P5)** | Data orchestration via **`wire_rules`** | Replace control-local playback hooks |
| **Actions (P6.1)** | Non-motion **presentation** + bounded numeric **`UiState`** ops via **`UiReactActionKind`** | Audio playback, haptics — use **Feedback** exports |
| **Animation** | Tweens via **`animation_targets`** / **`UiAnimUtils`** | Audio/haptics inside **`UiAnimTarget`** |
| **Feedback (CB-061)** | **`audio_targets`**, **`haptic_targets`** | Animation/tween APIs, **`UiReactActionKind`** presets, **`wire_rules`**, game-domain glue |

**Audio buses, mixer routing, ducking, UI mute settings, and handheld vibration (`Input.vibrate_handheld`)** are **project-owned** — the addon only invokes **`AudioStreamPlayer.play()`** and **`Input.start_joy_vibration`** as narrow hooks.

Cross-reference: [`ACTION_LAYER.md`](ACTION_LAYER.md) §2 — **`UiReactActionKind`** **must not** be extended for audio or haptics.

---

## 3. Row models

### 3.1 `UiReactAudioFeedbackTarget`

- **`enabled`**: `bool`, default `true`.
- **`state_watch`**: nullable **`UiBoolState`**. If non-null, row runs from **`value_changed`** + initial sync only; **`trigger` ignored** at runtime (**[`FEEDBACK_LAYER.md`](FEEDBACK_LAYER.md) §9** dispatch semantics; shape aligns with [`ACTION_LAYER.md`](ACTION_LAYER.md) **§3.1**).
- **`trigger`**: **`UiAnimTarget.Trigger`** — used only when **`state_watch`** is null (control-signal-driven).
- **`player`**: **`NodePath`** to an **`AudioStreamPlayer`** node **reachable from the host control** (relative path). Runtime: **`play()`** only (v1).

### 3.2 `UiReactHapticFeedbackTarget`

- **`enabled`**, **`state_watch`**, **`trigger`** — same semantics as **§3.1**.
- **`device_id`**: `int`, default **`-1`**. Runtime: **`-1`** means use the first entry of **`Input.get_connected_joypads()`** when non-empty; otherwise **silent no-op**.
- **`weak_magnitude`**, **`strong_magnitude`**: clamped to **`[0.0, 1.0]`** before **`Input.start_joy_vibration`**.
- **`duration_sec`**: must be **`> 0`** for a valid row; invalid rows are filtered with warnings (editor + runtime validate).

---

## 4. Host coverage

Any **`UiReact*`** control with an entry in **`ANIM_TRIGGERS_BY_COMPONENT`** ([`editor_plugin/ui_react_component_registry.gd`](../editor_plugin/ui_react_component_registry.gd)) exports **`audio_targets`** and **`haptic_targets`**. Allowed **`trigger`** values **per host** match that registry (same rule as motion diagnostics).

---

## 5. Validator intent (editor)

- Null rows → warning.
- Unknown/wrong resource type → warning / skip.
- **Trigger** not allowed for component → warning (**reuse animation trigger allowlist**).
- **Audio:** **`player`** resolves to an **`AudioStreamPlayer`** under the host subtree.
- **Haptic:** **`duration_sec > 0`**; magnitudes outside **`[0, 1]`** → warning (runtime still clamps).
- **`state_watch`** set and **`trigger != PRESSED`** → warning (authoring hygiene; **`trigger`** unused at runtime for state-driven rows).

---

## 6. Non-goals (v1)

- **`UiReactItemList` / `UiReactTree`** **`play_selected_row_animation`** / **`play_preamble_reset_only`** — **do not** dispatch feedback rows (animations-only APIs).
- Dock **Quick edit** / graph shallow authoring for feedback rows (**Inspector-first**; future **CB-053**).
- **`UiReactComputedGraphRebind.follow_path`** extensions for feedback-specific contexts.
- **`Input.vibrate_handheld`** and platform-adaptive trigger APIs.
- Per-row **`selection_slot`** for feedback (use wiring or game code if row-scoped cues are required).

---

## 7. Ordering

Within each array, **control-triggered** rows matching the same **`trigger`** run in **ascending array index** order (same contract as **`UiReactActionTargetHelper.run_actions`**).

---

## 9. Execution semantics (normative)

Bool coercion uses **[`UiReactStateBindingHelper.coerce_bool`](../scripts/internal/react/ui_react_state_binding_helper.gd)** on **`get_value()`** / **`value_changed`** arguments so subclasses and **`Variant`** payloads behave consistently with the Action layer.

### 9.1 Control-triggered (`state_watch == null`)

Unchanged from §7: **`run_audio_feedback`** / **`run_haptic_feedback`** filter enabled rows with **`trigger == T`**, **`state_watch == null`**, and optional disabled gating (`respects_disabled`, `is_disabled`).

### 9.2 State-driven (`state_watch != null`)

- **Initial sync:** **[`UiReactFeedbackTargetHelper.sync_initial_state`](../scripts/internal/react/ui_react_feedback_target_helper.gd)** runs once per control setup after **`owner.is_inside_tree()`**. For each eligible audio/haptic row with **`state_watch` set, **`play()`** / **`start_joy_vibration`** run **only if** **`coerce_bool(state_watch.get_value())`** is **true**. If the watched bool is **false**, no sensory output on load (avoids startup noise).
- **Updates:** On **`signal UiBoolState.value_changed(new, old)`**, sensory output runs **only on rising edge**: **`coerce_bool(new)`** is **true** and **`coerce_bool(old)`** is **false**. Toggles from true → false do **not** fire feedback via this path (one-shot “activation” cues). **`bind_value_changed`**’s synthetic first call uses **`(same, same)`**, so the rising-edge filter does **not** spuriously fire before real transitions.

This differs from [`ACTION_LAYER.md`](ACTION_LAYER.md) §5.1 for **presentation** presets that **reapply** on every **`value_changed`** (e.g. visibility): sensory hooks are intentionally **edge-triggered** for **`state_watch`** rows.

---

## 10. Related implementation

- Runtime: [`scripts/internal/react/ui_react_feedback_target_helper.gd`](../scripts/internal/react/ui_react_feedback_target_helper.gd)
- Models: [`scripts/api/models/ui_react_audio_feedback_target.gd`](../scripts/api/models/ui_react_audio_feedback_target.gd), [`scripts/api/models/ui_react_haptic_feedback_target.gd`](../scripts/api/models/ui_react_haptic_feedback_target.gd)
- Dock: [`editor_plugin/services/ui_react_feedback_validator.gd`](../editor_plugin/services/ui_react_feedback_validator.gd)

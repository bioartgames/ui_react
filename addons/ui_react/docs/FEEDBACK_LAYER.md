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
- **`state_watch`**: nullable **`UiBoolState`**. If non-null, row runs from **`value_changed`** + initial sync only; **`trigger` ignored** at runtime (same contract as [`ACTION_LAYER.md`](ACTION_LAYER.md) **§3.1** state-driven actions).
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

## 8. Related implementation

- Runtime: [`scripts/internal/react/ui_react_feedback_target_helper.gd`](../scripts/internal/react/ui_react_feedback_target_helper.gd)
- Models: [`scripts/api/models/ui_react_audio_feedback_target.gd`](../scripts/api/models/ui_react_audio_feedback_target.gd), [`scripts/api/models/ui_react_haptic_feedback_target.gd`](../scripts/api/models/ui_react_haptic_feedback_target.gd)
- Dock: [`editor_plugin/services/ui_react_feedback_validator.gd`](../editor_plugin/services/ui_react_feedback_validator.gd)

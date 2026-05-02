# Architecture and design decisions (Ui React)

**Maintenance:** Add an entry when you would re-argue the same design in six months. **Order:** newest first.

---

## 2026-05-01 — State-driven feedback: gated initial sync + rising edge

**Context:** Post-CB-061 audits noted ambiguity vs [`ACTION_LAYER.md`](ACTION_LAYER.md) “reflect state” semantics and poor UX if one-shot audio/haptics ran on **every** **`UiBoolState`** edge and unconditionally on **`sync_initial_state`**.

**Decision:** For **`state_watch` non-null** rows only: **`sync_initial_state`** runs **`play()`** / **`start_joy_vibration`** **only when** [`UiReactStateBindingHelper.coerce_bool`](../scripts/internal/react/ui_react_state_binding_helper.gd) applied to **`state_watch.get_value()`** is **true**. On **`value_changed(new, old)`**, run those rows **only on rising edge** (**`new`** coerces true and **`old`** coerces false). Control-triggered rows (**`state_watch` null**) unchanged. Migrating **`UiBoolState.value_changed`** wiring for feedback onto **`UiReactSubscriptionScope`** remains **future work** (same as action **`state_watch`** today).

**Consequences:** **[`FEEDBACK_LAYER.md`](FEEDBACK_LAYER.md)** §9 normative; **`CHANGELOG`** **Changed**; GUT updates. Authors needing cues on **falling** edge use **control-triggered** rows or game code.

**Links:** [`FEEDBACK_LAYER.md`](FEEDBACK_LAYER.md) §9, `scripts/internal/react/ui_react_feedback_target_helper.gd`

---

## 2026-05-01 — CB-061: separate `audio_targets` / `haptic_targets` (not `UiReactActionKind`); joy vibration v1

**Context:** Designers want click/UI confirmation audio and light controller rumble on the same triggers as animations/actions without scripting **`AudioStreamPlayer.play()`** or **`Input.start_joy_vibration`** by hand.

**Decision:** Add parallel **`Array[UiReactAudioFeedbackTarget]`** / **`Array[UiReactHapticFeedbackTarget]`** exports (**Feedback layer**), validated like animations/actions (paths, duplicates, trigger enums). **Do not** extend **`UiReactActionKind`** for audio/haptics—feedback stays **side-effect hooks**, not state mutations. Haptics v1: weak/medium presets mapped to **`Input.start_joy_vibration`** on connected joypads only (**PackedInt64Array** from **`Input.get_connected_joypads()`**); no SDL/OpenXR routing.

**Consequences:** **`FEEDBACK_LAYER.md`** normative spec; **`UiReactFeedbackTargetHelper`** mirrors subscription/teardown patterns from **`UiReactActionTargetHelper`**; editor **`UiReactFeedbackValidator`**; ROADMAP matrix columns; SemVer **minor** (**3.1.0**).

**Links:** [`FEEDBACK_LAYER.md`](FEEDBACK_LAYER.md), [`ACTION_LAYER.md`](ACTION_LAYER.md), `ui_react_feedback_target_helper.gd`, `ui_react_feedback_validator.gd`, **CB-061**

---

## 2026-04-29 — Deferred: trim global `class_name` surface + Tree pooling (audit follow-up)

**Context:** Review noted a broad **`class_name`** registration list (editor + runtime) and **full Tree rebuild** behavior when **`tree_items_state`** / list payloads churn (fine for modest data; costly at scale).

**Decision:** Defer **`class_name` reduction** to a chartered SemVer-conscious migration (no drive-by stripping). Defer **row reuse / pooling** to a scoped performance milestone with benchmarks and regressions.

**Consequences:** Expectations anchored for contributors; pooling or renaming later updates **CHANGELOG** / **ROADMAP** as appropriate.

**Links:** **`docs/CHANGELOG.md`**, **`scripts/controls/ui_react_tree.gd`**, **`scripts/controls/ui_react_item_list.gd`**

---

## 2026-04-09 — CB-058 / North star: Dependency Graph as blessed designer workbench

**Context:** Wiring, computeds, transactional, and actions are powerful but **spread** across Inspector, dock tabs, and scene tree. Designers benefit from a **single orchestration surface** (animation-tree-style) that **does not** fork the resource model.

**Decision:** Treat the **Dependency Graph** as the **blessed editor path** for **seeing and building** scoped UI/data microcosms—**same** `*.tscn` / `*.tres` shapes, **same** undo stack (`EditorUndoRedoManager` + existing commit helpers). **Inspector** and **Wire rules** tab remain **full** alternatives (**DRY**). **Official examples** stay **Inspector-authored** so the **Charter** evidence bar stays objective; prose in **README** / **ROADMAP** steers **tool** users to the graph first.

**Consequences:** **ROADMAP** Part I **North star** + **CB-058** Appendix row; **README** designer path; **WIRING_LAYER** / **ACTION_LAYER** editor callouts. Implementation milestones (disconnect, wire greenfield, file-backed targets, **Wiring** tab merge) remain **sequenced** in roadmap—not all shipped at once.

**Links:** [`ROADMAP.md`](ROADMAP.md), [`../README.md`](../README.md), [`WIRING_LAYER.md`](WIRING_LAYER.md), [`ACTION_LAYER.md`](ACTION_LAYER.md)

---

## 2026-04-07 — Button exports: `UiReactTransactionalHostBinding` + `SET_FLOAT_LITERAL` (replace flat transactional / press-write exports)

**Context:** Apply/Cancel and one-off float writes on **`UiReactButton`** / **`UiReactTextureButton`** used five separate Inspector exports (`transactional_*` triple + **`press_writes_float_*`**), overlapping the Action layer’s job for imperative steps.

**Decision:** Collapse transactional wiring into one optional **`transactional_host: UiReactTransactionalHostBinding`**. Fold press-time literal float writes into the Action layer as **`SET_FLOAT_LITERAL`** + **`UiReactStateOpService.set_float_literal`**. Ship as **SemVer major** (**3.0.0**); no deprecation shims.

**Consequences:** **[`CHANGELOG.md`](CHANGELOG.md) [3.0.0]**; **[`ACTION_LAYER.md`](ACTION_LAYER.md)** §3.2 item 10; **[`README.md`](../README.md)** matrix and transactional how-to.

**Links:** `ui_react_transactional_host_binding.gd`, `ui_react_action_target.gd`, `ui_react_state_op_service.gd`

---

## 2026-04-07 — CB-051: closed `UiReactActionKind` presets for whitelisted math (`UiReactStateOpService`)

**Context:** **`SUBTRACT_PRODUCT_FROM_FLOAT`** alone could not express refund-style add, pool-to-pool transfer, or **`UiIntState`** stacks without inventing ad hoc scripts or duplicating math in Computed-only paths.

**Decision:** Add **four** additive enum values (**`ADD_PRODUCT_TO_FLOAT`**, **`TRANSFER_FLOAT_PRODUCT_CLAMPED`**, **`ADD_PRODUCT_TO_INT`**, **`TRANSFER_INT_PRODUCT_CLAMPED`**) with typed **`@export`** fields on **`UiReactActionTarget`**, each delegating to a **named** **`UiReactStateOpService`** static. **No** generic expression layer; **no** `state_watch` on numeric mutators (control-triggered only, validator **error** otherwise). Int math uses overflow-safe **no-op** when multiply/add would leave signed 64-bit range.

**Consequences:** **`ACTION_LAYER.md`** §3.2 lists items 6–9; dock validates refs; **`shop_computed_demo.tscn`** exercises every new kind.

**Links:** [ACTION_LAYER.md](ACTION_LAYER.md) §3, `ui_react_state_op_service.gd`, **CB-051**

---

## 2026-04-06 — `SET_VISIBLE` branches on `state_watch` (mirror `SET_MOUSE_FILTER`)

**Context:** State-driven **`SET_VISIBLE`** rows ignored **`state_watch`** and always applied **`visible_value`**, unlike **`SET_MOUSE_FILTER`**, which already branched on **`state_watch.get_value()`**.

**Decision:** Add **`visible_when_true`** / **`visible_when_false`** on **`UiReactActionTarget`**, shown in the Inspector only when **`action == SET_VISIBLE`** and **`state_watch`** is set. Predicates (“dirty”, etc.) remain **`UiBoolState`** / **`UiComputedBoolState`** (or game-owned computeds); Actions only map bool → visibility on **`target`**, parallel to mouse-filter branching.

**Consequences:** **`ACTION_LAYER.md`** and validators describe the split; rare old scenes with **`state_watch` + `SET_VISIBLE`** may need migration (see **CHANGELOG**).

**Links:** [ACTION_LAYER.md](ACTION_LAYER.md) §3, `scripts/api/models/ui_react_action_target.gd`, **CB-056**

---

## 2026-04-06 — Charter evidence bar: official examples + symmetry (not dogfood)

**Context:** The maintainer will **not** rely on private-game dogfood; the old **3×** “same pattern in shipped game code” gate is unavailable.

**Decision:** **ROADMAP** **Charter** makes **official examples** (`addons/ui_react/examples/`, README **Quickstart**) the **objective** proof surface. **New** `UiReact*` wrappers ship only when **two** official examples **need** them. **Widened** inspector exports on existing controls ship only when the **Inspector surface matrix (CB-052)** or **Appendix** records the intent **and** at least **one** official example **exercises** the new surface—unless the change is validator-only / bugfix without public export shape change, or the matrix marks **—** with documented no-change.

**Consequences:** **CB-052** **†** / **○** → **●** work is justified by **symmetry** + **example updates**, not game repetition. ROADMAP intro, glossary (**Official example**, **Evidence bar**), P4 historical line, and matrix notes updated.

**Links:** [ROADMAP.md](ROADMAP.md) Charter + glossary, Part I **Inspector surface matrix (CB-052)**

---

## 2026-04-03 — Documentation spine for solo + agents

**Context:** The addon README grew large; normative behavior already lives in WIRING/ACTION specs. Solo dev and AI helpers need a small map and stable boundaries without a single “god doc.”

**Decision:** Add `docs/README.md` (routing only), `AGENTS.md` (scope and paths), and this `DECISIONS.md` log. README stays the author-facing story; specs remain authoritative for contracts.

**Consequences:** Extra files to maintain, but each stays short. Conflicts resolve: spec > README prose unless spec is wrong.

**Links:** [docs/README.md](README.md), [../AGENTS.md](../AGENTS.md)

---

## 2026-04-03 — Dock validation for `UiAnimTarget.Trigger` per host

**Context:** The full `Trigger` enum appears in the Inspector for every row, but each `UiReact*` only dispatches a subset; invalid combinations silently never fired.

**Decision:** Maintain **ANIM_TRIGGERS_BY_COMPONENT** in `editor_plugin/ui_react_component_registry.gd`; **`UiReactAnimValidator`** and control-driven **`UiReactActionValidator`** rows emit **WARNING** when the trigger is not listed for that component. Unknown/custom hosts skip the check. **UiReactTabContainer** **`SELECTION_CHANGED`** may use an empty animation **Target** (aligned with runtime `allow_empty_for`).

**Consequences:** Single source of truth to update when signal wiring changes; README documents supported triggers for humans.

**Links:** `editor_plugin/ui_react_component_registry.gd`, `editor_plugin/services/ui_react_validator_common.gd` (helpers), README “supported triggers per host”

---

## 2026-04-03 — Normative split: WIRING vs ACTION

**Context:** List/tree/filter/detail orchestration was drifting into scripts; imperative UI (focus, visibility, bounded float ops) needed a declarative home without duplicating wiring’s string jobs.

**Decision:** **`WIRING_LAYER.md`** owns **data-shaped** transforms and **wire rules**; **`ACTION_LAYER.md`** owns **`action_targets`** presets (non-motion, bounded state writes). README and ROADMAP cross-link; overlap is explicit (“Wiring wins” for conflicting string ownership).

**Consequences:** Two documents to update when boundaries move; clearer mental model than one mixed spec.

**Links:** [WIRING_LAYER.md](WIRING_LAYER.md), [ACTION_LAYER.md](ACTION_LAYER.md), ROADMAP **CB-031** / **CB-042**

---

## 2026-04-03 — Shared `UiAnimTarget.Trigger` for actions

**Context:** Action rows need a control-signal vocabulary; duplicating a second enum would drift.

**Decision:** **`UiReactActionTarget.trigger`** reuses **`UiAnimTarget.Trigger`** (defined on `UiAnimTarget` resource). Dispatch semantics differ (state-driven vs control-driven) but the enum is shared (**DRY**).

**Consequences:** Host trigger registry applies to both animation rows and control-driven action rows; state-driven rows use **`PRESSED`** as placeholder per ACTION validator conventions.

**Links:** `scripts/api/models/ui_react_action_target.gd`, [ACTION_LAYER.md](ACTION_LAYER.md) §3

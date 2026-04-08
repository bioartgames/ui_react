# Architecture and design decisions (Ui React)

**Maintenance:** Add an entry when you would re-argue the same design in six months. **Order:** newest first.

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

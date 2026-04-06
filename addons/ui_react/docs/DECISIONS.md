# Architecture and design decisions (Ui React)

**Maintenance:** Add an entry when you would re-argue the same design in six months. **Order:** newest first.

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

# Ui React — release readiness review (passes)

**Goal:** Bring the **Ui React** addon (`addons/ui_react/`) to a clean, lean **first public release**. Reviewed in **dependency-ordered passes** so each session has just enough context to judge real quality without hallucinating APIs.

**Scope:** Everything that ships or affects **plugin authors** (maintainer) or **plugin consumers** (game developers using the addon): runtime API, editor UX, user-facing docs, examples, plugin config.

**Out of scope (deep review):** `addons/gut/**`, GUT-specific patterns, internal process-only markdown, and the addon's own `tests/` line-by-line. A thin **test gate** still applies — see [§ Release gates](#release-gates).

**Companion docs:**

- [`addons/ui_react/AGENTS.md`](../addons/ui_react/AGENTS.md) — maintainer working agreement, key paths, hard boundaries.
- [`addons/ui_react/docs/README.md`](../addons/ui_react/docs/README.md) — documentation map for normative specs.
- [`docs/TESTING.md`](TESTING.md) — GUT rollout / test ledger.

---

## How to use this doc

1. **One pass per session.** Do not mix passes; context bloat is the main source of confabulated findings.
2. **Always start with the [Pass preamble](#pass-preamble-required-for-every-session).** Paste it into the agent's first message.
3. **Cite evidence.** Every finding must include `path:line` or a symbol reference, and (where relevant) a spec section from `WIRING_LAYER.md` / `ACTION_LAYER.md` / `EDITOR_COPY.md`.
4. **Score against [the rubric](#shared-rubric).** A finding without a rubric tag is a stylistic note, not a release blocker.
5. **Close each pass** by updating the [Completion ledger](#completion-ledger) and writing a **carry-forward note** (5–10 bullets) into the pass row.
6. **No drive-by edits.** Reviews produce findings; edits go through normal change policy ([`AGENTS.md` § Change policy](../addons/ui_react/AGENTS.md)). Findings tagged **P0 / P1** must land before tagging the release.

---

## Pass preamble (required for every session)

> You are conducting **Pass `<id>`** of the Ui React release readiness review.
>
> **Authoritative docs:** [`addons/ui_react/AGENTS.md`](../addons/ui_react/AGENTS.md), [`addons/ui_react/docs/README.md`](../addons/ui_react/docs/README.md), and the spec files it points to.
>
> **In scope (this pass only):** `<paths from pass row>`.
> **Out of scope:** everything else, especially `addons/gut/**`.
>
> **Carry-forward from prior passes:** `<paste bullets from completion ledger>`.
>
> **Deliverables:**
>
> 1. Findings list — each item: `severity (P0/P1/P2/P3) | rubric tag(s) | path:line or symbol | one-line description | suggested action or "defer with reason"`.
> 2. Rubric coverage table — for each rubric row: `applied / N/A` + one-sentence justification.
> 3. Carry-forward bullets (≤10) for the next pass: invariants, public types observed, open questions.
>
> **Hallucination guard:** Do not assert a symbol exists, a signal fires, or a script is `static` without opening the defining file in this session. If unsure, mark **needs verification** and stop.

---

## Shared rubric

Every pass scores against the relevant rows. Mark non-applicable rows **N/A** with a one-line reason rather than skipping silently.

| Tag | Dimension | What "good" means for v1 | Typical evidence |
|-----|-----------|---------------------------|------------------|
| **R-SOLID** | Single responsibility, open/closed | Files have one job; new wrappers extend without editing core god-files; wiring vs actions vs computed boundaries hold | Spec refs + file role table |
| **R-KISS** | Simplicity | Blessed paths are shallow; no speculative indirection; no abstract base nobody else extends | Trace the README quickstart through the code |
| **R-DRY** | No duplicated logic | String/catalog transforms not duplicated across wiring and actions; helpers used instead of copy-paste | Grep for the same pattern across layers |
| **R-YAGNI** | No unused capability | No dead exports, orphan menu IDs, unused resources, "future-proof" hooks without callers | Symbol search, scene/resource scan |
| **R-GODOT-API** | Correct Godot type usage | `Node` vs `Resource` vs `RefCounted` vs `Object` chosen for the right reasons; `Resource` only when persisting; `@tool` only when needed | File-by-file notes |
| **R-GODOT-LIFECYCLE** | Lifecycle hygiene | `_ready` / `_exit_tree` symmetry; signals disconnected; tweens cleaned up; no leaks of `Object`-derived data | Inspect callbacks, frees, signal teardown |
| **R-GODOT-LOAD** | Load model | `preload` for hot/fixed deps; `load` only where dynamic; no circular preloads; no `class_name` cycles | Trace top-of-file `preload` and `class_name` |
| **R-GODOT-STATIC** | Static vs instance | `static` only for stateless utilities; no instance state on `static`; classes vs services chosen sensibly | Audit `static func` and module-level state |
| **R-GDSCRIPT-STYLE** | GDScript idioms | `snake_case` funcs/vars, `PascalCase` classes, `SCREAMING_SNAKE` consts; explanatory names; type hints on public funcs; no abbreviations that hurt search | Spot audit |
| **R-EXPORT-SURFACE** | Inspector hygiene | `@export` names readable, grouped, tooltipped where ambiguous; `@export_group` / `@export_subgroup` consistent; no leaked debug exports | Inspector pass on each `UiReact*` |
| **R-POLISH** | Tooltips, diagnostics, copy | Strings actionable; tooltips match current behavior; empty / null / disabled states feel intentional | Compare strings to runtime + spec |
| **R-VOICE** | Editor copy | Matches [`EDITOR_COPY.md`](../addons/ui_react/docs/EDITOR_COPY.md) tone; same term for same concept everywhere (control names, action kinds, wire rule names) | Side-by-side terminology audit |
| **R-ONBOARDING** | README + blessed path | A new user can install the plugin and reach a working example following only README; examples match inspector reality | Walk the steps mentally; verify scenes load |
| **R-CLEAN-BREAK** | Lean v1 | No "temp until v1" shims, deprecated paths, or commented-out blocks; legacy compatibility layers either deleted or explicitly noted as known debt in CHANGELOG | Search `TODO`, `FIXME`, `DEPRECATED`, `legacy` |
| **R-SEMVER** | Stable surface | All `class_name`, public `@export` shapes, and documented resources are intentional; CHANGELOG reflects them | Diff against [CHANGELOG](../addons/ui_react/docs/CHANGELOG.md) |

**Severity convention** (used in findings):

- **P0 — release blocker.** Crashes, broken README path, public API mismatch with docs, misleading tooltip on a primary control, dead `class_name` exposed.
- **P1 — must fix before tag.** Confusing diagnostics, inconsistent naming on public surface, dead code in a public file, missing `@export` group on a primary control.
- **P2 — should fix or schedule.** Internal duplication, non-blocking polish, smaller copy issues.
- **P3 — nice-to-have / track.** Stylistic, refactor candidates with no user impact.

---

## Pass list

The order minimizes hallucination: contracts and small types first, then internals, then editor surface, then docs and examples that depend on everything before them.

| # | Name | Scope (in) | Scope (out) | Primary docs | Depends on |
|---|------|------------|-------------|--------------|------------|
| **0** | [Map & contracts](#pass-0--map--contracts) | `addons/ui_react/docs/**` (excluding history-only files), `addons/ui_react/AGENTS.md`, addon `README.md` | History (`CHANGELOG`, `DECISIONS`, `P5_CURRENT_STATE_AUDIT`) — read for *context only*, do not audit | `docs/README.md`, `WIRING_LAYER.md`, `ACTION_LAYER.md`, `MENU_GUIDELINES.md`, `EDITOR_COPY.md`, `ROADMAP.md` (Charter + glossary) | — |
| **1** | [Public API surface — models](#pass-1--public-api-surface--models) | `addons/ui_react/scripts/api/models/**`, `addons/ui_react/scripts/api/ui_anim_utils.gd` | Internals, controls | `WIRING_LAYER.md`, `ACTION_LAYER.md` | 0 |
| **2** | [Public API surface — controls](#pass-2--public-api-surface--controls) | `addons/ui_react/scripts/controls/**` | Internal helpers | `README` (Quickstart), Inspector surface matrix in `ROADMAP.md` | 0, 1 |
| **3** | [Runtime internals — react / state](#pass-3--runtime-internals--react--state) | `addons/ui_react/scripts/internal/react/**` (excluding tab + anim helpers split below) | Anim runtime, tab transition, controls | `WIRING_LAYER.md` | 1, 2 |
| **4** | [Runtime internals — animation](#pass-4--runtime-internals--animation) | `addons/ui_react/scripts/internal/anim/**`, `addons/ui_react/scripts/internal/react/ui_react_anim_target_helper.gd`, `addons/ui_react/scripts/internal/react/ui_tab_transition_animator.gd` | Wire / action runtime | `ACTION_LAYER.md` (motion vs actions boundary), `ui_react_component_registry.gd` `ANIM_TRIGGERS_BY_COMPONENT` | 1 |
| **5** | [Runtime internals — wiring](#pass-5--runtime-internals--wiring) | `addons/ui_react/scripts/internal/react/ui_react_wire_*.gd`, `addons/ui_react/scripts/api/models/ui_react_wire_*.gd`, `addons/ui_react/scripts/api/models/ui_react_action_target.gd` | Editor validators | `WIRING_LAYER.md`, `ACTION_LAYER.md` | 1, 3 |
| **6** | [Runtime internals — tab subsystem](#pass-6--runtime-internals--tab-subsystem) | `addons/ui_react/scripts/internal/react/ui_tab_*.gd`, `addons/ui_react/scripts/api/models/ui_tab_container_cfg.gd` | Editor surface | `README` tab section | 1, 2 |
| **7** | [Editor plugin spine](#pass-7--editor-plugin-spine) | `addons/ui_react/editor_plugin/ui_react_editor_plugin.gd`, `ui_react_component_registry.gd`, `editor_plugin/services/ui_react_scanner_service.gd`, `ui_react_state_factory_service.gd`, `ui_react_graph_resource_factory.gd`, `ui_react_scene_file_resource_paths.gd` | Dock UI, validators (separate passes) | `WIRING_LAYER.md`, `ACTION_LAYER.md`, registry constants | 1–6 |
| **8** | [Editor plugin — validators](#pass-8--editor-plugin--validators) | `editor_plugin/services/ui_react_validator_service.gd` + every `ui_react_*_validator.gd`, `ui_react_validator_common.gd`, `ui_react_*_introspection.gd`, `ui_react_*_catalog.gd` | Dock rendering | All specs | 7 |
| **9** | [Editor plugin — dock & graph UI](#pass-9--editor-plugin--dock--graph-ui) | `editor_plugin/dock/**`, `editor_plugin/controllers/**`, `editor_plugin/models/**`, dock-only services (`ui_react_explain_graph_*`, `ui_react_wire_graph_edit_service.gd`, `ui_react_dock_explain_scope_presets.gd`, `ui_react_value_preview_helper.gd`, `ui_react_unused_state_service.gd`, `ui_react_computed_*`) | Validators, runtime | `MENU_GUIDELINES.md`, `EDITOR_COPY.md`, `GRAPH_DEBUG_SURFACES.md` | 7, 8 |
| **10** | [Editor plugin — settings & shortcuts](#pass-10--editor-plugin--settings--shortcuts) | `editor_plugin/settings/**`, `editor_plugin/services/ui_react_editor_bottom_panel_shortcut.gd` | Dock, validators | `EDITOR_COPY.md` | 7 |
| **11** | [Examples & blessed path](#pass-11--examples--blessed-path) | `addons/ui_react/examples/**`, demo scripts they reference, `addons/ui_react/ui_resources/**` if cited by examples | Game projects consuming the addon | Addon `README.md` Quickstart, ROADMAP `Official example` glossary | 1, 2, 5 |
| **12** | [User-facing docs sweep](#pass-12--user-facing-docs-sweep) | Addon `README.md`, `WIRING_LAYER.md`, `ACTION_LAYER.md`, `MENU_GUIDELINES.md`, `EDITOR_COPY.md` for **public-facing accuracy** (not just internal consistency) | History-only docs | All earlier passes' findings | 1–11 |
| **13** | [Repo & plugin shell](#pass-13--repo--plugin-shell) | Repo `project.godot`, root `icon.*`, `addons/ui_react/editor_plugin/plugin.cfg`, `addons/ui_react/editor_plugin/ui_react_editor_plugin.gd` (plugin entrypoint), `.cursorignore`, `.vscode/settings.json` (only release-relevant entries) | `.godot/**` cache, `addons/gut/**` | — | — |
| **14** | [Integration sweep](#pass-14--integration-sweep) | Cross-cutting: registry ↔ validators ↔ runtime wiring ↔ examples ↔ README | — | All | 0–13 |

---

## Per-pass detail

Each pass section below uses the same structure: **objectives**, **files**, **release questions**, **rubric rows that apply**, **completion criteria**.

### Pass 0 — Map & contracts

- **Objectives:** Confirm the spec set is internally consistent and current; identify any rule that contradicts later passes' code; flag obsolete or duplicated guidance.
- **Files:** see scope table.
- **Release questions:**
  - Do the specs name a concept the same way the code does?
  - Are there unmarked TODOs or "to be revisited" notes that affect v1?
  - Does `EDITOR_COPY.md` actually describe the voice we use today?
  - Are there sections written for an unreleased phase that should be deferred?
- **Rubric:** R-VOICE, R-CLEAN-BREAK, R-YAGNI, R-ONBOARDING (docs side).
- **Done when:** Each spec is either approved as-is, or has a list of edits queued. Carry-forward includes the canonical glossary terms (control names, wire rule kinds, action kinds) that later passes must enforce.

### Pass 1 — Public API surface — models

- **Objectives:** Audit every `class_name`, `@export`, signal, and public method for v1 stability and clarity.
- **Files:** all of `addons/ui_react/scripts/api/models/**` + `ui_anim_utils.gd`.
- **Release questions:**
  - Is each model the right Godot type (`Resource` for persisted data, `RefCounted` for shared in-memory, `Node` only when in tree)?
  - Are exports grouped, ordered, and tooltipped where the meaning is non-obvious?
  - Does each `class_name` deserve to be a public symbol, or is it internal masquerading as public?
  - Are any `UiComputed*` or `UiReactWire*` rules unused by examples and should be cut?
- **Rubric:** R-SOLID, R-EXPORT-SURFACE, R-GODOT-API, R-GODOT-STATIC, R-GDSCRIPT-STYLE, R-SEMVER, R-YAGNI.
- **Done when:** Every public symbol has a recorded verdict (keep / rename / cut / defer) with a note. Carry-forward includes the **final** public type list.

### Pass 2 — Public API surface — controls

- **Objectives:** Confirm the `UiReact*` control set is the v1 surface and matches the inspector matrix.
- **Files:** `addons/ui_react/scripts/controls/**`.
- **Release questions:**
  - Does each control use shared helpers (`ui_react_base_button_reactive.gd`, `ui_react_control_state_wire.gd`) consistently?
  - Are `animation_targets`, `action_targets`, `wire_rules` exposed everywhere they should be (per the Inspector surface matrix in `ROADMAP.md`)?
  - Are tooltips authored on every export that needs them?
- **Rubric:** R-SOLID, R-DRY, R-EXPORT-SURFACE, R-POLISH, R-VOICE, R-SEMVER.
- **Done when:** Inspector matrix is verified against code. Carry-forward includes the final control list and any rename decisions.

### Pass 3 — Runtime internals — react / state

- **Objectives:** Validate the reactive core (state ops, computed service, binding helpers, transactional session, two-way driver, host wire tree).
- **Files:** `addons/ui_react/scripts/internal/react/**` *except* tab and anim helpers (covered in passes 4 and 6).
- **Release questions:**
  - Are `static` services truly stateless? If `UiReactComputedService` keeps state, is the lifecycle clear and reset-safe?
  - Is signal connect/disconnect symmetric on every host?
  - Any duplicated coercion / null handling between `ui_react_state_op_service.gd` and `ui_react_state_binding_helper.gd`?
- **Rubric:** R-SOLID, R-DRY, R-GODOT-LIFECYCLE, R-GODOT-STATIC, R-GDSCRIPT-STYLE, R-CLEAN-BREAK.
- **Done when:** Each file has a one-line role statement. Open questions for editor validators recorded.

### Pass 4 — Runtime internals — animation

- **Objectives:** Confirm the motion stack stays inside its lane (no action-side responsibilities) and cleans up tweens deterministically.
- **Files:** `addons/ui_react/scripts/internal/anim/**`, `ui_react_anim_target_helper.gd`, `ui_tab_transition_animator.gd`.
- **Release questions:**
  - Are `Tween` lifetimes tied to a node's lifetime?
  - Are baselines / snapshots restored on `_exit_tree` or scene change?
  - Is the `UiAnimTarget.Trigger` vocabulary identical to what the registry advertises per host?
  - Are there constants that belong in `ui_anim_constants.gd` instead of inline magic numbers?
- **Rubric:** R-SOLID (anim ↔ action boundary), R-GODOT-LIFECYCLE, R-GODOT-LOAD, R-CLEAN-BREAK, R-POLISH (default easing / durations).
- **Done when:** Trigger allowlist verified end-to-end. Anim runtime files have role statements.

### Pass 5 — Runtime internals — wiring

- **Objectives:** Audit the wiring rule set and runtime helper for v1 completeness and minimalism.
- **Files:** `ui_react_wire_rule_helper.gd`, `ui_react_wire_template.gd`, every `ui_react_wire_*.gd` model.
- **Release questions:**
  - Is each `UiReactWire*` rule used by an example or documented? If neither, defer or cut.
  - Do rules respect string ownership (no Action duplicates)?
  - Are pulse / continuous semantics consistent across rules?
- **Rubric:** R-SOLID (wiring vs action), R-DRY, R-YAGNI, R-EXPORT-SURFACE, R-VOICE (rule names), R-SEMVER.
- **Done when:** Rule catalog is the v1 set, mapped to examples. Carry-forward includes the canonical rule names for menu/dock review.

### Pass 6 — Runtime internals — tab subsystem

- **Objectives:** Confirm the tab helpers are stable and tested at the seam where pure logic meets Godot's `TabContainer`.
- **Files:** `ui_tab_selection_binding.gd`, `ui_tab_collection_sync.gd`, `ui_tab_content_state_binder.gd`, `ui_tab_container_cfg.gd`.
- **Release questions:**
  - Are tab helpers usable without a custom `TabContainer` subclass?
  - Are configs and bindings round-trip safe in the editor?
- **Rubric:** R-KISS, R-EXPORT-SURFACE, R-POLISH.
- **Done when:** Tab subsystem has a one-paragraph "how to use" matching README.

### Pass 7 — Editor plugin spine

- **Objectives:** Validate the plugin entry, registry, and core editor services that everything else depends on.
- **Files:** see scope table.
- **Release questions:**
  - Is `BINDINGS_BY_COMPONENT` / `ANIM_TRIGGERS_BY_COMPONENT` complete for every public control from passes 1–2?
  - Does the scanner handle missing scripts / partial scenes gracefully?
  - Are services correctly `static` vs instance?
  - Are editor-only operations guarded so they cannot run in exported builds?
- **Rubric:** R-SOLID, R-GODOT-API (`@tool`, editor APIs), R-GODOT-STATIC, R-GODOT-LOAD, R-CLEAN-BREAK.
- **Done when:** Registry is the source of truth for everything in passes 8–9.

### Pass 8 — Editor plugin — validators

- **Objectives:** Each validator emits actionable, deduplicated diagnostics consistent with the spec it enforces.
- **Files:** see scope table.
- **Release questions:**
  - Does the façade route to the right module without duplicating logic?
  - Are diagnostic messages and `fix_hint` strings authored per `EDITOR_COPY.md`?
  - Are severity levels consistent across validators?
  - Any validator producing warnings the user cannot act on?
- **Rubric:** R-SOLID, R-DRY, R-POLISH, R-VOICE.
- **Done when:** Diagnostic strings audited and the validator surface is the v1 set.

### Pass 9 — Editor plugin — dock & graph UI

- **Objectives:** Audit the Wiring tab, Explain graph, dock issue list, theme, and dock-only services for clarity, performance, and copy.
- **Files:** see scope table. Split into sub-passes if a single session feels overloaded:
  - **9a:** dock chrome + issue list + filter + theme (`ui_react_dock.gd`, `ui_react_dock_issue_list.gd`, `ui_react_dock_filter.gd`, `ui_react_dock_theme.gd`, `ui_react_dock_config.gd`, `ui_react_dock_details.gd`, `ui_react_dock_actions.gd`).
  - **9b:** Explain panel + graph view + scope + context menus (`ui_react_dock_explain_panel.gd`, `ui_react_explain_graph_view.gd`, `ui_react_dock_explain_*`).
  - **9c:** Wiring panel + wire rule sections + shallow editor + details (`ui_react_dock_wiring_panel.gd`, `ui_react_dock_wire_rules_section.gd`, `ui_react_dock_wire_rule_shallow_editor.gd`, `ui_react_dock_wire_details.gd`).
- **Release questions:**
  - Empty / null / first-launch states intentional and copy-checked?
  - Menus follow `MENU_GUIDELINES.md`?
  - Heavy graph operations debounced or chunked?
  - Tooltips match current behavior?
- **Rubric:** R-KISS, R-POLISH, R-VOICE, R-CLEAN-BREAK, R-GODOT-LIFECYCLE.
- **Done when:** UI matches `MENU_GUIDELINES.md` and `EDITOR_COPY.md`. Performance smoke acceptable on a representative scene.

### Pass 10 — Editor plugin — settings & shortcuts

- **Objectives:** Confirm settings surface (`ProjectSettings`, dock popup) and the bottom-panel shortcut are minimal and labeled clearly.
- **Files:** see scope table.
- **Release questions:**
  - Are all settings used? Defaults sensible?
  - Are setting paths namespaced (e.g. `ui_react/...`)?
  - Are hint strings and groups tooltipped?
- **Rubric:** R-YAGNI, R-EXPORT-SURFACE, R-POLISH, R-VOICE.
- **Done when:** Settings list is the v1 set with documented defaults.

### Pass 11 — Examples & blessed path

- **Objectives:** Each example loads, runs, and matches its README description; together the examples cover the blessed onboarding path.
- **Files:** `addons/ui_react/examples/**` (`shop_computed_demo.tscn`, `inventory_screen_demo.tscn`, `anim_targets_catalog_demo.tscn`, `options_transactional_demo.tscn`), referenced scripts and resources.
- **Release questions:**
  - Does each example demonstrate a public capability without using internals?
  - Is the inspector configuration on each control representative of how a user would actually use it?
  - Are there gaps in coverage of public controls / wire rules / action kinds?
- **Rubric:** R-ONBOARDING, R-DRY (examples vs README), R-CLEAN-BREAK.
- **Done when:** Every public control / wire rule / action kind from passes 1–5 either appears in an example or is explicitly noted as "minimal API only".

### Pass 12 — User-facing docs sweep

- **Objectives:** The addon `README.md` and the normative specs read coherently for a brand-new user, with consistent voice.
- **Files:** addon `README.md`, normative specs.
- **Release questions:**
  - Quickstart works in a fresh project?
  - Terms used in README, dock, and tooltips match exactly?
  - Any references to deferred features that read as "shipping"?
- **Rubric:** R-ONBOARDING, R-VOICE, R-CLEAN-BREAK.
- **Done when:** A fresh-eyes pass produces zero P0/P1 doc issues.

### Pass 13 — Repo & plugin shell

- **Objectives:** Repo and plugin metadata is release-clean.
- **Files:** `project.godot`, `addons/ui_react/editor_plugin/plugin.cfg`, `addons/ui_react/editor_plugin/ui_react_editor_plugin.gd` (plugin entrypoint), `icon.*`, `.cursorignore`, `.vscode/settings.json` (release-relevant only).
- **Release questions:**
  - `plugin.cfg` name / description / author / version match v1?
  - `project.godot` has no leftover autoloads, layers, or input maps required only by removed demos?
  - No stray editor-only files committed?
- **Rubric:** R-CLEAN-BREAK, R-YAGNI.
- **Done when:** Plugin can be copied into a clean Godot project and enabled with no manual steps.

### Pass 14 — Integration sweep

- **Objectives:** Verify the **whole loop** — registry exposes a control, validator enforces its bindings, runtime honors them, an example uses them, README explains them, tooltip matches the spec.
- **Files:** spot-check 2–3 representative controls (`UiReactButton`, a list-style control, a tab-aware control).
- **Release questions:** end-to-end consistency across passes 0–13 for each chosen control.
- **Rubric:** all rows, applied selectively.
- **Done when:** Each spot-checked control passes the loop with no open P0/P1.

---

## Release gates

A release tag may be cut when:

1. **All passes have a row in the [Completion ledger](#completion-ledger) marked `done`** (or explicitly `deferred` with a written reason approved by the maintainer).
2. **Zero P0 findings open.** P1 findings either fixed or moved to CHANGELOG **Known limitations** with sign-off.
3. **GUT smoke gate:** `godot --path . -s addons/gut/gut_cmdln.gd -gexit` (using the executable resolution rule in [`AGENTS.md`](../AGENTS.md)) passes locally. Test bodies themselves are not deep-reviewed; the gate is "the suite still runs green."
4. **CHANGELOG updated.** Pass 0 and Pass 13 changes recorded under the v1 section.

---

## Completion ledger

This is the **authoritative** progress record. Update the row at the **end** of each pass; do not pre-fill.

> If you switch to GitHub issues / a project board, replace this section with a single sentence pointing at it and delete the table.

| Pass | Status | Started | Completed | Reviewer | P0 | P1 | Findings link | Carry-forward (≤10 bullets) |
|------|--------|---------|-----------|----------|----|----|----------------|-----------------------------|
| **0** | **done** | 2026-04-27 | 2026-04-27 | release-readiness | **0** | **0** | Pass 0: README examples table + `ACTION_LAYER.md` link fixed in same change set; P3 graph wording (Manhattan) in README. | Glossary + MVP wire types + layer boundaries per `ROADMAP` / `WIRING_LAYER` / `ACTION_LAYER` / `AGENTS.md`; Pass 1 models + `ui_anim_utils.gd`; verify README default Main Scene vs `project.godot` in Pass 13. |
| **1** | **done** | 2026-04-27 | 2026-04-27 | release-readiness | **0** | **0** | Pass 1: api/models + `ui_anim_utils.gd` audited; Resource vs `RefCounted` appropriate; concrete `UiComputed*` / `UiReactWire*` used in examples; optional P3: primitive `value` exports lack per-field `##` tooltips (`UiBoolState`, `UiFloatState`, …), `UiTabContainerCfg` `class_name`/extends order, `UiReactWireRule.apply` inner comment style | Public model surface for Pass 2: all `scripts/api/models/*.gd` class_names + docs-forward `UiAnimUtils`; tighten Inspector tooltips on controls + align README/required-vs-optional; Pass 13 main scene verification. |
| **2** | **done** | 2026-04-27 | 2026-04-27 | release-readiness | **0** | **0** | Pass 2: `scripts/controls/**` audited vs ROADMAP **CB-052** matrix + helpers; Slider/SpinBox/ProgressBar omit `action_targets`/`wire_rules` (matches †); README **Required vs optional** Bindings column omits **`animation_targets`/`wire_rules`** for several §5 hosts (P3 docs — defer Pass **12**) | Runtime internals Pass **3**: `scripts/internal/react/**` excluding tab+anim splits; reuse `UiReactControlStateWire` / `UiReactBaseButtonReactive` / `UiReactHostWireTree` findings; README matrix parity wording in Pass 12. |
| **3** | **done** | 2026-04-28 | 2026-04-28 | release-readiness | **0** | **0** | Pass 3: `scripts/internal/react/**` minus `ui_tab_*` + `ui_react_anim_target_helper` — reactive core OK; `UiReactComputedService` / `UiReactTransactionalSession` intentionally use static tables (`reset_internal_state_for_tests()` for GUT); P3: `UiReactWireTemplate` English literals; `UiReactActionTargetHelper` lock edge case note in code | Pass **4**: `internal/anim/**`, `ui_react_anim_target_helper`, `ui_tab_transition_animator`; Pass **5**: wire models + `ui_react_wire_template`; motion vs actions boundary cross-check in Pass 4. |
| **4** | **done** | 2026-04-28 | 2026-04-28 | release-readiness | **0** | **0** | Pass 4: `internal/anim/**` + `UiReactAnimTargetHelper` + `UiTabTransitionAnimator` — motion/action boundary holds; refcounted **`UiAnimSnapshotStore`** + **`UiAnimBaselineApplyContext`** + loop-helper stacks are deliberate static state; tween cleanup via **`finished`**, **`Tween.kill`** on stop, **`queue_free`** on helpers; P3 only: **`UiTabTransitionAnimator`** stops after **first** empty-target **`SELECTION_CHANGED`** row (**`break`** ```40:41:addons/ui_react/scripts/internal/react/ui_tab_transition_animator.gd```); baseline acquire/release duplicated outside **`UiAnimSlideAnimations._dispatch_with_unified_baseline`** (**opportunity**, not correctness bug); **`UiAnimPresetRunner`** **`_`** arm defends future **`Preset`** enum additions | Pass **5**: wire rule models/helpers + **`ui_react_wire_template`** + **`UiReactWireRule.apply`** vs pulse/continuous; cross-check **`UiAnimTarget`** trigger ints vs registry (**Pass 7** spot); Pass **12** README binds column (prior carry-forward). |
| **5** | **done** | 2026-04-28 | 2026-04-28 | release-readiness | **0** | **0** | Pass 5: `ui_react_wire_*` + models + `UiReactActionTarget` — all six concrete wire rules + **`UiReactWireCatalogData`** documented (**`WIRING_LAYER.md`** §6) and exercised in **`inventory_screen_demo.tscn`** (subset in **`options_transactional_demo.tscn`**); wiring vs action trigger numbering called out in spec (**not** shared with **`UiReactActionTarget.trigger`** ```76:76:addons/ui_react/docs/WIRING_LAYER.md```); **`SetStringOnBoolPulse`** is only explicit rising-edge/pulse rule; pulse vs continuous semantics aligned (state `changed` / control signals → **`apply`**; bool pulse → **`apply_from_pulse`**); P3: **`UiReactWireRuleHelper`** **`_is_wire_sort_array_by_key`** script-path check vs **`is UiReactWireSortArrayByKey`**; English in **`UiReactWireTemplate`** / **`MapIntToString`** hints — Pass **12** | Pass **6**: `ui_tab_*` + **`UiTabContainerCfg`**; tab ↔ wire **`selected_state`** **`UiIntState`** vs host export note from **`WIRING_LAYER.md`**; **`UiReactWireTemplate`** i18n deferred **12**. |
| **6** | **done** | 2026-04-28 | 2026-04-28 | release-readiness | **0** | **0** | Pass 6: `ui_tab_*.gd` + **`UiTabContainerCfg`** — helpers are **static**, take **`TabContainer`** (no custom subclass required); selection index resolution centralizes **int** / **exact title** (**no `float`**) ```6:15:addons/ui_react/scripts/internal/react/ui_tab_selection_binding.gd``` (README strict-int note ```225:225:addons/ui_react/README.md```); **`UiTabContentStateBinder`** disconnects then connects each bind ```39:42:addons/ui_react/scripts/internal/react/ui_tab_content_state_binder.gd```; **`UiTabCollectionSync.apply_tabs_from_array`** resizes **`tab_config.tab_content_states`** ```53:54:addons/ui_react/scripts/internal/react/ui_tab_collection_sync.gd```; P3: **`UiTabTransitionAnimator`** first empty-target row **`break`** ```40:41:addons/ui_react/scripts/internal/react/ui_tab_transition_animator.gd``` (Pass 4 overlap); P3: binder returns after **first** matching **`UiState`** export on page ```34:43:addons/ui_react/scripts/internal/react/ui_tab_content_state_binder.gd```; **`UiTabContainerCfg`** minimal **`@export`** (Pass 1 P3 tooltips still optional) | Pass **7**: `ui_react_component_registry.gd`, `ui_react_editor_plugin.gd`, scanner/factory/state services per runbook; **`BINDINGS_BY_COMPONENT`** / **`ANIM_TRIGGERS_BY_COMPONENT`** completeness vs Pass 1–2 + README; tab wiring **`UiIntState`** vs rule `selected_state` per **`WIRING_LAYER.md`** spot-check in Pass 7–8. |
| **7** | **done** | 2026-04-28 | 2026-04-28 | release-readiness | **0** | **0** | Pass 7: editor spine **`ui_react_editor_plugin`** + **`UiReactComponentRegistry`** + factories/scanner/`UiReactSceneFileResourcePaths` — **`SCRIPT_STEM_TO_COMPONENT`** / **`BINDINGS_BY_COMPONENT`** / **`ANIM_TRIGGERS_BY_COMPONENT`** cover **13/13** `controls/*.gd` stems and match README animations table ```159:170:addons/ui_react/README.md``` vs registry ```23:159:addons/ui_react/editor_plugin/ui_react_component_registry.gd```; **`BINDINGS_BY_COMPONENT`** intentionally **state binding slots only** (not **`wire_rules`/`tab_config`/…** — graph uses collectors / README matrix); **`UiReactScannerService`** resolves **`class_name`** first then path stem **`/ui_react_`** heuristic ```9:19:addons/ui_react/editor_plugin/services/ui_react_scanner_service.gd``` (empty string if unknown); **`UiReactSceneFileResourcePaths`** tolerant **missing file / empty / regex compile** failures ```19:41:addons/ui_react/editor_plugin/services/ui_react_scene_file_resource_paths.gd```; **`@tool`** plugin + dock load guard ```19:24:addons/ui_react/editor_plugin/ui_react_editor_plugin.gd```; **`static`** service APIs + one-shot **`_shortcut_property_info_registered_global`** ```12:52:addons/ui_react/editor_plugin/ui_react_editor_plugin.gd```; P3 DRY **`output_dir_from_project_settings`** parallels **`UiReactStateFactoryService.default_output_dir`** — cosmetic | Pass **8**: validators + **`ui_react_validator_common`** + **`ui_react_validator_service`** + **`*_catalog`/`*_introspection`**; cross-check **`ANIM_TRIGGERS_BY_COMPONENT`** denial rules vs **`ui_react_validator_service`** triggers. |
| **8** | **done** | 2026-04-28 | 2026-04-28 | release-readiness | **0** | **0** | Pass 8: validator pipeline + wiring/tree/transactional/computed + **`UiReactValidatorCommon`** (registry **`ANIM_TRIGGERS`**) + **`UiReactWireRuleIntrospection`** + wire catalogs — **`validate_nodes`** fans out to binding/anim/action/wiring/tree ```6:23:addons/ui_react/editor_plugin/services/ui_react_validator_service.gd```; trigger allowlist shared for anim + action ```95:99:addons/ui_react/editor_plugin/services/ui_react_anim_validator.gd``` ```56:57:addons/ui_react/editor_plugin/services/ui_react_action_validator.gd``` via **`is_anim_trigger_allowed`** ```19:24:addons/ui_react/editor_plugin/services/ui_react_validator_common.gd```; unknown component → empty allowlist → **no** false trigger warnings ```21:24:addons/ui_react/editor_plugin/services/ui_react_validator_common.gd```; graceful null roots / missing exports throughout; copy uses **Inspector**-first imperatives (aligns **`EDITOR_COPY.md`** pattern); P3: **`UiReactComputedValidator`** only marks **`UiComputedStringState`/`UiComputedBoolState`** as bound computeds ```27:28:addons/ui_react/editor_plugin/services/ui_react_computed_validator.gd``` — other **`UiComputed*`** on exports **needs verification** if allowed; P3: **`UiReactWireRuleStackCatalog`** **`extends Object`** not **`RefCounted`** ```4:addons/ui_react/editor_plugin/services/ui_react_wire_rule_stack_catalog.gd```; sort-rule script path duplicated vs Pass **5** pattern | Pass **9**: dock/**`ui_react_dock`** + controllers/models + explain/graph services per runbook; align diagnostics surfaces with Pass **8** severities; Pass **12** copy sweep for any stragglers. |
| **9a** | **done** | 2026-04-28 | 2026-04-28 | release-readiness | **0** | **0** | **Pass 9 (9a+9b+9c, single session)** — **Dock:** **`UiReactDock.refresh`** invokes **`UiReactValidatorService.validate_nodes`** + **`validate_wiring_under_root`** + **`validate_transactional_under_root`** + **`validate_computed_under_root`** ```667:672:addons/ui_react/editor_plugin/dock/ui_react_dock.gd```, then **`UiReactUnusedStateService.build_issues`** ```674:addons/ui_react/editor_plugin/dock/ui_react_dock.gd``` (coalesced refresh, undo→Wiring refresh ```141:154:addons/ui_react/editor_plugin/dock/ui_react_dock.gd```, empty-scene/no-controls INFO copy ```616:665:addons/ui_react/editor_plugin/dock/ui_react_dock.gd```); **9a** chrome: issue list/grouping, filter, tooltips-on-build comment ```168:171:addons/ui_react/editor_plugin/dock/ui_react_dock.gd``` | **Pass 10:** `editor_plugin/settings/**`, `ui_react_editor_bottom_panel_shortcut`; **Pass 11** examples + doc cross-check; computed orphan coverage **F9-01** if extending **`UiComputed*`** graph kinds. |
| **9b** | **done** | 2026-04-28 | 2026-04-28 | release-readiness | **0** | **0** | **Pass 9b (with 9a/9c)** — **Explain/graph:** **`UiReactExplainGraphBuilder`** null-guards / scanner / caps (`MAX_*` walk) ```12:16:addons/ui_react/editor_plugin/services/ui_react_explain_graph_builder.gd```; loads snapshot/narrative/wire introspection models ```5:7:addons/ui_react/editor_plugin/services/ui_react_explain_graph_builder.gd```; **P3:** graph **computed** nodes only distinguish **`UiComputedStringState`/`UiComputedBoolState`** ```90:92:addons/ui_react/editor_plugin/services/ui_react_explain_graph_builder.gd``` (aligns Pass **8** F8-01, **needs verification** if graph should show other **`UiComputed*`**). | same as 9a carry-forward. |
| **9c** | **done** | 2026-04-28 | 2026-04-28 | release-readiness | **0** | **0** | **Pass 9c (with 9a/9b)** — **Wiring edit:** **`UiReactWireGraphEditService.try_mutate_wire_rule_at_index`** uses **`duplicate(false)`** + **`UiReactActionController`** for undo ```82:97:addons/ui_react/editor_plugin/services/ui_react_wire_graph_edit_service.gd``` (embeds **state id** stability note in comment); trigger ordinals match **`WIRING_LAYER`** wire **`TriggerKind`** subset ```8:36:addons/ui_react/editor_plugin/services/ui_react_wire_graph_edit_service.gd```; **`UiReactActionController`** standard undo property wrap ```12:25:addons/ui_react/editor_plugin/controllers/ui_react_action_controller.gd```; **P3:** **`ui_react_computed_validator.gd`** in Pass **9 scope** duplicates Pass **8** surface (dock only **calls** `validate_computed_under_root` from **`UiReactDock`**) | same as 9a carry-forward. |
| **10** | **done** | 2026-04-28 | 2026-04-28 | release-readiness | **0** | **0** | **Pass 10 (audit + follow-up):** **`UiReactEditorBottomPanelShortcut`** — defaults **Alt+1** / **Alt+2** ```9:30:addons/ui_react/editor_plugin/services/ui_react_editor_bottom_panel_shortcut.gd```; parse + fallback + warnings ```53:94:addons/ui_react/editor_plugin/services/ui_react_editor_bottom_panel_shortcut.gd```; bottom-tab tooltip ```97:123:addons/ui_react/editor_plugin/services/ui_react_editor_bottom_panel_shortcut.gd```. **`editor_plugin/settings/**` (post–follow-up):** only **`ui_react_project_settings_panel`** + **`.tscn`** (**unused**, **F10-01**). **`UiReactDockSettingsPopup`** (deleted) and the Diagnostics **Settings** button removed — open-tab shortcuts are internal Project Settings JSON under **`ui_react/settings/shortcuts/open_*`** (defaults **Alt+1** / **Alt+2**; README **Project settings**). **GUT:** **`test_ui_react_settings_config_migration.gd`** retains migration tests only (popup tests removed). | **Pass 11** examples; **Pass 12** doc sweep; **F10-01** remove or wire **`UiReactProjectSettingsPanel`**; **F9-01** **`UiComputed*`** graph kinds if expanded; Pass **13** shell. |
| **11** | **done** | 2026-04-28 | 2026-04-28 | release-readiness | **0** | **0** | **Pass 11:** four **`examples/*.tscn`** — all **`ext_resource`** scripts under **`addons/ui_react/scripts/controls/**` or **`scripts/api/models/**`** only (no **`scripts/internal/**`**, no **`editor_plugin/**`**); **`project.godot`** main scene **`inventory_screen_demo.tscn`** ```14:14:project.godot```; README Quickstart matches ```60:65:addons/ui_react/README.md```; **`options_transactional_demo.tscn`** references committed **`MuteToggle_disabled_state_3.tres`** ```10:10:addons/ui_react/examples/options_transactional_demo.tscn```; **`inventory_screen_demo.tscn`** uses **`res://icon.svg`** ```14:14:addons/ui_react/examples/inventory_screen_demo.tscn``` ```121:121:addons/ui_react/examples/inventory_screen_demo.tscn```; wiring inventory covers **MapIntToString**, **RefreshItemsFromCatalog**, **CopySelectionDetail**, **SetStringOnBoolPulse**, **SyncBoolStateDebugLine**, **SortArrayByKey** ```18:25:addons/ui_react/examples/inventory_screen_demo.tscn```; options subset **Copy** / **Map** ```15:17:addons/ui_react/examples/options_transactional_demo.tscn```; **13/13** `UiReact*` controls appear across the four scenes (spot-check file list). **P3:** README **Examples at a glance** marks **`anim_targets_catalog_demo`** Actions as **—** but scene sets **`action_targets`** on **`FireCompletedButton`** ```537:541:addons/ui_react/examples/anim_targets_catalog_demo.tscn```; optional README bullet: inventory line could name **sort** rule explicitly vs ```62:62:addons/ui_react/README.md```. | **Pass 12** README/spec alignment (**glance** table, inventory bullet), **CB-052** Bindings column / Pass 2 carry; **F10-01** orphan project settings panel; **F9-01** computed kinds if expanded; Pass **13** shell / main scene parity. |
| **12** | **done** | 2026-04-28 | 2026-04-28 | release-readiness | **0** | **0** | **Pass 12:** README vs normative specs — **Examples at a glance** **`anim_targets_catalog_demo`** Actions corrected ```74:74:addons/ui_react/README.md``` (scene evidence ```537:541:addons/ui_react/examples/anim_targets_catalog_demo.tscn```); inventory Quickstart names **`UiReactWireSortArrayByKey`** + **`WIRING_LAYER`** §6 ```62:62:addons/ui_react/README.md```; **Required vs optional** Bindings column aligned to **ROADMAP** **CB-052** ```132:144:addons/ui_react/README.md``` ```204:218:addons/ui_react/docs/ROADMAP.md```; **`UiReactWireRuleHelper`** wording matches **`WIRING_LAYER`** §3 (**`wire_rules`** hosts only) ```3:3:addons/ui_react/README.md``` ```30:30:addons/ui_react/README.md``` ```46:46:addons/ui_react/docs/WIRING_LAYER.md```; Dependency Graph computed copy scoped to **`UiComputedStringState`/`UiComputedBoolState`** subclasses ```11:11:addons/ui_react/README.md``` (**F9-01** guard); **`WIRING_LAYER`/`ACTION_LAYER`/`MENU_GUIDELINES`/`EDITOR_COPY`** opened — no P0/P1 spec contradictions vs README; **Project settings** shortcut story unchanged (no in-dock shortcut editor) ```477:484:addons/ui_react/README.md```. | **Pass 13:** `plugin.cfg`, `project.godot` shell, stray files, copy **`ui_react`** into clean project smoke; **Pass 14:** 2–3 control E2E loop; **F10-01** **`UiReactProjectSettingsPanel`** orphan; **F9-01** if non-**bool**/**string**-based **`UiComputed*`** ever ships expand graph/validator/docs together; **P3** **`UiReactWireTemplate`** English literals (**Pass 5** carry). |
| **13** | **done** | 2026-04-28 | 2026-04-28 | release-readiness | **0** | **0** | **Pass 13:** **`editor_plugin/plugin.cfg`** ```1:7:addons/ui_react/editor_plugin/plugin.cfg``` + **`ui_react_editor_plugin.gd`** entry ```1:34:addons/ui_react/editor_plugin/ui_react_editor_plugin.gd```; **`project.godot`** main scene + **GUT** + **Ui React** enable ```13:20:project.godot```; removed committed **`ai_assistant_hub`** **`[plugins]`** block from **`project.godot`**; **`.vscode/settings.json`** placeholder Godot path (non–machine-specific) per **`AGENTS.md`**; **`.gitignore`** ignores **`.godot/`** ```4:4:.gitignore```; **README** enable path matches **`editor_plugin/plugin.cfg`** ```117:117:addons/ui_react/README.md```; **`plugin.cfg` `version`** aligned to **`[3.0.0]`** ```6:6:addons/ui_react/editor_plugin/plugin.cfg``` ```113:113:addons/ui_react/docs/CHANGELOG.md```; **Runbook** Pass **13** scope paths corrected. | **Pass 14:** registry ↔ validators ↔ runtime ↔ examples ↔ README; **F10-01**; **F9-01**; **P3** **`author=ui_react`**; **P3** wire-template English (**Pass 5**). |
| **14** | **done** | 2026-04-29 | 2026-04-29 | release-readiness | **0** | **0** | **Pass 14:** integration loop verified for **`UiReactButton`** / **`UiReactItemList`** / **`UiReactTabContainer`** across registry ```24:61:addons/ui_react/editor_plugin/ui_react_component_registry.gd```, validator façade ```8:22:addons/ui_react/editor_plugin/services/ui_react_validator_service.gd```, runtime exports/paths ```9:65:addons/ui_react/scripts/controls/ui_react_button.gd``` ```10:98:addons/ui_react/scripts/controls/ui_react_item_list.gd``` ```10:43:addons/ui_react/scripts/controls/ui_react_tab_container.gd```, examples ```354:366:addons/ui_react/examples/inventory_screen_demo.tscn``` ```152:158:addons/ui_react/examples/options_transactional_demo.tscn```, and README/spec alignment ```132:142:addons/ui_react/README.md``` ```80:98:addons/ui_react/docs/WIRING_LAYER.md``` ```121:123:addons/ui_react/docs/ACTION_LAYER.md```; transactional duplicate-role diagnostics now label offending host type correctly in **`UiReactTransactionalValidator`** ```17:52:addons/ui_react/editor_plugin/services/ui_react_transactional_validator.gd```. | Release closeout: run GUT smoke gate; track **F10-01** (`UiReactProjectSettingsPanel`), **F9-01** (`UiComputed*` parity if expanded), optional registry metadata for `UiReactTabContainer.tab_config`, and P3 copy debt from Pass 5. |

**Status values:** `pending`, `in_progress`, `done`, `deferred` (with reason).

---

## Anti-hallucination rules (for reviewing agents)

1. **No claim without an open file.** If you say "`X` is `static`" or "`Y` emits signal `Z`", you must have read the defining file in this session.
2. **No proposed breaking change without `R-SEMVER` evidence.** Cite the `class_name` / `@export` / spec impact and call for a CHANGELOG entry.
3. **No "feels heavy" findings.** Either name a concrete refactor (with file paths) or downgrade to **P3 / track**.
4. **Do not audit `addons/gut/**`.** If a finding requires it, write `out of scope (GUT vendor)` and stop.
5. **Mark uncertainty.** If you cannot confirm something within the pass scope, write **needs verification** and move on; do not guess.
6. **One pass at a time.** If a finding belongs to a later pass, file it as a carry-forward bullet rather than expanding scope.

---

## Doc maintenance

- **Last reviewed:** 2026-04-28 (Passes 0–11 ledger; Pass **11** official examples + `ui_resources` cited by examples).
- **Owner:** maintainer.
- **Change policy:** Renaming a pass, adding a pass, or moving files between passes is a doc change requiring an entry in [`addons/ui_react/docs/CHANGELOG.md`](../addons/ui_react/docs/CHANGELOG.md) under **Documentation** so reviewers know the runbook moved.

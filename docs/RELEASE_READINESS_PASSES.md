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
| **13** | [Repo & plugin shell](#pass-13--repo--plugin-shell) | Repo `project.godot`, root `icon.*`, `addons/ui_react/plugin.cfg`, `addons/ui_react/ui_react.gd` (plugin entrypoint), `.cursorignore`, `.vscode/settings.json` (only release-relevant entries) | `.godot/**` cache, `addons/gut/**` | — | — |
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
- **Files:** `project.godot`, `addons/ui_react/plugin.cfg`, plugin entrypoint script, `icon.*`, `.cursorignore`, `.vscode/settings.json` (release-relevant only).
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
| 0    | pending | — | — | — | — | — | — | — |
| 1    | pending | — | — | — | — | — | — | — |
| 2    | pending | — | — | — | — | — | — | — |
| 3    | pending | — | — | — | — | — | — | — |
| 4    | pending | — | — | — | — | — | — | — |
| 5    | pending | — | — | — | — | — | — | — |
| 6    | pending | — | — | — | — | — | — | — |
| 7    | pending | — | — | — | — | — | — | — |
| 8    | pending | — | — | — | — | — | — | — |
| 9a   | pending | — | — | — | — | — | — | — |
| 9b   | pending | — | — | — | — | — | — | — |
| 9c   | pending | — | — | — | — | — | — | — |
| 10   | pending | — | — | — | — | — | — | — |
| 11   | pending | — | — | — | — | — | — | — |
| 12   | pending | — | — | — | — | — | — | — |
| 13   | pending | — | — | — | — | — | — | — |
| 14   | pending | — | — | — | — | — | — | — |

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

- **Last reviewed:** _set when the runbook itself is updated_.
- **Owner:** maintainer.
- **Change policy:** Renaming a pass, adding a pass, or moving files between passes is a doc change requiring an entry in [`addons/ui_react/docs/CHANGELOG.md`](../addons/ui_react/docs/CHANGELOG.md) under **Documentation** so reviewers know the runbook moved.

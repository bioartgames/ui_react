# Ui React — notes for agents and solo maintainer

**Scope:** Work under `addons/ui_react/` unless the user explicitly points elsewhere.

**Repo workspace (Godot binary, GUT from project root):** [`REPO_AGENTS.md`](../../REPO_AGENTS.md).

This file is the **single entrypoint** for maintaining the addon: **documentation map**, **read order**, **hard boundaries**, and **change policy**. User-facing narrative stays in [**README.md**](README.md).

**Decision log:** [**docs/DECISIONS.md**](docs/DECISIONS.md). **Glossary:** [docs/ROADMAP.md](docs/ROADMAP.md) § Glossary (single source; no duplicate glossary here).

---

## Read order (refactors and new features)

1. **Documentation map** (tables below) — which normative doc owns what.
2. Relevant spec: [`docs/WIRING_LAYER.md`](docs/WIRING_LAYER.md) (wiring), [`docs/ACTION_LAYER.md`](docs/ACTION_LAYER.md) (actions), and/or [`docs/FEEDBACK_LAYER.md`](docs/FEEDBACK_LAYER.md) (audio / haptics feedback).
3. If touching exports, scanner, or dock issues: [`editor_plugin/ui_react_component_registry.gd`](editor_plugin/ui_react_component_registry.gd) (**BINDINGS_BY_COMPONENT**, **ANIM_TRIGGERS_BY_COMPONENT**).
4. Validators: [`editor_plugin/services/ui_react_validator_service.gd`](editor_plugin/services/ui_react_validator_service.gd) (façade) and the specific `ui_react_*_validator.gd` modules.

---

## Documentation map — files in `docs/`

| File | Purpose | Primary reader |
|------|---------|----------------|
| [**CHANGELOG.md**](docs/CHANGELOG.md) | Release history and breaking changes | author, maintainer |
| [**ROADMAP.md**](docs/ROADMAP.md) | Charter, phases, **Inspector surface matrix (CB-052)**, Appendix backlog (**CB-***), glossary, **Release readiness** runbook | author, maintainer |
| [**WIRING_LAYER.md**](docs/WIRING_LAYER.md) | Normative **P5** wiring contract (`UiReactWireRuleHelper`, `wire_rules`, …) | maintainer, agent |
| [**ACTION_LAYER.md**](docs/ACTION_LAYER.md) | Normative **P6.1** action contract (`action_targets`, `UiReactActionKind`, …) | maintainer, agent |
| [**FEEDBACK_LAYER.md**](docs/FEEDBACK_LAYER.md) | Normative **P6.3** feedback contract (`audio_targets`, `haptic_targets`, **CB-061**) | maintainer, agent |
| [**MENU_GUIDELINES.md**](docs/MENU_GUIDELINES.md) | Normative menu IA rules for context menus, chooser popups, and selectors | maintainer, agent |
| [**P5_CURRENT_STATE_AUDIT.md**](docs/P5_CURRENT_STATE_AUDIT.md) | Stock-take checklist for wiring readiness (**P5.1.b** / **CB-041**) | maintainer |
| [**DECISIONS.md**](docs/DECISIONS.md) | Lightweight ADR log (context → decision → consequences) | author, agent |
| [**TESTING.md**](docs/TESTING.md) | GUT rollout / test ledger (ordered foundation backlog) | maintainer, agent |

---

## Task routing (“if you are doing X, read Y first”)

| Task | Read first |
|------|------------|
| Change or debug **wiring** rules / helper behavior | [WIRING_LAYER.md](docs/WIRING_LAYER.md) — **`§7.1`** (**`value_changed` vs `Resource.changed`**, **`UiReactControlStateWire`** effective computed hook); **`§7.2`** **`@export` typing vs Diagnostics**; additionally `scripts/internal/react/ui_react_wire_rule_helper.gd`, `scripts/api/models/ui_react_wire_*.gd` |
| Change or debug **action** presets / transactional action constraints | [ACTION_LAYER.md](docs/ACTION_LAYER.md); `scripts/api/models/ui_react_action_target.gd`, `editor_plugin/services/ui_react_action_validator.gd` |
| Change or debug **feedback** (audio / haptics rows) | [FEEDBACK_LAYER.md](docs/FEEDBACK_LAYER.md); `scripts/internal/react/ui_react_feedback_target_helper.gd`, `editor_plugin/services/ui_react_feedback_validator.gd` |
| Add a **new `UiReact*`** control or **export** | [ROADMAP.md](docs/ROADMAP.md) Charter; `editor_plugin/ui_react_component_registry.gd` (**BINDINGS_BY_COMPONENT**, **ANIM_TRIGGERS_BY_COMPONENT**); `editor_plugin/services/ui_react_binding_validator.gd` |
| **Dock diagnostics** (anim, actions, wiring, tree, computed) | `editor_plugin/services/ui_react_validator_service.gd` façade → `ui_react_*_validator.gd` |
| **Dock Wiring** tab — graph + embedded **`wire_rules`** UI (**CB-035** / **CB-058** / **`CB-018C`** console toggle) | `editor_plugin/dock/ui_react_dock_wiring_panel.gd` ( **`UiReactDockExplainPanel`**, **`ui_react_dock_wire_rules_section.gd`**, layout/view services) |
| **Runtime Output trace (**`CB-018C`** v1)** | [GRAPH_DEBUG_SURFACES.md](docs/GRAPH_DEBUG_SURFACES.md); `scripts/runtime/ui_react_runtime_console_debug.gd`; taps in `scripts/internal/react/ui_react_wire_rule_helper.gd`, `ui_react_computed_service.gd`, `ui_react_action_target_helper.gd` |
| Change menu grouping, naming, or placement | [MENU_GUIDELINES.md](docs/MENU_GUIDELINES.md); then menu builders/handlers in dock panel and wire rules section |
| **Animation triggers** vs host control | `editor_plugin/ui_react_component_registry.gd` (**ANIM_TRIGGERS_BY_COMPONENT**); [README animation triggers table](README.md) (search “supported triggers per host”) |
| **Phased capability** / backlog / CB IDs | [ROADMAP.md](docs/ROADMAP.md) Appendix |
| **North star** — Dependency Graph as designer workbench (**CB-058**) | [ROADMAP.md](docs/ROADMAP.md) Part I **North star** + **Visual wiring graph**; [DECISIONS.md](docs/DECISIONS.md) **2026-04-09** |
| **Charter** evidence bar (new wrappers, widened **`@export`**) | [ROADMAP.md](docs/ROADMAP.md) **Charter** + glossary (**Official example**); scenes in [`examples/`](examples/) |
| **`UiReact*`** **`animation_targets`** / **`action_targets`** / **`audio_targets`** / **`haptic_targets`** / **`wire_rules`** parity | [ROADMAP.md](docs/ROADMAP.md) Part I — **Inspector surface matrix (CB-052)**; **CB-052** Notes in Appendix |
| **P5 exit / hub** readiness | [P5_CURRENT_STATE_AUDIT.md](docs/P5_CURRENT_STATE_AUDIT.md), ROADMAP **CB-034** / **CB-041** |
| **Why** a design choice was made (not only *what*) | [DECISIONS.md](docs/DECISIONS.md) |
| **Release readiness** / pass-based review | [ROADMAP.md](docs/ROADMAP.md) § **Release readiness** |

---

## Rules of engagement

1. **Normative specs win.** If [WIRING_LAYER.md](docs/WIRING_LAYER.md), [ACTION_LAYER.md](docs/ACTION_LAYER.md), or [FEEDBACK_LAYER.md](docs/FEEDBACK_LAYER.md) disagrees with the addon README, treat the **spec** as authoritative for behavior; fix README or [CHANGELOG.md](docs/CHANGELOG.md) unless the spec is wrong.
2. **No duplication of contracts.** README explains *usage* and points here; WIRING/ACTION/FEEDBACK define *must/must not* for implementations.
3. **Appendix and SemVer.** Public API changes (`class_name`, `@export` shapes, documented resources) follow [ROADMAP.md](docs/ROADMAP.md) Charter and [CHANGELOG.md](docs/CHANGELOG.md) discipline.

---

## Hard boundaries (do not “simplify” away)

| Topic | Rule | Spec |
|------|------|------|
| **String / data ownership** | Wiring owns filter/catalog/detail **string** transforms; Actions **must not** duplicate those jobs. | [WIRING_LAYER.md](docs/WIRING_LAYER.md) §2; [ACTION_LAYER.md](docs/ACTION_LAYER.md) §2 |
| **Conditional copy** | Derived user-visible strings → **`UiComputed*`** or wiring — not ad hoc Actions writing wiring-owned `UiStringState`. | [ACTION_LAYER.md](docs/ACTION_LAYER.md) §2; README “Conditional strings” |
| **Motion vs actions** | No tweens inside Action rows; motion stays on **`animation_targets`** / **`UiAnimUtils`**. | [ACTION_LAYER.md](docs/ACTION_LAYER.md) |
| **Feedback vs actions** | Audio / haptics use **`audio_targets`** / **`haptic_targets`** only — **not** **`UiReactActionKind`**. | [FEEDBACK_LAYER.md](docs/FEEDBACK_LAYER.md); [ACTION_LAYER.md](docs/ACTION_LAYER.md) §2 |
| **Trigger vocabulary** | **`UiAnimTarget.Trigger`** is shared by animations, control-driven **`action_targets`**, and feedback rows; host support is **not** identical for every trigger — see registry. | [`editor_plugin/ui_react_component_registry.gd`](editor_plugin/ui_react_component_registry.gd) **ANIM_TRIGGERS_BY_COMPONENT** |

---

## Where things live

| Area | Path |
|------|------|
| Editor dock façade | `editor_plugin/services/ui_react_validator_service.gd` |
| Dock **Wiring** tab — graph + embedded **`wire_rules`** section (P5.2 / **CB-035** / **CB-058**) | `editor_plugin/dock/ui_react_dock_wiring_panel.gd` (`ui_react_dock_explain_panel.gd`, `ui_react_dock_wire_rules_section.gd`; parent `ui_react_dock.gd`) |
| Dock Wire rules **details** report (BBCode) | `editor_plugin/dock/ui_react_dock_wire_details.gd` |
| Binding / anim / action / feedback / wiring / transactional / tree / computed validators | `editor_plugin/services/ui_react_*_validator.gd` |
| Component metadata (stems, bindings, **animation trigger allowlist**) | `editor_plugin/ui_react_component_registry.gd` |
| Shared validator helpers | `editor_plugin/services/ui_react_validator_common.gd` |
| Scene scan / component name from script | `editor_plugin/services/ui_react_scanner_service.gd` |
| Dock scope preset record helpers (pure) | `editor_plugin/services/ui_react_dock_explain_scope_presets.gd` |
| Wiring rule binder registry (`Script` → binder) | `scripts/internal/react/ui_react_wire_rule_helper.gd` (**`_ensure_wire_dispatch_table`**). New **`UiReactWireRule`** subclasses must register their script plus **`_bind_impl_*`** there or runtime skips binding with a warning. |
| Shared `UiState` ↔ control hook + `value_changed` wiring | `scripts/internal/react/ui_react_control_state_wire.gd` |
| `UiReactButton` / `UiReactTextureButton` shared reactive core | `scripts/internal/react/ui_react_base_button_reactive.gd` |
| Animation dispatch (triggers, `selection_slot`) | `scripts/internal/react/ui_react_anim_target_helper.gd` |
| Feedback dispatch (`audio_targets`, `haptic_targets`) | `scripts/internal/react/ui_react_feedback_target_helper.gd` |
| Wiring runtime | `scripts/internal/react/ui_react_wire_rule_helper.gd`, `scripts/api/models/ui_react_wire_*.gd` |
| Official examples | `examples/*.tscn` |
| Normative docs | `docs/WIRING_LAYER.md`, `docs/ACTION_LAYER.md`, `docs/FEEDBACK_LAYER.md`, `docs/ROADMAP.md` |
| Decision log | `docs/DECISIONS.md` |

---

## Inspector export order (`UiReact*` controls)

When adding or reordering **`@export`** blocks on a **`UiReact*`** script, follow this **canonical order** so the Inspector stays predictable and aligned with [`editor_plugin/ui_react_component_registry.gd`](editor_plugin/ui_react_component_registry.gd):

1. **Primary / secondary bindings** — in the same order as **`BINDINGS_BY_COMPONENT`** for that component (e.g. **`UiReactItemList`**: **`items_state`**, then **`selected_state`**).
2. **Extra control-specific resources** — only **`UiReactTabContainer.tab_config`** today; place immediately after the registry binding exports for that control.
3. **`animation_targets`**
4. **`action_targets`** — omit this step on controls that do not ship **`action_targets`** (e.g. **`UiReactLabel`**).
5. **`audio_targets`**
6. **`haptic_targets`**
7. **`wire_rules`** **or** **`transactional_host`** (only one of these surfaces per control; exclusive).

Update **both** the registry row and the script when introducing a new binding export.

---

## Maintainer hygiene

- **User-facing copy** (Diagnostics strings, graph / Wiring dock text, menus, tooltips, `push_warning`): follow [`docs/EDITOR_COPY.md`](docs/EDITOR_COPY.md) (solo-designer tone; `issue_text` / `fix_hint` rules).
- **New `UiReact*` reactive controls:** mirror reactive teardown from **`NOTIFICATION_PREDELETE`** the same way as **`_exit_tree`** (shared helper **`ui_react_control_exit_teardown.gd`**); **`_disconnect_all_states()`** remains **before** **`UiReactHostWireTree.on_exit`** where **`wire_rules`** apply; **`UiReactButton`** / **`UiReactTextureButton`** delegate to **`UiReactBaseButtonReactive`** (**`on_exit_tree`** / **`on_predelete`**).
- **Reactive signal channels** are normative in **`docs/WIRING_LAYER.md`** **`§7.1`** — do not assume **`value_changed`** implies **`changed`** timing parity.

## Change policy

- **`class_name`**, **`@export`** shapes, or **documented public** wiring/action API: follow [ROADMAP.md](docs/ROADMAP.md) Charter (SemVer) and record in [CHANGELOG.md](docs/CHANGELOG.md).
- **New or widened `UiReact*` inspector surface:** Charter **evidence bar**—**official examples** (README **Quickstart**) + **Appendix** / **Inspector surface matrix (CB-052)** tracking; **not** private-game dogfood. See [ROADMAP.md](docs/ROADMAP.md) glossary (**Official example**).
- **Normative** spec edits: mention in CHANGELOG under **Documentation** or **Changed** as appropriate.

---

## Non-goals for automated edits

- No drive-by refactors of unrelated files or game projects consuming the addon.
- No new capability without a **ROADMAP** Appendix row or explicit user approval (solo scope guard); widening **`@export`** surface must meet Charter **evidence bar** (examples + matrix/Appendix).
- Do not delete or replace normative **WIRING** / **ACTION** / **FEEDBACK** docs without a superseding revision and CHANGELOG entry.

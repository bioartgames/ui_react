# Ui React — documentation map

Quick index for **solo maintenance** and **AI agents**. Authoring narrative and examples stay in the addon [**README**](../README.md); this folder holds **contracts**, **history**, and **decisions**.

**Also read:** [**AGENTS.md**](../AGENTS.md) (working agreement, paths, boundaries). **Decision log:** [**DECISIONS.md**](DECISIONS.md). **Glossary:** [ROADMAP.md](ROADMAP.md) § Glossary (single source; no duplicate glossary here).

---

## Files in `docs/`

| File | Purpose | Primary reader |
|------|---------|----------------|
| [**README.md**](README.md) | This map — routing and rules of engagement | author, agent |
| [**CHANGELOG.md**](CHANGELOG.md) | Release history and breaking changes | author, maintainer |
| [**ROADMAP.md**](ROADMAP.md) | Charter, phases, **Inspector surface matrix (CB-052)**, Appendix backlog (**CB-***), glossary | author, maintainer |
| [**WIRING_LAYER.md**](WIRING_LAYER.md) | Normative **P5** wiring contract (`UiReactWireRuleHelper`, `wire_rules`, …) | maintainer, agent |
| [**ACTION_LAYER.md**](ACTION_LAYER.md) | Normative **P6.1** action contract (`action_targets`, `UiReactActionKind`, …) | maintainer, agent |
| [**P5_CURRENT_STATE_AUDIT.md**](P5_CURRENT_STATE_AUDIT.md) | Stock-take checklist for wiring readiness (**P5.1.b** / **CB-041**) | maintainer |
| [**DECISIONS.md**](DECISIONS.md) | Lightweight ADR log (context → decision → consequences) | author, agent |

---

## Task routing (“if you are doing X, read Y first”)

| Task | Read first |
|------|------------|
| Change or debug **wiring** rules / helper behavior | [WIRING_LAYER.md](WIRING_LAYER.md); `scripts/internal/react/ui_react_wire_rule_helper.gd`, `scripts/api/models/ui_react_wire_*.gd` |
| Change or debug **action** presets / transactional action constraints | [ACTION_LAYER.md](ACTION_LAYER.md); `scripts/api/models/ui_react_action_target.gd`, `editor_plugin/services/ui_react_action_validator.gd` |
| Add a **new `UiReact*`** control or **export** | [ROADMAP.md](ROADMAP.md) Charter; `editor_plugin/ui_react_component_registry.gd` (**BINDINGS_BY_COMPONENT**, **ANIM_TRIGGERS_BY_COMPONENT**); `editor_plugin/services/ui_react_binding_validator.gd` |
| **Dock diagnostics** (anim, actions, wiring, tree, computed) | `editor_plugin/services/ui_react_validator_service.gd` façade → `ui_react_*_validator.gd` |
| **Dock Wiring** tab — graph + **`wire_rules`** list (**CB-035** / **CB-058**) | `editor_plugin/dock/ui_react_dock_wiring_panel.gd` ( **`ui_react_dock_explain_panel.gd`**, **`ui_react_dock_wire_rules_panel.gd`**, layout/view services) |
| **Animation triggers** vs host control | `editor_plugin/ui_react_component_registry.gd` (**ANIM_TRIGGERS_BY_COMPONENT**); [README animation triggers table](../README.md) (search “supported triggers per host”) |
| **Phased capability** / backlog / CB IDs | [ROADMAP.md](ROADMAP.md) Appendix |
| **North star** — Dependency Graph as designer workbench (**CB-058**) | [ROADMAP.md](ROADMAP.md) Part I **North star** + **Visual wiring graph**; [DECISIONS.md](DECISIONS.md) **2026-04-09** |
| **Charter** evidence bar (new wrappers, widened **`@export`**) | [ROADMAP.md](ROADMAP.md) **Charter** + glossary (**Official example**); scenes in [`../examples/`](../examples/) |
| **`UiReact*`** **`animation_targets`** / **`action_targets`** / **`wire_rules`** parity | [ROADMAP.md](ROADMAP.md) Part I — **Inspector surface matrix (CB-052)**; **CB-052** Notes in Appendix |
| **P5 exit / hub** readiness | [P5_CURRENT_STATE_AUDIT.md](P5_CURRENT_STATE_AUDIT.md), ROADMAP **CB-034** / **CB-041** |
| **Why** a design choice was made (not only *what*) | [DECISIONS.md](DECISIONS.md) |

---

## Rules of engagement

1. **Normative specs win.** If [WIRING_LAYER.md](WIRING_LAYER.md) or [ACTION_LAYER.md](ACTION_LAYER.md) disagrees with the addon README, treat the **spec** as authoritative for behavior; fix README or [CHANGELOG.md](CHANGELOG.md) unless the spec is wrong.
2. **No duplication of contracts.** README explains *usage* and points here; WIRING/ACTION define *must/must not* for implementations.
3. **Appendix and SemVer.** Public API changes (`class_name`, `@export` shapes, documented resources) follow [ROADMAP.md](ROADMAP.md) Charter and [CHANGELOG.md](CHANGELOG.md) discipline.

---

## Related (outside `docs/`)

| Path | Role |
|------|------|
| [`../AGENTS.md`](../AGENTS.md) | Scope, read order, key paths, agent guardrails for `addons/ui_react/` |
| [`../README.md`](../README.md) | User-facing north star, quickstart, examples, troubleshooting |

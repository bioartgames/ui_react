# Ui React — notes for agents and solo maintainer

**Scope:** Work under `addons/ui_react/` unless the user explicitly points elsewhere.

This file is the **checklist** before large refactors. The **documentation map** is [`docs/README.md`](docs/README.md).

---

## Read order (refactors and new features)

1. [`docs/README.md`](docs/README.md) — which normative doc owns what.
2. Relevant spec: [`docs/WIRING_LAYER.md`](docs/WIRING_LAYER.md) (wiring) and/or [`docs/ACTION_LAYER.md`](docs/ACTION_LAYER.md) (actions).
3. If touching exports, scanner, or dock issues: [`editor_plugin/ui_react_component_registry.gd`](editor_plugin/ui_react_component_registry.gd) (**BINDINGS_BY_COMPONENT**, **ANIM_TRIGGERS_BY_COMPONENT**).
4. Validators: [`editor_plugin/services/ui_react_validator_service.gd`](editor_plugin/services/ui_react_validator_service.gd) (façade) and the specific `ui_react_*_validator.gd` modules.

---

## Hard boundaries (do not “simplify” away)

| Topic | Rule | Spec |
|------|------|------|
| **String / data ownership** | Wiring owns filter/catalog/detail **string** transforms; Actions **must not** duplicate those jobs. | [WIRING_LAYER.md](docs/WIRING_LAYER.md) §2; [ACTION_LAYER.md](docs/ACTION_LAYER.md) §2 |
| **Conditional copy** | Derived user-visible strings → **`UiComputed*`** or wiring — not ad hoc Actions writing wiring-owned `UiStringState`. | [ACTION_LAYER.md](docs/ACTION_LAYER.md) §2; README “Conditional strings” |
| **Motion vs actions** | No tweens inside Action rows; motion stays on **`animation_targets`** / **`UiAnimUtils`**. | [ACTION_LAYER.md](docs/ACTION_LAYER.md) |
| **Trigger vocabulary** | **`UiAnimTarget.Trigger`** is shared by animations and control-driven **`action_targets`**; host support is **not** identical for every trigger — see registry. | [`editor_plugin/ui_react_component_registry.gd`](editor_plugin/ui_react_component_registry.gd) **ANIM_TRIGGERS_BY_COMPONENT** |

---

## Where things live

| Area | Path |
|------|------|
| Editor dock façade | `editor_plugin/services/ui_react_validator_service.gd` |
| Dock **Wiring** tab — graph + embedded **`wire_rules`** section (P5.2 / **CB-035** / **CB-058**) | `editor_plugin/dock/ui_react_dock_wiring_panel.gd` (`ui_react_dock_explain_panel.gd`, `ui_react_dock_wire_rules_section.gd`; parent `ui_react_dock.gd`) |
| Dock Wire rules **details** report (BBCode) | `editor_plugin/dock/ui_react_dock_wire_details.gd` |
| Binding / anim / action / wiring / transactional / tree / computed validators | `editor_plugin/services/ui_react_*_validator.gd` |
| Component metadata (stems, bindings, **animation trigger allowlist**) | `editor_plugin/ui_react_component_registry.gd` |
| Shared validator helpers | `editor_plugin/services/ui_react_validator_common.gd` |
| Scene scan / component name from script | `editor_plugin/services/ui_react_scanner_service.gd` |
| Animation dispatch (triggers, `selection_slot`) | `scripts/internal/react/ui_react_anim_target_helper.gd` |
| Wiring runtime | `scripts/internal/react/ui_react_wire_rule_helper.gd`, `scripts/api/models/ui_react_wire_*.gd` |
| Official examples | `examples/*.tscn` |
| Normative docs | `docs/WIRING_LAYER.md`, `docs/ACTION_LAYER.md`, `docs/ROADMAP.md` |
| Decision log | `docs/DECISIONS.md` |

---

## Change policy

- **`class_name`**, **`@export`** shapes, or **documented public** wiring/action API: follow [ROADMAP.md](docs/ROADMAP.md) Charter (SemVer) and record in [CHANGELOG.md](docs/CHANGELOG.md).
- **New or widened `UiReact*` inspector surface:** Charter **evidence bar**—**official examples** (README **Quickstart**) + **Appendix** / **Inspector surface matrix (CB-052)** tracking; **not** private-game dogfood. See [ROADMAP.md](docs/ROADMAP.md) glossary (**Official example**).
- **Normative** spec edits: mention in CHANGELOG under **Documentation** or **Changed** as appropriate.

---

## Non-goals for automated edits

- No drive-by refactors of unrelated files or game projects consuming the addon.
- No new capability without a **ROADMAP** Appendix row or explicit user approval (solo scope guard); widening **`@export`** surface must meet Charter **evidence bar** (examples + matrix/Appendix).
- Do not delete or replace normative **WIRING** / **ACTION** docs without a superseding revision and CHANGELOG entry.

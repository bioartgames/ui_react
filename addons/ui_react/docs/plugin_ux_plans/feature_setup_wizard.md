# Feature Plan: Guided Setup Wizard (Defaults Only, v1)

## 1) Objective

New users can run a **short wizard** that creates **recommended default** `UiState` resources and wiring for `UiReact*` controls on the selected scene subtree—without learning every menu path first.

## 2) Scope / Non-goals

**In scope**

- Linear wizard: pick scope (selection vs scene), confirm output folder, create defaults with **sensible names**.
- Reuse existing **state factory** and **action controller** for all writes.
- Idempotent-ish behavior: running twice should **not** duplicate resources if names collide (match existing plugin dedupe).

**Out of scope (YAGNI v1)**

- Template marketplace, preset packs, or user-defined recipes.
- Visual graph editor for state machines.

## 3) Files to change

- `addons/ui_system/editor_plugin/ui_system_dock.gd` — wizard UI flow (steps, validation).
- `addons/ui_system/editor_plugin/services/ui_system_state_factory_service.gd` — default resource creation helpers.
- `addons/ui_system/editor_plugin/controllers/ui_system_action_controller.gd` — assign paths / undo transactions.
- Optional: `editor_plugin/` dialog scene `.tscn` if wizard grows beyond inline `AcceptDialog`.

## 4) Implementation steps

1. Define **default policy**: one `UiState` per discovered binding vs shared pool — document choice in roadmap if ambiguous.
2. Enumerate `UiReact*` nodes under scope via scene tree walk (editor-safe).
3. For each node missing state, propose resource path under user-chosen folder; run collision check.
4. Create resources + assign in one undoable transaction per batch.
5. End screen: summary list with **Open folder** / **Rescan** actions.

## 5) UX text and interaction notes

- Wizard title: **Set up UiReact bindings**
- Steps: **Scope** → **Output folder** → **Review** → **Apply**
- Errors: path not writable, duplicate name — actionable copy.

## 6) Validation

- **Static**: lint; wizard code paths do not run in exported game.
- **Editor smoke**: empty scene, single control, many controls, rerun wizard.
- **Edge cases**: nodes in instanced scenes (read-only), missing permissions.

## 7) Rollout

- **Compatibility**: additive; wizard entry as button in dock toolbar.
- **Risks**: Wrong defaults for advanced projects — mitigate with **Advanced** link to manual docs only (no extra UI in v1).

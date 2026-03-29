# Feature Plan: Guided Setup Wizard (Typed Defaults Only, v1)

## 1) Objective

New users can run a **short wizard** that creates **recommended default concrete `Ui*State` resources** and assigns them to empty **`UiReact*`** binding exports on the selected scene subtree—without learning every menu path first.

**Alignment:** Each binding slot expects a **specific concrete class** (see [`BINDINGS_BY_COMPONENT`](../../editor_plugin/services/ui_react_scanner_service.gd) + [`kind_to_suggested_class`](../../editor_plugin/services/ui_react_scanner_service.gd)). The abstract [`UiState`](../../scripts/api/models/ui_state.gd) base is **not** instantiated. Polymorphic exports (e.g. `UiReactItemList.selected_state`, `UiReactLabel.text_state`) require the wizard to branch on **control configuration** (e.g. `ItemList.select_mode`) or documented defaults (**`UiIntState`** vs **`UiArrayState`**, **`UiStringState`** vs **`UiArrayState`**).

## 2) Scope / Non-goals

**In scope**

- Linear wizard: pick scope (selection vs scene), confirm output folder, create typed defaults with **sensible names**.
- Reuse [`UiReactStateFactoryService`](../../editor_plugin/services/ui_react_state_factory_service.gd) and [`UiReactActionController`](../../editor_plugin/controllers/ui_react_action_controller.gd) for all writes.
- Idempotent-ish behavior: running twice should **not** duplicate resources if names collide (match existing plugin dedupe in `build_unique_file_path`).

**Out of scope (YAGNI v1)**

- Template marketplace, preset packs, or user-defined recipes.
- Visual graph editor for state machines.

## 3) Files to change

- `addons/ui_react/editor_plugin/ui_react_dock.gd` — wizard UI flow (steps, validation).
- `addons/ui_react/editor_plugin/services/ui_react_state_factory_service.gd` — optional thin helpers that delegate to `instantiate_state` per `StringName`.
- `addons/ui_react/editor_plugin/controllers/ui_react_action_controller.gd` — assign paths / undo transactions.
- Optional: `editor_plugin/` dialog scene `.tscn` if wizard grows beyond inline `AcceptDialog`.

## 4) Implementation steps

1. Define **default policy**: **one concrete `Ui*State` `.tres` per empty binding slot** (not a shared generic pool unless explicitly chosen and documented).
2. Enumerate `UiReact*` nodes under scope via scene tree walk (editor-safe).
3. For each **empty** export in [`BINDINGS_BY_COMPONENT`](../../editor_plugin/services/ui_react_scanner_service.gd), resolve **suggested class** (`kind_to_suggested_class` + ItemList/Label overrides mirroring the validator).
4. Propose resource path under user-chosen folder; run collision check (`build_unique_file_path`).
5. Create resources + assign in one undoable batch (mirror **Fix All** semantics).
6. End screen: summary list with **Open folder** / **Rescan** actions.

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
- **Risks**: Wrong defaults for advanced projects — mitigate with **Advanced** link to [`README.md`](../README.md) only (no extra UI in v1).

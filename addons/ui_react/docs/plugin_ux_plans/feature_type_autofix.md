# Feature Plan: Typed Assign and Replace Autofix

## 1) Objective

Users can apply **deterministic, undo-friendly** actions that align bindings with the **expected concrete `Ui*State` subclass** for each slot—building on the existing **Fix** flow (create resource + assign via [`UiReactStateFactoryService`](../../editor_plugin/services/ui_react_state_factory_service.gd) + [`UiReactActionController`](../../editor_plugin/controllers/ui_react_action_controller.gd)).

This is **not** a generic “normalize any `Variant` inside one resource” engine.

## 2) Scope / Non-goals

**In scope**

- Extend **Fix** / toolbar actions for additional **high-confidence** cases, e.g.:
  - **Empty optional slot** → create **`kind_to_suggested_class`** instance and assign (already exists for many rows).
  - **Wrong concrete subclass** (validator ERROR) → **Replace with new** resource of the suggested class **or** offer **Open in Inspector** for manual migration when automatic replace would lose data.
- **Undo-friendly** writes only through existing factory + action controller paths.
- Non-destructive failure: if action cannot be applied, show reason; do not partially corrupt state.

**Out of scope (YAGNI)**

- Arbitrary expression evaluator or plugin-style scripting.
- Bulk “convert entire project” beyond existing **Fix All** patterns for the same rule.
- **In-place float→int coercion** for **tab index** / **list index** semantics—those are **`UiIntState`** + **int** only; users **create new resources** rather than silently morphing floats.
- **In-place Variant shape repair** (e.g. string→number) inside a single `UiStringState` unless you add a **narrow, explicit** rule with a migration story—default is **assign correct type**, not **edit payload magic**.

## 3) Files to change

- `addons/ui_react/editor_plugin/services/ui_react_validator_service.gd` — structured hints / issue codes for eligible **typed assign** actions (where not already present).
- `addons/ui_react/editor_plugin/services/ui_react_state_factory_service.gd` — ensure `instantiate_state` covers every **`kind_to_suggested_class`** return value.
- `addons/ui_react/editor_plugin/controllers/ui_react_action_controller.gd` — undo snapshots for assign/replace.
- `addons/ui_react/editor_plugin/ui_react_dock.gd` — surface Fix for new rules; tooltips name the **target class** (`UiIntState`, `UiFloatState`, …).

## 4) Implementation steps

1. Catalog **2–3** concrete scenarios (e.g. **UiFloatState** on `UiReactItemList.selected_state` in single-select → suggest **UiIntState** + new resource) with test vectors in comments.
2. Prefer **replace assignment** (new `.tres` path, assign) over mutating a foreign script on an existing resource unless the team explicitly chooses migration tooling later.
3. Map validator rule → stable **action id** for logging (optional).
4. On Fix: re-validate preconditions, then save/load resource and assign, then refresh scan.
5. On failure: surface **validator message** + suggest manual fix; never silent no-op.

## 5) UX text and interaction notes

- Button: **Create and assign `UiIntState`** / **Replace with suggested type** (wording per rule).
- Tooltip: one sentence: **Creates a new `.tres` of the expected type and assigns it** (or equivalent).
- Avoid promising **“convert value”** unless the rule is explicitly a safe same-class edit.

## 6) Validation

- **Static**: lint; no new cyclic deps between dock and services.
- **Editor smoke**: trigger each action on a minimal scene; **Undo** restores prior assignment.
- **Edge cases**: `@export` reload races, external resources, read-only filesystem (imported resources).

## 7) Rollout

- **Compatibility**: additive; document any **breaking** manual migration for users who relied on deprecated patterns (see README strict-int rules).
- **Risks**: Wrong heuristic — mitigate with narrow rule match and explicit preconditions.

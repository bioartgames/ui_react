# Feature Plan: Type-Aware Autofix (Safe Conversions)

## 1) Objective

Users can apply **safe, deterministic autofixes** that convert incompatible or suboptimal `UiState.value` shapes when the scanner/validator identifies a known pattern (starting with 2–3 high-confidence conversions).

## 2) Scope / Non-goals

**In scope**

- Autofix actions surfaced next to relevant diagnostics (or in Fix menu) with **clear labels**.
- **Undo-friendly** writes through existing state factory + action controller paths.
- Non-destructive failure: if conversion cannot be applied, show reason; do not partially corrupt state.

**Out of scope (YAGNI)**

- Arbitrary expression evaluator or plugin-style scripting for conversions.
- Bulk “convert entire project” beyond existing Fix All patterns for the same rule.

## 3) Files to change

- `addons/ui_system/editor_plugin/services/ui_system_validator_service.gd` — emit rule IDs / structured hints for eligible fixes.
- `addons/ui_system/editor_plugin/services/ui_system_state_factory_service.gd` — implement conversion writers (or delegate to focused helpers).
- `addons/ui_system/editor_plugin/controllers/ui_system_action_controller.gd` — wire Fix action to the correct conversion + undo snapshot.
- `addons/ui_system/editor_plugin/ui_system_dock.gd` — show Fix button / context for conversion rules.

## 4) Implementation steps

1. Catalog **2–3** concrete mismatches (e.g. string vs number for a known property class) with test vectors in comments or dev-only asserts.
2. Implement **pure conversion functions** (input Variant + metadata → output Variant or err); keep them unit-testable in isolation if the repo adds tests.
3. Map validator rule → conversion id; ensure id is stable for telemetry/logging (optional).
4. On Fix: validate preconditions again, then write via state factory, then refresh scan.
5. On failure: surface **validator message** + suggest manual edit; never silent no-op.

## 5) UX text and interaction notes

- Button: **Convert to &lt;target type&gt;** or **Normalize value**.
- Confirmation: only when data loss is possible (e.g. float → int); default to safe conversions without modal.
- Tooltip: one sentence on what will change.

## 6) Validation

- **Static**: lint; no new cyclic deps between dock and services.
- **Editor smoke**: trigger each conversion on a minimal scene; Undo restores prior value.
- **Edge cases**: `@export` reload races, resource external to scene, read-only filesystem (imported resources).

## 7) Rollout

- **Compatibility**: only touches `.tres` / assigned values; document any one-way conversions.
- **Risks**: Wrong heuristic — mitigate with narrow rule match and explicit preconditions.

# Ui React — automated testing rollout (GUT)

This document is the **ordered backlog** for **foundation** (pure logic) tests using [GUT](https://gut.readthedocs.io/) (Godot Unit Test, 9.x) in this project. **GUT “Run All” and CI** are the source of truth for what is actually covered; update the **Status** column here when layers land or scope changes.

**Convention:** tests live under `addons/ui_react/tests/` (or subfolders), scripts extend `GutTest`, methods use the `test_` prefix. Configure dirs in `res://.gutconfig.json` when you add the suite.

---

## How to use this doc

| Rule | Detail |
|------|--------|
| **Granularity** | Check off **layers** or **modules** when done—not every single assertion (avoid stale checklists). |
| **Order** | Implement in the **Rollout order** below unless a dependency forces a small skip-then-return. |
| **Truth** | If this file disagrees with a failing/passing GUT run, fix the tests or the code—not the prose alone. |

---

## Test tiers (A / B / C) and resilience

Tests are grouped by how brittle they are when product copy or formatting changes.

- **Tier A — State, math, and invariants:** Prefer exact checks on primitives, booleans, and structured data (dictionary keys, array sizes, `str(row.get("kind"))`). Avoid asserting full multi-line user-facing strings unless the string is an intentional, low-churn contract (for example short template grammar).

- **Tier B — Public API, apply outcomes, and diagnostics:** Assert observable behavior after `apply` / `recompute`, and treat expected `push_warning` / `push_error` as **count-based** GUT assertions: call `assert_engine_error(1)` or `assert_push_error(1)` **after** the line that triggers the diagnostic, with **no message substring** so tests do not break when log copy is edited. GUT marks those errors as handled; **Godot may still print yellow warnings in the editor console**—that is normal.

- **Tier C — Presentation, registry text, and wiring hints:** Do not duplicate production BBCode or sentence templates in tests. Prefer `String.contains` anchors, numeric substrings, or `String.count` when that is enough to distinguish scenarios. When you intentionally change copy or registry strings, update the matching Tier C tests **in the same change** so the suite stays honest.

---

## Rollout order (recommended)

Implement in this sequence so early layers need **no scene tree** (or only thin `TabContainer` setup at the end). Each step builds fixtures (`UiFloatState`, wire rules, action rows) reused later.

| Step | Layer | Primary paths |
|------|--------|----------------|
| 1 | Typed `UiState` primitives | `addons/ui_react/scripts/api/models/ui_*_state.gd` |
| 2 | `UiReactStateOpService` | `addons/ui_react/scripts/internal/react/ui_react_state_op_service.gd` |
| 3 | `UiReactWireTemplate` | `addons/ui_react/scripts/internal/react/ui_react_wire_template.gd` |
| 4 | `UiComputed*` | `addons/ui_react/scripts/api/models/ui_computed_*.gd` |
| 5 | `UiTransactionalState` | `addons/ui_react/scripts/api/models/ui_transactional_state.gd` |
| 6 | Wire rule `apply` / `apply_from_pulse` | `addons/ui_react/scripts/api/models/ui_react_wire_*.gd` |
| 7 | `UiReactActionTargetHelper.validate_action_targets` (+ `collect_control_trigger_map`) | `addons/ui_react/scripts/internal/react/ui_react_action_target_helper.gd` |
| 8 | `UiReactStateBindingHelper` | `addons/ui_react/scripts/internal/react/ui_react_state_binding_helper.gd` |
| 9 | `UiReactValidatorCommon` | `addons/ui_react/editor_plugin/services/ui_react_validator_common.gd` |
| 10 | Tab helpers **(thin UI)** | `ui_tab_selection_binding.gd`, `ui_tab_collection_sync.gd` |

---

## Layer 0 — Typed `UiState` primitives

**Implemented:** GUT scripts under `addons/ui_react/tests/unit/state/` (see `test_ui_*_state.gd`, `test_gut_environment_smoke.gd`). **CLI** loads [`res://.gutconfig.json`](../.gutconfig.json) by default. The **GUT dock** may use its own saved config under `user://`; if Run All finds no tests, set the test directory to `res://addons/ui_react/tests` (include subfolders) or load the project `.gutconfig.json` from the GUT panel if available.

| Status | Test focus | Why |
|--------|------------|-----|
| [x] | **`UiFloatState`**: `set_value` no-op when `is_equal_approx`; `null` → `0.0`; `set_silent` | Avoid spurious `value_changed` / missed updates when refactoring float/null handling. |
| [x] | **`UiBoolState`**: equality short-circuit; `set_silent` | Same for toggles and bindings. |
| [x] | **`UiIntState`**: reject `float` / invalid types in `set_value` (warning + no-op); `null` → `0` | Prevents silent truncation when UI passes wrong `Variant`. |
| [x] | **`UiArrayState`**: duplicate on assign; reject non-array; packed arrays coerced; equality short-circuit | Tab lists, catalog lines, wiring depend on copy semantics. |
| [x] | **`UiStringState`**: `set_value` / normalization if non-trivial | Same contract class as other states. |

---

## Layer 1 — `UiReactStateOpService`

**Implemented:** [`addons/ui_react/tests/unit/react/test_ui_react_state_op_service.gd`](addons/ui_react/tests/unit/react/test_ui_react_state_op_service.gd) — full public static API on [`ui_react_state_op_service.gd`](../addons/ui_react/scripts/internal/react/ui_react_state_op_service.gd).

| Status | Test focus | Why |
|--------|------------|-----|
| [x] | **`float_from_state`**: null → `0.0`; else reads float | Null-safe reads for computeds / actions. |
| [x] | **`int_from_state`**: null → `0`; else reads int | Same for discrete indices / counts. |
| [x] | **`set_float_literal`**: null accum no-op; else `set_value` | One-way literal write for action presets. |
| [x] | **`afford_floats`**: `gold >= price×qty`; null slots behave as 0 | Core afford / buy-disable contract. |
| [x] | **`subtract_product_from_accumulator`**: null / unaffordable no-op; else subtract total | Shop-style spend without negative gold. |
| [x] | **`add_product_to_accumulator`**: any null no-op; unbounded `cur + fa×fb` | Additive presets; null-safe. |
| [x] | **`transfer_float_product_clamped`**: null / `p<=0` / `actual<=0` no-op; else clamped transfer | Float transfer edge cases. |
| [x] | **`add_product_to_int_clamped`**: null; mul/sum overflow; `p<0`; else add | Signed i64 safety for int accum. |
| [x] | **`transfer_int_product_clamped`**: null; mul overflow; `p<=0`; `actual<=0`; add overflow; else transfer | Int transfer + overflow guards. |

---

## Layer 2 — `UiReactWireTemplate`

**Implemented:** [`addons/ui_react/tests/unit/react/test_ui_react_wire_template.gd`](addons/ui_react/tests/unit/react/test_ui_react_wire_template.gd) — full public static API on [`ui_react_wire_template.gd`](../addons/ui_react/scripts/internal/react/ui_react_wire_template.gd).

| Status | Test focus | Why |
|--------|------------|-----|
| [x] | **`selection_detail_base`**: no selection text; dict with `name`/`kind`; dict with `label`/`text`; non-dict row | User-visible detail strings; formatting regressions are common. |
| [x] | **`selected_row_dict`**: out of range → `{}`; non-dict → `{}` | Defensive behavior for pulse / “Use” flows. |
| [x] | **`row_display_name`**: strips `name` | Template edge cases for empty names. |
| [x] | **`substitute_row_placeholders`**: `{name}` / `{kind}` / `{qty}`; missing keys | Broken action strings when row shape evolves. |

---

## Layer 3 — `UiComputed*`

**Implemented:** [`addons/ui_react/tests/unit/computed/test_ui_computed.gd`](addons/ui_react/tests/unit/computed/test_ui_computed.gd) — concrete `UiComputed*` subclasses (`ui_computed_*.gd`) under [`addons/ui_react/scripts/api/models/`](../addons/ui_react/scripts/api/models/).

| Status | Test focus | Why |
|--------|------------|-----|
| [x] | **`UiComputedBoolInvert`**: empty sources → `true`; null first source → `true`; else `not bool(source)` | Default-safe invert semantics. |
| [x] | **`UiComputedFloatGeProductBool`**: matches afford; wrong-typed `sources` entries | Keeps computed layer aligned with `UiReactStateOpService`. |
| [x] | **`UiComputedOrderSummaryThreeFloatString`**: totals, gold line, afford verdict (substring or stable fragments) | BBCode summary is string-sensitive. |
| [x] | **`UiComputedTransactionalStatusString`**: null txn sources; pending when either dirty | Options-screen status line; multi-resource pending logic. |
| [x] | *(Smoke)* **`UiComputedBoolState` / `UiComputedStringState`**: `recompute` delegates to `set_value` | Belt-and-suspenders on abstract base wiring. |

---

## Layer 4 — `UiTransactionalState`

**Implemented:** [`addons/ui_react/tests/unit/state/test_ui_transactional_state.gd`](addons/ui_react/tests/unit/state/test_ui_transactional_state.gd) — public API on [`ui_transactional_state.gd`](../addons/ui_react/scripts/api/models/ui_transactional_state.gd).

| Status | Test focus | Why |
|--------|------------|-----|
| [x] | **Cloning**: arrays/dictionaries copied on `set_value` / `begin_edit` (not shared mutation) | Prevents “editing committed value” bugs. |
| [x] | **`_variants_equal` semantics** (via public API): int/float tolerance; float `is_equal_approx` | False pending / duplicate emissions. |
| [x] | **`has_pending_changes`**, `apply_draft`, `cancel_draft` / `reset_to_committed` | Whole draft/commit UX contract. |
| [x] | **`matches_expected_binding_class`** for each documented `StringName` | Validator / binding slot alignment. |

---

## Layer 5 — `UiReactWire*` `apply` / `apply_from_pulse`

Use real `Ui*State` + rule resources; `_source` may be `null` where unused.

**Implemented:** [`addons/ui_react/tests/unit/wire/test_ui_react_wire_rules.gd`](addons/ui_react/tests/unit/wire/test_ui_react_wire_rules.gd) — concrete `UiReactWire*` rules (`ui_react_wire_*.gd`) under [`addons/ui_react/scripts/api/models/`](../addons/ui_react/scripts/api/models/).

| Status | Test focus | Why |
|--------|------------|-----|
| [x] | **`UiReactWireMapIntToString`**: int key match; stringified int keys; optional `hint_state` | Category + hint wiring; dict key typing is fragile. |
| [x] | **`UiReactWireRefreshItemsFromCatalog`**: kind filter; name/kind needle; `selected_state` clamped to `-1`; first-row icon branch | Catalog → list payload without running demos. |
| [x] | **`UiReactWireCopySelectionDetail`**: index + items + suffix; null `items_state` | Aligns with `UiReactWireTemplate`. |
| [x] | **`UiReactWireSetStringOnBoolPulse.apply_from_pulse`**: rising edge; non-rising; `template_no_selection`; substitution | Order-sensitive pulse → string. |
| [x] | **`UiReactWireSyncBoolStateDebugLine`**: null bool vs set; `line_prefix` | Debug readout wiring. |
| [x] | **`UiReactWireSortArrayByKey`**: empty key no-op; empty array; dict sort by key; non-dict `str` sort; descending reverses | Pure sort contract for wiring. |

---

## Layer 6 — `UiReactActionTargetHelper`

**Implemented:** [`addons/ui_react/tests/unit/react/test_ui_react_action_target_helper.gd`](addons/ui_react/tests/unit/react/test_ui_react_action_target_helper.gd) — `validate_action_targets` and `collect_control_trigger_map` on [`ui_react_action_target_helper.gd`](../addons/ui_react/scripts/internal/react/ui_react_action_target_helper.gd).

| Status | Test focus | Why |
|--------|------------|-----|
| [x] | **Disabled rows** preserved in output | Inspector round-trips must not drop disabled config. |
| [x] | **`UiReactTransactionalActions`**: control-triggered row dropped + warning path | ACTION_LAYER transactional-only rule. |
| [x] | **`state_watch` + trigger ≠ `PRESSED`**: warned; row retained unless another branch drops it | Mis-tuned rows: runtime warns; row stays unless a later validation branch drops it. |
| [x] | **`SET_UI_BOOL_FLAG`**: missing `bool_flag_state`; `bool_flag_state == state_watch` rejected | Loop / misconfiguration prevention. |
| [x] | **`GRAB_FOCUS` / `SET_VISIBLE` / `SET_MOUSE_FILTER`**: empty `target` unless allowlist trigger | Path validation for focus/visibility. |
| [x] | **`collect_control_trigger_map`**: ignores `state_watch` rows; trigger keys merged | Host trigger merging contract. |

*Implementation note:* `validate_action_targets` **warns** when `state_watch` is set and `trigger` is not `PRESSED`, but still **keeps** the row in the returned array if no later branch drops it (see tests and `ui_react_action_target_helper.gd`).

---

## Layer 7 — `UiReactStateBindingHelper`

**Implemented:** [`addons/ui_react/tests/unit/react/test_ui_react_state_binding_helper.gd`](addons/ui_react/tests/unit/react/test_ui_react_state_binding_helper.gd) — public static API on [`ui_react_state_binding_helper.gd`](../addons/ui_react/scripts/internal/react/ui_react_state_binding_helper.gd).

| Status | Test focus | Why |
|--------|------------|-----|
| [x] | **`coerce_bool` / `coerce_float`** (incl. `null` default) | Variant coercion refactors. |
| [x] | **`approx_equal_float`**: negative epsilon → `is_equal_approx`; positive window | Float binding stability. |
| [x] | **`as_text_flat` / `as_text_recursive`** (nested `UiState`, arrays) | Label / debug text assembly. |
| [x] | **`expect_array_state`**: pass array; non-array → `null` | Tab/list setup guardrail. |
| [x] | **`initial_sync`**: callable receives `(v, v)` | First-frame correctness. |

`warn_setup` and `deferred_finish_initialization` are covered in the same test file.

---

## Layer 8 — `UiReactValidatorCommon`

**Implemented:** [`addons/ui_react/tests/unit/validator/test_ui_react_validator_common.gd`](addons/ui_react/tests/unit/validator/test_ui_react_validator_common.gd) — public static API on [`ui_react_validator_common.gd`](../addons/ui_react/editor_plugin/services/ui_react_validator_common.gd) (registry via [`ui_react_component_registry.gd`](../addons/ui_react/editor_plugin/ui_react_component_registry.gd) `ANIM_TRIGGERS_BY_COMPONENT`).

| Status | Test focus | Why |
|--------|------------|-----|
| [x] | **`variant_type_name`** (`Object` vs primitives) | Stable validator messaging. |
| [x] | **`get_allowed_anim_triggers` / `is_anim_trigger_allowed`**: known component; unknown → allowed | Registry edits must not forbid valid triggers. |
| [x] | **`format_anim_trigger_name` / `format_allowed_anim_triggers_hint`** | Dock hint strings. |

---

## Layer 9 — Tab helpers **(thin UI)**

**Implemented:** [`addons/ui_react/tests/unit/tab/test_ui_tab_helpers.gd`](addons/ui_react/tests/unit/tab/test_ui_tab_helpers.gd) — [`UiTabSelectionBinding`](../addons/ui_react/scripts/internal/react/ui_tab_selection_binding.gd) and [`UiTabCollectionSync`](../addons/ui_react/scripts/internal/react/ui_tab_collection_sync.gd) (programmatic `TabContainer` under `GutTest`).

Requires a `TabContainer` in the scene tree (minimal test scene or programmatic add to `SceneTree`).

| Status | Test focus | Why |
|--------|------------|-----|
| [x] | **`UiTabSelectionBinding.resolve_tab_index`**: int passthrough; string title match; missing → `-1` | External `Variant` → tab index. |
| [x] | **`UiTabCollectionSync.apply_tabs_from_array`**: shrink removes children; grow adds tabs; dict vs string titles; `tab_content_states` resize; `current_tab` clamp | Dynamic tab list correctness. |

---

## Deferred (not foundation — document for phase 2)

| Area | Reason to defer |
|------|------------------|
| **`UiReactComputedService`** | Static registries, `Engine.is_editor_hint()`; needs reset strategy or doubles. |
| **`UiReactWireRuleHelper.attach` / signals** | Integration-level; build after wire `apply` tests. |
| **Animation statics** (`UiAnim*`, tweens) | Frame/timing; use focused scenes or harnesses. |
| **Full dock validators** on real scenes | Heavy; extract pure checks first where possible. |

---

## Related paths

| Topic | Location |
|-------|----------|
| Addon contracts | `addons/ui_react/docs/WIRING_LAYER.md`, `addons/ui_react/docs/ACTION_LAYER.md` |
| Maintainer map | `addons/ui_react/docs/README.md`, `addons/ui_react/AGENTS.md` |
| GUT addon | `addons/gut/` |

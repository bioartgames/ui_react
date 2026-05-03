# Graph debug surfaces (CB-018A / CB-018B / CB-018C)

This addon exposes three related but **non-overlapping** tools. Keep their contracts stable:

## Diagnostics tab (CB-001 / CB-018B)

- **Purpose:** actionable **issues** and **hints** (severity, ignore, Reveal).
- **Emits:** `UiReactDiagnosticModel.DiagnosticIssue` rows via `UiReactValidatorService`.
- **CB-018B** adds declarative-graph hints (cycles with wire flow, multi-writer risk) using the same snapshot as Explain — **do not** duplicate graph construction logic outside `UiReactExplainGraphBuilder`.

## Wiring tab — Dependency Graph pane (CB-018A / CB-018A.1 / CB-018A.2 / CB-018A.3)

- **Purpose:** static dependency snapshot for a **selected** `UiReact*` node — **Visual** graph: scoped canvas with **Manhattan** routing (**CB-018A.2**), **short** labels, **legend**, **edge filters**, **details** + authoring actions (**CB-058**), debounced **auto-refresh** on selection (**CB-018A.3**). **`wire_rules`** list + rule report are embedded under **details** (`ui_react_dock_wire_rules_section.gd`); graph/context **RMB** exposes wire and **Focus** actions. **Edge filter toggles**, **legend**, and **scope preset** affordances are available from **right-click on empty canvas** (View menu); choices remain **session-only** unless you apply a **named scope preset** (saved under **ProjectSettings**); **Default** does not persist those choices across editor restarts.
- **Does not** emit dock **validator** rows (that is **Diagnostics**); graph actions mutate via **`UiReactActionController`** (**CB-058**).

## Runtime console trace (**CB-018C** v1 — Output)

- **Purpose:** Optional **running-game** **`print`** traces in **Godot Output** (**debug builds** + **`UiReactDockConfig`** / **`ui_react/settings/runtime/console_debug_enabled`**, persisted **only** via the dock **Wiring** tab **`CheckBox`**). Events: **`WIRE`**, **`CMP`**, **`ACT`** (**`UiReactWireRuleHelper`**, **`UiReactComputedService`**, **`UiReactActionTargetHelper`**) — not exhaustive **`UiState.set_value`**.
- **Does not** replace Diagnostics or Dependency Graph; **Defer:** live Dependency Graph pulses during play, ring buffer overlay.

## Invariants (snapshot)

- **Control id:** `ctrl:` + host path string from edited/root-stable resolver.
- **State id:** `state:` + resource path, or embedded fingerprint for non-file states.
- **Edge kinds:** `BINDING` (state → control), `COMPUTED_SOURCE` (state → computed), `WIRE_FLOW` (state → state via wire rule product edges).

# Graph debug surfaces (CB-018A / CB-018B / CB-018C)

This addon exposes three related but **non-overlapping** tools. Keep their contracts stable:

## Diagnostics tab (CB-001 / CB-018B)

- **Purpose:** actionable **issues** and **hints** (severity, ignore, Reveal).
- **Emits:** `UiReactDiagnosticModel.DiagnosticIssue` rows via `UiReactValidatorService`.
- **CB-018B** adds declarative-graph hints (cycles with wire flow, multi-writer risk) using the same snapshot as Explain — **do not** duplicate graph construction logic outside `UiReactExplainGraphBuilder`.

## Dependency Graph tab (CB-018A / CB-018A.1 / CB-018A.2 / CB-018A.3)

- **Purpose:** **read-only** static dependency snapshot for a **selected** `UiReact*` node — **Text** mode: full BBCode report; **Visual** mode: scoped graph with **Manhattan** routing (**CB-018A.2**), **short** labels, **legend**, **edge filters**, **bottom** details, **Focus in Inspector** (**CB-018A.3**), debounced **auto-refresh** on selection (**CB-018A.3**).
- **Does not** emit dock warnings or mutate resources.

## Runtime debug overlay (CB-018C)

- **Purpose:** optional **live** value / edge inspection in a **running** scene (debug builds + project setting).
- **Does not** replace Diagnostics or Dependency Graph; **no** editor log spam by default.

## Invariants (snapshot)

- **Control id:** `ctrl:` + host path string from edited/root-stable resolver.
- **State id:** `state:` + resource path, or embedded fingerprint for non-file states.
- **Edge kinds:** `BINDING` (state → control), `COMPUTED_SOURCE` (state → computed), `WIRE_FLOW` (state → state via wire rule product edges).

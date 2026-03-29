# Feature Plan: Value Preview in Diagnostics Details

## 1) Objective

Issue detail rows show a **truncated, safe preview** of the effective bound payload (via **`get_value()`** on the assigned concrete `Ui*State` resource) and a human-readable **type** label, so users can confirm what the scan evaluated without opening resources.

**Typed-state note:** [`UiState`](../../scripts/api/models/ui_state.gd) is **abstract**; there is no shared exported `value` on the base class. Preview must read **`get_value()`** (or the concrete resource’s typed `value` through the same contract).

## 2) Scope / Non-goals

**In scope**

- Display value snippet + type string in the **details** panel for issues where a **bound `UiState` subclass** is relevant (optional fields on [`DiagnosticIssue`](../../editor_plugin/models/ui_react_diagnostic_model.gd): `value_preview`, `value_type`, `value_truncated`).
- Truncate long strings; avoid dumping huge arrays/objects in full.
- Read-only; no mutation from this UI.
- **Scan-time only** — reflects state at the moment of validation (may differ from runtime after edits).

**Out of scope (YAGNI)**

- Full JSON/tree editor for values.
- Live re-evaluation on every frame (see [runtime bridge](feature_runtime_bridge.md)).

## 3) Files to change

- `addons/ui_react/editor_plugin/ui_react_dock.gd` — populate detail UI from issue payload (already partially wired).
- `addons/ui_react/editor_plugin/services/ui_react_validator_service.gd` — optional: populate preview fields when building issues (requires reading assigned resource and calling **`get_value()`** with safe formatting), or a small `RefCounted` helper under `editor_plugin/` if the same formatting is needed twice (DRY threshold).

## 4) Implementation steps

1. Keep a **stable shape** for optional fields: `value_preview: String`, `value_type: String`, `value_truncated: bool`.
2. When building diagnostics for a node with an assigned **`UiState` subclass**, compute preview from **`st.get_value()`** → string with length cap (e.g. 120 chars) and ellipsis; respect [`BINDINGS_BY_COMPONENT`](../../editor_plugin/services/ui_react_scanner_service.gd) only for deciding *whether* preview is worth showing (e.g. skip for pure subclass-mismatch errors if noisy).
3. In the dock details UI, render type on one line and preview on the next; hide section if no preview.
4. Guard: if value cannot be read (missing resource, parse error), show a short **neutral** message and do not throw.
5. Performance: build preview only when building the issue list for the current scan (not on idle every frame).

## 5) UX text and interaction notes

- Label: **Effective value** / **Value type** (or single line **Value (type):** …).
- Tooltip: explain truncation and that it reflects **scan-time** payload from **`get_value()`**.
- If unavailable: **Value not available** (not alarming unless paired with an error).

## 6) Validation

- **Static**: GDScript lint passes on touched files.
- **Editor smoke**: Open dock → run scan → select issue with state → preview appears; large string truncates.
- **Edge cases**: `null`, empty string, nested Dictionary/Array, very long resource path strings; **`UiIntState`** / **`UiArrayState`** polymorphic slots.

## 7) Rollout

- **Compatibility**: additive UI only; no file format changes.
- **Risks**: Accidentally stringifying huge structures — mitigate with strict caps and type-aware branch for Array/Dictionary (e.g. first N elements only).

# Feature Plan: Value Preview in Diagnostics Details

## 1) Objective

Issue detail rows show a **truncated, safe preview** of the effective `UiState.value` (and its type) so users can confirm what the scanner is evaluating without opening resources.

## 2) Scope / Non-goals

**In scope**

- Display value snippet + type string in the **details** panel for issues where `UiState.value` is relevant.
- Truncate long strings; avoid dumping huge arrays/objects in full.
- Read-only; no mutation from this UI.

**Out of scope (YAGNI)**

- Full JSON/tree editor for values.
- Live re-evaluation on every frame (see runtime bridge plan).

## 3) Files to change

- `addons/ui_system/editor_plugin/ui_system_dock.gd` — populate detail UI from issue payload.
- `addons/ui_system/editor_plugin/services/ui_system_scanner_service.gd` — ensure issue data includes serializable value preview fields where applicable (or a small helper).
- Optional: small helper module under `editor_plugin/` if the same formatting is needed twice elsewhere (DRY threshold).

## 4) Implementation steps

1. Define a **stable shape** for optional fields on diagnostic/issue objects: e.g. `value_preview: String`, `value_type: String`, `value_truncated: bool`.
2. In the scanner path that already reads `UiState` resources, populate preview using **Variant → string** with length cap (e.g. 120 chars) and ellipsis.
3. In the dock details UI, render type on one line and preview on the next; hide section if no preview.
4. Guard: if value cannot be read (missing resource, parse error), show a short **neutral** message and do not throw.
5. Performance: build preview only when building the issue list for the current scan (not on idle every frame).

## 5) UX text and interaction notes

- Label: **Effective value** / **Type** (or single line **Value (Type):** …).
- Tooltip: explain truncation and that it reflects scan-time state.
- If unavailable: **Value not available** (not alarming unless paired with an error code).

## 6) Validation

- **Static**: GDScript lint passes on touched files.
- **Editor smoke**: Open dock → run scan → select issue with state → preview appears; large string truncates.
- **Edge cases**: `null`, empty string, nested Dictionary/Array, very long resource path strings.

## 7) Rollout

- **Compatibility**: additive UI only; no file format changes.
- **Risks**: Accidentally stringifying huge structures — mitigate with strict caps and type-aware branch for Array/Dictionary (e.g. first N keys only).

# Feature Plan: Real-Time Binding Health Card

## 1) Objective

A compact **health summary** in the dock reflects the **current editor selection** and its **`UiReact*`** binding slots: pass / warn / fail counts (from [`UiReactValidatorService`](../../editor_plugin/services/ui_react_validator_service.gd) output) and quick navigation to related issues.

## 2) Scope / Non-goals

**In scope**

- Card updates on **selection changed** and after **scan complete**.
- Summarize binding health using existing scanner/validator output (filter issues to selected `node_path` + `property_name` where possible).
- Click/select affordance to focus the first matching issue in the list (if the dock supports it).

**Out of scope (YAGNI)**

- Graph of historical health over time.
- Per-frame runtime telemetry (see [runtime bridge](feature_runtime_bridge.md)).

## 3) Files to change

- `addons/ui_react/editor_plugin/ui_react_dock.gd` — card UI + subscribe to `EditorSelection` (Godot 4 editor API).
- `addons/ui_react/editor_plugin/services/ui_react_scanner_service.gd` — optional: index issues by node path for O(1) lookup.
- `addons/ui_react/editor_plugin/services/ui_react_validator_service.gd` — ensure issue payloads carry **node path** + **property name** + **component** consistently (already the common shape via [`DiagnosticIssue.make_structured`](../../editor_plugin/models/ui_react_diagnostic_model.gd)).

## 4) Implementation steps

1. Add selection listener in dock `_enter_tree` / plugin enable; disconnect on exit.
2. After each scan, build a **map** from `node_path` → issue list (reuse existing structures if present).
3. On selection change: resolve selected `Node` path; filter issues; compute counts by severity.
4. Render card: title **Selection**, subtitle node name, chips or labels for counts.
5. Debounce rapid selection changes (single frame or 50 ms) to avoid UI thrash.

## 5) UX text and interaction notes

- Empty selection: **Select a node** to see binding health.
- No issues: **No issues for selection** (positive framing).
- Mismatch: if selection has no `UiReact*` script, short hint **No UiReact bindings on this node** (link to [wizard](feature_setup_wizard.md) optional).

## 6) Validation

- **Static**: lint; verify no leaks (signals disconnected).
- **Editor smoke**: select nodes in hierarchy; counts match list filters.
- **Edge cases**: multiselect (show union or “multiple selected” summary — pick one and document).

## 7) Rollout

- **Compatibility**: UI-only; toggle card section if needed for narrow screens.
- **Risks**: Stale counts if scan is manual — show **Last scan: …** or disable card until scan exists.

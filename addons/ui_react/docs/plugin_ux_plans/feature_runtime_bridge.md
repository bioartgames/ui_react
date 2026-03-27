# Feature Plan: Runtime Play-Mode Bridge / Live Stream (v1)

## 1) Objective

While the game runs from the editor, the dock can show a **live stream** of `UiState` values across the **whole scene** with **filtering controls**, so users can verify bindings without print-debugging.

## 2) Scope / Non-goals

**In scope**

- **Whole-scene** value stream with filters: by node path substring, by property name, severity/change-only toggles.
- Explicit **Enable / Disable** stream; disabled = zero processing.
- Rate limiting / coalescing updates to avoid editor UI flooding.

**Out of scope (YAGNI v1)**

- Persisting streams to disk, CSV export, network sync.
- Editing values from the stream (read-only v1).

## 3) Files to change

- `addons/ui_system/editor_plugin/ui_system_dock.gd` — stream panel, filters, enable toggle.
- New or existing **runtime** helper under `addons/ui_system/` (tool-safe boundaries): e.g. autoload or scene-level bridge that reports only in debug/editor play.
- `addons/ui_system/plugin.cfg` / export considerations — ensure runtime code is stripped or no-op in release if required.

## 4) Implementation steps

1. Define a minimal **message schema**: `{ node_path, property, value_preview, tick }`.
2. Implement **runtime collector** that walks `UiReact*` nodes each physics frame or on value change (prefer change-based if available).
3. Send to editor via `EngineDebugger` session, `rpc`, or Godot’s **EditorDebuggerPlugin** pattern — pick one supported in this repo’s Godot version.
4. Editor side: queue messages; apply filters; update UI at **fixed interval** (e.g. 10 Hz max).
5. On play end / disable: flush queue, disconnect signals, verify no orphans.

## 5) UX text and interaction notes

- Toggle: **Live stream** (Off by default).
- Filter placeholders: **Node contains…**, **Property…**
- Status line: **Connected** / **Waiting for play** / **Stopped**

## 6) Validation

- **Static**: no editor API calls from exported runtime path.
- **Editor smoke**: start play, toggle stream, filter nodes, stop play — no errors.
- **Edge cases**: large scenes (must stay responsive), rapid value churn, scene reload mid-play.

## 7) Rollout

- **Compatibility**: opt-in feature; document performance impact.
- **Risks**: Debugger API changes between Godot minors — gate behind version check or feature flag.

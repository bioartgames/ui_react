# Feature Plan: Runtime Play-Mode Bridge / Live Stream (v1)

## 1) Objective

While the game runs from the editor, the dock can show a **live stream** of **bound state payloads** (via each assigned resource’s **`get_value()`**) across the **whole scene** with **filtering controls**, so users can verify bindings without print-debugging.

**Typed-state note:** Iterate **`UiReact*`** nodes and, for each filled `*_state` export that holds a [`UiState`](../../scripts/api/models/ui_state.gd) subclass, read **`get_value()`** on the concrete resource. Do not assume a `UiState.value` property on the abstract base.

## 2) Scope / Non-goals

**In scope**

- **Whole-scene** value stream with filters: by node path substring, by property name, change-only toggles.
- Explicit **Enable / Disable** stream; disabled = zero processing.
- Rate limiting / coalescing updates to avoid editor UI flooding.

**Out of scope (YAGNI v1)**

- Persisting streams to disk, CSV export, network sync.
- Editing values from the stream (read-only v1).

## 3) Files to change

- `addons/ui_react/editor_plugin/ui_react_dock.gd` — stream panel, filters, enable toggle.
- New or existing **runtime** helper under `addons/ui_react/` (tool-safe boundaries): e.g. scene-level bridge that reports only in debug/editor play, subscribed to **`value_changed`** on assigned states where practical (prefer **signal-driven** updates over polling every frame).
- `addons/ui_react/editor_plugin/plugin.cfg` / export considerations — ensure runtime bridge code is editor-only or no-op in release exports if required.

## 4) Implementation steps

1. Define a minimal **message schema**: `{ node_path, property, value_preview, tick }` (preview from **`get_value()`**).
2. Implement **runtime collector** that finds `UiReact*` nodes and connects to **`value_changed`** on assigned `UiState` subclasses, or polls at a low rate if needed for unconnected edge cases.
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

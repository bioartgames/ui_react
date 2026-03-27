# Reactive UI System

Self-contained UI building blocks for Godot 4.x: attach **UiReact\*** scripts for two-way **UiState** binding, optional **inspector-driven animations** via **UiAnimTarget**, and a code-friendly **UiAnimUtils** tween facade—so you can build polished UI with little or no game code.

---

## The 3-step setup (repeat for every control)

1. **Attach** the matching `UiReact*` script to a native Control (Button, HSlider, Label, …).
2. **Assign** `UiState` (or optional typed `UiBoolState` / `UiFloatState` / `UiStringState` / `UiArrayState`) on the exported fields you care about (pressed/value/text/etc.).
3. **Optionally** fill `animation_targets` with `UiAnimTarget` entries to run tweens from the Inspector (no tween code).

That’s it. Game logic can read/write the same `UiState` resources; controls stay in sync.

### Inspector hints (Godot 4.x)

- **`UiAnimTarget.target` / `UiControlTargetCfg.target`**: exported as a **Control-only** node path (`@export_node_path("Control")`). The picker rejects non-`Control` nodes.
- **`UiAnimTarget` tuning numbers** (duration, repeat count, rotate angle, pop/pulse/shake/flash intensity, etc.): use **@export_range** sliders/spinboxes in the Inspector—see tooltips on each field.

---

## Quickstart

### 1) Add the addon

Copy `addons/ui_system/` into your Godot project at **`addons/ui_system/`**. Open the project and wait for import.

### 2) Run the example

Open **`res://addons/ui_system/examples/reactive_ui.tscn`** and press **Play** (or set it as **Main Scene** in **Project Settings → Application → Run**). Use the scene tree to see how states and targets are wired.

### 3) Minimal recipes (editor-first, no code required)

**Button + pressed state**

1. Add a **Button**, attach **`UiReactButton`** (`scripts/controls/ui_react_button.gd`).
2. Create a **UiState** resource (`scripts/api/models/ui_state.gd`), set `value` to `false` (or your default).
3. Assign it to **`pressed_state`** on the button.
4. Optional: assign **`disabled_state`** and/or **`animation_targets`**.

**Slider + shared value**

1. Add **HSlider**, attach **`UiReactSlider`**.
2. Create **UiState** with a numeric `value` (e.g. `50.0`).
3. Assign to **`value_state`**.

**Label + text from state**

1. Add **Label**, attach **`UiReactLabel`**.
2. Create **UiState** with `value` as **String** (or nested structure per label docs).
3. Assign to **`text_state`**.

### 4) Optional: animations from code

```gdscript
await UiAnimUtils.animate_expand(self, some_control).finished
```

**Named show/hide presets (preferred):** use `UiAnimUtils.preset(UiAnimUtils.Preset.FADE_IN, self, panel)` (enum) instead of string-based `show_animated` / `hide_animated`, which remain for older projects.

`UiAnimUtils` is **`res://addons/ui_system/scripts/api/ui_anim_utils.gd`** (global class `UiAnimUtils`).

### 5) Optional: **UI System Tools** editor plugin

1. Open **Project → Project Settings → Plugins** and enable **UI System Tools** (bundled at `editor_plugin/plugin.cfg`).
2. Open the **UI System Tools** panel in the **bottom editor dock** (tab bar).
3. Choose **Scan: Selection** or **Entire scene**, press **Rescan** to run diagnostics on demand, and review results. Dock choices (scan mode, filters, auto-refresh, output folder) are **remembered per project** when you reopen it. The tool also **updates when you switch the active edited scene** (so you do not need to toggle scan mode to see results).
4. Use **Group** (flat / by node / by severity), **Filter** (text search across node, path, property, messages), and severity toggles to narrow the list. Each row has **Fix**, **Focus**, and **Ignore** (hide until next **Rescan**). Click the issue summary in the **Issues** list to select it and show full details in the **Report** panel. **Hover** any control for a short tooltip (scope, filters, and actions).
5. For unassigned `*_state` slots with a suggested type, use **Fix** on a row (single issue) or **Fix All** in the toolbar (every eligible issue in the **filtered** list). New `.tres` files are saved under the configured folder (default `res://addons/ui_system/ui_resources/plugin_generated/`); if a filename already exists, the plugin saves as `<name>_2.tres`, `<name>_3.tres`, … instead of overwriting. Override the folder with **`ui_system/plugin_state_output_path`**.

All plugin usage details are documented in this README.

---

## Required vs optional (by control)

| Control | Bindings (typical) | Required for “reactive” behavior |
|--------|--------------------|----------------------------------|
| **UiReactButton** | `pressed_state`, `disabled_state` | At least one state if you want sync with `UiState`; neither required for a plain Button. |
| **UiReactCheckBox** | `checked_state`, `disabled_state` | Same pattern as Button. |
| **UiReactSlider** | `value_state` | Assign `value_state` for two-way sync; else behaves like a normal slider. |
| **UiReactSpinBox** | `value_state`, `disabled_state` | `value_state` for sync; `disabled_state` optional. |
| **UiReactProgressBar** | `value_state` | `value_state` for sync from state. |
| **UiReactLineEdit** | `text_state` | `text_state` for sync. |
| **UiReactLabel** | `text_state` | `text_state` for sync. |
| **UiReactOptionButton** | `selected_state`, `disabled_state` | `selected_state` for sync (usually string item text). |
| **UiReactItemList** | `items_state`, `selected_state`, `disabled_state` | `items_state` (optional) populates rows from an **Array** (`str()` per entry). `selected_state` is **index-based** selection sync. |
| **UiReactTabContainer** | `selected_state`, `tab_config` | `selected_state` for index sync; `tab_config` optional (dynamic tabs / per-tab states). |

**`animation_targets`** is always **optional**: leave empty if you don’t want automatic tweens.

---

## Public API (use directly)

Paths are under **`res://addons/ui_system/`**.

| Kind | Global class / area | Path |
|------|---------------------|------|
| Animation facade | `UiAnimUtils` | `scripts/api/ui_anim_utils.gd` |
| Chained animations (optional) | `UiAnimSequence` | `scripts/internal/anim/ui_anim_sequence.gd` |
| State (generic) | `UiState` | `scripts/api/models/ui_state.gd` |
| State (optional typed) | `UiBoolState`, `UiFloatState`, `UiStringState`, `UiArrayState` | `scripts/api/models/ui_*_state.gd` |
| Inspector animation row | `UiAnimTarget` | `scripts/api/models/ui_anim_target.gd` |
| Config bases | `UiTargetCfg`, `UiControlTargetCfg`, `UiTabContainerCfg` | `scripts/api/models/` |
| Attachable controls | `UiReact*` | `scripts/controls/` |

Prefer **`UiAnimUtils`** for tweens from code; prefer **`UiAnimTarget`** arrays on controls for no-code animation.

**Typed vs generic `UiState`:** `UiState` accepts any `Variant` and is the default. Use `UiBoolState` / `UiFloatState` / `UiStringState` / `UiArrayState` when you want clearer intent in the Inspector and typed helpers (`get_float_value()`, etc.). Existing scenes using `UiState` do not need to change.

---

## Used by controls (avoid importing unless advanced)

- Internal animation modules: `scripts/internal/anim/*` (runners, families, snapshot store).
- Internal react helpers: `scripts/internal/react/*` (binding utilities, tab plumbing).

These may change between template versions; **do not rely on them from game code** unless you accept maintenance cost.

---

## Common mistakes

| Symptom | Likely cause | Fix |
|--------|----------------|-----|
| Animation never plays | Empty `animation_targets`, wrong **Trigger**, or invalid **Target** NodePath | In Inspector: set Trigger, drag a **Control** onto Target, pick animation type. Check Output for warnings. |
| State doesn’t sync | `UiState` not assigned, or wrong type | Assign the exported `*_state` field; ensure `UiState.value` type matches (bool/float/String/Array as documented). |
| “Target not found” warning | NodePath not under this node | Use a path relative to the control, or drag the node into the Target field. |
| Tab arrays don’t apply | `tabs_state` / `disabled_tabs_state` / `visible_tabs_state` not an **Array** | Those `UiState` values must be `Array` (see Output warning). |
| Item list rows don’t update | `items_state` missing or not an **Array** | Assign `items_state` to a `UiState` / `UiArrayState` whose `value` is an `Array` (e.g. `["A", "B", 1]` — each entry is stringified for display). |

---

## Layout

| Path | Purpose |
|------|---------|
| `scripts/api/` | Public entry points (`UiAnimUtils`). |
| `scripts/api/models/` | Public resources (`UiState`, `UiAnimTarget`, configs). |
| `scripts/controls/` | Attachable **UiReact\*** scripts. |
| `scripts/internal/anim/` | Animation implementation (unstable for direct use). |
| `scripts/internal/react/` | Reactive helpers (unstable for direct use). |
| `examples/` | `reactive_ui.tscn` smoke demo. |
| `docs/` | Extra notes (e.g. migration, editor plugin, [Plugin UX roadmap](plugin_ux_roadmap.md)). |
| `editor_plugin/` | Optional Godot editor plugin (dock, validation, quick state creation). |
| `ui_resources/` | Sample `.tres` for the example scene; `plugin_generated/` holds plugin-created states (optional). |

---

## Importing into another project

Copy the entire **`addons/ui_system/`** folder into the host project’s **`addons/`** directory, reimport, then attach scripts from **`scripts/controls/`** or call **`UiAnimUtils`** from your game code.

Extended path mapping (old tree → addon) lives in **`docs/migration.md`** if present.

---

## Optional upgrades (non-breaking)

| You have | Optional improvement |
|----------|----------------------|
| Generic `UiState` everywhere | Swap to `UiBoolState` / `UiFloatState` / `UiStringState` / `UiArrayState` where it clarifies payload type. |
| `show_animated` / `hide_animated` with strings | Prefer `UiAnimUtils.preset(...)` with `UiAnimUtils.Preset` enums. |
| Plain `NodePath` targets in mind | Inspector now restricts targets to **Control**; existing saved paths still load. |

# UI System Tools (Editor Plugin)

Optional editor tooling shipped under **`addons/ui_system/editor_plugin/`**. It does **not** change runtime gameplay; it only helps you wire and validate **UiReact\*** scenes faster.

## Enable

1. **Project → Project Settings → Plugins**
2. Enable **UI System Tools**
3. Find the **UI System Tools** panel in the **bottom editor dock** (tab bar alongside Output, Debugger, etc.)

If you copy `addons/ui_system/` into another project, re-enable the plugin there after import.

## Diagnostics layout

- The **Issues** panel lists **compact summary lines** per issue (severity prefix + short text). Full “Fix:” prose stays in the **Report** panel so narrow docks stay readable.
- **Click an issue summary** to load the **Report** panel: full issue text, fix hint, component/node/path, and property metadata when applicable. For **binding type warnings** (e.g. value shape mismatch), the report also shows a scan-time **Value type** and **Effective value** snippet (truncated for long strings), reflecting `UiState.value` at the time of the scan.
- **Toolbar:** **Rescan**, **Copy report**, and **Fix All** (bulk quick-fix for eligible filtered issues). Each issue row has **Fix**, **Focus** (select that issue’s scene node), and **Ignore**. Use **Copy report** to copy the entire filtered list.

**Persisted per project:** scan mode, severity filters, auto-refresh, and state output folder are saved in **Project Settings** and restored when you reopen the project (no need to reconfigure each session).

**When diagnostics update:** the list updates when you press **Rescan**, when you open or **switch the active edited scene** tab (so **Entire scene** mode stays accurate after restart), and—if **Auto-refresh on selection** is enabled—in **Selection** mode when the editor selection changes.

## Dock features

| Control | Purpose |
|--------|---------|
| **Scan** | **Selection** — selected nodes and their subtree `UiReact*` controls. **Entire scene** — all `UiReact*` nodes under the edited scene root. |
| **Group** | **Flat list**, **By node**, or **By severity** (collapsible groups). |
| **Show** | Filter diagnostics by severity (Errors / Warnings / Info). |
| **Filter** | Text filter across node name, path, property, component, and issue text (debounced). When an issue includes a value preview, the **Value type** label is also matched (not the full value text). |
| **State output folder** | Where quick-create saves new `.tres` files. Default: `res://addons/ui_system/ui_resources/plugin_generated/`. Collision-safe names: `<NodeName>_<property>_2.tres`, `_3.tres`, … |
| **Rescan** | Run diagnostics now using the current **Scan** mode and filters (clears **Ignore** hides). |
| **Copy report** | Copy the **filtered** summary list (and full text for export) to the clipboard. |
| **Focus** | On each row: select the scene node for that issue (disabled when the row has no `node_path`). |
| **Fix** | On each row: for an unassigned `*_state` with a suggested type (**Info** optional slots or **Warning** required slots), creates the typed state, saves it, assigns with **undo/redo**. |
| **Fix All** | Same as **Fix** for **every** eligible issue in the **current filtered** list (skips rows without a suggested type). |

## Project settings

| Key | Default | Meaning |
|-----|---------|---------|
| `ui_system/plugin_state_output_path` | `res://addons/ui_system/ui_resources/plugin_generated/` | Folder for plugin-generated `.tres` files (trailing `/` recommended). |
| `ui_system/plugin_scan_mode` | `0` | `0` = Selection scan, `1` = Entire scene. |
| `ui_system/plugin_show_errors` | `true` | Show **Errors** in the list. |
| `ui_system/plugin_show_warnings` | `true` | Show **Warnings** in the list. |
| `ui_system/plugin_show_info` | `true` | Show **Info** in the list. |
| `ui_system/plugin_auto_refresh` | `true` | Auto-refresh when selection changes (Selection scan only). |

## Binding metadata & validation

The scanner (`ui_system_scanner_service.gd`) records which `UiState` exports each `UiReact*` control expects, including a **kind** hint (`bool`, `float`, `string`, `array`, ...). The validator (`ui_system_validator_service.gd`) turns those hints into **warnings** when the assigned `UiState.value` shape is unlikely to match typical usage.

### `UiReactItemList` bindings

| Export | Kind | Notes |
|--------|------|--------|
| `items_state` | `array` | Optional. When set, `value` should be an **Array**; each element is displayed with `str()`. Non-array values are ignored at runtime (with a warning) and produce a **Warning** in the dock. |
| `selected_state` | `float` | Index-based selection (single: numeric index; multi: `Array` of indices). |
| `disabled_state` | `bool` | Optional; reserved for API consistency. |

Use **`UiArrayState`** (or a generic `UiState` holding an `Array`) for `items_state` so inspector intent and diagnostics line up.

## Architecture (for contributors)

- `ui_system_editor_plugin.gd` — `EditorPlugin` entry; registers the dock.
- `ui_system_dock.gd` — Dock UI only.
- `services/ui_system_scanner_service.gd` — Finds `UiReact*` nodes and binding metadata.
- `services/ui_system_validator_service.gd` — Emits `UiSystemDiagnosticModel.DiagnosticIssue` rows (mirrors runtime validation rules where practical).
- `services/ui_system_state_factory_service.gd` — Creates typed states and saves them to disk.
- `controllers/ui_system_action_controller.gd` — Wraps `EditorUndoRedoManager` property changes.

### Plugin UX roadmap (planned work)

Canonical **master roadmap** (feature order, dependencies, shared constraints, **acceptance gates**, rollback strategy, **milestone review cadence**): **[plugin_ux_roadmap.md](plugin_ux_roadmap.md)**.

Per-feature implementation plans (objective, files, steps, validation, rollout):

| Feature | Plan |
|--------|------|
| Preview `UiState.value` in issue details | [feature_value_preview.md](plugin_ux_plans/feature_value_preview.md) |
| Type-aware autofix (safe conversions) | [feature_type_autofix.md](plugin_ux_plans/feature_type_autofix.md) |
| Real-time binding health card | [feature_binding_health_card.md](plugin_ux_plans/feature_binding_health_card.md) |
| Guided setup wizard (defaults only, v1) | [feature_setup_wizard.md](plugin_ux_plans/feature_setup_wizard.md) |
| Runtime play-mode bridge / live stream (v1) | [feature_runtime_bridge.md](plugin_ux_plans/feature_runtime_bridge.md) |

Runtime addon code under `scripts/internal/*` remains **unstable** for direct game use; the plugin may depend on it only for parity with future refactors—prefer mirroring rules inside `services/` if drift becomes a problem.

## Troubleshooting

| Symptom | Fix |
|--------|-----|
| Plugin not listed | Confirm `addons/ui_system/editor_plugin/plugin.cfg` exists and the project was reimported. |
| Dock empty / “No edited scene” | Open a scene in the editor (set as active edited scene). |
| **Fix** / **Fix All** does nothing | The issue may not be eligible (no suggested type), or the path/folder is invalid; check the **details** pane and folder permissions for the output path. |
| Too many **[I]** rows | Turn off **Info** in **Show** filters. |

## Limitations

- No live animation preview in the editor.
- No automatic migration of existing scenes beyond explicit **Fix** / **Fix All** actions.
- Tab-container advanced `tab_config` is not fully modeled in quick-create flows (use manual resources as today).

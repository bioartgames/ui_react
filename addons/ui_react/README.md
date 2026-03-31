# Ui React

Self-contained UI building blocks for Godot 4.x: attach **UiReact\*** scripts for two-way **UiState** binding, optional **inspector-driven animations** via **UiAnimTarget**, and a code-friendly **UiAnimUtils** tween facade—so you can build polished UI with little or no game code.

### Roadmap

Public direction, phased delivery, and a full **capability backlog** (so deferred work stays visible) live in **[`docs/ROADMAP.md`](docs/ROADMAP.md)**—charter, phases **P0–P5+**, screen matrix, exit criteria, and Appendix table **CB-001–CB-030**.

---

## The 3-step setup (repeat for every control)

1. **Attach** the matching `UiReact*` script to a native Control (Button, HSlider, Label, …).
2. **Assign** the **typed** state resource each export expects (`UiBoolState`, `UiIntState`, `UiFloatState`, `UiStringState`, or `UiArrayState`). Two polymorphic exports use the abstract `UiState` slot so you can pick the right concrete class: `UiReactLabel.text_state` (**`UiStringState` or `UiArrayState`**) and `UiReactItemList.selected_state` (**`UiIntState`** in single-select, **`UiArrayState`** in multi-select).
3. **Optionally** fill `animation_targets` with `UiAnimTarget` entries to run tweens from the Inspector (no tween code).

That’s it. Game logic reads and writes through **`get_value()`** / **`set_value()`** on those resources; controls stay in sync.

### Inspector hints (Godot 4.x)

- **`UiAnimTarget.target`**: exported as a **Control-only** node path (`@export_node_path("Control")`). The picker rejects non-`Control` nodes.
- **`UiAnimTarget` tuning numbers** (duration, repeat count, rotate angle, pop/pulse/shake/flash intensity, etc.): use **@export_range** sliders/spinboxes in the Inspector—see tooltips on each field.

---

## Quickstart

### 1) Add the addon

Copy `addons/ui_react/` into your Godot project at **`addons/ui_react/`**. Open the project and wait for import.

### 2) Run the example

Open **`res://addons/ui_react/examples/demo.tscn`** (smoke demo) and press **Play** (or set it as **Main Scene** in **Project Settings → Application → Run**). Use the scene tree to see how states and targets are wired.

### 3) Minimal recipes (editor-first, no code required)

**Button + pressed state**

1. Add a **Button**, attach **`UiReactButton`** (`scripts/controls/ui_react_button.gd`).
2. Create a **`UiBoolState`** resource (`scripts/api/models/ui_bool_state.gd`), set **`value`** to `false` (or your default).
3. Assign it to **`pressed_state`** on the button.
4. Optional: assign **`disabled_state`** and/or **`animation_targets`**.

**Slider + shared value**

1. Add **HSlider**, attach **`UiReactSlider`**.
2. Create **`UiFloatState`** with **`value`** e.g. `50.0`.
3. Assign to **`value_state`**.

**Label + text from state**

1. Add **Label**, attach **`UiReactLabel`**.
2. Create **UiState** with `value` as **String** (or nested structure per label docs).
3. Assign to **`text_state`**.

### 4) Optional: animations from code

```gdscript
await UiAnimUtils.animate_expand(self, some_control).finished
```

**Show/hide presets:** use `UiAnimUtils.preset(UiAnimUtils.Preset.FADE_IN, self, panel)` (and other `UiAnimUtils.Preset` values). Default durations, offsets, and related numeric defaults for your own compositions live in **`UiAnimConstants`** (`scripts/internal/anim/ui_anim_constants.gd`).

`UiAnimUtils` is **`res://addons/ui_react/scripts/api/ui_anim_utils.gd`** (global class `UiAnimUtils`).

### 5) Optional: **Ui React** editor plugin

1. Open **Project → Project Settings → Plugins** and enable **Ui React** (bundled at `editor_plugin/plugin.cfg`).
2. Open the **Ui React** panel in the **bottom editor dock** (tab bar).
3. Choose **Scan: Selection** or **Entire scene**, press **Rescan** to run diagnostics on demand, and review results. Dock choices (scan mode, **Group** mode, filters, auto-refresh, output folder) are **remembered per project** when you reopen it. The tool also **updates when you switch the active edited scene**, and when **EditorFileSystem** reports filesystem changes (coalesced refresh so rapid imports do not spam rescans).
4. Use **Group** (flat / by node / by severity), **Filter**, and severity toggles to narrow the list. **Binding** issues (validator output) show **Fix**, **Focus**, and **Ignore**—**Ignore** is session-only until the next **Rescan**. **Unused state file** issues (typed `UiState` `.tres` in the output folder, not referenced by this scene) show **Reveal** and **Ignore**—**Reveal** opens the FileSystem dock and calls **`navigate_to_path`** so the file is shown with keyboard focus; **Ignore** is **stored in Project Settings** (**`ui_react/plugin_ignored_unused_state_paths`**) and survives **Rescan**. With **Group → By node**, those unused-file rows appear under **Unused state files**, not under **`(scene)`**. Click an issue summary in the **upper list** to select it and show full details in the **report** below. **Hover** any control for a short tooltip (scope, filters, and actions).
5. For unassigned `*_state` slots with a suggested type, use **Fix** on a row (single issue) or **Fix All** in the toolbar (every eligible **binding** row in the **filtered** list). **Ignore All** applies session **Ignore** to binding rows and appends unused-file paths to the persisted ignore list (see **Project settings** below). New `.tres` files are saved under the configured folder (default `res://addons/ui_react/ui_resources/plugin_generated/`); if a filename already exists, the plugin saves as `<name>_2.tres`, `<name>_3.tres`, … instead of overwriting. Override the folder with **`ui_react/plugin_state_output_path`**.

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
| **UiReactItemList** | `items_state`, `selected_state` | **`items_state`**: **`UiArrayState`**. **`selected_state`**: **`UiIntState`** (single-select) or **`UiArrayState`** (multi-select indices). Godot’s **ItemList** has no built-in disabled state—wrap or gate input with a parent **Control** / `mouse_filter` / focus policy in game code if you need “disabled” behavior. |
| **UiReactTabContainer** | `selected_state`, `tab_config` | **`selected_state`**: **`UiIntState`**. **`tab_config`**: optional **`UiTabContainerCfg`** (use **`UiArrayState`** for tab/disabled/visibility arrays). |

**`animation_targets`** is always **optional**: leave empty if you don’t want automatic tweens.

---

## Public API (use directly)

Paths are under **`res://addons/ui_react/`**.

| Kind | Global class / area | Path |
|------|---------------------|------|
| Animation facade | `UiAnimUtils` | `scripts/api/ui_anim_utils.gd` |
| Animation defaults (numeric) | `UiAnimConstants` | `scripts/internal/anim/ui_anim_constants.gd` |
| Chained animations (optional) | `UiAnimSequence` | `scripts/internal/anim/ui_anim_sequence.gd` |
| State (abstract base) | `UiState` | `scripts/api/models/ui_state.gd` |
| State (concrete) | `UiBoolState`, `UiIntState`, `UiFloatState`, `UiStringState`, `UiArrayState` | `scripts/api/models/ui_*_state.gd` |
| Inspector animation row | `UiAnimTarget` | `scripts/api/models/ui_anim_target.gd` |
| Tab / container config | `UiTabContainerCfg` | `scripts/api/models/ui_tab_container_cfg.gd` |
| Attachable controls | `UiReact*` | `scripts/controls/` |

Prefer **`UiAnimUtils`** for tweens from code; prefer **`UiAnimTarget`** arrays on controls for no-code animation.

**`UiState` is abstract:** do not instantiate it directly. Each control export uses a concrete **`Ui*State`** (or the abstract slot only where noted above). Read and write payload data with **`get_value()`** / **`set_value()`** (subclasses expose a typed **`value`** property in the Inspector). Older projects that used a single concrete `UiState` resource with a `Variant` export must migrate to the matching concrete class and resave resources.

**Strict integer indices:** Tab index (`UiReactTabContainer.selected_state`), **`UiIntState`**, and ItemList single-select **`selected_state`** use **`int` only**. **`float` is not accepted** for those bindings (no silent coercion from float or from **`UiFloatState`** there). Reserve **`UiFloatState`** for sliders, spin boxes, and progress bars.

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
| State doesn’t sync | State not assigned, or wrong concrete type | Assign the exported `*_state` field; use the **Ui React** dock to catch type mismatches. Use **int** for tab list indices; **float** only for range controls (slider / spin / progress); bool / String / Array as documented per control. |
| “Target not found” warning | NodePath not under this node | Use a path relative to the control, or drag the node into the Target field. |
| Tab arrays don’t apply | `tabs_state` / `disabled_tabs_state` / `visible_tabs_state` not an **Array** | Those `UiState` values must be `Array` (see Output warning). |
| Item list rows don’t update | `items_state` missing or not an **Array** | Assign `items_state` to a `UiState` / `UiArrayState` whose `value` is an `Array` (e.g. `["A", "B", 1]` — each entry is stringified for display). |
| Need a “disabled” list | **`UiReactItemList` has no `disabled_state`** (ItemList has no engine disabled flag) | Use a parent **Control**, `mouse_filter`, or focus rules to block interaction; keep list visibility/text driven by state as usual. |

---

## Layout

| Path | Purpose |
|------|---------|
| `scripts/api/` | Public entry points (`UiAnimUtils`). |
| `scripts/api/models/` | Public resources (`UiState`, `UiAnimTarget`, configs). |
| `scripts/controls/` | Attachable **UiReact\*** scripts. |
| `scripts/internal/anim/` | Animation implementation (unstable for direct use). |
| `scripts/internal/react/` | Reactive helpers (unstable for direct use). |
| `examples/` | `demo.tscn` smoke demo. |
| `docs/` | **README**, **CHANGELOG**, and addon **ROADMAP** (this folder). |
| `editor_plugin/` | Optional Godot editor plugin (dock, validation, quick state creation). |
| `ui_resources/` | Sample `.tres` for the example scene; `plugin_generated/` holds plugin-created states (optional). |

---

## Importing into another project

Copy the entire **`addons/ui_react/`** folder into the host project’s **`addons/`** directory, reimport, then attach scripts from **`scripts/controls/`** or call **`UiAnimUtils`** from your game code.

Extended path mapping (old tree → addon) lives in **`docs/migration.md`** if present.

---

## Optional upgrades (non-breaking)

| You have | Optional improvement |
|----------|----------------------|
| Older generic `UiState` `.tres` files | Replace with the concrete **`Ui*State`** expected by each export; **`UiReactTabContainer.selected_state`** uses **`UiIntState`**. |
| String preset APIs removed in 2.x | Use `UiAnimUtils.preset(...)` with `UiAnimUtils.Preset` enums. |
| Plain `NodePath` targets in mind | Inspector now restricts targets to **Control**; existing saved paths still load. |

# Ui React (Editor Plugin)

Optional editor tooling shipped under **`addons/ui_react/editor_plugin/`**. It does **not** change runtime gameplay; it only helps you wire and validate **UiReact\*** scenes faster.

## Enable

1. **Project → Project Settings → Plugins**
2. Enable **Ui React**
3. Find the **Ui React** panel in the **bottom editor dock** (tab bar alongside Output, Debugger, etc.)

If you copy `addons/ui_react/` into another project, re-enable the plugin there after import.

## Versioning

The plugin **version** is declared in [`editor_plugin/plugin.cfg`](editor_plugin/plugin.cfg) (`version=`). Release history and notable changes are tracked in **[`docs/CHANGELOG.md`](docs/CHANGELOG.md)** in this addon folder (so it travels when you copy `addons/ui_react/`).

## Diagnostics layout

- The **upper issue list** shows **compact summary lines** per issue (severity prefix + short text). Full “Fix:” prose stays in the **report** area below so narrow docks stay readable.
- **Click an issue summary** to load the **report**: full issue text, fix hint, component/node/path, **Resource** (`res://` path when the issue carries `resource_path`), property metadata when applicable, and—when present—scan-time **Value type** / **Effective value** (truncated for long strings).
- **Toolbar:** **Rescan**, **Copy report**, **Fix All** (binding issues only; eligible filtered rows), and **Ignore All** (applies session **Ignore** to binding issues; adds unused-file paths to the **persisted** ignore list). **Row actions:** binding rows—**Fix**, **Focus**, **Ignore**; unused-file rows—**Reveal**, **Ignore**. Use **Copy report** to copy the filtered list using the same summary text as each row (and fix hints when present).

**Persisted per project:** scan mode, **Group** mode, severity filters, auto-refresh, state output folder, and ignored unused file paths (**`ui_react/plugin_ignored_unused_state_paths`**) are saved in **Project Settings** and restored when you reopen the project (no need to reconfigure each session).

**When diagnostics update:** the list updates when you press **Rescan**, when you open or **switch the active edited scene** tab, when **EditorFileSystem** signals filesystem changes, and—if **Auto-refresh on selection** is enabled—in **Selection** mode when the editor selection changes.

**Rescan** clears **session-only** hides (**Ignore** on binding issues). It does **not** remove paths from **`plugin_ignored_unused_state_paths`**; clear those in **Project Settings** if needed.

## Dock features

| Control | Purpose |
|--------|---------|
| **Scan** | **Selection** — selected nodes and their subtree `UiReact*` controls. **Entire scene** — all `UiReact*` nodes under the edited scene root. |
| **Group** | **Flat list**, **By node**, or **By severity** (collapsible groups). **By node:** unused `.tres` diagnostics group under **Unused state files**. |
| **Show** | Filter diagnostics by severity (Errors / Warnings / Info). |
| **Filter** | Text filter across node name, path, property, component, messages, fix hints, **resource path** (`res://` for unused-file rows), and value-type hints (debounced). Value preview body text is not searched. |
| **State output folder** | Where quick-create saves new `.tres` files. Default: `res://addons/ui_react/ui_resources/plugin_generated/`. Collision-safe names: `<NodeName>_<property>_2.tres`, `_3.tres`, … |
| **Rescan** | Run diagnostics now using the current **Scan** mode and filters; clears **session** **Ignore** on binding issues only. |
| **Copy report** | Copy the **filtered** list to the clipboard: same summary line as each row, plus **Fix:** hint when present. |
| **Reveal** | Unused-file rows only: FileSystem dock **`navigate_to_path`** for that `.tres`. |
| **Focus** | Binding rows only: select the scene node for that issue (disabled when the row has no `node_path`). |
| **Fix** | Binding rows only: for an unassigned `*_state` with a suggested type (**Info** optional slots or **Warning** required slots), creates the typed state, saves it, assigns with **undo/redo**. |
| **Fix All** | Same as **Fix** for **every** eligible **binding** row in the **current filtered** list. |
| **Ignore** / **Ignore All** | Binding issues: hide until **Rescan**. Unused-file issues: append path to **`plugin_ignored_unused_state_paths`** (persisted). |

## Project settings

| Key | Default | Meaning |
|-----|---------|---------|
| `ui_react/plugin_state_output_path` | `res://addons/ui_react/ui_resources/plugin_generated/` | Folder for plugin-generated `.tres` files (trailing `/` recommended). |
| `ui_react/plugin_scan_mode` | `0` | `0` = Selection scan, `1` = Entire scene. |
| `ui_react/plugin_show_errors` | `true` | Show **Errors** in the list. |
| `ui_react/plugin_show_warnings` | `true` | Show **Warnings** in the list. |
| `ui_react/plugin_show_info` | `true` | Show **Info** in the list. |
| `ui_react/plugin_auto_refresh` | `true` | Auto-refresh when selection changes (Selection scan only). |
| `ui_react/plugin_group_mode` | `0` | `0` = Flat list, `1` = By node, `2` = By severity. |
| `ui_react/plugin_ignored_unused_state_paths` | `PackedStringArray()` (empty) | `res://` paths of unused-file diagnostics hidden until removed from this list. |

## Binding metadata & validation

The scanner (`ui_react_scanner_service.gd`) records which exports each `UiReact*` control expects, including a **kind** hint (`bool`, `int`, `float`, `string`, `array`, ...). The validator (`ui_react_validator_service.gd`) reports **errors** when the assigned resource is not the expected concrete `Ui*State` subclass for that slot.

### `UiReactItemList` bindings

| Export | Kind | Notes |
|--------|------|--------|
| `items_state` | `array` | Optional. When set, **`UiArrayState`** **`value`** should be an **Array**; each element is displayed with `str()`. Non-array values are ignored at runtime (with a warning). |
| `selected_state` | `int` (suggested) | Single-select: **`UiIntState`** (**`int`** indices only, including `-1`). Multi-select: **`UiArrayState`** with **`Array`** of **`int`** indices. **`float` / `UiFloatState` are not supported** for selection sync. |
| `disabled_state` | `bool` | Optional; reserved for API consistency. |

Use **`UiArrayState`** for `items_state` so inspector intent and diagnostics line up.

## Architecture (for contributors)

- `ui_react_editor_plugin.gd` — `EditorPlugin` entry; registers the dock.
- `ui_react_dock.gd` — Dock UI, refresh orchestration, editor signal wiring.
- `models/ui_react_diagnostic_model.gd` — `DiagnosticIssue`, **IssueKind** (`GENERIC` vs `UNUSED_STATE_FILE`), **`resource_path`** for file-scoped rows.
- `services/ui_react_scanner_service.gd` — Finds `UiReact*` nodes and binding metadata.
- `services/ui_react_validator_service.gd` — Emits binding `DiagnosticIssue` rows (mirrors runtime validation rules where practical).
- `services/ui_react_state_reference_collector.gd` — Collects `res://` paths of `UiState` resources referenced by bindings (including `tab_config`).
- `services/ui_react_unused_state_service.gd` — Emits **unused** `.tres` issues for the configured output folder vs the current scene.
- `services/ui_react_state_factory_service.gd` — Creates typed states and saves them to disk.
- `ui_react_dock_config.gd` — ProjectSettings keys and load/save for dock preferences.
- `controllers/ui_react_action_controller.gd` — Wraps `EditorUndoRedoManager` property changes.

**Planning docs:** phased capability backlog for this addon lives in **[`docs/ROADMAP.md`](docs/ROADMAP.md)**. A hosting repository may add its own root roadmap separately.

Runtime addon code under `scripts/internal/*` remains **unstable** for direct game use; the plugin may depend on it only for parity with future refactors—prefer mirroring rules inside `services/` if drift becomes a problem.

## Troubleshooting

| Symptom | Fix |
|--------|-----|
| Plugin not listed | Confirm `addons/ui_react/editor_plugin/plugin.cfg` exists and the project was reimported. |
| Dock shows a message to open a scene / no scan yet | Godot needs an **active edited scene** tab. Open a scene from the Scene or FileSystem dock, switch to its tab if it’s already open, then press **Rescan**. |
| **Fix** / **Fix All** does nothing | The issue may not be eligible (no suggested type), or the path/folder is invalid; check the **details** pane and folder permissions for the output path. |
| Too many **[I]** rows | Turn off **Info** in **Show** filters. |

## Limitations

- No live animation preview in the editor.
- No automatic migration of existing scenes beyond explicit **Fix** / **Fix All** actions.
- Tab-container advanced `tab_config` is not fully modeled in quick-create flows (use manual resources as today).

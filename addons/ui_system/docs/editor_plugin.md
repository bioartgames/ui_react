# UI System Tools (Editor Plugin)

Optional editor tooling shipped under **`addons/ui_system/editor_plugin/`**. It does **not** change runtime gameplay; it only helps you wire and validate **UiReact\*** scenes faster.

## Enable

1. **Project → Project Settings → Plugins**
2. Enable **UI System Tools**
3. Find the **UI System Tools** panel in the **bottom editor dock** (tab bar alongside Output, Debugger, etc.)

If you copy `addons/ui_system/` into another project, re-enable the plugin there after import.

## Diagnostics layout

- The **list** at the top shows **compact summary lines** per issue (severity prefix + short text). Rows do **not** include full “Fix:” prose so narrow panels stay readable.
- **Select a row** to load the **details pane** below: full issue text, fix hint, component/node/path, and property metadata when applicable.
- **Actions** (**Focus node**, **Create & assign typed state**) apply to the **selected** issue. Use **Copy report** to copy the entire filtered list (same as before).

## Dock features

| Control | Purpose |
|--------|---------|
| **Scan** | **Selection** — selected nodes and their subtree `UiReact*` controls. **Entire scene** — all `UiReact*` nodes under the edited scene root. |
| **Show** | Filter diagnostics by severity (Errors / Warnings / Info). |
| **State output folder** | Where **Create & assign typed state** saves new `.tres` files. Default: `res://addons/ui_system/ui_resources/plugin_generated/`. |
| **Refresh** | Re-run validation. |
| **Copy report** | Copy the **filtered** summary list (and full text for export) to the clipboard. |
| **Focus node** | Select the scene node for the **selected** issue (enabled when the issue has a `node_path`). |
| **Create & assign typed state** | For a **selected** **[I]** row about **unassigned** `*_state` exports, creates a typed `UiBoolState` / `UiFloatState` / `UiStringState` (etc.), saves it, and assigns the property with **undo/redo** support. |

## Project settings

| Key | Default | Meaning |
|-----|---------|---------|
| `ui_system/plugin_state_output_path` | `res://addons/ui_system/ui_resources/plugin_generated/` | Folder for plugin-generated `.tres` files (trailing `/` recommended). |

## Architecture (for contributors)

- `ui_system_editor_plugin.gd` — `EditorPlugin` entry; registers the dock.
- `ui_system_dock.gd` — Dock UI only.
- `services/ui_system_scanner_service.gd` — Finds `UiReact*` nodes and binding metadata.
- `services/ui_system_validator_service.gd` — Emits `UiSystemDiagnosticModel.DiagnosticIssue` rows (mirrors runtime validation rules where practical).
- `services/ui_system_state_factory_service.gd` — Creates typed states and saves them to disk.
- `controllers/ui_system_action_controller.gd` — Wraps `EditorUndoRedoManager` property changes.

Runtime addon code under `scripts/internal/*` remains **unstable** for direct game use; the plugin may depend on it only for parity with future refactors—prefer mirroring rules inside `services/` if drift becomes a problem.

## Troubleshooting

| Symptom | Fix |
|--------|-----|
| Plugin not listed | Confirm `addons/ui_system/editor_plugin/plugin.cfg` exists and the project was reimported. |
| Dock empty / “No edited scene” | Open a scene in the editor (set as active edited scene). |
| Create & assign does nothing | **Select** an **[I]** row that mentions an unassigned `*_state` with a suggested type; check folder permissions for the output path. |
| Too many **[I]** rows | Turn off **Info** in **Show** filters. |

## Limitations (by design)

- No live animation preview in the editor.
- No automatic migration of existing scenes beyond explicit **Create & assign** actions.
- Tab-container advanced `tab_config` is not fully modeled in quick-create flows (use manual resources as today).

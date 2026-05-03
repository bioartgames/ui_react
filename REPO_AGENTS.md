# Ui-system-new — repo agent notes

**Scope:** This file is **workspace-level** only (Godot binary resolution, running GUT from the project root). **Ui React** maintainer map, specs routing, and change policy: [`addons/ui_react/AGENTS.md`](addons/ui_react/AGENTS.md).

*(Renamed from `AGENTS.md` at repo root to avoid confusion with the addon’s `AGENTS.md`.)*

---

## Godot + GUT (CLI)

**Problem:** On Windows, `godot` is often **not** on `PATH`, so bare `godot --path . ...` fails in shells and automation.

**Resolve the executable (in order):**

1. **Workspace setting:** read `.vscode/settings.json` → `godotTools.editorPath.godot4` (Godot Tools / Cursor). The repo ships a **placeholder** path; replace it with your local `Godot*.exe` (see the committed example string in **`.vscode/settings.json`**). Use that path verbatim in PowerShell with the call operator, e.g. `& "C:\...\Godot_v4.x_win64.exe" ...`.
2. **Override:** if the team adds one, an environment variable such as `GODOT_BIN` pointing at `Godot*.exe`.

**Run all GUT tests** from this directory (`ui-system-new`):

```powershell
Set-Location "<path-to-this-repo>"
& "<path-to-godot.exe>" --path . -s addons/gut/gut_cmdln.gd -gexit
```

Test dirs and conventions: [`addons/ui_react/docs/TESTING.md`](addons/ui_react/docs/TESTING.md). GUT config: [`.gutconfig.json`](.gutconfig.json).

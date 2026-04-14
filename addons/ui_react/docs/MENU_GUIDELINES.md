# Menu Guidelines

Menu information architecture standards for `addons/ui_react/editor_plugin`.

## Purpose

- Keep menus predictable across the editor plugin.
- Reduce cognitive load by using stable grouping and naming.
- Prevent regressions from ad hoc menu additions.

## Scope

These rules apply to:

- Context menus (`PopupMenu`) opened by right-click.
- Chooser popups (`PopupMenu`) opened during action flows.
- Option selectors (`OptionButton`) that act as menu-like selectors.

Primary code anchors:

- `ui_react_explain_graph_view.gd::_gui_input`
- `ui_react_dock_explain_panel.gd::_fill_selection_actions_popup`
- `ui_react_dock_explain_panel.gd::_fill_canvas_view_popup`
- `ui_react_dock_wire_rules_section.gd::_fill_row_context_menu`
- `ui_react_dock.gd::_build_ui`

## Taxonomy

- **Context menu**: action menu for current scope (canvas, selection, row).
- **Chooser popup**: short-lived decision menu during an operation.
- **Option selector**: persistent dropdown for mode/group/scope-like settings.

## Core Rules

1. **Scope ownership first**
   - Canvas/global actions belong to canvas menu.
   - Selection actions belong to selection menu.
   - Row/item actions belong to row menu.

2. **Stable root order**
   - `Focus/Navigate` -> `Create` -> `Modify` -> `Remove/Clear` -> `View/Scope` -> `Copy/Inspect`.

3. **Submenu threshold**
   - `0` items: hide group.
   - `1` item: inline at parent level.
   - `2+` items: submenu allowed.

4. **Canonical home**
   - Every action has one canonical menu.
   - Duplicates are allowed only as explicit shortcuts with matching label/tooltip semantics.

5. **Naming consistency**
   - Standard verbs: `Create`, `Rebind`, `Clear`, `Remove`, `Copy`, `Inspect`, `Refresh`, `Manage`.
   - Avoid mixed synonyms for same action type within the same surface.

6. **Dispatch by domain**
   - Keep menu builders and `id_pressed` handlers separated by domain.
   - Do not mix unrelated menu domains in one handler.

## Separators

- Use separators only between intent groups.
- Never start or end a menu with a separator.
- Never emit two separators in a row.

## Submenu Decision Tree

- Is the group empty?
  - Yes: hide.
  - No: continue.
- Does the group have exactly one item?
  - Yes: inline that item in parent.
  - No: continue.
- Does the group have two or more items?
  - Yes: keep as submenu.

## Label and Tooltip Grammar

- Labels:
  - Verb-first (`Create ...`, `Rebind ...`, `Copy ...`).
  - Keep object explicit (`Copy rule details`, `Copy details`).
- Tooltips:
  - One short sentence.
  - Include side effects when relevant (`undoable`, assignment target, scope impact).

## Canonical Home Matrix (Current Plugin)

- **Canvas context menu**
  - Canonical: graph-global view/scope/create actions.
  - Shortcuts allowed: none by default.

- **Selection context menu**
  - Canonical: actions on selected node/edge and selected wire host context.
  - Shortcut allowed: `Pin node` may appear in canvas scope if wording remains consistent.

- **Wire row context menu**
  - Canonical: row-local reorder/duplicate/remove/copy/inspect actions.
  - No global graph actions.

- **Chooser popups**
  - Canonical: immediate branch choice inside an operation.
  - Should prefer `Create ...` labels for create outcomes.

- **Option selectors**
  - Canonical: persistent mode/group/scope settings.
  - Label should describe setting domain (`Scan mode`, `Group by`, `Scope preset`, `Wire trigger`).

## Do / Don't

- **Do**
  - Inline a single eligible action instead of adding a one-item submenu.
  - Keep action IDs stable while refactoring grouping.
  - Reuse existing action methods when moving menu placement.

- **Don't**
  - Put selection-only actions only in canvas/global menus.
  - Introduce deeper submenu chains for context menus.
  - Change commit logic when only reorganizing IA.

## Rollout Checklist for New Menu Work

- Scope ownership is correct.
- Root order follows guideline order.
- Submenu threshold (0/1/2+) is applied.
- Label verb and tooltip style match glossary.
- Canonical-home decision is documented in PR notes.
- `PopupMenu` submenu parenting is correct (child popup under owning popup).
- Existing side effects and capability gates remain unchanged.


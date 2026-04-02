# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

No unreleased changes yet.

## [2.5.1] - 2026-04-02

### Added

- **Example:** **`examples/anim_targets_catalog_demo.tscn`** + **`anim_targets_catalog_demo.gd`** — scrollable list plays every **`UiAnimTarget.AnimationAction`** on a shared **`PreviewPanel`** after an instant **`RESET`**; trigger playground covers every **`UiAnimTarget.Trigger`** with **`POP`** targets on the same preview.

### Notes

- **Patch** release: new example files and docs only; no API changes.

## [2.5.0] - 2026-04-02

### Added

- **`UiReactRichTextLabel`** (`scripts/controls/ui_react_rich_text_label.gd`): display-only **`RichTextLabel`** binding; **`text_state`** mirrors **`UiReactLabel`** (string / array / computed / transactional shapes via **`UiReactStateBindingHelper.as_text_recursive`**); **`bbcode_enabled`** forced **`true`** in **`_ready()`**; optional **`animation_targets`** (hover + **`TEXT_CHANGED`**) — **CB-014**.
- **Example:** **`examples/rich_text_label_demo.tscn`** + **`rich_text_label_demo.gd`** (mutate **`UiStringState`** only; no direct **`RichTextLabel.text`** writes).
- **Editor:** **`UiReactScannerService`** stem + **`BINDINGS_BY_COMPONENT`** for **`UiReactRichTextLabel`**; **`UiReactValidatorService`** **`text_state`** typing parity with **`UiReactLabel`** — **CB-020**.

### Changed

- **README:** control table, **Text controls** subsection, quickstart + layout row + common mistake for display-only rich text; step-2 bullet includes **`UiReactRichTextLabel.text_state`**.
- **`docs/ROADMAP.md`:** **CB-014** marked **Done** for **`UiReactRichTextLabel`** (**`UiReactTextEdit`** still out of scope).

### Notes

- **Minor** release: additive **`class_name`** + `@export` surface; no breaking changes to existing controls.

## [2.4.0] - 2026-04-02

### Added

- **`UiReactTextureButton`** (`scripts/controls/ui_react_texture_button.gd`): same **`pressed_state`** / **`disabled_state`** / **`animation_targets`** pattern as **`UiReactButton`**, for **`TextureButton`** — **CB-012**.
- **`UiReactTree`** (`scripts/controls/ui_react_tree.gd`): **`selected_state`** (**`UiIntState`**) maps to **visible pre-order** row index or **`-1`**; forces **`Tree.SELECT_SINGLE`** — **CB-013**.
- **Examples:** **`examples/texture_button_demo.tscn`** + **`texture_button_demo.gd`**; **`examples/tree_demo.tscn`** + **`tree_demo.gd`** (deferred tree build so indices match bind time).
- **Editor:** **`UiReactScannerService`** `SCRIPT_STEM_TO_COMPONENT` + **`BINDINGS_BY_COMPONENT`** for **`UiReactTextureButton`** and **`UiReactTree`** (**CB-020**).

### Changed

- **README:** control table + **UiReactTree binding semantics**; quickstart + layout paths for new demos; **Strict integer indices** note includes **`UiReactTree.selected_state`**.

### Notes

- **Minor** release: new global **`class_name`** controls and new `@export` surfaces only (additive).

## [2.3.0] - 2026-04-01

### Added

- **`shop_computed_demo.gd`:** **Buy** subtracts **price × quantity** from **gold** when affordable (**CB-006**); wired from **`shop_computed_demo.tscn`**.
- **`UiReactItemList`:** row entries may be **`Dictionary`** with **`label`** or **`text`**, optional **`icon`** (**`Texture2D`** or **`res://`** texture path) — **CB-008**.

### Changed

- **README:** **Imperative actions (CB-006)**, **Screen transitions (CB-016)**, **Modals / focus (CB-017)**, **Escape hatch (CB-025)**; **List patterns** updated for dict/icon rows; inventory demo first row uses project **`icon.svg`**.

### Notes

- **Minor** release: additive public behavior for **`UiReactItemList`** row parsing (strings and dicts remain supported).

## [2.2.1] - 2026-04-01

### Added

- **Example:** **`examples/inventory_list_demo.tscn`** + **`inventory_list_demo.gd`** — text filter, **`UiReactItemList`** bound to string rows in **`UiArrayState`**, detail label, selection **`UiIntState`**, and **CB-015** pointer gating via full-rect overlay + **`mouse_filter`**.

### Changed

- **README:** new **List patterns (P3)** section ( **`str(entry)`** row text, filter recipe, gating workaround); quickstart + layout table + common-mistake rows updated.

### Notes

- **No** change to public **`class_name`** / **`UiReact*`** export shapes (**patch** release).

## [2.2.0] - 2026-04-01

### Added

- **`UiComputedStringState`**, **`UiComputedBoolState`:** abstract bases with **`sources`**, **`recompute()`**, and **`compute_string()`** / **`compute_bool()`** (`scripts/api/models/ui_computed_string_state.gd`, `ui_computed_bool_state.gd`). No graph solver—explicit dependencies only; **do not** create cycles.
- **`UiReactComputedSync`:** control that subscribes to **`sources`** on a computed resource (**`value_changed`** + **`changed`**), calls **`recompute()`**, and disconnects on **`_exit_tree()`**; hard cap of **32** dependency slots (`scripts/controls/ui_react_computed_sync.gd`).
- **Examples:** **`examples/shop_computed_demo.tscn`** (+ afford / Buy-disabled / status subclass scripts); **`options_transactional_demo.tscn`** now uses computed status + sync (root scene script removed).

### Changed

- **Editor validator:** binding hints / label **`text_state`** phrasing now mention **`UiComputedStringState`** / **`UiComputedBoolState`** where relevant (`editor_plugin/services/ui_react_validator_service.gd`).

## [2.1.0] - 2026-04-01

### Added

- **`UiTransactionalGroup`:** batch **`begin_edit_all`**, **`apply_all`**, **`cancel_all`**, **`has_pending_changes`** over an ordered **`states`** array (`scripts/api/models/ui_transactional_group.gd`).
- **`UiReactTransactionalActions`:** inspector **`NodePath`** wiring from **Apply** / **Cancel** **`BaseButton`** nodes to a group’s **`apply_all`** / **`cancel_all`**, optional **`begin_on_ready`** (`scripts/controls/ui_react_transactional_actions.gd`).
- **`UiTransactionalState`:** draft / **`committed_value`** lifecycle with **`begin_edit`**, **`apply_draft`**, **`cancel_draft`** / **`reset_to_committed`**, and **`has_pending_changes`** (`scripts/api/models/ui_transactional_state.gd`). Controls bind to the draft via **`get_value`/`set_value`** (same as other **`UiState`** resources).
- **Example:** **`examples/options_transactional_demo.tscn`** (+ controller script) — options-style audio controls with **Apply** / **Cancel** using transactional state.
- **Editor dock — unused state files:** INFO diagnostics for typed **`UiState`** `.tres` in the output folder that appear in the **saved** edited **`.tscn`** and are not bound on **`UiReact*`** exports; **Reveal** (**FileSystemDock** **`navigate_to_path`**) and **Ignore** (persisted in **`ui_react/plugin_ignored_unused_state_paths`**).
- **Editor dock — refresh:** coalesced rescan on **`EditorFileSystem.filesystem_changed`**.
- **Diagnostics model:** **`IssueKind`**, **`resource_path`**, and **`make_unused_state_file_issue`** on **`UiReactDiagnosticModel.DiagnosticIssue`**.
- **Services:** **`UiReactStateReferenceCollector`**, **`UiReactUnusedStateService`**, **`UiReactSceneFileResourcePaths`** (scene-file **`res://`** extraction for unused-state filtering).

### Changed

- **`UiReactUnusedStateService`:** unused **`UiState`** `.tres` INFO rows are **scene-file-scoped**—only resources under the configured output folder whose **`res://` path appears in the edited scene’s saved `.tscn` text** and are **not** assigned on any **`UiReact*`** export in that scene. **Unsaved scenes** yield no unused-state rows. New helper **`UiReactSceneFileResourcePaths`** parses **`res://`** substrings from the scene file.
- **Copy / docs:** issue summary and fix hint state edited-scene-only scope; **README** and dock tooltips describe limitations (no project-wide scan; script-only refs not detected).
- **`examples/options_transactional_demo`:** orchestration uses **`UiTransactionalGroup`** + **`UiReactTransactionalActions`**; scene script handles status display only.
- **`UiReactSlider` / `UiReactSpinBox` / `UiReactProgressBar`:** **`value_state`** export type widened to **`UiState`** so **`UiFloatState`** or **`UiTransactionalState`** (float/int payload) can be assigned without losing inspector compatibility.
- **`UiReactCheckBox`:** **`checked_state`** export type widened to **`UiState`** for **`UiBoolState`** or bool-shaped **`UiTransactionalState`**.
- **Validator:** accepts **`UiTransactionalState`** when **`committed_value`** matches the binding’s expected payload type; **`UiReactLabel.text_state`** allows transactional string/array payloads.
- **Editor dock — grouping:** **By node** places unused-file rows under **Unused state files** (not **`(scene)`**).
- **Editor dock — details report:** optional **`Resource`** line for **`resource_path`**.
- **`UiReactStateFactoryService.default_output_dir()`:** normalize saved path with **`String(...).strip_edges()`**.
- **`examples/options_transactional_demo`:** status line uses **`UiReactLabel`** + **`UiStringState`**; root script updates **`UiStringState`** via **`set_value()`** only; **`transactional_group`** export drives **`has_pending_changes()`** for the status suffix.

### Removed

- **Unused-state false positives** from listing output-folder **`UiState`** files that are only referenced by **other** scenes’ `.tscn` files while a different scene is edited.

### Fixed

- **`UiReactUnusedStateService`:** handle **`DirAccess.list_dir_begin()`** failure instead of listing silently.

### Documentation

- **README:** scene-file-scoped unused **`UiState`** rules; **`UiReactSceneFileResourcePaths`** in contributor architecture list; **`UiTransactionalGroup`** + **`UiReactTransactionalActions`** orchestration; public API table + layout paths; transactional example description; existing transactional / **`UiState`** export / editor-plugin sections retained.
- **`ROADMAP.md`:** P1 phase summary, exit-criteria orchestration note, **CB-002** notes, and footer **Last updated** for group + adapter.
- **README:** **P1 vs P2 (computed state)** scope subsection; orchestration step 7 (**`UiStringState`** + **`UiReactLabel`** summary pattern); deferred-work sentence for P2+ systems.
- **`ROADMAP.md`:** P1 exit criteria marked complete; **CB-002** notes for reactive demo status.

## [2.0.0] - 2026-03-29

### Removed

- **`UiTargetCfg` / `UiControlTargetCfg`** scripts and global classes (unused config bases).
- **`UiAnimUtils.show_animated` / `UiAnimUtils.hide_animated`** and string preset handling in **`UiAnimPresetRunner`** — use **`UiAnimUtils.preset(UiAnimUtils.Preset.*, ...)`** only.
- **`UiReactItemList.disabled_state`** (no-op previously; ItemList has no disabled API). Use parent **`Control`** / **`mouse_filter`** / focus policy for equivalent behavior.

### Changed

- **Animation defaults:** duplicate constants were removed from **`UiAnimUtils`**; **`UiAnimConstants`** is the single public numeric default source (includes **`PIVOT_USE_CONTROL_DEFAULT`** for center pivot).
- **Editor dock:** ProjectSettings registration and UI preference load/save moved to **`UiReactDockConfig`**; **`UiReactDock`** keeps layout and actions.
- **Scale pop:** internal phase lengths (`0.6` / `0.4` of duration) are named constants in **`UiAnimScaleAnimations`**.
- **State factory:** unique `.tres` suffix loop bound named **`MAX_UNIQUE_FILENAME_SUFFIX_ATTEMPTS`**.
- **Validator:** clearer local names (`node_path`, `property_value`, `ui_state`).
- **Loop runner:** infinite-loop **`stop()`** no longer reassigns transform properties after killing tweens (values unchanged).

### Fixed

- **`UiAnimTarget.apply_to_control`:** entry guard via **`UiAnimTweenFactory.guard_anim_pair`**; **`UiAnimUtils`** dispatch uses correct argument order for slide/center-slide/bounce/elastic/rotate-out so **`repeat_count`** and **`easing`** are not misaligned.

## [1.0.0] - 2026-03-28

- Initial documented release for the Ui React addon: reactive **UiReact\*** controls, **UiState** resources, optional **UiAnimTarget** inspector animations, **UiAnimUtils**, and the optional **Ui React** editor dock (validation, filters, Fix / Fix All / Ignore All, project settings for dock preferences). See **README.md** and **editor_plugin/plugin.cfg** for details.

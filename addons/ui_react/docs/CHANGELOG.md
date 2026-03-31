# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- **Editor dock — unused state files:** INFO diagnostics for typed **`UiState`** `.tres` in the configured output folder that are not referenced by the edited scene; **Reveal** (**FileSystemDock** **`navigate_to_path`**) and **Ignore** (persisted in **`ui_react/plugin_ignored_unused_state_paths`**).
- **Editor dock — refresh:** coalesced rescan on **`EditorFileSystem.filesystem_changed`**.
- **Diagnostics model:** **`IssueKind`**, **`resource_path`**, and **`make_unused_state_file_issue`** on **`UiReactDiagnosticModel.DiagnosticIssue`**.
- **Services:** **`UiReactStateReferenceCollector`**, **`UiReactUnusedStateService`**.

### Changed

- **Editor dock — grouping:** **By node** places unused-file rows under **Unused state files** (not **`(scene)`**).
- **Editor dock — details report:** optional **`Resource`** line for **`resource_path`**.
- **`UiReactStateFactoryService.default_output_dir()`:** normalize saved path with **`String(...).strip_edges()`**.

### Fixed

- **`UiReactUnusedStateService`:** handle **`DirAccess.list_dir_begin()`** failure instead of listing silently.

### Documentation

- **README:** editor plugin sections updated (row actions, refresh triggers, filter/`resource_path`, project key **`plugin_ignored_unused_state_paths`**, architecture list); removed dead **plugin_ux_*** links in favor of **`docs/ROADMAP.md`**.
- Addon [`ROADMAP.md`](ROADMAP.md) (charter, phases P0–P5+, screen matrix, exit criteria, capability appendix **CB-001–CB-030**); link from **README** top.

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

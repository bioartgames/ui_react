# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Documentation

- **North-star alignment:** README (inspector-first **four pillars**, designer/blessed path, **Examples at a glance**, **Conditional strings**, list-patterns lead with **`inventory_screen_demo`** + **`wire_rules`**); [`ROADMAP.md`](ROADMAP.md) (Charter **inspector-first** row, glossary **Action layer** = §5 + **`UiReactButton`** + float ops, **CB-002** / **CB-043** notes, **CB-048** stock-computed backlog, **CB-040** closed); [`WIRING_LAYER.md`](WIRING_LAYER.md) §2 **Actions** + bounded float cross-link; [`ACTION_LAYER.md`](ACTION_LAYER.md) §2 `UiComputed*` vs Actions for conditional copy; [`P5_CURRENT_STATE_AUDIT.md`](P5_CURRENT_STATE_AUDIT.md) **Last run** context. **No** `plugin.cfg` version bump (docs-only).

### Breaking

- **Examples:** removed **`examples/shop_computed_afford.gd`**, **`shop_computed_buy_disabled.gd`**, **`shop_computed_status.gd`** (replaced by stock **`UiComputed*`** under **`scripts/api/models/`**). **`class_name`** **`ShopComputedAfford`**, **`ShopComputedBuyDisabled`**, **`ShopComputedStatus`** removed.
- **Examples:** removed **`examples/shop_computed_demo.gd`** and **`examples/options_status_computed.gd`**. Shop **Buy** is **`UiReactButton.action_targets`** **`SUBTRACT_PRODUCT_FROM_FLOAT`**; options status uses **`UiComputedTransactionalStatusString`**.
- **Wiring:** removed **`examples/inventory_screen_demo.gd`**. **`inventory_screen_demo.tscn`** is **inspector-only** (**`wire_rules`** + **`UiReactWireRunner`**). New rules: **`UiReactWireSetStringOnBoolPulse`**, **`UiReactWireSyncBoolStateDebugLine`**. **`UiReactWireCopySelectionDetail`** defaults **`clear_suffix_on_selection_change`** to **true** (runner clears **`suffix_note_state`** when **`selected_state`** changes before recomputing detail).
- **`UiReactTree`:** requires **`tree_items_state`** (**`UiArrayState`** whose value is an **`Array` of `UiReactTreeNode`**). Populate the tree via data, not ad hoc **`create_item`** code on the control.
- **Computed wiring:** removed **`UiReactComputedSync`**. Assign **`UiComputedStringState`** / **`UiComputedBoolState`** subclasses to **`UiReact*`** exports (e.g. **`text_state`**, **`checked_state`**); **`UiReactComputedService`** wires **`sources`** at runtime. Nested computeds (sources of other computeds) are wired automatically.
- **`UiAnimTarget`:** renamed **`preamble_reset_duration`** → **`reset_duration`**, **`await_preamble_before_main`** → **`wait_after_reset`**. Re-save scenes/subresources that referenced the old property names.
- **`UiReact*`** controls: removed **`animation_selection_provider`**. **`selection_slot`** filtering uses **`get_animation_selection_index()`** on the **same** host when any **`animation_targets`** row uses **`selection_slot >= 0`**.
- **`UiReactItemList`:** removed **`row_play_preamble_reset`**, **`row_play_soft_reset_duration`**, **`preamble_reset_target`**. Use **`UiAnimTarget.reset_duration`** / **`wait_after_reset`** per row instead.
- **`UiReactItemList`:** removed **`row_animation_targets`**. Use **`animation_targets`** with **`selection_slot`** set per row for **`play_selected_row_animation`** / **`play_preamble_reset_only`**.

### Added

- **`UiReactStateOpService.afford_floats`**; stock computeds **`UiComputedFloatGeProductBool`**, **`UiComputedBoolInvert`**, **`UiComputedOrderSummaryThreeFloatString`** (shop demo afford / buy-disabled / order-summary BBCode; no **`examples/*.gd`**).
- **`UiReactStateOpService`** (`scripts/internal/react/ui_react_state_op_service.gd`); **`UiReactActionKind.SUBTRACT_PRODUCT_FROM_FLOAT`** on **`UiReactActionTarget`**; **`UiReactButton.action_targets`** + **`run_actions`** on **`PRESSED`** (merged trigger map with **`animation_targets`**).
- **`UiComputedTransactionalStatusString`** for draft/committed transactional status lines.
- **`UiReactWireSetStringOnBoolPulse`**, **`UiReactWireSyncBoolStateDebugLine`**; internal **`UiReactWireTemplate`** helpers for **`{name}`** / **`{kind}`** / **`{qty}`** substitution shared with **`UiReactWireCopySelectionDetail`**.
- **`UiReactTreeNode`** resource and **`UiReactTree.tree_items_state`**: hierarchical **`Tree`** rows from **`UiArrayState`** (full rebuild on change; **`get_visible_row_count()`** for **`selection_slot`** diagnostics).
- **Editor:** **`UiReactTreeValidator`** (payload shape) and **`UiReactAnimValidator`** extension for **`UiReactTree`** (**`selection_slot`** vs visible row count).
- **`UiAnimTarget`:** **`reset_duration`**, **`wait_after_reset`**; **`apply_with_preamble()`**, **`apply_preamble_reset_only()`**.
- **`UiReactComputedService`** (`scripts/internal/react/ui_react_computed_service.gd`): refcounted dependency wiring for bound computeds; one **`recompute()`** per computed per frame (deferred).
- **Editor:** dock **WARNING** via **`UiReactComputedValidator`** when a **`UiComputed*`** has **`sources`** but is neither bound to a registry **`UiReact*`** export nor only nested as another computed’s source.
- **`UiReactTree`:** **`get_animation_selection_index()`** (visible pre-order index) for **`selection_slot`** filtering.
- **`UiReactButton`** / **`UiReactTextureButton`:** **`press_writes_float_state`** + **`press_writes_float_value`** for one-way float writes on press.
- **Editor:** dock **`animation_targets`** **`selection_slot`** vs **`item_count`** on **`UiReactItemList`** (**`UiReactAnimValidator`**).
- **`anim_targets_catalog_demo.tscn`:** scriptless left column (**`items_state`**, **`animation_targets`** + **`selection_slot`**, signal connections); **`FireCompletedButton`** uses **`press_writes_float_state`**.

### Changed

- **`UiReactSpinBox`:** **`UiReactComputedService.hook_bind`** / **`hook_unbind`** for **`value_state`** and **`disabled_state`** so bound **`UiComputed*`** (including nested sources, e.g. shop **`disabled_state`**) recompute like other **`UiReact*`** controls.
- **`inventory_screen_demo.tscn`:** wire catalog rows live on **`UiReactWireCatalogData.rows`** in the scene (removed **`inventory_demo_catalog.gd`** / **`inventory_demo_catalog_wire_data.gd`**).
- **`inventory_screen_demo.tscn`:** category **`UiReactTree`** uses scene **`tree_items_state`** + **`UiReactTreeNode`** subresources (no **`_build_tree`** script).
- **`UiAnimTarget`:** Inspector **`@export`** order is **`target`** → **`selection_slot`** → **`trigger`** → **`reset_duration`** / **`wait_after_reset`** → **`animation`**, then timing and behavior.
- **`UiReactAnimTargetHelper`:** **`collect_animation_targets_for_row_slot`**; **`UiReactItemList`** row play uses **`animation_targets`** + **`selection_slot`** only.
- **`UiReactAnimTargetHelper.trigger_animations`:** resolves selection index from the host when slot gating is used (no external provider node).
- **Reactivity:** `UiReactWireRunner` listens to **`Resource.changed` only** on `UiState` dependencies where applicable; **`UiReactComputedService`** uses **`Resource.changed`** on computed **`sources`**.
- **Wiring:** `UiReactWireRule.trigger` uses **`UiReactWireRule.TriggerKind`** (`TEXT_CHANGED = 5`, `SELECTION_CHANGED = 6`, `TEXT_ENTERED = 13`) so wiring does not depend on `UiAnimTarget.Trigger`; existing saved ints stay valid.
- **Catalog rule:** `UiReactWireRefreshItemsFromCatalog.first_row_icon_path` applies to the **first row after filters**, not catalog row 0 only.
- **`UiTransactionalState`:** `set_value` / `set_silent` clone array/dictionary drafts like other states.
- **Actions:** `UiReactActionTargetHelper._with_reentry_guard` still uses sequential unlock after `fn.call()` (same behavior as before this batch; full **`try` / `finally`** is optional if you target an engine/toolchain that parses it reliably).
- **Controls:** Shared **`UiReactTwoWayBindingDriver`**; exported `UiState` bindings use **getters/setters** with reconnect when the resource is swapped at runtime.
- **Editor:** `UiReactComponentRegistry` is the single binding/stem registry; **`UiReactValidatorService`** delegates to split validators; **`UiReactUnusedStateService`** caches loads by `mtime` (full cache clear on dock **Rescan**).
- **Editor:** dock UI scripts live under **`editor_plugin/dock/`** (`ui_react_dock.tscn`, `ui_react_dock*.gd`); **`ui_react_editor_plugin.gd`** loads **`res://addons/ui_react/editor_plugin/dock/ui_react_dock.tscn`**.
- **Hygiene:** Removed unreferenced plugin-generated sample `.tres` files; README notes not committing stray plugin output.

## [2.7.0] - 2026-04-04

### Added

- **Wiring layer (P5.1 core):** [`docs/WIRING_LAYER.md`](WIRING_LAYER.md) — **`UiReactWireRunner`**, **`UiReactWireRule`** + **`UiReactWireMapIntToString`**, **`UiReactWireRefreshItemsFromCatalog`**, **`UiReactWireCopySelectionDetail`**, **`UiReactWireCatalogData`**; **`wire_rules`** on **`UiReactItemList`**, **`UiReactTree`**, **`UiReactLineEdit`**, **`UiReactCheckBox`**, **`UiReactTransactionalActions`**.
- **Editor diagnostics (CB-034):** dock **WARNING** when **`wire_rules`** exist without **`UiReactWireRunner`** or when multiple runners are in the edited scene; **per-rule** validation of MVP **`wire_rules`** exports (`UiReactValidatorService`); **`UiReactTransactionalActions`** registered in **`UiReactScannerService`**; unused **`UiState` .tres** scan includes **`UiState`** refs inside **`wire_rules`** (`UiReactStateReferenceCollector`).
- **`inventory_screen_demo`:** **`UiReactWireRunner`** + inspector **`wire_rules`**; **`InventoryDemoCatalogWireData`**; category hint via **`UiReactLabel`** + state; root script trimmed to tree build + demo-only **Use/Sort** notes + debug labels.

### Changed

- **Examples:** Consolidated to **four** scenes under `examples/`: **`inventory_screen_demo.tscn`**, **`options_transactional_demo.tscn`**, **`shop_computed_demo.tscn`**, **`anim_targets_catalog_demo.tscn`**. Removed **`demo.tscn`**, **`action_layer_demo.tscn`**, **`inventory_list_demo`**, **`texture_button_demo`**, **`tree_demo`**, **`rich_text_label_demo`** (and paired `*.gd` where applicable). **Main Scene** (`project.godot`) defaults to **`inventory_screen_demo.tscn`**.
- **`inventory_screen_demo`:** List lock uses **`action_targets`** **`SET_MOUSE_FILTER`** on **`UiReactItemList`**; **`LockList`** **`GRAB_FOCUS`** on unlock. Folded former micro-demo widgets: **`UiReactOptionButton`** (sort preset showcase).
- **`options_transactional_demo`:** Added **`UiReactTabContainer`** with audio controls on tab 0.
- **`shop_computed_demo`:** Added **`UiReactProgressBar`** (gold) and **`UiReactSpinBox`** (quantity; **`disabled_state`** mirrors Buy when unaffordable).

### Documentation

- **`docs/P5_CURRENT_STATE_AUDIT.md`:** Stock-take for P5.1, **CB-034**, and P5.1.b / P5.2 gates.
- **`docs/WIRING_LAYER.md`:** §3 collection scope + ordering note; §9 **CB-034** shipped vs extensions.
- **`docs/ROADMAP.md`:** P5.1 checklist + Appendix; **CB-034** **Done** for P5.1 editor scope.
- **`README.md`**, **`docs/ROADMAP.md`**, **`docs/WIRING_LAYER.md`:** Example paths and Appendix notes for removed / consolidated scenes.

## [2.6.5] - 2026-04-02

### Fixed

- **`UiReactTree`:** **`action_targets`** now runs **`UiReactActionTargetHelper.apply_validated_actions_and_merge_triggers`** (same as other §5 controls) so control-triggered rows connect signals and **`state_watch`** rows get **`value_changed`** + initial sync.
- **`UiReactActionTarget`:** Inspector **`trigger`** is hidden (storage-only) when **`state_watch`** is set; **`PROPERTY_USAGE_DEFAULT`** when control-driven.
- **`UiReactActionTargetHelper`:** duplicate **`bool_flag_state`** / **`state_watch`** on **`SET_UI_BOOL_FLAG`** uses **`push_error`** at runtime (aligned with §3.1.1 and dock **ERROR**).

### Changed

- **Editor:** dock **`action_targets`** validation — **WARNING** when **`state_watch`** is set and **`trigger`** is not **`PRESSED`**.

### Documentation

- **`docs/ACTION_LAYER.md`:** §7 note on Action implementation vs P5.1 wiring sequencing.
- **`README.md`:** one-line pointer to that note.

## [2.6.4] - 2026-04-02

### Added

- **Action layer (P6.1):** normative **[`docs/ACTION_LAYER.md`](ACTION_LAYER.md)**; **`UiReactActionTarget`** + **`UiReactActionKind`** (`scripts/api/models/ui_react_action_target.gd`); **`UiReactActionTargetHelper`** (`scripts/internal/react/ui_react_action_target_helper.gd`); **`action_targets`** on **[`WIRING_LAYER.md`](WIRING_LAYER.md) §5** controls (**`UiReactItemList`**, **`UiReactTree`**, **`UiReactLineEdit`**, **`UiReactCheckBox`**, **`UiReactTransactionalActions`** — state-driven rows only on the transactional host).
- **Example:** **`examples/action_layer_demo.tscn`** — **`GRAB_FOCUS`** row on **`UiReactCheckBox`** (**CB-047**).
- **Editor:** **`UiReactValidatorService`** validates **`action_targets`** paths and **`UiReactTransactionalActions`** constraints (**CB-046**).

### Documentation

- **`docs/ROADMAP.md`:** phase **P6.1**, glossary **Action layer**, Appendix **CB-042–CB-047**, review process + **CB-020** note.
- **`docs/WIRING_LAYER.md`:** Actions cross-paragraph in §2.
- **`README.md`:** Action layer subsection, **`action_targets`** in setup + control table + examples list.

## [2.6.3] - 2026-04-02

### Documentation

- **Roadmap:** phase model **P5** (wiring layer) and **P6+** (deferred parking, replacing the old **P5**-plus parking row); glossary **Wiring**; screen matrix **P5** column; exit criteria for **P5.1**, **P5.1.b** (optional **`UiReactWireHub`**), **P5.2**; review process **CB-031–CB-041** + [`WIRING_LAYER.md`](WIRING_LAYER.md) drift.
- **[`WIRING_LAYER.md`](WIRING_LAYER.md):** normative **P5** spec—**`UiReactWireRunner`**, **`UiReactWireRule`**, **`wire_rules`**, MVP rule types, diagnostics, phasing, optional hub (**P5.1.b**).
- **Appendix:** **CB-031–CB-041** (wiring backlog + **`UiReactWireHub`** **CB-041**); historical rows **CB-005/007/010/018/019** retargeted **P6+**.
- **README:** roadmap blurb **P0–P6+** / **CB-001–CB-041**; **Wiring layer (P5)** subsection; layout + planning links to **ROADMAP** and **WIRING_LAYER**.

## [2.6.2] - 2026-04-02

### Changed

- **`examples/inventory_screen_demo.tscn`:** **`UiAnimTarget`** rows — **FADE_IN** on **Detail** when the item list selection changes, **FADE_IN** on the category hint when the tree selection changes, **POP** on **Sort** (matching **Use**); help labels updated.

## [2.6.1] - 2026-04-02

### Added

- **Example:** **`examples/inventory_screen_demo.tscn`** + **`inventory_screen_demo.gd`** — one **inventory-style** layout combining **`UiReactTree`** (category/kind filter), **`UiReactItemList`** (filter, detail, lock overlay), and **`UiReactTextureButton`** action row (**Use** + **Sort**, shared **Disable actions**).
- **`examples/inventory_demo_catalog.gd`** (**`InventoryDemoCatalog`**): shared demo item rows used by **`inventory_screen_demo`**.

### Notes

- **Patch** release: new example + shared catalog helper; **`inventory_list_demo`** now references **`InventoryDemoCatalog.CATALOG`** (same data as before).

## [2.6.0] - 2026-04-02

### Added

- **`UiAnimBaselineApplyContext`** (`scripts/internal/anim/ui_anim_baseline_apply_context.gd`): apply-scope stack so **`UiAnimTarget`** can opt out of baseline capture per row without threading flags through **`UiAnimUtils`**.
- **`UiAnimTarget.use_unified_baseline`** (`@export`, default **true**): when **false**, skip unified snapshot **acquire**/**release** for supported internal animations on that row.

### Changed

- **Slides** (edge + center): use the same unified snapshot **acquire** on start and **release** on completion as scale/expand (including **`UiAnimLoopRunner`** paths).
- **`UiAnimTarget` RESET:** **`duration`** and **`easing`** on the row are passed through to **`animate_reset_all`** (**`duration == 0`** → instant restore; **`duration > 0`** → tweened restore). **`duration`** export minimum is **`0`** so hard reset is selectable in the Inspector.

### Notes

- **Minor** release: default **`UiAnimTarget`** behavior now restores slides to the baseline after the tween (matching expand). Projects that relied on slides **keeping** an offset must set **`use_unified_baseline = false`** on those rows. Direct **`UiAnimUtils`** calls do **not** push the context stack, so they keep the previous default (baseline **on**).

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

**Note:** **`UiReactComputedSync`** later moved to **`Resource.changed`**-only dependencies (avoids double **`recompute`** on the same update). See **`[Unreleased]`** at the top of this file (post–**2.7.0** hardening batch).

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

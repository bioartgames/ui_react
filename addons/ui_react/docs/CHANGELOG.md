# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Breaking

- **`UiReactCheckBox.checked_state`** is now typed **`UiBoolState`** (was **`UiState`**). **`UiComputedBoolState`** and other **`UiBoolState`** subclasses remain valid; assign **`UiStringState`** / unrelated **`UiState`** types to this slot only via broken scenes (fix in Inspector).
- **`UiReactTransactionalActions` removed:** the path-based Apply/Cancel coordinator control is deleted. Use **`UiReactButton`** / **`UiReactTextureButton`** **`transactional_host`** + **`UiReactTransactionalSession`** only. Scenes that still instantiated the coordinator must switch to button-hosted transactional wiring.
- **Editor plugin — tab shortcuts only (`ui_react/settings/schema_version` 3):** the Ui React bottom dock tab no longer registers a global toggle shortcut (no **Alt+U** / no `ui_react/settings/shortcuts/bottom_panel_json`). **Alt+1** (main row **`KEY_1`**, not numpad) and **Alt+2** are the defaults for **Open Diagnostics** / **Open Wiring** (`open_diagnostics_json`, `open_wiring_json`). Migrating from schema versions before **3** clears `bottom_panel_json` and resets both `open_*` keys to those defaults once (prior custom **Alt+D** / **Alt+G** bindings are overwritten).

### Changed

- **Examples:** Removed **`feedback_demo.tscn`**. **`audio_targets`** / **`haptic_targets`** (**CB-061**) are now Inspector-authored on **Use** (**`UiReactTextureButton`**) in **`inventory_screen_demo.tscn`** and **Buy** (**`UiReactButton`**) in **`shop_computed_demo.tscn`** (each with a child **`AudioStreamPlayer`**). **README** / **ROADMAP** updated (**four** official example scenes).
- **Subscription scope / editor signal lifecycle:** runtime **`UiReact*`** controls and **`UiReactBaseButtonReactive`** route local **`Control`** signals through **`UiReactSubscriptionScope`** (**`connect_bound`** / **`dispose`**); the editor uses **`UiReactEditorSignalLifecycle`** (dock, settings panel, wiring explain panel, plugin entry) so teardown matches hand-maintained **`connect`** / **`disconnect`** pairs. **`UiReactAnimTargetHelper.connect_if_absent`** remains the supported path for **`UiBoolState.value_changed`** in **`UiReactActionTargetHelper`** / **`UiReactFeedbackTargetHelper`** (**`state_watch`** rows); prefer **`UiReactSubscriptionScope`** for **control** signals only. Reordering **`@export`** blocks in **`.gd`** does not change **`.tscn`** serialization for existing properties.
- **State-driven feedback (`audio_targets` / `haptic_targets`, `state_watch` non-null):** **`UiReactFeedbackTargetHelper.sync_initial_state`** runs **`play()`** / **`start_joy_vibration`** only when **`UiReactStateBindingHelper.coerce_bool(state_watch.get_value())`** is **true**; **`value_changed`** dispatches those rows **only on rising edge** (new coerces true, old coerces false). Control-triggered rows unchanged. Migration: use **control-triggered** rows or game code for cues on **falling** edge — see **[FEEDBACK_LAYER.md](FEEDBACK_LAYER.md) §9**, **[DECISIONS.md](DECISIONS.md)** (2026-05-01 entry).
- **`UiReactBaseButtonReactive`:** **`sync_initial_state`** reads **`action_targets`** **after** validation (**post-filter** array), matching other **`UiReact*`** controls.
- **`UiReactControlStateWire`:** `use_computed_hook: false` still runs **`UiReactComputedService`** for **`UiComputed*`** resources (effective hook via **`UiReactComputedService.supports_computed_wiring`**), so list/tree/tab bindings that passed **`false`** no longer strand sole-consumer computeds.
- **`UiReactComputedService`:** public **`supports_computed_wiring(state)`**; when **`Engine.get_main_loop()`** is unavailable, dirty computeds flush **synchronously** instead of leaving **`_dirty_computed_ids`** stranded.
- **`UiReactActionTargetHelper`:** **`teardown_for_control_exit(owner)`** clears **`state_watch`** connections and action reentry-lock meta; **`UiReact*`** / **`UiReactBaseButtonReactive`** call it before unbinding states / wire detach.
- **`UiReactEditorPlugin`:** **`set_process_input(false)`** in **`_exit_tree`** (symmetry with **`_enter_tree`**).
- **`UiReact*`** controls (and shared **`UiReactBaseButtonReactive`**): **`_disconnect_local_control_signals`** / **`disconnect_local_signals`** dispose the per-control **`UiReactSubscriptionScope`**, releasing **`pressed`**, **`toggled`**, selection, text, range, focus, hover, and GUI-input handlers bound in **`_ready`** / animation validation.
- **`UiReactItemList`:** string icon **`res://`** paths use a capped **FIFO texture cache**; identical row **signatures** skip **`clear()`** rebuilds while still syncing selection and validation (ItemList hot path).
- **`UiReactWireRuleHelper`**, **`UiReactWireRuleIntrospection`**, **`UiReactWiringValidator`:** detect **`UiReactWireSortArrayByKey`** via **`rule is UiReactWireSortArrayByKey`** (no script-path string equality).
- **`UiAnimLoopRunner`:** inner loop helpers use **`signal`** declarations instead of **`var … = Signal()`**; **`_helper_stack`** is **`Array[Node]`**.
- **Editor diagnostics dock:** **`UiReactDockFilter.visible_issues`** (**pure**) centralizes severity, search, and ignore-key narrowing; Diagnostics refresh **coalescing** and manual unused-cache clearing live in **`UiReactDockRefreshCoalescer`** (`editor_plugin/dock/ui_react_dock_refresh_coalescer.gd`).
- **Repo / shell (release readiness, Pass 13):** removed third-party **`ai_assistant_hub`** **`[plugins]`** entries from root **`project.godot`**; **`.vscode/settings.json`** uses a placeholder **`godotTools.editorPath.godot4`** (replace locally; see root **`AGENTS.md`**); **`docs/RELEASE_READINESS_PASSES.md`** Pass **13** scope lists **`editor_plugin/plugin.cfg`** and **`ui_react_editor_plugin.gd`** (correct paths).
- **Plugin metadata:** **`editor_plugin/plugin.cfg`** **`version`** set to **3.1.0** (**CB-061** feedback layer); bump **`version=`** again when cutting the next tagged release.
- **Docs (release readiness, Pass 12):** README **Quickstart** inventory example documents **`UiReactWireSortArrayByKey`** and points at **`WIRING_LAYER`** §6; **Examples at a glance** marks **`anim_targets_catalog_demo`** **Actions** as used (**`SET_FLOAT_LITERAL`** on **`FireCompletedButton`**); **Required vs optional** table **Bindings** column aligned with **ROADMAP** **CB-052** (incl. Slider/SpinBox/ProgressBar **†**, label **—**, §5 hosts); primary story + blessed path state **`UiReactWireRuleHelper`** applies to **`wire_rules`** exports per **`WIRING_LAYER`** §3; **Four pillars** graph copy limits Dependency Graph **`sources[]`** UX to **`UiComputedStringState`/`UiComputedBoolState`** subclasses (matches graph builder).
- **Editor plugin:** removed the Diagnostics-tab **Settings** button and **`UiReactDockSettingsPopup`** (shortcut capture UI). Open-tab shortcuts remain internal **`open_diagnostics_json`** / **`open_wiring_json`** Project Settings keys with defaults **Alt+1** / **Alt+2**; README documents optional advanced JSON editing.
- **`UiReactWireRuleHelper`:** lazy **`Script` → Callable** dispatcher for shipped **`UiReactWireRule`** subclasses (**`_ensure_wire_dispatch_table`**); single-scan **`attach`** with bind-all-then-apply staged ordering; warns when **`rule.get_script()`** is **`null`** or unregistered (**`debug_wire_bind_dispatch_count_for_tests`** wraps table size).
- **`UiReactReentryGuardByMeta`:** shared meta-dictionary lock for **`UiReactActionTargetHelper`** / **`UiReactFeedbackTargetHelper`** reentry guards (`scripts/internal/react/ui_react_reentry_guard_by_meta.gd`).
- **`UiReactTransactionalSession.register_host`:** **`screen`** typed **`UiTransactionalScreenConfig`** (**nullable**); **`begin_on_ready`** read via property (**no** `Resource.get`).
- **`UiReactBaseButtonReactive`:** **`_matching_export_rows`** delegates **`action_targets`** / **`audio_targets`** / **`haptic_targets`** / **`animation_targets`** reads (typed **`Array[T]`** fast paths preserved).
- **Controls exporting `wire_rules`:** **`UiReactLineEdit`**, **`UiReactOptionButton`**, **`UiReactTabContainer`**, **`UiReactCheckBox`**, **`UiReactItemList`**, **`UiReactTree`** reference **`UiReactHostWireTree`** via **`class_name`** only (**no** redundant **`preload`**).

### Fixed

- **`action_targets` / `state_watch`:** **`UiReactActionTargetHelper.teardown_for_control_exit`** runs before control state unbind on **`_exit_tree`** / **`NOTIFICATION_PREDELETE`**, so shared **`UiBoolState`** instances do not retain dangling **`value_changed`** connections to freed **`UiReact*`** hosts.
- **`NOTIFICATION_PREDELETE`:** **`UiReact*`** controls and **`UiReactButton`** / **`UiReactTextureButton`** mirror the same reactive teardown as **`_exit_tree`** (shared **`ui_react_control_exit_teardown.gd`**; buttons via **`UiReactBaseButtonReactive.on_predelete`**) so static coordinators unload reliably when **`_exit_tree`** ordering is surprising.
- **Reactive lifecycle:** **`UiReact*`** controls and **`UiReactBaseButtonReactive`** **`on_exit_tree`** now call **`UiReactControlStateWire.unbind_value_changed`** (and computed hooks) on **`Node._exit_tree`** before transactional / wiring teardown, so **`UiReactComputedService`** static registration cannot leak across **`queue_free`**, scene swaps, or GUT teardown.
- **`UiReactTransactionalValidator`:** duplicate **Apply** / **Cancel** per-group errors now label **`UiReactButton`** vs **`UiReactTextureButton`** from the offending node type (Pass **14** integration polish).

### Documentation

- **Audit remediation:** **[FEEDBACK_LAYER.md](FEEDBACK_LAYER.md)** §9 (execution semantics); **[ACTION_LAYER.md](ACTION_LAYER.md)** §5.1 feedback cross-reference; **[DECISIONS.md](DECISIONS.md)** (2026-05-01 — state-driven feedback gated sync + rising edge); addon **[README.md](../README.md)** Layout (**`examples/`** + **`docs/`** rows); **[README.md](README.md)** task routing (**`audio_targets`** / **`haptic_targets`** parity); **`UiReactAnimTargetHelper.connect_if_absent`** doc comment aligns with **`state_watch`** vs control-signal scope.
- **CB-061:** **`FEEDBACK_LAYER.md`** (normative **`audio_targets`** / **`haptic_targets`**); cross-links from **`ACTION_LAYER.md`**, **`WIRING_LAYER.md`**, **`docs/README.md`**, **`AGENTS.md`**; **ROADMAP** Inspector matrix **`audio_targets`** / **`haptic_targets`** columns; **README** examples (official scenes include **`inventory_screen_demo.tscn`** + **`shop_computed_demo.tscn`** feedback rows; **Examples at a glance** Feedback column).
- **`WIRING_LAYER.md`:** **`§7.1`** — reactive channels (**`value_changed`** vs **`Resource.changed`**) plus **`UiReactControlStateWire`** effective computed hook (**`UiReactComputedService.supports_computed_wiring`**); **`§7.2`** **`@export` typing vs Diagnostics** (**`UiState`** slots including **`UiTransactionalState`**); **`§7.3`** signal-channel summary; **`§3–§4`** **`run_apply_on_attach`** and attach/apply ordering.
- **Computed wiring lifetime** callout (**README**, **Computed state (P2)**): **`UiReactComputedService`** session-scoped tables; **`reset_internal_state_for_tests`** for harnesses only (**`scripts/internal/react/ui_react_computed_service.gd`** header).
- **`AGENTS.md`** — wiring rule binder registry row (**`_ensure_wire_dispatch_table`**, **`_bind_impl_*`** registration for new subclasses).
- **`docs/README.md`** task routing cites **`§7.1`** / **`§7.2`**; **`AGENTS.md`** maintainer cue for **`§7.1`**.
- **`UiReactBindingValidator`:** binding mismatch text links **`§7.1`**; **`value_state`** expected-type phrasing mentions **`UiTransactionalState`** **`matches_expected_binding_class`**; **`UiReactLabel`** / **`UiReactRichTextLabel`** script **`##`** recap allowed **`text_state`** resources.

### Added

- **CB-061 — Reactive feedback (`audio_targets` / `haptic_targets`):** **`UiReactAudioFeedbackTarget`** / **`UiReactHapticFeedbackTarget`** resources; **`UiReactFeedbackTargetHelper`** (validate, merge-after-animation triggers, **`state_watch`**, sync, **`run_audio_feedback`** / **`run_haptic_feedback`**, teardown); **`UiReactFeedbackValidator`** + computed/explain scans; wired on all **`ANIM_TRIGGERS_BY_COMPONENT`** hosts (**`UiReactBaseButtonReactive`** included). Official **`feedback_demo.tscn`** was added then removed (**[Unreleased]** **Changed**): demos live on **Use** / **Buy** in **`inventory_screen_demo.tscn`** / **`shop_computed_demo.tscn`**. Joypad rumble uses **`Input.start_joy_vibration`** over **`Input.get_connected_joypads()`** (**PackedInt64Array**).
- **Testing:** **`test_ui_react_feedback_target_helper`** / **`test_ui_react_feedback_validator`** (**CB-061**).
- **`UiReactWireRule.run_apply_on_attach`:** default **`true`**; when **`false`**, **`UiReactWireRuleHelper.attach`** binds triggers but skips the initial **`apply`** pass (**`WIRING_LAYER.md`** §3–§4).
- **Runtime + dock:** **`UiReactComputedService.sources_dependency_graph_has_cycle`**; **`ensure_wired`** **`push_error`** and skips registration when **`UiComputed*`** **`sources`** form a cycle; **`UiReactComputedValidator`** emits **ERROR** for the same (deduped by resource id).
- **Dock:** **`UiReactWiringValidator`** warns when two **enabled** rules on the same host both list the same **`out`** **`UiState`** (**`UiReactWireRuleIntrospection`**).
- **`UiReactProjectSettingsPanel`:** disconnects **`Button.pressed`** in **`_exit_tree`** for locally connected handlers.
- **`UiReactTree`:** structure signature matches **`tree_items_state`** payloads to skip **`clear()`** + rebuild when unchanged (selection sync / clamp / validation still run).
- **Testing:** **`test_ui_react_computed_service`** — **`supports_computed_wiring`**, **`bind_value_changed`** with **`use_computed_hook: false`** still wires **`UiComputed*`** dependencies; cycle detection, **`ensure_wired`** refusal, acyclic chain wiring; **`test_ui_react_dock_wire_details_validation.test_duplicate_wire_outputs_warns_when_two_rules_write_same_state`**.
- **Testing:** **`UiReactComputedService.debug_is_wired_for_tests`** (GUT-only aid).
- **Testing:** **`test_ui_react_action_target_helper.test_teardown_clears_state_watch_connections`** — **`teardown_for_control_exit`** drops **`state_watch`** **`value_changed`** subscriptions.
- **Testing:** **`test_ui_react_item_list_hot_path`** — icon path cache reuse and signature short-circuit (dict **`label`** vs **`text`** equivalent rows).
- **Testing:** **`test_ui_react_wire_rules.test_wire_dispatch_table_registered_for_all_shipped_rules`** — **`UiReactWireRuleHelper.debug_wire_bind_dispatch_count_for_tests`** == **6**.
- **Testing:** **`test_ui_react_control_lifecycle_computed`** — **`UiComputedBoolInvert`** rebound to a replacement **`UiReactCheckBox`** after the first instance is **`queue_free`**, guarding **`UiReactComputedService`** teardown on **`_exit_tree`**.
- **Editor dock — Selection RMB** **Wire → Stacks** submenu inserts curated multi-rule recipes (**Inventory detail**, **Filter, sort, detail**, **Catalog list**) as a **single undo** step ([`UiReactWireRuleStackCatalog`](../editor_plugin/services/ui_react_wire_rule_stack_catalog.gd), [`append_stack_from_catalog_index`](../editor_plugin/dock/ui_react_dock_wire_rules_section.gd) on `UiReactDockWireRulesSection`). **No** new exports; rules ship with empty state slots so existing **§8** diagnostics guide completion (**`CB-063`**).
- **Editor plugin — plugin-only settings surface:** removed user-facing Ui React Project Settings tab exposure (dock shortcut capture UI was added later and **removed** — see **Changed** in **[Unreleased]**).
- **Editor plugin — dual action shortcuts:** two internal Project Settings keys (`open_diagnostics_json`, `open_wiring_json`) with defaults **Alt+1** / **Alt+2**; both open/select the Ui React bottom panel when needed (no editor restart).
- **Editor plugin — bottom dock tab tooltip:** single-line custom tooltip (`shortcut_in_tooltip = false`), default copy **`Toggle Ui React Bottom Panel (Alt+1, Alt+2)`**, built from the same parsed shortcuts as runtime dispatch (with **` (Physical)`** stripped when the engine adds it).
- **Editor dock — Dependency Graph / Wiring (`CB-058`, shallow quick edit):** under the **`wire_rules`** list, **Quick edit (selected rule)** for **`rule_id`** (Apply) and allowlisted **`@export`** strings/bools on **`UiReactWireCopySelectionDetail`** and **`UiReactWireSetStringOnBoolPulse`** (Apply for strings; checkboxes commit on toggle); commits use **`UiReactWireGraphEditService.try_commit_wire_rule_id`** / **`try_commit_wire_rule_shallow_export`** and the same **`duplicate(false)`** path as other dock rule edits. **Inspector** remains full parity for all fields.
- **Editor dock — Wiring (`CB-058`, Milestone 2 payload depth):** shallow quick-edit is now **descriptor-driven** (`UiReactWireGraphEditService.try_commit_wire_rule_shallow_field`) and reused by the embedded wire list/editor surfaces; new in-tab fields include **`line_prefix`** (`UiReactWireSyncBoolStateDebugLine`) and **`first_row_icon_path`** (`UiReactWireRefreshItemsFromCatalog`) in addition to prior CopySelectionDetail / BoolPulse fields. Wire-edge details now list available quick-edit fields for the selected rule.
- **Editor dock — Wiring / factory + scope polish (`CB-058`, Milestone 2 ergonomics):** create-state save defaults now use deterministic class-aware suggested paths (`UiReactGraphResourceFactory.suggest_state_save_path`) and assign-mode dialog titles include host/property context; scope preset pickers now use sorted helper loading (`UiReactDockExplainScopePresets.load_sorted_presets_raw`) for stable lifecycle UX in dropdown/menu/manage surfaces.
- **Controls:** `UiReactHostWireTree` (`scripts/internal/react/ui_react_host_wire_tree.gd`) centralizes `UiReactWireRuleHelper.schedule_attach` / `detach` for `wire_rules` hosts; named `WIRE_TRIGGER_*` storage codes on `UiReactWireRule` document stable on-disk trigger integers (see `WIRING_LAYER.md` §5).
- **Testing / tooling:** `UiReactComputedService.reset_internal_state_for_tests()` clears all static wiring tables and listeners (GUT isolation).
- **Scanner:** `UiReactScannerService.get_component_name_from_script` resolves **`class_name`** first when it matches `UiReactComponentRegistry.BINDINGS_BY_COMPONENT`, then falls back to the existing script-stem path heuristic.
- **Controls:** `UiReactControlStateWire` centralizes `value_changed` + optional `UiReactComputedService` hook_bind/unbind; `UiReactBaseButtonReactive` shares `UiReactButton` / `UiReactTextureButton` wiring, animations, actions, and transactional host registration.
- **Editor dock:** `UiReactDockExplainScopePresets` holds pure helpers for scope preset JSON lookup; dependency graph panel drops unused idle/focus stubs and tightens wire-host edge index handling.
- **Animation:** expanded `UiAnimConstants` (pulse/shake/rotate/stagger/reset defaults, etc.) so `UiAnimUtils` and animation modules share one source of truth.
- **Editor dock — Diagnostics / Wiring session**: **ProjectSettings** persist **last dock tab** (`ui_react/plugin_dock_last_tab`), **Wiring restore** scene path + scope node path + optional graph node id (`ui_react/plugin_wiring_last_*`); leaving **Wiring** captures session, returning to **Wiring** or switching edited scenes (while on **Wiring**) restores editor selection + graph when keys match the current scene. **Diagnostics** tab title shows **filtered visible issue count** (e.g. `Diagnostics (12)`). See [`UiReactDockConfig`](../editor_plugin/dock/ui_react_dock_config.gd), [`UiReactDock`](../editor_plugin/dock/ui_react_dock.gd), [`UiReactDockExplainPanel`](../editor_plugin/dock/ui_react_dock_explain_panel.gd).
- **Editor dock — Dependency Graph**: **double-click** a node or edge to open the same **Inspector** target as **Focus in Inspector** (control host, `.tres` state/computed, or edge edit host); [`UiReactExplainGraphView`](../editor_plugin/dock/ui_react_explain_graph_view.gd) **`inspector_focus_selection_requested`** → [`UiReactDockExplainPanel`](../editor_plugin/dock/ui_react_dock_explain_panel.gd).
- **Editor dock — Wiring / Dependency Graph — Track 3 factories & scope** (**no new `UiReact*` `@export`**): **Create** menu saves new **`UiBoolState` / `UiIntState` / `UiFloatState` / `UiStringState` / `UiArrayState`** `.tres` via **`EditorFileDialog`** (SAVE), **`UiReactGraphResourceFactory`** + **`UiReactStateFactoryService`**, then **`EditorFileSystem.scan()`**; optional **Create & assign…** (under **Actions…** / canvas context menu) for a selected **optional empty** **BINDING** edge (**`UiReactGraphNewBindingService.try_commit_assign`**). **Named scope presets** (layout caps, edge filters, **Full lists**, **pinned** snapshot node ids) persist in **ProjectSettings** (**`UiReactDockConfig.KEY_GRAPH_SCOPE_PRESETS`** / **`KEY_GRAPH_ACTIVE_SCOPE_PRESET`**); **Default** keeps prior session-style behavior until a preset is chosen; **`UiReactExplainGraphLayout.layout_snapshot`** accepts **`extra_scope_ids`** for pins.
- **Editor dock — Wiring workbench**: **Wiring** tab merges **Dependency Graph** and **`wire_rules`** list (**`UiReactDockWiringPanel`**); **WIRE_FLOW** details — **enabled** and **trigger** (**`UiReactWireGraphEditService.try_commit_wire_rule_enabled`** / **`try_commit_wire_rule_trigger`**); selecting a wire edge on the **focus** host highlights the rule row (**`focus_rule_index`**).
- **Editor dock — Dependency Graph (**`CB-058`**, follow-on)**: **Clear wire link** (both IO exports on a **WIRE_FLOW** edge, **Delete** included); details **rule_id** row; **Move source up/down** and **Remove source slot** for **COMPUTED_SOURCE** (**`UiReactComputedGraphRebind.try_commit_swap_sources`** / **`try_commit_remove_source_at`**); **canvas new link** — **UI_STATE** donor to a **control** with **`wire_rules`** can append a rule (**`UiReactWireGraphEditService`**, **`UiReactWireRuleCatalog`**) or pick binding vs wire when both apply; **file-backed** **UI_COMPUTED** targets resolve via **`UiReactComputedResourceMounts`** (multi-mount **`PopupMenu`**; optional **make unique** when the mount uses a **`.tres`** path before append). Shared catalog: **`UiReactWireRuleCatalog`** (Wire rules **Add** menu uses the same list).
- **Editor dock — Dependency Graph (**`CB-058`**, slice **1** disconnect)**: **Clear optional binding** and **Remove computed dependency** on selected **BINDING** / **COMPUTED_SOURCE** edges (registry **optional** gate for bindings; **`sources[i] = null`** for computeds via **`UiReactComputedGraphRebind.try_commit_clear_source`**); **Delete** / **Backspace** on the graph when an edge is selected runs the same policy as the buttons; undo via **`UiReactActionController`**. **WIRE_FLOW** disconnect shipped in follow-on above.
- **Editor dock — Dependency Graph (**`CB-058`**, phase **2b**)**: **Canvas new link** — with **no** edge selected, **Ctrl+Shift+drag** from a **state** or **computed** donor to a **control** (assigns a compatible **empty** registry binding via **`UiReactGraphNewBindingService`**) or to an **embedded** **computed** node (fill first **`sources[]`** gap or **append** up to runtime cap via **`UiReactComputedGraphRebind.try_commit_append_or_fill_source`**). Dashed rubber-band and distinct valid-target outline vs reconnect; multiple empty binding slots open a **`PopupMenu`**. **Wire-rule** greenfield and **file-backed** computed targets on canvas: see follow-on entry above.
- **Editor dock — Dependency Graph (**`CB-058`**, step 2)**: **Canvas reconnect** — with an edge selected, **Shift+drag** from the **source** endpoint node (binding / computed upstream / wire **input** or **output** node) onto another **state** or **computed** graph node; commits match **Rebind…** buttons (**`UiReactActionController`**, **`UiReactComputedGraphRebind`**). Valid targets highlight during drag; **Esc** cancels. Resolver: **`UiReactGraphNodeStateResolver`**. **New wire-flow** rows on canvas remain out of scope (use **Wire rules** tab); binding / embedded-computed greenfield: phase **2b** above.
- **Editor dock — Dependency Graph (**`CB-058`**, slice 3)**: **Rebind computed source…** on **computed-source** edges — **`COMPUTED_SOURCE`** edge meta **`computed_context`** (disambiguates nested computeds); builder uses **`wire[i].property`** and **`tab_config.content[i]`** contexts; undo-safe **`sources[]`** replace via **`UiReactComputedGraphRebind`** and **`UiReactActionController`**; dock refresh **`dependency_graph_edit`**. Edges from an older snapshot without **`computed_context`** stay disabled until **Refresh**.
- **Editor dock — Dependency Graph (**`CB-058`**, slice 2)**: **Rebind wire input…** / **Rebind wire output…** on **wire-flow** edges — edge meta **`wire_in_property` / `wire_out_property`** from **`UiReactExplainGraphBuilder`**; **`UiReactWireRuleIntrospection.list_io`** now includes **`property`** per slot; undo-safe **`wire_rules`** commit via **`Resource.duplicate(false)`** rule row (distinct rule instance; preserves nested **`UiState`** references for the graph). Dock co-refresh uses reason **`dependency_graph_edit`**.
- **Editor dock — Dependency Graph (**`CB-058`**, slice 1)**: **Rebind to resource…** on a selected **binding** edge — undo-safe assignment via **`UiReactActionController`**, file picker for a **`UiState`** `.tres`, and co-refresh of dock **Diagnostics**. Computed-source reconnect deferred.
- **Editor dock — Dependency Graph tab (**`CB-018A.3`**)**: tab renamed from **Explain**; **Refresh** button + **debounced auto-refresh** on scene selection change; **legend** for node/edge colors; graph footer **Nodes / Edges / truncated** (no raw spacing debug); **rounded** node corners + **centered** labels; redesigned **details** copy (**select** wording); **Focus in Inspector** (control, `.tres` state/computed, binding host, wire host, computed target) with additive **edge provenance** metadata from **`UiReactExplainGraphBuilder`**; **Copy details** button. Declarative / read-only; **Text** mode unchanged in substance.
- **Editor dock — Explain tab — Visual readability pass (**`CB-018A.2`**)**: **orthogonal (Manhattan)** edge routing with per-band **lanes** and **arrowheads** on the final segment; **short** node/edge tokens on-canvas with **full** labels/ids in the **bottom** details pane (diagnostics-style); **adaptive** spacing; darker **framed** graph viewport; **filters** for binding/computed/wire edges and optional **all edge labels**; **breadcrumb** line; **hover/selection** dimming of unrelated edges; progressive edge labels (hover/selection, or toggle). Declarative / read-only; **Text** mode unchanged.
- **Editor dock — Explain tab — Visual mode (**`CB-018A.1`**)**: read-only **scoped** node graph (focus + upstream/downstream) with **pan**, **zoom** (wheel), **Fit view**, and a **details** pane for selected node/edge; deterministic layout via **`UiReactExplainGraphLayout`**; rendering via **`UiReactExplainGraphView`**. **Text** mode preserves the full BBCode report. Truncation when node/edge caps hit.
- **Editor dock — Explain tab (**`CB-018A`**)**: declarative dependency snapshot for a selected **`UiReact*`** node — registry **bindings**, **`wire_rules`** in/out flow (via **`UiReactWireRuleIntrospection`**), **`UiComputed*`** **`sources`**, and capped **static cycle candidates** (**`UiReactExplainGraphBuilder`**, **`UiReactExplainGraphSnapshot`**). Not a runtime causality trace.
- **`UiAnimTarget.ResetBehavior`**: **`RESET_VISUAL_ONLY`** (restore unified snapshot only) vs **`RESET_AND_STOP`** (call **`UiAnimUtils.stop_all_animations`** on the target, then restore).
- **`UiAnimUtils.animate_reset_all`**: optional **`stop_before_reset`** — when **true**, runs **`stop_all_animations`** first, then **`UiAnimStateUtils.animate_reset_all`**.

### Fixed

- **Documentation — release readiness:** [`docs/RELEASE_READINESS_PASSES.md`](../../../docs/RELEASE_READINESS_PASSES.md) Pass **11** ledger marked **done** (four **`examples/*.tscn`**, public scripts + **`ui_resources`** only where cited, **`project.godot`** main scene; **P3** README glance table vs **`anim_targets_catalog_demo`** **`action_targets`** — doc tweak for Pass **12**).
- **Documentation — release readiness:** [`docs/RELEASE_READINESS_PASSES.md`](../../../docs/RELEASE_READINESS_PASSES.md) Pass **10** ledger row refined post-removal: **`UiReactEditorBottomPanelShortcut`** + `editor_plugin/settings/**` (only unused **`UiReactProjectSettingsPanel`**); deleted **`UiReactDockSettingsPopup`** and Diagnostics **Settings** button; migration-only GUT in **`test_ui_react_settings_config_migration.gd`**.
- **Documentation — release readiness:** [`docs/RELEASE_READINESS_PASSES.md`](../../../docs/RELEASE_READINESS_PASSES.md) Pass **9a–9c** ledger marked **done** (dock/controllers/models + explain/graph + wire graph edit + scope presets + value preview + unused-state + `ui_react_computed_*` services; **`UiReactDock`** ↔ **`UiReactValidatorService`** integration spot-check; optional P3 computed-kind graph parity — no code changes required from audit).
- **Documentation — release readiness:** [`docs/RELEASE_READINESS_PASSES.md`](../../../docs/RELEASE_READINESS_PASSES.md) Pass **8** ledger marked **done** (validator services + wire introspection/catalog; registry trigger parity; optional P3 computed-class coverage note — no code changes required from audit).
- **Documentation — release readiness:** [`docs/RELEASE_READINESS_PASSES.md`](../../../docs/RELEASE_READINESS_PASSES.md) Pass **7** ledger marked **done** (`editor_plugin` spine + `UiReactComponentRegistry` + scanner/factories/`UiReactSceneFileResourcePaths`; registry vs README animations spot-check; optional P3 DRY notes only — no code changes required from audit).
- **Documentation — release readiness:** [`docs/RELEASE_READINESS_PASSES.md`](../../../docs/RELEASE_READINESS_PASSES.md) Pass **6** ledger marked **done** (`ui_tab_*.gd`, **`UiTabContainerCfg`**; tab helper vs control seam cites README; optional P3 notes only — no code changes required from audit).
- **Documentation — release readiness:** [`docs/RELEASE_READINESS_PASSES.md`](../../../docs/RELEASE_READINESS_PASSES.md) Pass **5** ledger marked **done** (`ui_react_wire_*`, wire models, **`UiReactActionTarget`**; **`WIRING_LAYER`** + inventory demo coverage; optional P3 polish notes only — no code changes required from audit).
- **Documentation — release readiness:** [`docs/RELEASE_READINESS_PASSES.md`](../../../docs/RELEASE_READINESS_PASSES.md) Pass **4** ledger marked **done** (`internal/anim/**`, `UiReactAnimTargetHelper`, `UiTabTransitionAnimator`; refcount/snapshot/teardown audit; optional P3 docs-only notes — no code changes required from audit).
- **Documentation — release readiness:** [`docs/RELEASE_READINESS_PASSES.md`](../../../docs/RELEASE_READINESS_PASSES.md) Pass **1** ledger marked **done** (`scripts/api/models/**`, `scripts/api/ui_anim_utils.gd` surface audit; carries optional P3 tooltip-ordering notes — no blocking doc/code changes required from audit).
- **Documentation — release readiness:** [`docs/RELEASE_READINESS_PASSES.md`](../../../docs/RELEASE_READINESS_PASSES.md) Pass **3** ledger marked **done** (`scripts/internal/react/**` minus tab + `ui_react_anim_target_helper`; static wiring tables audit; optional P3 polish notes only — no code changes).
- **Documentation — release readiness:** [`docs/RELEASE_READINESS_PASSES.md`](../../../docs/RELEASE_READINESS_PASSES.md) Pass **2** ledger marked **done** (`scripts/controls/**` vs **CB-052** matrix + shared helpers audit; optional P3: expand README **Bindings** column for **`animation_targets`/`wire_rules`** on §5 hosts — Pass **12**).
- **Documentation — README Quickstart:** **Examples at a glance** — **`options_transactional_demo.tscn`** **Wiring** column is **yes**, matching the Quickstart bullet (`wire_rules` + `action_targets`). **Dependency Graph** sentence now says **orthogonal (Manhattan)** edges (same phrasing as **CB-018A.2** / **`GRAPH_DEBUG_SURFACES.md`**).
- **Documentation — `ACTION_LAYER.md`:** §2 layer table link to **`UiReactStateOpService`** corrected to **`../scripts/internal/react/ui_react_state_op_service.gd`** (path from `docs/`).
- **Documentation — release readiness:** repo [`docs/RELEASE_READINESS_PASSES.md`](../../../docs/RELEASE_READINESS_PASSES.md) Pass **0** completion ledger marked **done** (findings addressed in-repo).
- **Editor dock — Dependency Graph (copy, `CB-058`):** Clarify **Shift+drag reconnect** for **`COMPUTED_SOURCE`** / **`sources[]`** (global graph help, edge details **On canvas**, and edge-edit tooltips) so it matches binding and wire behavior; no change to commit logic. **Historical note:** the **CB-058** slice-1 changelog phrase “Computed-source reconnect deferred” referred to shipping **menu** **Rebind computed source…** after binding-only file rebind—not **canvas** reconnect, which **slice 2** already documented.
- **Actions:** `UiReactActionTargetHelper._with_reentry_guard` clears its per-owner lock immediately after `fn.call()` (linear unlock). GDScript in **Godot 4.5.1** does not parse `try`/`finally` here, so that pattern was removed to restore compilation; upgrade paths that ship `try`/`except`/`finally` could revisit a `finally`-style unlock if needed.
- **Editor dock — Dependency Graph — Scope / presets menus**: canvas and graph **`PopupMenu`** submenus now use **`add_submenu_node_item`** (Godot 4.5 deprecates name-based **`add_submenu_item`**), so **Scope → Presets / Save as… / Manage / Pin** and sibling submenus receive **`id_pressed`** reliably. **Presets** is a nested submenu (**Default** + user presets); **Pin node** appears only when a pin target exists (node selection, or edge anchor aligned with **Focus in Inspector**).
- **Editor dock — Dependency Graph / wire rules**: toggling **`UiReactWireRule.enabled`** (and other undo-safe row edits via **`UiReactWireGraphEditService.try_mutate_wire_rule_at_index`**) no longer **deep-duplicates** nested **`UiState`** references, so embedded state ids stay aligned with the graph snapshot and **`WIRE_FLOW`** edges remain in layout scope — the dock **wire rules** list no longer clears when a selected wire edge refreshes. **`WIRE_FLOW`** edges carry **`wire_rule_enabled`** metadata; disabled rules draw **muted** wire strokes in **`UiReactExplainGraphView`** and the edge **details** pane notes the rule is paused.

### Changed

- **Editor dock — Selection RMB → Wire** submenu reorganized: per-rule `Add wire: <Type>` entries moved into a nested **Add rule…** submenu, sibling to **Stacks**; **Refresh wire list** and **Copy rule details** sit below a separator. No row-id changes; existing handler dispatch unchanged. ([`UiReactDockExplainPanel._fill_selection_wire_submenu`](../editor_plugin/dock/ui_react_dock_explain_panel.gd))
- **Editor copy:** Diagnostics validators, wire rule details, Dependency Graph help, menus/tooltips, and dock warnings use solo-designer plain language; see [`EDITOR_COPY.md`](EDITOR_COPY.md).
- **Editor dock — Selected wire rule details:** removed the inline **Checks** row from [`UiReactDockWireDetails`](../editor_plugin/dock/ui_react_dock_wire_details.gd). Wiring issue display and resolution are now Diagnostics-only; wire details stay descriptive (intent/runtime/inputs/outputs).
- **Validator parity (`CB-058`):** wiring validation now includes quick-edit-aligned checks for oversized shallow text fields (`text_no_selection`, `template_rising`, `template_no_selection`, `line_prefix`, `first_row_icon_path`) and warns when `first_row_icon_path` is not `res://`-scoped.
- **Editor dock — Dependency Graph layout (pinned-only islands)**: `UiReactExplainGraphLayout.layout_snapshot` now partitions scoped nodes by weakly connected component and renders only the **focus component** plus disconnected components that contain at least one **pinned** node id. Each pinned component is laid out as its own island and packed to the right of focus with bounded spacing, so cross-focus pins no longer drive off-canvas placement. Orphan `-512` placement is removed from x-positioning, and `node_layer` now reports focus-component layering only.
- **Manual QA checklist for this change**: (1) pin on A then focus B with no shared path shows two readable islands; (2) pin on A then focus B with shared connectivity remains one cohesive graph; (3) no pins behaves like prior focus-scoped layout; (4) caps (`max_nodes` / `max_edges`) still mark `truncated` and keep the graph interactive.
- **Editor dock — Dependency Graph — scope presets**: named presets may store an optional **`about`** description (author in **Save scope preset as…**); preset rows show it as a **tooltip**; **Manage scope presets** lists tooltips per row. With a **named** preset active, **Update "&lt;name&gt;"** overwrites that preset from current caps/filters/pins/**about** (disabled when nothing would change). **Pin node** moved under **Scope** on graph RMB (removed duplicate root/Node entries).
- **Editor dock — Wire rules & Diagnostics rows**: clicking the **wire rule** summary row opens that **`UiReactWireRule`** in the **Inspector**; clicking a **Diagnostics** issue row focuses the referenced **scene node** when **`node_path`** is set. Per-row **Focus** buttons were removed as redundant. Graph-driven wire list sync (**`focus_rule_index`**) still updates selection only and does not open the Inspector.
- **Editor dock — Wiring / Dependency Graph information hierarchy**: under the graph, the workbench now flows **Wire rules list → Details** (single narrative surface); the embedded wire-rule report pane and verbose host banner in **`UiReactDockWireRulesSection`** were removed to cut redundancy. Wire rows now expose inline controls for **enabled**, **trigger**, **order** (**spinner**, runtime-order aware), **Duplicate**, and **Delete**; right-click remains as secondary access for copy/inspect actions. Rule narrative remains canonical via **`UiReactDockWireDetails`** and is rendered in the main details pane.
- **Documentation — menu IA governance**: added **[`MENU_GUIDELINES.md`](MENU_GUIDELINES.md)** as the normative reference for menu surface taxonomy, scope ownership, stable group order, submenu threshold policy (`0/1/2+`), canonical-home guidance, verb glossary, and menu rollout checklist for future PRs.
- **Editor dock — menu IA alignment rollout**: standardized menu wording/order across context and chooser surfaces in the wiring workbench — selection RMB applies single-item submenu flattening for sparse groups, wire row RMB groups actions by intent (create/modify/remove/copy/inspect), new-link chooser labels use consistent **Create ...** phrasing, and selector tooltips in Diagnostics/Wiring explicitly identify mode/group/trigger/scope selector roles (**`UiReactDockExplainPanel`**, **`UiReactDockWireRulesSection`**, **`UiReactDock`**).
- **Editor dock — Dependency Graph RMB IA**: canvas right-click now keeps **Refresh** and **Fit view** at root, with grouped **Create** / **View** / **Scope** submenus to reduce vertical menu load; node context menu now includes **Pin node** directly; and selected control nodes expose explicit **Create state & bind…** actions (class-mismatch entries disabled with expected-class tooltip) while canvas **New `Ui*State`…** remains create-only (no implicit bind) (**[`UiReactDockExplainPanel`](../editor_plugin/dock/ui_react_dock_explain_panel.gd)**).
- **Editor dock — Dependency Graph selection RMB IA**: node/edge context right-click now keeps high-frequency root actions (**Focus in Inspector**, **Copy details**) and groups the rest into **Node**, **Wire**, and **Edge edit** submenus; wire catalog add/refresh/report actions and edge rebind/clear/source-slot/create-assign actions keep their existing gates, disabled states, and commit behavior (**[`UiReactDockExplainPanel`](../editor_plugin/dock/ui_react_dock_explain_panel.gd)**).
- **Editor dock — Dependency Graph — computed-source details**: **Computed source** edge summary is a single **run-in** line (like **Property binding**) with **`sources[n]`** as the slot phrase; **endpoint labels** use `_edge_endpoint_pair_for_summary_bb_plain` / `_endpoint_discriminating_plain` when short labels collide; **Where to edit** uses **Inspector**-aligned wording and the shared missing-control-path blurb when **host_path** is empty; **Computed owner** names the computed endpoint and slot, with **`computed_context`** on a separate **Resolver path** line (**[`UiReactDockExplainPanel`](../editor_plugin/dock/ui_react_dock_explain_panel.gd)**).
- **Editor dock — Dependency Graph details formatting**: unified **run-in** vs **block** section helpers (`_details_run_in_bb_plain`, `_details_block_head_bb_plain`) so node and edge copy follow the same patterns (single-line `Title — …` vs title line + following bullets/lines); **Upstream** / **Downstream** / **Cycle candidates** / generic **Edge** / **Relation to focus** / **On canvas** headlines and **Computed source** / **Wire flow** summaries aligned (**[`UiReactDockExplainPanel`](../editor_plugin/dock/ui_react_dock_explain_panel.gd)**).
- **Editor dock — Dependency Graph details layout**: one blank line between **major** sections (**Focus** / **Connections** / **Wire rules** / **Graph context** / **On canvas** / **Incident edges** / **Relative to layout** / **Technical**, and edge summary / **Other edges at this anchor** / graph / **Technical**) via `_details_append_major`; final newline pass collapses only **three or more** consecutive breaks (`_normalize_details_newlines`) so intentional `\n\n` is kept.
- **Editor dock — Dependency Graph edge details**: **Graph context** applies **display-only** suppression of the selected edge’s opposite endpoint in human **Upstream** / **Downstream** lists (full ids unchanged for canvas mismatch); **edge** selection uses clearer empty-upstream copy for state/computed anchors; summary uses **Actions** instead of **Graph** for dock buttons and omits redundant **Endpoints** for bind / computed / wire edges (**[`UiReactDockExplainPanel`](../editor_plugin/dock/ui_react_dock_explain_panel.gd)**, **`UiReactExplainGraphBuilder.compute_narrative`**).
- **Editor dock — Dependency Graph details copy**: **Upstream** / **Downstream** headings use parallel **in this snapshot — …** glosses by anchor kind (**control** vs **resource**); **node** details add the same **Graph context** heading as **edge** details; empty **Upstream** lines share a single state/computed wording; **control**-first phrasing for Inspector / wire **Where to edit**; **computed-source** and **wire-flow** summaries align with **States / computed** grouping (**[`UiReactDockExplainPanel`](../editor_plugin/dock/ui_react_dock_explain_panel.gd)**).
- **Editor dock — Dependency Graph edge details (trim)**: removed redundant **Selected edge** / **Actions** prose; **compact** bind / computed / wire headings; **Where to edit** for bindings only when the snapshot path does not resolve to a **Control** in the edited scene (or path missing); optional bindings use a **single** italic dock hint; **Rule exports** parenthetical points at the dock action row; **Other edges at this anchor** list (**[`UiReactDockExplainPanel`](../editor_plugin/dock/ui_react_dock_explain_panel.gd)**).
- **Editor dock — Dependency Graph details (consistency)**: **Graph context** / **Upstream** / **Downstream** spacing unified (no stray blank line after section titles); **edge** details order matches **node** — **Cycle candidates** → **Canvas note** → declarative footer; **wire** **Where to edit** plain text when **wire_host_path** is missing; shared missing-control-path blurb for bind/wire; **details** / **Copy details** collapse consecutive newlines to a single break (**[`UiReactDockExplainPanel`](../editor_plugin/dock/ui_react_dock_explain_panel.gd)**).
- **Editor dock — Dependency Graph control narrative**: **Focus control** — **Name** + **Type** (registry component name like the Scene tree tooltip, then script **global** name, else `Node.get_class()`); **Technical** omits **Short label**; scene path only under **Technical** (**[`UiReactExplainGraphBuilder`](../editor_plugin/services/ui_react_explain_graph_builder.gd)**, **`UiReactDockExplainPanel`**).
- **Editor dock — Dependency Graph legend**: **Nodes** / **Edges** group labels, **responsive** single- vs two-row layout (width threshold), **line-style** edge samples, **focus** chip border aligned with graph palette, per-item **tooltips**, muted group **typography**; node/edge **colors** shared via **`UiReactExplainGraphView`** **`GRAPH_*`** constants (**[`UiReactDockExplainPanel`](../editor_plugin/dock/ui_react_dock_explain_panel.gd)**).
- **Editor dock — Dependency Graph details pane**: restructured **node** and **edge** reports — **Connections** (registry binding slots with bound/unbound + merged binding/incident lines for **control** hosts), **Wire rules** one-line summaries from the live host, **Upstream** / **Downstream** use **human-only** labels (no `state:` / `ctrl:` ids), **seed** states and **self** control are suppressed from **Downstream** for control anchors, **Incident edges** removed for controls (covered under Connections), **On canvas** / **Relative to layout center** tautology trimmed when the selection is the **layout focus** control; **Graph context** on edges shares the same reachability helper; **Technical** ids stay in the footer (**[`UiReactExplainGraphNarrative`](../editor_plugin/models/ui_react_explain_graph_narrative.gd)**, **`UiReactExplainGraphBuilder.compute_narrative`**, **`UiReactGraphNewBindingService.list_registry_binding_rows`**, **`UiReactDockExplainPanel`**).
- **Editor dock — Dependency Graph**: canvas **tooltip** removed; **pan / zoom / RMB / gestures / node shapes** copy lives in the **details** pane when **no graph selection** (and when the graph layout is empty), with the existing select-or-refresh prompts (**[`UiReactDockExplainPanel`](../editor_plugin/dock/ui_react_dock_explain_panel.gd)**).
- **Editor dock — Dependency Graph node shapes**: **role** (control / state / computed) is encoded by **corner radius** on nodes and legend chips in addition to color; same **hit box** and layout (**[`UiReactExplainGraphLayout.fill_corner_radius_px`](../editor_plugin/services/ui_react_explain_graph_layout.gd)**, **[`UiReactExplainGraphView`](../editor_plugin/dock/ui_react_explain_graph_view.gd)**, **[`UiReactDockExplainPanel`](../editor_plugin/dock/ui_react_dock_explain_panel.gd)** legend).
- **Editor dock — tooltips**: shorter, consistent copy across **Diagnostics**, **Dependency Graph** / **Wiring** docks (**`UiReactDock`**, **`UiReactDockIssueList`**, **`UiReactDockExplainPanel`**, **`UiReactDockWireRulesSection`**); graph canvas hint condensed to two lines; removed redundant scroll tooltip; doc refs use **`WIRING_LAYER.md`** without section symbols.
- **Editor dock — Dependency Graph UX**: **Upstream** narrative heading matches anchor kind (state/computed vs control); **edge** details lead with the selected-edge summary, then a **Graph context** block; details **RichTextLabel** uses editor theme sizing (no mixed inline font sizes); **resizable** graph vs details/wire column (**`VSplitContainer`**, offset persisted in **`UiReactDockConfig.KEY_GRAPH_BODY_VSPLIT_OFFSET`**); **legend** on by default with **`KEY_GRAPH_LEGEND_VISIBLE`** persistence; **Pin node** on **Default** scope opens **Save scope preset** to create a named preset and append the pin (**`UiReactDockExplainPanel`**).
- **Editor dock — Dependency Graph details narrative**: trims repeated declarative-scope disclaimers (single footer line in the narrative block); **Upstream** is omitted when it only repeats direct binding sources; **Downstream** is grouped under **States / computed** vs **Controls**; the **Cycle candidates** section is hidden when there are no matching rows; node details order puts **Incident edges** before **Relative to layout center**.
- **Editor dock — Wiring / Dependency Graph — chrome**: the Dependency Graph dock no longer shows persistent **Refresh** / **Fit** / **Create** / **scope** / **filter** / **legend** rows; **right-click empty canvas** opens a consolidated **View** `PopupMenu` (**Refresh**, **Fit**, **Create state…**, toggles, **Default** + named **scope presets**, **Save as…** / **Manage…** / **Pin node**) via **`canvas_view_menu_requested`**, **without** clearing the current graph selection. **Right-click** on a **node** or **edge** runs **`_pick`** and opens the **context** `PopupMenu` (**`context_menu_requested`**) with **Focus**, **wire rules**, rebind/clear/copy, etc. Preset **`OptionButton`** and filter checkboxes stay in the scene tree under a hidden host for **DRY** preset/sync logic.
- **Editor dock — RMB-first wire workbench**: **Wiring** tab is a single column (no **`wire_rules`** **HSplit**); **`UiReactDockWireRulesSection`** under graph details tracks the **graph-selected** `wire_rules` host (falls back to **Scene** selection); **Focus**, **Add wire** (catalog), **Refresh wire list**, and **Copy rule report** live on the node/edge context menu; each rule row’s **right-click** menu handles reorder, duplicate, remove, copy report, and **Inspect**; **canvas new-link** wire choices are filtered by donor vs first **in** export type (**`UiReactWireGraphEditService.filter_rule_template_indices_for_donor`**), with a dialog when none match. **`UiReactDockWireRulesPanel`** removed in favor of **`UiReactDockWireRulesSection`**.
- **Documentation — North star (**`CB-058`**)**: **ROADMAP** Part I **North star** (Dependency Graph as **blessed** designer wiring workbench; Inspector full parity); **Visual wiring graph** milestones updated; **Appendix CB-058** row; **README** four pillars + designer path + plugin graph copy; **WIRING_LAYER** / **ACTION_LAYER** editor callouts; **DECISIONS** ADR **2026-04-09**; **docs/README** routing row.
- **Editor dock — Dependency Graph graph-only narrative (**`CB-018A.5`**)**: **Text** mode removed; **details** pane shows the former **Text** report (**bound / upstream / downstream / cycles**) for the **narrative anchor** (selected node, or **`from_id`** on edge selection with **`to_id`** fallback), via **`UiReactExplainGraphBuilder.compute_narrative`** and **`UiReactExplainGraphNarrative`**. Snapshot **`upstream_ids` / `downstream_ids`** remain **layout scope** for the refresh host only; **canvas note** when narrative ids are missing from the drawn graph or layout is **truncated**; **Full lists** checkbox uncaps narrative line lists; graph **auto-selects** the host after **Refresh**; **`UiReactExplainGraphView.select_node_by_id`**. **Breaking:** no separate Text tab; users rely on the graph + details pane only.
- **Editor dock — Dependency Graph details pane (**`CB-018A.4`**)**: task-oriented copy for selected nodes and edges — **focus-relative** placement via layout **`node_layer`**, capped **incident** edge lines, **cycle** hints from the snapshot, and **technical** ids moved to the end; edge details lead with a plain-English **kind** sentence, **where to edit**, and a **focus-touch** note when applicable. Layout output adds **`node_layer`** (`String` id → int layer index); graph view unchanged. *(Superseded for “full narrative” flow by **CB-018A.5**.)*
- **`UiReactStateReferenceCollector`**: **`wire_rules`** state paths go through **`UiReactWireRuleIntrospection.list_io`** (**DRY** with Dependency Graph builder).
- **`UiReactAnimValidator`**: no longer warns about unsupported **`UiAnimTarget.trigger`** on **`UiReactItemList`** / **`UiReactTree`** when **`selection_slot` ≥ 0** (row-play presets; trigger is not used for host dispatch).
- **Lead-in preamble reset** (when **`reset_duration` ≥ 0**): internal copy always uses **`RESET_AND_STOP`**.
- **`anim_targets_catalog_demo.tscn`**: removed standalone **`RESET`** catalog row; reset affordance is **`Reset Preview`** only; help text updated.

## [3.0.0] - 2026-04-07

### Breaking

- **`UiReactButton`** / **`UiReactTextureButton`:** removed **`transactional_group`**, **`transactional_screen`**, **`transactional_role`**, **`press_writes_float_state`**, and **`press_writes_float_value`**. Use **`transactional_host`** ([**`UiReactTransactionalHostBinding`**](../scripts/api/models/ui_react_transactional_host_binding.gd)) and literal float writes via **`action_targets`** row **`UiReactActionKind.SET_FLOAT_LITERAL`**.
- Official examples **`options_transactional_demo.tscn`** and **`anim_targets_catalog_demo.tscn`** updated accordingly.

### Added

- **`UiReactTransactionalHostBinding`**: cohort **`group`**, optional **`screen`** ([**`UiTransactionalScreenConfig`**](../scripts/api/models/ui_transactional_screen_config.gd)), **`role`** (Apply/Cancel).
- **`UiReactActionKind.SET_FLOAT_LITERAL`**, **`UiReactStateOpService.set_float_literal`**.

## [2.22.0] - 2026-04-07

### Added

- **Editor dock — Wire rules tab (P5.2 / CB-035):** second tab on the **Ui React** bottom panel — lists **`wire_rules`** for one selected §5 host, **Add rule…** (§6 concrete types), **Remove**, **Duplicate**, **Move up/down**, **Inspect rule**, **Refresh list**; **UndoRedo** via **`EditorUndoRedoManager`** and **`UiReactActionController.assign_property_variant`** (same embedded **`UiReactWireRule`** subresources as the Inspector; no parallel format).
- **`UiReactActionController.assign_property_variant`:** undo-safe assignment for any **`Variant`** property (used for **`wire_rules`** **`Array[UiReactWireRule]`**).

### Documentation

- **[`WIRING_LAYER.md`](WIRING_LAYER.md)** §8 / §9; **[`README.md`](../README.md)** designer path; **[`ROADMAP.md`](ROADMAP.md)** P5.2 exit + Appendix **CB-035** **Done**.

## [2.21.0] - 2026-04-07

### Added

- **`UiReactActionKind`**: **`ADD_PRODUCT_TO_FLOAT`**, **`TRANSFER_FLOAT_PRODUCT_CLAMPED`**, **`ADD_PRODUCT_TO_INT`**, **`TRANSFER_INT_PRODUCT_CLAMPED`** on **`UiReactActionTarget`**; **`UiReactStateOpService`**: **`add_product_to_accumulator`**, **`transfer_float_product_clamped`**, **`add_product_to_int_clamped`**, **`transfer_int_product_clamped`** (**CB-051**).
- **`shop_computed_demo.tscn`**: exercises all four new presets (Sell, Deposit, Add tickets, Tip) alongside existing Buy (**`SUBTRACT_PRODUCT_FROM_FLOAT`**).

### Documentation

- **[`ACTION_LAYER.md`](ACTION_LAYER.md)** §2 / §3.2 (numeric presets, int overflow **no-op** policy); **[`DECISIONS.md`](DECISIONS.md)** CB-051 entry; **[`ROADMAP.md`](ROADMAP.md)** Appendix **CB-051** **Done**.

## [2.20.0] - 2026-04-07

### Added

- **`UiReactWireSortArrayByKey`**: wiring rule to sort **`UiArrayState`** rows by a flat dictionary key (**`UiStringState`**) with optional **`UiBoolState`** descending; **`inventory_screen_demo.tscn`** exercises it (**CB-011**).
- **`UiTransactionalScreenConfig`**, **`UiReactTransactionalSession`**: tree-scoped Apply/Cancel cohort (**`begin_edit_all`** deferred one frame on first registration); **`UiReactButton`** / **`UiReactTextureButton`** exports **`transactional_group`**, **`transactional_screen`**, **`transactional_role`**.
- **`UiReactTransactionalValidator.validate_transactional_under_root`**: dock **ERROR** when **`UiReactTransactionalActions`** and button **`transactional_*`** target the same **`UiTransactionalGroup`**; duplicate Apply/Cancel role checks; **`pressed_state` + `transactional_role`** warning (**CB-057**).

### Changed

- **`UiReactTransactionalActions`**: delegates to **`UiReactTransactionalSession`**; **`options_transactional_demo.tscn`** uses **`UiReactButton`** Apply/Cancel (no coordinator node).

### Deprecated

- **`UiReactTransactionalActions`**: prefer **`UiReactButton`** / **`UiReactTextureButton`** **`transactional_*`** for Apply/Cancel.

### Documentation

- **Charter evidence bar:** [`ROADMAP.md`](ROADMAP.md) intro + **Charter**—**official examples** (README-indexed) replace private-game **dogfood** / **3×** as proof; new glossary **Official example**, **Evidence bar**; **Inspector surface matrix (CB-052)** and **CB-052** Note tie **†** → **●** to the bar; [`DECISIONS.md`](DECISIONS.md) **2026-04-06**; [`docs/README.md`](README.md) task routing; [`AGENTS.md`](../AGENTS.md) change policy + non-goals; [`README.md`](../README.md) roadmap paragraph.
- **Transactional mini-host (CB-057):** [`README.md`](../README.md), [`ROADMAP.md`](ROADMAP.md), [`ACTION_LAYER.md`](ACTION_LAYER.md), [`WIRING_LAYER.md`](WIRING_LAYER.md), model docstrings.

## [2.19.1] - 2026-04-07

### Fixed

- **`UiReactActionTargetHelper._install_state_watch_bindings`**: In GDScript, **`PackedInt32Array`** is value-typed; **`append`** on a value read from a **`Dictionary`** did not update the stored array, so per-**`state_watch`** row **`indices`** stayed **empty** and **`value_changed`** never dispatched **`action_targets`** rows (e.g. **`SET_VISIBLE`**, **`SET_MOUSE_FILTER`**). The array is now read, appended, and **written back** to the dictionary (**2.19.1**).

## [2.19.0] - 2026-04-03

### Added

- **`UiReactActionTarget`**: **`visible_when_true`** and **`visible_when_false`** for **state-driven** **`SET_VISIBLE`** rows (bool from **`state_watch.get_value()`**, coerced); Inspector shows branch fields when **`state_watch`** is set, **`visible_value`** when control-triggered (**CB-056**).
- **`options_transactional_demo.tscn`**: **`UiReactCheckBox`** row (**`CB056DemoToggle`**) with **`state_watch`** **`SET_VISIBLE`** on **`CB056Hint`** (Charter **official example**).

### Changed

- **`SET_VISIBLE`** with **`state_watch`**: visibility now follows **`visible_when_true`** / **`visible_when_false`** instead of always applying **`visible_value`** on each **`value_changed`**. Rows that need **unchanged** visibility whenever the watched bool updates should set **both** branch fields to the same **`bool`** (e.g. always visible: **`true`** / **`true`**).
- **`UiReactCheckBox`**: **`UiReactActionTargetHelper.sync_initial_state`** after validating **`action_targets`** (parity with **`UiReactButton`** and other hosts; state-driven rows apply on first frame).

### Documentation

- [`ACTION_LAYER.md`](ACTION_LAYER.md) §3 (`SET_VISIBLE` bullets, validator note); [`DECISIONS.md`](DECISIONS.md) **`SET_VISIBLE`** branches entry; [`ROADMAP.md`](ROADMAP.md) **CB-056**; README **Conditional strings** (presentation).

## [2.18.0]

### Added

- **`UiReactOptionButton`**: **`action_targets`**, **`wire_rules`**, **`UiReactWireRuleHelper`** attach/detach, merged triggers + **`sync_initial_state`** + **`run_actions`** (**CB-054**).
- **`UiReactTabContainer`**: **`action_targets`**, **`wire_rules`**, same action/wiring integration; **`tab_selected`** always dispatches **`SELECTION_CHANGED`** for animations/actions when either array is non-empty (**CB-055**).
- **`UiReactWireRuleHelper`**: **`SELECTION_CHANGED`** bindings for **`OptionButton.item_selected`** and **`TabContainer.tab_selected`** on **`MapIntToString`**, **`RefreshItemsFromCatalog`**, **`CopySelectionDetail`**.
- **`options_transactional_demo.tscn`**: demonstrates **`CopySelectionDetail`** + **`MapIntToString`** on tabs/quality row + **`SET_VISIBLE`** action on **`UiReactOptionButton`**.

### Documentation

- [`WIRING_LAYER.md`](WIRING_LAYER.md) §5 (**OptionButton**, **TabContainer**); [`ACTION_LAYER.md`](ACTION_LAYER.md) §4; [`ROADMAP.md`](ROADMAP.md) Inspector matrix + **CB-052** **Done** + **CB-054** / **CB-055**; [`P5_CURRENT_STATE_AUDIT.md`](P5_CURRENT_STATE_AUDIT.md) A3; README binding rows + Quickstart.
- **North-star alignment:** README (inspector-first **four pillars**, designer/blessed path, **Examples at a glance**, **Conditional strings**, list-patterns lead with **`inventory_screen_demo`** + **`wire_rules`**); [`ROADMAP.md`](ROADMAP.md) (Charter **inspector-first** row, glossary **Action layer** = §5 + **`UiReactButton`** + float ops, **CB-002** / **CB-043** notes, **CB-048** stock-computed backlog, **CB-040** closed); [`WIRING_LAYER.md`](WIRING_LAYER.md) §2 **Actions** + bounded float cross-link; [`ACTION_LAYER.md`](ACTION_LAYER.md) §2 `UiComputed*` vs Actions for conditional copy; [`P5_CURRENT_STATE_AUDIT.md`](P5_CURRENT_STATE_AUDIT.md) **Last run** context. **No** `plugin.cfg` version bump (docs-only).
- **Wiring decentralization:** [`WIRING_LAYER.md`](WIRING_LAYER.md) — **`UiReactWireRuleHelper`**, per-host **`wire_rules`**, removed **`UiReactWireRunner`** / hub; [`ROADMAP.md`](ROADMAP.md) (**CB-032**, **CB-034**, **CB-039**, **CB-041** Wont); [`P5_CURRENT_STATE_AUDIT.md`](P5_CURRENT_STATE_AUDIT.md); [`README.md`](../README.md), [`AGENTS.md`](../AGENTS.md), [`docs/README.md`](README.md).

### Breaking

- **Wiring:** removed **`UiReactWireRunner`** (`scripts/controls/ui_react_wire_runner.gd`). Each **`UiReact*`** host with **`wire_rules`** applies rules via **`UiReactWireRuleHelper`** (`scripts/internal/react/ui_react_wire_rule_helper.gd`) from **`_enter_tree`** / **`_exit_tree`**. **`inventory_screen_demo.tscn`** no longer includes a **`WireRunner`** node.
- **Examples:** removed **`examples/shop_computed_afford.gd`**, **`shop_computed_buy_disabled.gd`**, **`shop_computed_status.gd`** (replaced by stock **`UiComputed*`** under **`scripts/api/models/`**). **`class_name`** **`ShopComputedAfford`**, **`ShopComputedBuyDisabled`**, **`ShopComputedStatus`** removed.
- **Examples:** removed **`examples/shop_computed_demo.gd`** and **`examples/options_status_computed.gd`**. Shop **Buy** is **`UiReactButton.action_targets`** **`SUBTRACT_PRODUCT_FROM_FLOAT`**; options status uses **`UiComputedTransactionalStatusString`**.
- **Wiring:** removed **`examples/inventory_screen_demo.gd`**. **`inventory_screen_demo.tscn`** is **inspector-only** (**`wire_rules`** on controls + **`UiReactWireRuleHelper`**). New rules: **`UiReactWireSetStringOnBoolPulse`**, **`UiReactWireSyncBoolStateDebugLine`**. **`UiReactWireCopySelectionDetail`** defaults **`clear_suffix_on_selection_change`** to **true** (helper clears **`suffix_note_state`** when **`selected_state`** changes before recomputing detail).
- **`UiReactTree`:** requires **`tree_items_state`** (**`UiArrayState`** whose value is an **`Array` of `UiReactTreeNode`**). Populate the tree via data, not ad hoc **`create_item`** code on the control.
- **Computed wiring:** removed **`UiReactComputedSync`**. Assign **`UiComputedStringState`** / **`UiComputedBoolState`** subclasses to **`UiReact*`** exports (e.g. **`text_state`**, **`checked_state`**); **`UiReactComputedService`** wires **`sources`** at runtime. Nested computeds (sources of other computeds) are wired automatically.
- **`UiAnimTarget`:** renamed **`preamble_reset_duration`** → **`reset_duration`**, **`await_preamble_before_main`** → **`wait_after_reset`**. Re-save scenes/subresources that referenced the old property names.
- **`UiReact*`** controls: removed **`animation_selection_provider`**. **`selection_slot`** filtering uses **`get_animation_selection_index()`** on the **same** host when any **`animation_targets`** row uses **`selection_slot >= 0`**.
- **`UiReactItemList`:** removed **`row_play_preamble_reset`**, **`row_play_soft_reset_duration`**, **`preamble_reset_target`**. Use **`UiAnimTarget.reset_duration`** / **`wait_after_reset`** per row instead.
- **`UiReactItemList`:** removed **`row_animation_targets`**. Use **`animation_targets`** with **`selection_slot`** set per row for **`play_selected_row_animation`** / **`play_preamble_reset_only`**.

### Added

- **Editor:** dock validates **`UiAnimTarget.trigger`** on **`animation_targets`** and **control-driven** **`action_targets`** rows against **`ANIM_TRIGGERS_BY_COMPONENT`** ([`editor_plugin/ui_react_component_registry.gd`](../editor_plugin/ui_react_component_registry.gd)); **`UiReactTabContainer`** **`SELECTION_CHANGED`** may use an **empty** animation **Target** without a dock error (aligned with runtime **`allow_empty_for`**).

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
- **Reactivity:** **`UiReactWireRuleHelper`** listens to **`Resource.changed` only** on `UiState` dependencies where applicable; **`UiReactComputedService`** uses **`Resource.changed`** on computed **`sources`**.
- **Wiring:** `UiReactWireRule.trigger` uses **`UiReactWireRule.TriggerKind`** (`TEXT_CHANGED = 5`, `SELECTION_CHANGED = 6`, `TEXT_ENTERED = 13`) so wiring does not depend on `UiAnimTarget.Trigger`; existing saved ints stay valid.
- **Catalog rule:** `UiReactWireRefreshItemsFromCatalog.first_row_icon_path` applies to the **first row after filters**, not catalog row 0 only.
- **`UiTransactionalState`:** `set_value` / `set_silent` clone array/dictionary drafts like other states.
- **Actions:** `UiReactActionTargetHelper._with_reentry_guard` still uses sequential unlock after `fn.call()` (same behavior as before this batch; full **`try` / `finally`** is optional if you target an engine/toolchain that parses it reliably).
- **Controls:** Shared **`UiReactTwoWayBindingDriver`**; exported `UiState` bindings use **getters/setters** with reconnect when the resource is swapped at runtime.
- **Editor:** `UiReactComponentRegistry` is the single binding/stem registry; **`UiReactValidatorService`** delegates to split validators; **`UiReactUnusedStateService`** caches loads by `mtime` (full cache clear on dock **Rescan**).
- **Editor:** dock UI scripts live under **`editor_plugin/dock/`** (`ui_react_dock.tscn`, `ui_react_dock*.gd`); **`ui_react_editor_plugin.gd`** loads **`res://addons/ui_react/editor_plugin/dock/ui_react_dock.tscn`**.
- **Hygiene:** Removed unreferenced plugin-generated sample `.tres` files; README notes not committing stray plugin output.

## [2.17.1] - 2026-04-03

### Fixed

- **`UiReactComputedService`:** dependency **`Resource.changed`** listeners for multiple **`UiComputed*`** instances sharing the same **`UiFloatState`** (e.g. **`shop_computed_demo.tscn`** afford bool + order summary string) — use a per-wiring lambda instead of **`Callable.bind`** and **`is_connected`**, and always **`connect`**, so every computed’s flush/recompute runs when gold/price/qty change.

## [2.17.0] - 2026-04-03

### Added

- **CB-049:** **`UiReactSlider`** and **`UiReactProgressBar`** — **`UiReactComputedService.hook_bind`** / **`hook_unbind`** on **`value_state`** (parity with **`UiReactSpinBox`**) so bound **`UiComputed*`** dependency wiring applies to range controls.
- **CB-050:** **`UiReactTextureButton`** — **`action_targets`** export; merged trigger map with **`animation_targets`**, **`sync_initial_state`**, and **`run_actions`** (parity with **`UiReactButton`**).

### Documentation

- **[`ACTION_LAYER.md`](ACTION_LAYER.md) §4**, **[`WIRING_LAYER.md`](WIRING_LAYER.md)** Actions one-liner, **[`README.md`](../README.md)** binding table, **[`ROADMAP.md`](ROADMAP.md)** (glossary + **CB-049** / **CB-050**): **`UiReactTextureButton`** **`action_targets`**; range **`value_state`** computed hooks.

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

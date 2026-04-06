# Ui React

**Primary story:** Build **reactive UI** in the Godot **editor**—attach **UiReact\*** controls, **bind** **`UiState`**, **animate** with **`animation_targets`**, **wire** data with **`wire_rules`** (**`UiReactWireRuleHelper`** on each host), **derive** labels and flags with **`UiComputed*`**, **draft/commit** with **transactional** state, and run **bounded** **imperative** steps (focus, visibility, shop-style float ops) via **`action_targets`**—**without scene scripts** for those “obvious” layers, wherever the addon covers the pattern. Domain rules, networking, and one-off glue still belong in **game code** when needed ([**Non-goals**](docs/ROADMAP.md#non-goals-explicit) in **ROADMAP**).

Self-contained building blocks for Godot 4.x: two-way **UiState** binding, optional **inspector-driven** **`UiAnimTarget`** tweens, and **`UiAnimUtils`** for code-driven motion when you want it.

**Documentation map and agent notes:** **[`docs/README.md`](docs/README.md)** (index of `docs/`), **[`AGENTS.md`](AGENTS.md)** (scope, paths, boundaries for this addon).

### Four pillars (inspector-first)

| Pillar | Role | Normative / entry |
|--------|------|-------------------|
| **Wiring** | When X changes, update Y (filters, list refresh, selection detail, …) | **[`docs/WIRING_LAYER.md`](docs/WIRING_LAYER.md)** — **`UiReactWireRuleHelper`**, **`UiReactWireRule`**, per-control **`wire_rules`**. |
| **Computed** | Derive **`UiStringState` / `UiBoolState`** payloads from **`sources`** | **`UiComputedStringState`** / **`UiComputedBoolState`** subclasses, **`UiReactComputedService`** — see **Computed state** below. |
| **Transactional** | Draft vs committed **Apply / Cancel** | **`UiTransactionalState`**, **`UiTransactionalGroup`**, **`UiReactTransactionalActions`** — see **Transactional state** below. |
| **Actions** | Non-motion UI steps + **bounded** float mutations | **[`docs/ACTION_LAYER.md`](docs/ACTION_LAYER.md)** — **`UiReactActionTarget`**, **`UiReactStateOpService`** (not a full command DSL). |

**Layers (short):** **Wiring** = reactive data rules; **Computed** = derived **`UiComputed*`** state; **Actions** = focus / visibility / mouse filter / bool UI flags / whitelisted float ops; **`UiReactStateOpService`** = shared float helpers (**DRY**).

### Roadmap and phases

Public direction, phased delivery, and the full **Appendix backlog** (**CB-001–CB-047**) live in **[`docs/ROADMAP.md`](docs/ROADMAP.md)**—including the **Charter** **evidence bar** (**official examples** here in **`examples/`** + **symmetry** / matrix tracking for new or widened exports) and the **Inspector surface matrix (CB-052)** (**`animation_targets`** / **`action_targets`** / **`wire_rules`** per control). **P5** wiring, **P6.1** actions, exit criteria, and **stock-take** (**[`docs/P5_CURRENT_STATE_AUDIT.md`](docs/P5_CURRENT_STATE_AUDIT.md)**) are linked from there.

### Designer path, blessed defaults, common gaps

- **Who:** UI authors and small teams who want **fast iteration** with **resources in the Inspector** instead of **per-screen glue scripts** for the same patterns.
- **Manual pain this reduces:** ad hoc **`_ready`** wiring, duplicated filter/list/detail logic, and inconsistent approaches to afford flags, apply/cancel, and list overlays—**where** the addon’s **wiring + computed + transactional + actions** cover the job.
- **Blessed path (typical full screen):** attach **`UiReact*`** → assign **`*_state`** → optional **`animation_targets`** → optional **`wire_rules`** ( **`UiReactWireRuleHelper`** registers from each host ) → optional **`UiComputed*`** on bindings → optional **`UiTransactionalGroup`** + **`UiReactTransactionalActions`** → optional **`action_targets`**. Official **examples** (below) mix these layers.
- **What you still hand-code:** economy/catalog **content**, servers, and anything under [**Non-goals**](docs/ROADMAP.md#non-goals-explicit). **Play** still validates behavior; “no scripting” here means **no GDScript required** for the **inspector-authored** layers on the recommended path—not zero Godot familiarity.

---

## The 3-step setup (repeat for every control)

**Mechanical minimum:** the three steps below are the **binding** layer. For **whole screens**, prefer the **four pillars** (wiring → computed → transactional → actions) so behavior stays **declarative** and **validator-friendly**—see **Quickstart** examples.

1. **Attach** the matching `UiReact*` script to a native Control (Button, HSlider, Label, …).
2. **Assign** the **typed** state resource each export expects (`UiBoolState`, `UiIntState`, `UiFloatState`, `UiStringState`, `UiArrayState`, **`UiTransactionalState`**, or a **subclass** of **`UiComputedStringState` / `UiComputedBoolState`** where noted). Exports typed as **`UiState`** accept any concrete state implementing the binding’s payload shape — including **`UiTransactionalState`** — for `UiReactSlider` / `UiReactSpinBox` / `UiReactProgressBar` **`value_state`**, `UiReactCheckBox` **`checked_state`**, `UiReactLabel.text_state` / **`UiReactRichTextLabel.text_state`** (**`UiStringState` or `UiArrayState`**, **`UiComputedStringState`**, or transactional string/array), and `UiReactItemList.selected_state` (**`UiIntState`** in single-select, **`UiArrayState`** in multi-select).
3. **Optionally** fill `animation_targets` with `UiAnimTarget` entries to run tweens from the Inspector (no tween code).

That’s it. Gameplay and domain code (when you use it) reads and writes through **`get_value()`** / **`set_value()`** on those resources; controls stay in sync. Prefer **Inspector-assigned** resources for everything the addon models above.

### Inspector hints (Godot 4.x)

- **`UiAnimTarget.target`**: exported as a **Control-only** node path (`@export_node_path("Control")`). The picker rejects non-`Control` nodes.
- **`UiAnimTarget` tuning numbers** (duration, repeat count, rotate angle, pop/pulse/shake/flash intensity, etc.): use **@export_range** sliders/spinboxes in the Inspector—see tooltips on each field.

---

## Quickstart

### 1) Add the addon

Copy `addons/ui_react/` into your Godot project at **`addons/ui_react/`**. Open the project and wait for import.

### 2) Run the example

The addon ships **four** runnable examples under **`res://addons/ui_react/examples/`** (game-screen style + one animation catalog). Open any of these and press **Play** (default **Main Scene** is **`inventory_screen_demo.tscn`**):

- **`res://addons/ui_react/examples/inventory_screen_demo.tscn`** — **`wire_rules`** on controls (map / refresh / copy-detail / bool-pulse suffix / debug lines per **[`docs/WIRING_LAYER.md`](docs/WIRING_LAYER.md)**); **no** root script; **`UiReactTree`** + filtered **`UiReactItemList`** + actions; list lock via overlay + **`action_targets`** (**CB-015** / **P6.1**); sample **`UiAnimTarget`** fades/POP.
- **`res://addons/ui_react/examples/options_transactional_demo.tscn`** — transactional **Apply / Cancel** + **`UiReactTabContainer`** showcase tab.
- **`res://addons/ui_react/examples/shop_computed_demo.tscn`** — **`UiComputedFloatGeProductBool`** / **`UiComputedBoolInvert`** / **`UiComputedOrderSummaryThreeFloatString`** + **`UiReactRichTextLabel`**; **`UiReactProgressBar`** / **`UiReactSpinBox`**; **Buy** via **`action_targets`** **`SUBTRACT_PRODUCT_FROM_FLOAT`**; no root script, no **`examples/*.gd`** for shop computeds.
- **`res://addons/ui_react/examples/anim_targets_catalog_demo.tscn`** — catalog of **`UiAnimTarget.AnimationAction`** ( **`animation_targets`** with **`selection_slot`** per row + **`play_selected_row_animation`**) + trigger playground; no root script.

**Examples at a glance** (which layers each scene stresses):

| Scene | Wiring | Computed | Transactional | Actions |
|-------|:------:|:--------:|:-------------:|:-------:|
| **`inventory_screen_demo.tscn`** | yes | — | — | yes |
| **`options_transactional_demo.tscn`** | — | yes (status line) | yes | — |
| **`shop_computed_demo.tscn`** | — | yes | — | yes (Buy) |
| **`anim_targets_catalog_demo.tscn`** | — | — | — | — |

Use the scene tree to see how states and targets are wired.

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

**RichTextLabel + BBCode from state (display-only)**

1. Add **RichTextLabel**, attach **`UiReactRichTextLabel`**.
2. Use the same **`text_state`** payload family as **`UiReactLabel`** (**`UiStringState`**, **`UiArrayState`**, **`UiComputedStringState`**, or transactional string/array payloads).
3. Mutate copy only through **`get_value()`** / **`set_value()`** on that state — the wrapper sets **`bbcode_enabled`** and pushes the flattened string to **`RichTextLabel.text`**. There is **no** edit-back from the control; for editable rich text, use the **escape hatch** or await a future **`UiReactTextEdit`** (see **Text controls** below).

### 4) Optional: animations from code

```gdscript
await UiAnimUtils.animate_expand(self, some_control).finished
```

**Show/hide presets:** use `UiAnimUtils.preset(UiAnimUtils.Preset.FADE_IN, self, panel)` (and other `UiAnimUtils.Preset` values). See **Screen transitions** below for a preset summary. Default durations, offsets, and related numeric defaults for your own compositions live in **`UiAnimConstants`** (`scripts/internal/anim/ui_anim_constants.gd`).

`UiAnimUtils` is **`res://addons/ui_react/scripts/api/ui_anim_utils.gd`** (global class `UiAnimUtils`).

### 5) Optional: **Ui React** editor plugin

1. Open **Project → Project Settings → Plugins** and enable **Ui React** (bundled at `editor_plugin/plugin.cfg`).
2. Open the **Ui React** panel in the **bottom editor dock** (tab bar).
3. Choose **Scan: Selection** or **Entire scene**, press **Rescan** to run diagnostics on demand, and review results. Dock choices (scan mode, **Group** mode, filters, auto-refresh, output folder) are **remembered per project** when you reopen it. The tool also **updates when you switch the active edited scene**, and when **EditorFileSystem** reports filesystem changes (coalesced refresh so rapid imports do not spam rescans).
4. Use **Group** (flat / by node / by severity), **Filter**, and severity toggles to narrow the list. **Binding** issues (validator output) show **Fix**, **Focus**, and **Ignore**—**Ignore** is session-only until the next **Rescan**. **Unused state file** rows apply only to the **active edited, saved** scene: a typed `UiState` `.tres` must (1) live under the configured output folder, (2) have its `res://` path appear in that scene’s **`.tscn` text on disk**, and (3) **not** be assigned on any **Ui React** export in that scene’s node tree. Such rows show **Reveal** and **Ignore**—**Reveal** calls the FileSystem dock’s **`navigate_to_path`** for that `.tres`; **Ignore** is **stored in Project Settings** (**`ui_react/plugin_ignored_unused_state_paths`**) and survives **Rescan**. **Unsaved scenes** (no `scene_file_path`) produce **no** unused-state rows. **Script-only** references (never written into the `.tscn`) are **not** detected as candidates. This is **not** a project-wide unused scan. With **Group → By node**, unused-file rows appear under **Unused state files**, not under **`(scene)`**. Click an issue summary in the **upper list** to select it and show full details in the **report** below. **Hover** any control for a short tooltip (scope, filters, and actions).
5. For unassigned `*_state` slots with a suggested type, use **Fix** on a row (single issue) or **Fix All** in the toolbar (every eligible **binding** row in the **filtered** list). **Ignore All** applies session **Ignore** to binding rows and appends unused-file paths to the persisted ignore list (see **Project settings** below). New `.tres` files are saved under the configured folder (default `res://addons/ui_react/ui_resources/plugin_generated/`); if a filename already exists, the plugin saves as `<name>_2.tres`, `<name>_3.tres`, … instead of overwriting. Override the folder with **`ui_react/plugin_state_output_path`**.
6. **Repo hygiene:** Do not commit plugin-generated `.tres` under that folder unless a **committed** example scene references them. Remove one-off Quick Create leftovers before opening a PR.

All plugin usage details are documented in this README.

---

## Required vs optional (by control)

| Control | Bindings (typical) | Required for “reactive” behavior |
|--------|--------------------|----------------------------------|
| **UiReactButton** | `pressed_state`, `disabled_state` | At least one state if you want sync with `UiState`; neither required for a plain Button. **`disabled_state`** accepts **`UiBoolState`** or a **`UiComputedBoolState`** subclass. |
| **UiReactCheckBox** | `checked_state`, `disabled_state`, optional `action_targets` | Assign `checked_state` (**`UiState`**: **`UiBoolState`** or bool-shaped **`UiTransactionalState`**) for two-way sync. |
| **UiReactSlider** | `value_state` | Assign **`value_state`** (**`UiState`**: **`UiFloatState`** or float/int-shaped **`UiTransactionalState`**) for two-way sync; else behaves like a normal slider. |
| **UiReactSpinBox** | `value_state`, `disabled_state` | Same **`value_state`** pattern as slider; `disabled_state` optional (**`UiBoolState`** or **`UiComputedBoolState`** subclass). |
| **UiReactProgressBar** | `value_state` | Same **`value_state`** pattern as slider. |
| **UiReactLineEdit** | `text_state`, optional `action_targets` | `text_state` for sync. |
| **UiReactLabel** | `text_state` | `text_state` for sync. |
| **UiReactRichTextLabel** | `text_state` | **`text_state`** for **display-only** sync (BBCode string → **`RichTextLabel.text`**); wrapper forces **`bbcode_enabled`**. Same payload family as **`UiReactLabel`**; **no** UI→state writeback. |
| **UiReactOptionButton** | `selected_state`, `disabled_state` | `selected_state` for sync (usually string item text). |
| **UiReactItemList** | `items_state`, `selected_state`, optional `action_targets` | **`items_state`**: **`UiArrayState`** (`Array` of strings/variants or **`label`/`icon`** dicts per **List patterns**). **`selected_state`**: **`UiIntState`** (single-select) or **`UiArrayState`** (multi-select indices). Godot’s **ItemList** has no built-in disabled state—wrap or gate input with a parent **Control** / `mouse_filter` / focus policy in game code if you need “disabled” behavior. |
| **UiReactTabContainer** | `selected_state`, `tab_config` | **`selected_state`**: **`UiIntState`**. **`tab_config`**: optional **`UiTabContainerCfg`** (use **`UiArrayState`** for tab/disabled/visibility arrays). |
| **UiReactTextureButton** | `pressed_state`, `disabled_state`, optional `action_targets` | Same semantics as **`UiReactButton`** on **`BaseButton`** (`pressed` vs `toggle_mode` / `toggled`, **`disabled_state`** may use **`UiBoolState`** or **`UiComputedBoolState`**). Assign **`texture_normal`** (and optional hover/pressed textures) in the Inspector. |
| **UiReactTree** | `tree_items_state`, `selected_state`, optional `action_targets` | **`tree_items_state`**: **`UiArrayState`** — value is an **`Array` of `UiReactTreeNode`** (see below). **`selected_state`**: **`UiIntState`**. Wrapper forces **single selection** (`Tree.SELECT_SINGLE`). See **UiReactTree binding semantics** below. |
| **`UiReactTransactionalActions`** | `group`, button paths, optional `action_targets` | **`action_targets`** must be **state-driven** only ([`ACTION_LAYER.md`](docs/ACTION_LAYER.md))—this host does not emit **`UiAnimTarget`** triggers. |

### UiReactTree binding semantics (P4)

- **Row data:** Assign **`tree_items_state`** to a **`UiArrayState`** whose **`value`** is an **`Array` of `UiReactTreeNode`**. Each node has **`text`**, **`icon`** (**`Texture2D`**), and **`children`** (**`Array[UiReactTreeNode]`**; use an **empty** array for leaves). The control **clears and rebuilds** the **`Tree`** whenever that array changes. Top-level entries are created as children of the tree’s root item (with **`hide_root`** **`true`**, index **`0`** is the first top-level row).
- **Payload:** **`UiIntState`** stores the **visible pre-order row index** for the current selection, or **`-1`** when nothing is selected.
- **Traversal:** Rows are visited in depth-first order using Godot’s visible tree walk (`TreeItem.get_next_visible(false)`). If **`hide_root`** is **`true`**, the engine’s root **`TreeItem` is not counted**—index **`0`** is the first visible child under that root. If **`hide_root`** is **`false`**, the root row is index **`0`**.
- **State → UI:** Valid indices call **`Tree.set_selected(item, 0)`**; **`-1`** calls **`deselect_all()`**. Out-of-range indices deselect and snap the state to **`-1`** after a rebuild.
- **Editor:** The dock validates **`tree_items_state`** shape (non-null **`icon`**, nested **`UiReactTreeNode`**, max depth) and **`animation_targets`** **`selection_slot`** against **`get_visible_row_count()`** (same idea as **`UiReactItemList`** vs **`item_count`**).

**`animation_targets`** is always **optional**: leave empty if you don’t want automatic tweens. **`action_targets`** (where exposed) is optional; see **`docs/ACTION_LAYER.md`** and the **Action layer (P6.1)** section above.

### UiAnimTarget: supported triggers per host

The Inspector lists **all** [`UiAnimTarget.Trigger`](scripts/api/models/ui_anim_target.gd) values on every row, but each **`UiReact*`** only **connects** the signals for triggers that appear in its **`animation_targets`** (see **`_validate_animation_targets`** on that control). The **editor dock** warns if a row’s **Trigger** is not supported on that host (registry: **`ANIM_TRIGGERS_BY_COMPONENT`** in [`editor_plugin/ui_react_component_registry.gd`](editor_plugin/ui_react_component_registry.gd)). The same set applies to **control-driven** **`action_targets`** rows (**`state_watch`** null). **`UiReactTabContainer`**: **`SELECTION_CHANGED`** rows may use an **empty** **Target** path for tab transition presets (runtime **`allow_empty_for`**).

| Host | Supported triggers |
|------|-------------------|
| **`UiReactButton`**, **`UiReactTextureButton`** | `PRESSED`, `HOVER_ENTER`, `HOVER_EXIT`, `TOGGLED_ON`, `TOGGLED_OFF` |
| **`UiReactCheckBox`** | `TOGGLED_ON`, `TOGGLED_OFF`, `HOVER_ENTER`, `HOVER_EXIT` |
| **`UiReactSlider`** | `VALUE_CHANGED`, `VALUE_INCREASED`, `VALUE_DECREASED`, `DRAG_STARTED`, `DRAG_ENDED`, `HOVER_ENTER`, `HOVER_EXIT` |
| **`UiReactSpinBox`** | `VALUE_CHANGED`, `VALUE_INCREASED`, `VALUE_DECREASED`, `FOCUS_ENTERED`, `FOCUS_EXITED`, `HOVER_ENTER`, `HOVER_EXIT` |
| **`UiReactProgressBar`** | `VALUE_CHANGED`, `VALUE_INCREASED`, `VALUE_DECREASED`, `COMPLETED`, `HOVER_ENTER`, `HOVER_EXIT` |
| **`UiReactLineEdit`** | `TEXT_CHANGED`, `TEXT_ENTERED`, `FOCUS_ENTERED`, `FOCUS_EXITED`, `HOVER_ENTER`, `HOVER_EXIT` |
| **`UiReactLabel`**, **`UiReactRichTextLabel`** | `TEXT_CHANGED`, `HOVER_ENTER`, `HOVER_EXIT` |
| **`UiReactOptionButton`** | `SELECTION_CHANGED`, `HOVER_ENTER`, `HOVER_EXIT` |
| **`UiReactItemList`**, **`UiReactTree`** | `SELECTION_CHANGED`, `HOVER_ENTER`, `HOVER_EXIT` |
| **`UiReactTabContainer`** | `SELECTION_CHANGED`, `HOVER_ENTER`, `HOVER_EXIT` |

### UiAnimTarget: unified baseline and RESET

- **`use_unified_baseline`** defaults to **on**. Supported motions (slides, center slides, **`EXPAND`/`EXPAND_X`/`EXPAND_Y`**, shake, float, color flash, etc.) **capture** a unified baseline for the tween and **release** it when the animation completes, so the control returns to the snapshot baseline (and **RESET** can restore it later).
- Set **`use_unified_baseline`** to **off** on a row when you intentionally want motion to **persist** (legacy “slide stays offset” behavior).
- **`RESET`** honors **`duration`**: **`0`** is an **instant** (**hard**) restore to the stored snapshot; **values above zero** tween (**soft** reset) using **`easing`**. **RESET** still needs a snapshot in **`UiAnimSnapshotStore`** from a prior captured animation (unchanged).
- **`reset_duration`** (default **`-1`**) and **`wait_after_reset`**: optional lead-in **`RESET`** on the same **`target`** before the main **`animation`** (not the main tween’s **`duration`**). **`>= 0`** seconds enables the lead-in (**`0`** = hard); **`wait_after_reset`** controls whether the main animation waits for that reset tween or may overlap it.
- **`selection_slot`** (default **`-1`**) on each **`UiAnimTarget`**: when the host **`UiReact*`** control’s **`animation_targets`** array includes at least one row with **`selection_slot >= 0`**, **`UiReactAnimTargetHelper.trigger_animations`** filters using **`get_animation_selection_index()`** on that **same** host (e.g. **`UiReactItemList`**, **`UiReactTree`**). Targets with **`selection_slot == -1`** always run; otherwise the slot must match the current index. If the host lacks **`get_animation_selection_index()`** but slot gating is requested, only ungated (**`-1`**) targets run (with a warning). **`play_selected_row_animation`** runs every target whose **`selection_slot`** equals the selected row index (see **`UiReactItemList`** below).

### UiReactItemList: `animation_targets` and play API

- **Single `animation_targets` array** for signal-driven tweens **and** row-play presets. Use **`selection_slot == -1`** for entries not tied to a row (e.g. hover-only on another node). Use **`selection_slot == row_index`** ( **`>= 0`** ) for presets used by **`play_selected_row_animation()`** / **`play_preamble_reset_only()`**; **all** matching entries run **in array order** (multiple nodes per row are supported).
- **`play_selected_row_animation()`** / **`play_preamble_reset_only()`** apply **`apply_with_preamble()`** / **`apply_preamble_reset_only()`** per matching resource (**`reset_duration`**, **`wait_after_reset`** on each **`UiAnimTarget`**). Connect **`Button.pressed`** to **`play_selected_row_animation`** in the editor for scriptless catalog-style demos.
- **`get_animation_selection_index()`** on the list supplies the current row index for **`selection_slot`** filtering on **`trigger_animations`**.

### `UiReactButton` / `UiReactTextureButton`: `press_writes_float_state`

- Optional **`press_writes_float_state`** + **`press_writes_float_value`**: one-way **`set_value`** on **`BaseButton.pressed`** (e.g. set a **`UiFloatState`** to **100** for a progress demo). Not part of the Action layer; keep to UI/test harness patterns.

### Text controls (`UiReactLineEdit`, `UiReactLabel`, `UiReactRichTextLabel`)

| Control | Direction | Notes |
|---------|-----------|--------|
| **`UiReactLineEdit`** | Two-way | Plain string **`text_state`**; typing updates state when configured. |
| **`UiReactLabel`** | Display | Plain **`Label`**; **`text_state`** accepts **`UiStringState`** / **`UiComputedStringState`**, **`UiArrayState`** (including nested **`UiState`** entries, flattened via **`as_text_recursive`**), and **`UiTransactionalState`** whose draft matches string/array shapes. |
| **`UiReactRichTextLabel`** | Display-only | **`RichTextLabel`**; **`bbcode_enabled`** is set **`true`** in **`_ready()`** so BBCode always applies. **`text_state`** uses the **same** accepted family as **`UiReactLabel`**; the result is assigned to **`text`**. **No** editing back into state—if you need bidirectional rich editing, bind manually (**escape hatch**) or wait for **`UiReactTextEdit`**. |

---

## Public API (use directly)

Paths are under **`res://addons/ui_react/`**.

| Kind | Global class / area | Path |
|------|---------------------|------|
| Animation facade | `UiAnimUtils` | `scripts/api/ui_anim_utils.gd` |
| Animation defaults (numeric) | `UiAnimConstants` | `scripts/internal/anim/ui_anim_constants.gd` |
| Chained animations (optional) | `UiAnimSequence` | `scripts/internal/anim/ui_anim_sequence.gd` |
| State (abstract base) | `UiState` | `scripts/api/models/ui_state.gd` |
| State (concrete) | `UiBoolState`, `UiIntState`, `UiFloatState`, `UiStringState`, `UiArrayState`, `UiTransactionalState`, `UiTransactionalGroup` | `scripts/api/models/ui_*_state.gd`, `scripts/api/models/ui_transactional_state.gd`, `scripts/api/models/ui_transactional_group.gd` |
| State (computed base) | `UiComputedStringState`, `UiComputedBoolState` | `scripts/api/models/ui_computed_string_state.gd`, `scripts/api/models/ui_computed_bool_state.gd` |
| Computed dependency wiring | `UiReactComputedService` | `scripts/internal/react/ui_react_computed_service.gd` |
| Inspector animation row | `UiAnimTarget` | `scripts/api/models/ui_anim_target.gd` |
| Tab / container config | `UiTabContainerCfg` | `scripts/api/models/ui_tab_container_cfg.gd` |
| Wiring (P5) | `UiReactWireRuleHelper`, `UiReactWireRule` + map / refresh / copy rules, `UiReactWireCatalogData` | `scripts/internal/react/ui_react_wire_rule_helper.gd`, `scripts/api/models/ui_react_wire_*.gd` |
| Attachable controls | `UiReact*`, `UiReactTransactionalActions` | `scripts/controls/` |

Prefer **`UiAnimUtils`** for tweens from code; prefer **`UiAnimTarget`** arrays on controls for no-code animation.

**`UiState` is abstract:** do not instantiate it directly. Each control export uses a concrete **`Ui*State`**, **`UiTransactionalState`**, a **subclass** of **`UiComputedStringState`** / **`UiComputedBoolState`** (see **Computed state** below), or the polymorphic **`UiState`** slot where noted. Read and write the **bound** payload with **`get_value()`** / **`set_value()`** (typed states expose a **`value`** property; **`UiTransactionalState`** exposes **`committed_value`** plus draft via those methods). Older projects that used a single generic `UiState` resource with a `Variant` export must migrate to the matching concrete class and resave resources.

**Strict integer indices:** Tab index (`UiReactTabContainer.selected_state`), **`UiReactTree.selected_state`**, **`UiIntState`**, and ItemList single-select **`selected_state`** use **`int` only**. **`float` is not accepted** for those bindings (no silent coercion from float or from **`UiFloatState`** / float-shaped **`UiTransactionalState`** there). Reserve **`UiFloatState`** (or transactional **float** payload) for sliders, spin boxes, and progress bars.

---

## Transactional state (draft / commit / cancel)

Use **`UiTransactionalState`** when you want **working-copy** values on an options-style screen that only persist after **Apply**, and **Cancel** restores controls from **`committed_value`**.

| Method / field | Role |
|----------------|------|
| **`committed_value`** | Last **committed** payload (`@export` in the Inspector). |
| **`get_value()` / `set_value()`** | Read/write the **draft** — this is what **`UiReact*`** controls sync with. |
| **`begin_edit()`** | Refresh draft from **`committed_value`** when opening the sheet (or after external commits). |
| **`apply_draft()`** | Copy draft → **`committed_value`** (commit). |
| **`cancel_draft()`** / **`reset_to_committed()`** | Copy **`committed_value`** → draft (revert UI). |
| **`has_pending_changes()`** | `true` when draft and committed differ (see **`UiTransactionalState`** tooltips / script). |

**Runnable example:** **`res://addons/ui_react/examples/options_transactional_demo.tscn`** — master volume (**`HSlider`** + **`UiReactSlider`**) and mute (**`CheckBox`** + **`UiReactCheckBox`**) share transactional resources; **Apply** / **Cancel** are wired through **`UiReactTransactionalActions`** to a **`UiTransactionalGroup`** (no per-scene apply/cancel loops). The demo status line uses **`UiReactLabel`** + **`UiComputedTransactionalStatusString`** on **`text_state`** (stock addon computed; or another **`UiComputedStringState`** subclass) so draft / committed / pending text stays in sync (see **Computed state**).

### Transactional batch orchestration (`UiTransactionalGroup` + `UiReactTransactionalActions`)

When one screen has **several** `UiTransactionalState` resources and a single **Apply** / **Cancel** bar:

1. Create a **`UiTransactionalGroup`** resource (`scripts/api/models/ui_transactional_group.gd`).
2. Set its **`states`** array to those `UiTransactionalState` instances **in commit order** (null entries are skipped at runtime).
3. Add a **`Control`** node in the scene, attach **`UiReactTransactionalActions`** (`scripts/controls/ui_react_transactional_actions.gd`).
4. Assign **`group`** to that `UiTransactionalGroup`.
5. Set **`apply_button_path`** and **`cancel_button_path`** as `NodePath`s **relative to the `UiReactTransactionalActions` node** (example: `../VBox/OptionsTabs/AudioPanel/AudioVBox/ButtonRow/ApplyButton` in **`options_transactional_demo.tscn`**).
6. Leave **`begin_on_ready`** `true` to call **`begin_edit_all()`** once when the scene enters the tree, unless you start the edit session from code.
7. **Read-only summary line:** prefer **`UiComputedTransactionalStatusString`** (stock) or another **`UiComputedStringState`** subclass on the label’s **`text_state`** (see **Computed state**) so the label tracks draft / committed transactional values without scene glue. Alternatively, use a **`UiStringState`** and call **`set_value()`** from code. Do **not** assign **`Label.text`** directly if the label uses **`UiReactLabel`**, or **`RichTextLabel.text`** if it uses **`UiReactRichTextLabel`**.

**API — `UiTransactionalGroup`:** `begin_edit_all()`, `apply_all()`, `cancel_all()`, `has_pending_changes()`.

**API — `UiReactTransactionalActions`:** connects **`BaseButton.pressed`** on the two paths to **`apply_all()`** / **`cancel_all()`** on the group. No undo, no autoload, no extra bindings on other `UiReact*` controls.

---

## Computed state (P2)

Use a **`UiComputedStringState`** or **`UiComputedBoolState`** **subclass** when a **`UiStringState` / `UiBoolState` payload** should be **derived** from other **`UiState`** dependencies. Dependencies are listed only on the resource’s **`sources`** array (order preserved; **null** entries are skipped). There is **no** dependency graph solver, cycle detection, or automatic ordering—**avoid cycles** and keep **`sources`** explicit.

| Piece | Role |
|-------|------|
| **`UiComputedStringState`**, **`UiComputedBoolState`** | Base **`@abstract`** resources; implement **`compute_string()`** / **`compute_bool()`** and call **`recompute()`** to **`set_value()`** from the result. |
| **`UiReactComputedService`** | Runtime wiring when a computed resource is assigned to a **`UiReact*`** binding (e.g. **`text_state`**, **`checked_state`**): subscribes to **`Resource.changed`** on each non-null **`sources`** entry (and nested computeds), coalesces **`recompute()`** to once per frame. Editor: no runtime wiring. |
| **Dependency cap** | At most **32** **`sources`** entries are subscribed; extras are ignored with a warning. |

**Transactional + computed:** inside **`compute_*`**, read **`UiTransactionalState`** with **`get_draft_value()`**, **`get_committed_value()`**, and **`has_pending_changes()`** as needed—use **one** transactional resource per field in **`sources`**, not separate “draft” vs “committed” nodes.

**Examples:** **`res://addons/ui_react/examples/shop_computed_demo.tscn`** (Buy via **`action_targets`** **`SUBTRACT_PRODUCT_FROM_FLOAT`**; status **`UiReactRichTextLabel`** + **`UiComputedOrderSummaryThreeFloatString`**); **`res://addons/ui_react/examples/options_transactional_demo.tscn`** (**`UiComputedTransactionalStatusString`**).

**Dock:** a **WARNING** appears when a **`UiComputed*`** has **`sources`** but is not assigned to a registry **`UiReact*`** binding and is not only used as a nested source of another computed (**`UiReactComputedValidator`**).

### Conditional strings (derived copy vs wiring vs actions)

- **Derived UI copy:** Subclass **`UiComputedStringState`**, list dependencies in **`sources`**, implement **`compute_string()`**, assign to **`text_state`** on **`UiReactLabel`** / **`UiReactRichTextLabel`**. Stock examples: **`UiComputedOrderSummaryThreeFloatString`**, **`UiComputedTransactionalStatusString`**. Use this for “show this BBCode / line when state looks like X.”
- **Data-shaped strings the wiring layer owns:** Filter keys, catalog-driven rows, selection detail text — implement with **`wire_rules`**, not **`action_targets`** ([**`docs/WIRING_LAYER.md`**](docs/WIRING_LAYER.md) §2; [**`docs/ACTION_LAYER.md`**](docs/ACTION_LAYER.md) §2 — Actions must not duplicate those jobs).
- **Conditional presentation without new string payloads:** **`SET_VISIBLE`**, **`SET_UI_BOOL_FLAG`**, **`SET_MOUSE_FILTER`** on **`action_targets`** ([**`docs/ACTION_LAYER.md`**](docs/ACTION_LAYER.md)).
- **More stock computeds** for common conditionals are tracked in **[`docs/ROADMAP.md`](docs/ROADMAP.md)** Appendix (see backlog rows for **stock computed** / **CB-003** extensions)—shipped helpers will be called out in **CHANGELOG** when added.

---

## List patterns (P3)

**`UiReactItemList`** rebuilds rows from **`items_state`**: each element of the bound **`Array` becomes one row**:

| Entry type | Behavior |
|------------|----------|
| **String**, number, or other non-**Dictionary** | Label is **`str(entry)`** (same as before). |
| **Dictionary** | Use key **`label`** or **`text`** for the row label. Optional **`icon`**: a **`Texture2D`** or a **`String`** `res://` path loadable as a texture (e.g. imported **`.svg`** / **`.png`**). If `icon` is invalid or missing, the row has **no** icon. Unknown dict shapes still stringify poorly—prefer explicit **`label`**. |

**Bindings (single-select):** assign **`items_state`** → **`UiArrayState`**, **`selected_state`** → **`UiIntState`**. The stored index is **the row index in the current list** (after any filter). See **Strict integer indices** under **Public API**—no floats for selection.

**Filter / inventory recipe (recommended):** **`res://addons/ui_react/examples/inventory_screen_demo.tscn`** — **`wire_rules`** on the tree, filter **`UiReactLineEdit`**, and **`UiReactItemList`** (refresh from catalog, copy selection detail, bool-pulse suffix, debug lines per **[`docs/WIRING_LAYER.md`](docs/WIRING_LAYER.md)**). **No** root script; declarative rules only.

**Alternative (game-layer):** If you are **not** using the wiring layer yet:

1. Keep authoritative item data where your game prefers (resources, dictionaries in a script, etc.).
2. Use a **`UiStringState`** (with **`UiReactLineEdit.text_state`**) or similar as the **filter query**.
3. When the filter changes, rebuild an **`Array`** (strings and/or **`label`/`icon` dictionaries**) and call **`items_state.set_value(...)`** so the list reflects the filtered rows.
4. Reset **`selected_state`** to **`-1`** (or clamp) when the filter changes so the selection does not point at the wrong item.
5. Drive any **detail label** from **`selected_state`** + row payloads manually, or adopt **`wire_rules`** + **`UiReactWireCopySelectionDetail`** when you are ready.

The addon does not ship a generic virtualized list or a graph solver (**[`docs/ROADMAP.md`](docs/ROADMAP.md)** — **CB-010** deferred).

**Disabled / modal gating (CB-015):** Godot’s **`ItemList`** has no real **disabled** mode, and **`UiReactItemList.disabled_state`** is not wired to engine list disabling. **Canonical workaround:** place the list inside a **`Control`**, add a **full-rect transparent sibling overlay** **above** the list in tree order, and drive **`Control.mouse_filter`**: **`MOUSE_FILTER_IGNORE`** when interaction is allowed (clicks pass through), **`MOUSE_FILTER_STOP`** when the list should not receive pointer input. Prefer inspector **`action_targets`** **`SET_MOUSE_FILTER`** with **`state_watch`** on the lock bool (**`inventory_screen_demo.tscn`**).

**Runnable example:** **`res://addons/ui_react/examples/inventory_screen_demo.tscn`**.

---

## Imperative actions (command-style, CB-006)

The addon does **not** ship a generic **`UiCommand`** graph (**[`docs/ROADMAP.md`](docs/ROADMAP.md)** — **CB-007** deferred). For **bounded** shop-style math (**accumulator −= a × b** when affordable), use **`UiReactButton`** **`action_targets`** **`SUBTRACT_PRODUCT_FROM_FLOAT`** ([**`ACTION_LAYER.md`**](docs/ACTION_LAYER.md) §3.2) — implementation **`UiReactStateOpService`**.

For **other** one-shot domain actions (**equip**, **delete**, server calls), use **game-layer** code: connect **`pressed`**, read **`UiState`**, **`set_value()`** on authoritative state.

**Pitfall:** **`UiReactButton.pressed_state`** syncs the button’s pressed flag with a **`UiBoolState`**; it is **not** a general “run this command” hook.

**Confirm / equip variants** often pair with a **modal** (**CB-017**).

**Example (declarative buy):** **`res://addons/ui_react/examples/shop_computed_demo.tscn`**.

---

## Screen transitions (CB-016)

Named show/hide presets are **`UiAnimUtils.preset(preset_type, source_node, target_control, speed)`** (`scripts/api/ui_anim_utils.gd`). Typical pairing:

| `UiAnimUtils.Preset` | Typical use |
|----------------------|------------|
| **`FADE_IN`** / **`FADE_OUT`** | Panels, overlays |
| **`EXPAND_IN`** / **`EXPAND_OUT`** | Center pop emphasis |
| **`POP_IN`** / **`POP_OUT`** | Short scale pop |
| **`SLIDE_IN_LEFT`**, **`SLIDE_IN_RIGHT`**, **`SLIDE_IN_TOP`** | Enter off-screen |
| **`SLIDE_OUT_LEFT`**, **`SLIDE_OUT_RIGHT`**, **`SLIDE_OUT_TOP`** | Exit off-screen |

**Example:**

```gdscript
await UiAnimUtils.preset(UiAnimUtils.Preset.FADE_IN, self, panel).finished
```

Tune durations and defaults via **`UiAnimConstants`** when composing lower-level **`animate_*`** calls; presets wrap the common cases.

---

## Modals, popups, and focus (CB-017)

For dialogs and confirmations:

- Prefer engine nodes suited to overlay UI: **`Window`**, **`PopupPanel`**, **`AcceptDialog`**, or a full-screen **`Control`** with **`process_mode`** / **`z_index`** as needed.
- On open: move focus into the modal (**`grab_focus()`** on a **`LineEdit`** or default **`Button`**) so keyboard/gamepad users land in the right place.
- On close: **`hide()`** / queue free and return focus to the control that opened the dialog if you track it (**`Viewport.gui_get_focus_owner()`** patterns in Godot work well for simple games).

**Limitation:** A **full** focus trap (tab cycle strictly inside the modal, blocking every edge case) usually needs extra wiring or custom input filtering—not guaranteed by **`UiReact*`** alone.

Godot reference: [Popup](https://docs.godotengine.org/en/stable/classes/class_popup.html), [Window](https://docs.godotengine.org/en/stable/classes/class_window.html), [Control focus](https://docs.godotengine.org/en/stable/classes/class_control.html#class-control-method-grab-focus).

---

## When not to use a `UiReact*` wrapper (escape hatch, CB-025)

It is valid to attach a **plain** `Control` script and **manually** connect **`UiState.value_changed`** (and **`Resource.changed`**) to update widgets, then **`disconnect`** in **`_exit_tree()`**. Trade-offs:

- **Pros:** arbitrary layouts, third-party controls, one-off screens without a matching **`UiReact*`** script.
- **Cons:** more boilerplate, no **Ui React** dock binding diagnostics for that node unless you add a **`UiReact*`** later.

Use this when the charter’s **“little or no game code”** path does not fit a specific screen; keep **economy / domain rules** in your game layer anyway (**Non-goals** in **`docs/ROADMAP.md`**).

---

## Used by controls (avoid importing unless advanced)

- Internal animation modules: `scripts/internal/anim/*` (runners, families, snapshot store).
- Internal react helpers: `scripts/internal/react/*` (binding utilities, tab plumbing).

These may change between template versions; **do not rely on them from game code** unless you accept maintenance cost.

---

## Common mistakes

| Symptom | Likely cause | Fix |
|--------|----------------|-----|
| Animation never plays | Empty `animation_targets`, **Trigger** not supported on this **`UiReact*`** (dock warns), or invalid **Target** NodePath | Use a **Trigger** from the **supported triggers** table above; drag a **Control** onto Target (except **`UiReactTabContainer`** **`SELECTION_CHANGED`** tab presets). Check the **Ui React** dock and Output. |
| State doesn’t sync | State not assigned, or wrong concrete type | Assign the exported `*_state` field; use the **Ui React** dock to catch type mismatches. Use **int** for tab list indices; **float** only for range controls (slider / spin / progress); bool / String / Array as documented per control. |
| “Target not found” warning | NodePath not under this node | Use a path relative to the control, or drag the node into the Target field. |
| Tab arrays don’t apply | `tabs_state` / `disabled_tabs_state` / `visible_tabs_state` not an **Array** | Those `UiState` values must be `Array` (see Output warning). |
| Item list rows don’t update | `items_state` missing or not an **Array** | Assign `items_state` to a `UiState` / `UiArrayState` whose `value` is an `Array` (e.g. `["A", "B", 1]` — each entry is stringified for display). |
| List rows look ugly (`{ ... }`) | `items_state` dictionaries lack **`label`** / **`text`** | Use **`label`** (or **`text`**) per **List patterns (P3)**; optional **`icon`**. |
| Need a “disabled” list | **`UiReactItemList` has no `disabled_state`** (ItemList has no engine disabled flag) | Use a parent **Control**, **`mouse_filter`** overlay (**List patterns (P3)** / **CB-015**), or focus rules to block interaction; keep list visibility/text driven by state as usual. |
| Rich label never reflects typing / edits | **`UiReactRichTextLabel`** is **display-only** (state → UI only) | Update copy via **`text_state.set_value()`** (or nested/array patterns as for **`UiReactLabel`**). For two-way rich editing, use the **escape hatch** or await **`UiReactTextEdit`**. |

---

## Layout

| Path | Purpose |
|------|---------|
| `scripts/api/` | Public entry points (`UiAnimUtils`). |
| `scripts/api/models/` | Public resources (`UiState`, `UiAnimTarget`, configs). |
| `scripts/controls/` | Attachable **UiReact\*** scripts. |
| `scripts/internal/anim/` | Animation implementation (unstable for direct use). |
| `scripts/internal/react/` | Reactive helpers (unstable for direct use). |
| `examples/` | **`inventory_screen_demo.tscn`** (**`wire_rules`**, **`UiReactWireCatalogData.rows`**, **`action_targets`**, **`UiAnimTarget`**); no root script. **`options_transactional_demo.tscn`** (**`UiComputedTransactionalStatusString`**, transactional **Apply / Cancel** + **`UiReactTabContainer`**). **`shop_computed_demo.tscn`** (**`UiComputedFloatGeProductBool`** / **`UiComputedBoolInvert`** / **`UiComputedOrderSummaryThreeFloatString`**; **`action_targets`** buy; no root script). **`anim_targets_catalog_demo.tscn`** (animation catalog + trigger playground). |
| `docs/` | **[`README.md`](docs/README.md)** (map), **CHANGELOG**, **[`DECISIONS.md`](docs/DECISIONS.md)**, **[`ROADMAP.md`](docs/ROADMAP.md)**, **[`WIRING_LAYER.md`](docs/WIRING_LAYER.md)** (normative **P5** wiring), **[`ACTION_LAYER.md`](docs/ACTION_LAYER.md)** (normative **P6.1** actions). **[`AGENTS.md`](AGENTS.md)** (addon root — agent/solo checklist). |
| `editor_plugin/ui_react_component_registry.gd` | Single source of truth for script-stem → **`UiReact*`** name and per-control **`BINDINGS_BY_COMPONENT`** (edit here when adding a control; **`UiReactScannerService`** and validators consume it). |
| `editor_plugin/` | Optional Godot editor plugin: bottom dock, split **`ui_react_*_validator.gd`** modules + **`ui_react_validator_service`** façade, quick state creation. |
| `ui_resources/` | Sample `.tres` for the example scene; `plugin_generated/` holds plugin-created states (optional). |

---

## Importing into another project

Copy the entire **`addons/ui_react/`** folder into the host project’s **`addons/`** directory, reimport, then attach scripts from **`scripts/controls/`** or call **`UiAnimUtils`** from your game code.

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

The plugin **version** is declared in [`editor_plugin/plugin.cfg`](editor_plugin/plugin.cfg) (`version=` — see that file for the current number). Release history and notable changes are tracked in **[`docs/CHANGELOG.md`](docs/CHANGELOG.md)** in this addon folder (so it travels when you copy `addons/ui_react/`).

## Diagnostics layout

- The **upper issue list** shows **compact summary lines** per issue (severity prefix + short text). Full “Fix:” prose stays in the **report** area below so narrow docks stay readable.
- **Click an issue summary** to load the **report**: full issue text, fix hint, component/node/path, **Resource** (`res://` path when the issue carries `resource_path`), property metadata when applicable, and—when present—scan-time **Value type** / **Effective value** (truncated for long strings).
- **Toolbar:** **Rescan**, **Copy report**, **Fix All** (binding issues only; eligible filtered rows), and **Ignore All** (applies session **Ignore** to binding issues; adds **edited-scene** unused-file paths to the **persisted** ignore list). **Row actions:** binding rows—**Fix**, **Focus**, **Ignore**; unused-file rows (see step 4 scope)—**Reveal**, **Ignore**. Use **Copy report** to copy the filtered list using the same summary text as each row (and fix hints when present).

**Persisted per project:** scan mode, **Group** mode, severity filters, auto-refresh, state output folder, and ignored unused file paths (**`ui_react/plugin_ignored_unused_state_paths`**) are saved in **Project Settings** and restored when you reopen the project (no need to reconfigure each session).

**When diagnostics update:** the list updates when you press **Rescan**, when you open or **switch the active edited scene** tab, when **EditorFileSystem** signals filesystem changes, and—if **Auto-refresh on selection** is enabled—in **Selection** mode when the editor selection changes.

**Rescan** clears **session-only** hides (**Ignore** on binding issues). It does **not** remove paths from **`plugin_ignored_unused_state_paths`**; clear those in **Project Settings** if needed.

## Dock features

| Control | Purpose |
|--------|---------|
| **Scan** | **Selection** — selected nodes and their subtree `UiReact*` controls. **Entire scene** — all `UiReact*` nodes under the edited scene root. |
| **Group** | **Flat list**, **By node**, or **By severity** (collapsible groups). **By node:** unused-file (scene-file-scoped) `.tres` diagnostics group under **Unused state files**. |
| **Show** | Filter diagnostics by severity (Errors / Warnings / Info). |
| **Filter** | Text filter across node name, path, property, component, messages, fix hints, **resource path** (`res://` for unused-file rows), and value-type hints (debounced). Value preview body text is not searched. |
| **State output folder** | Where quick-create saves new `.tres` files. Default: `res://addons/ui_react/ui_resources/plugin_generated/`. Collision-safe names: `<NodeName>_<property>_2.tres`, `_3.tres`, … |
| **Rescan** | Run diagnostics now using the current **Scan** mode and filters; clears **session** **Ignore** on binding issues only. |
| **Copy report** | Copy the **filtered** list to the clipboard: same summary line as each row, plus **Fix:** hint when present. |
| **Reveal** | Unused-file rows only (edited saved scene scope): FileSystem dock **`navigate_to_path`** for that `.tres`. |
| **Focus** | Binding rows only: select the scene node for that issue (disabled when the row has no `node_path`). |
| **Fix** | Binding rows only: for an unassigned `*_state` with a suggested type (**Info** optional slots or **Warning** required slots), creates the typed state, saves it, assigns with **undo/redo**. |
| **Fix All** | Same as **Fix** for **every** eligible **binding** row in the **current filtered** list. |
| **Ignore** / **Ignore All** | Binding issues: hide until **Rescan**. Unused-file issues (edited scene file + output folder rule): append path to **`plugin_ignored_unused_state_paths`** (persisted). |

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
| `ui_react/plugin_ignored_unused_state_paths` | `PackedStringArray()` (empty) | `res://` paths of **scene-file-scoped** unused-file diagnostics hidden until removed from this list. |

## Binding metadata & validation

The scanner (`ui_react_scanner_service.gd`) records which exports each `UiReact*` control expects, including a **kind** hint (`bool`, `int`, `float`, `string`, `array`, ...). The validator (`ui_react_validator_service.gd`) reports **errors** when the assigned resource does not match that slot — including **`UiTransactionalState`** when its **`committed_value`** has a compatible **Variant** type for the binding (**`UiBoolState`**, **`UiFloatState`**, etc.).

### `UiReactItemList` bindings

| Export | Kind | Notes |
|--------|------|--------|
| `items_state` | `array` | Optional. When set, **`UiArrayState`** **`value`** should be an **Array**; each element is displayed with `str()`. Non-array values are ignored at runtime (with a warning). |
| `selected_state` | `int` (suggested) | Single-select: **`UiIntState`** (**`int`** indices only, including `-1`). Multi-select: **`UiArrayState`** with **`Array`** of **`int`** indices. **`float` / `UiFloatState` are not supported** for selection sync. |
| `disabled_state` | `bool` | Optional; reserved for API consistency. |

Use **`UiArrayState`** for `items_state` so inspector intent and diagnostics line up.

## Architecture (for contributors)

- `ui_react_editor_plugin.gd` — `EditorPlugin` entry; registers the dock.
- `dock/ui_react_dock.gd` — Dock UI, refresh orchestration, editor signal wiring.
- `models/ui_react_diagnostic_model.gd` — `DiagnosticIssue`, **IssueKind** (`GENERIC` vs `UNUSED_STATE_FILE`), **`resource_path`** for file-scoped rows.
- `services/ui_react_scanner_service.gd` — Finds `UiReact*` nodes and binding metadata.
- `services/ui_react_validator_service.gd` — Emits binding `DiagnosticIssue` rows (mirrors runtime validation rules where practical).
- `services/ui_react_state_reference_collector.gd` — Collects `res://` paths of `UiState` resources referenced by bindings (including `tab_config`).
- `services/ui_react_scene_file_resource_paths.gd` — Parses the edited scene’s saved `.tscn` text for `res://` substrings (candidate paths for unused-state detection).
- `services/ui_react_unused_state_service.gd` — Emits **unused** `.tres` INFO rows: **intersection** of output-folder `UiState` files, paths present in the saved scene file, and **not** referenced by Ui React on the edited tree.
- `services/ui_react_state_factory_service.gd` — Creates typed states and saves them to disk.
- `dock/ui_react_dock_config.gd` — ProjectSettings keys and load/save for dock preferences.
- `controllers/ui_react_action_controller.gd` — Wraps `EditorUndoRedoManager` property changes.

**Planning docs:** phased capability backlog for this addon lives in **[`docs/ROADMAP.md`](docs/ROADMAP.md)**; the **P5** wiring contract is **[`docs/WIRING_LAYER.md`](docs/WIRING_LAYER.md)**; the **P6.1** action contract is **[`docs/ACTION_LAYER.md`](docs/ACTION_LAYER.md)**. A hosting repository may add its own root roadmap separately.

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

# Ui React — Wiring layer (normative)

**Status:** Normative specification for **Phase P5** (wiring layer). Runtime implementation **must** conform to this document until a superseding revision is recorded in [`CHANGELOG.md`](CHANGELOG.md) and Charter in [`ROADMAP.md`](ROADMAP.md).

**Charter (one line):** Ui React adds a first-class, inspector-authored **wiring layer**—a **`UiReactWireRuleHelper`** plus a **family of narrow `UiReactWireRule` resources** and **per-control `wire_rules` entry points**—so framework-level orchestration is explicit, serializable, and teachable; the **P5.2** dock editor is optional convenience on the **same** resource model.

### Editor: Dependency Graph (designer path)

**Recommended:** Use the **Ui React** dock **Wiring** tab (**CB-058**) — **Dependency Graph** + **`wire_rules`** list — as the **primary** place to **see** scoped **`wire_rules`**-related flow alongside bindings and computeds, and to **author** changes that touch **`wire_rules`**—**provided** the graph exposes that operation—using the **same** **`Array[UiReactWireRule]`** commits as the **Inspector** (**DRY**; no parallel format). **Inspector** remains **fully authoritative** for every field for authors who prefer not to use the graph. Roadmap intent and sequencing: [`ROADMAP.md`](ROADMAP.md) Part I **North star** and **Visual wiring graph**.

---

## 1. Problem statement

Root-node **orchestration scripts** (`_ready`, manual `connect`, ad-hoc filtering) are **not** the long-term recommended pattern for **official examples** or for authors who want scenes to read as **nodes + resources**. **Glue** (“tree index → kind string”, “filter + catalog → item rows”, “selection → detail text”) **belongs** in the **wiring layer** as **inspectable rules**, not scattered logic.

---

## 2. Three-layer model

| Layer | Responsibility | What ships |
|-------|----------------|------------|
| **Controls** | Bind UI ↔ `UiState`, emit known signals / lifecycle | `UiReact*` |
| **State** | Hold truth, drafts, commits, computed payloads | `Ui*` states, transactional, computed |
| **Wiring** | When X changes, update Y (paths, small transforms, UI-side reactions) | `UiReactWireRuleHelper` + `UiReactWireRule` |

Wiring **observes** sources and **writes** target state (or triggers documented side effects). It **does not** replace control bindings or reimplement transactional commit semantics.

```mermaid
flowchart TB
  Controls[Controls_UiReact]
  State[State_UiStar]
  Wiring[Wiring_HelperAndRules]
  Controls --> State
  Wiring --> State
  Wiring -.->|"observe trigger sources"| Controls
```

**Actions (P6.1):** Inspector **`action_targets`** on the **§5** control set—including **`UiReactOptionButton`** and **`UiReactTabContainer`**—(and **`UiReactButton`** / **`UiReactTextureButton`** per [`ACTION_LAYER.md`](ACTION_LAYER.md) §4) drives **non-motion** UI behavior: **presentation** (focus, visibility, **`Control.mouse_filter`**, narrow UI **`UiBoolState`** flags) **and bounded** **`UiFloatState`** mutations (e.g. **`SUBTRACT_PRODUCT_FROM_FLOAT`** — see [`ACTION_LAYER.md`](ACTION_LAYER.md)). Normative contract: [`ACTION_LAYER.md`](ACTION_LAYER.md). **Wiring** still owns **`UiStringState`** catalog/filter/detail data transforms (**§2**); **Actions** must not duplicate those jobs.

---

## 3. `UiReactWireRuleHelper` contract

- **Kind:** `RefCounted` helper (`class_name UiReactWireRuleHelper`), **not** a scene node.
- **Registration:** Each **`UiReact*`** host that exports **`wire_rules`** calls **`UiReactHostWireTree.on_enter(self)`** from **`_enter_tree`** and **`UiReactHostWireTree.on_exit(self)`** from **`_exit_tree`** ([`ui_react_host_wire_tree.gd`](../scripts/internal/react/ui_react_host_wire_tree.gd) — thin wrappers over **`UiReactWireRuleHelper.schedule_attach`** / **`detach`**). **`schedule_attach`** no-ops when there are no enabled rules; otherwise it defers **`attach`** to the next **`SceneTree.process_frame`** (same “after frame” intent as the prior deferred registration path).
- **Per-host scope:** **`attach`** runs only the **`wire_rules`** array on **that** node. It **does not** walk the scene or merge other nodes’ rules.
- **Ordering:** Within one host, rules run in **array index order**: **bind all** enabled rules, then **apply all** enabled rules. **Cross-host** synchronous order is **undefined**; correctness must follow **state / dataflow** (each rule reads canonical `UiState`), not reliance on which control’s rules run first.
- **Subresource policy:** **One `UiReactWireRule` instance per host**—do not assign the **same** rule object to **`wire_rules`** on two different nodes (dock **warning** when the same instance appears on two hosts).
- **Teardown:** **`detach`** disconnects every signal / callback recorded for that host; **no** leaks.
- **Logging:** Warnings use the prefix **`UiReactWireRuleHelper:`** (e.g. rule skipped, trigger mismatch).

---

## 4. `UiReactWireRule` base contract

- **Base type:** `Resource`, abstract **`UiReactWireRule`** (name fixed for public API; **CB-039** SemVer).
- **Serializable:** All fields must round-trip in `.tscn` / `.tres`.
- **Minimum fields (normative intent):** `rule_id: String` (diagnostics), `enabled: bool` default `true`. Concrete sources/targets (node paths, state refs) are defined on **subclasses**.
- **No mega-struct:** **No** single “kitchen sink” reaction type. **Many narrow** subclasses (**CB-033**).

---

## 5. Per-control `wire_rules` export

Each `UiReact*` that can **source** wires exposes **at most one** additional export:

`wire_rules: Array[UiReactWireRule]`  

(Exact typed array when Godot permits; until then: documented as array of `UiReactWireRule`.)

**P5.1 control set** (controls **without** `wire_rules` stay **Appendix-promoted**; see matrix in [`ROADMAP.md`](ROADMAP.md) Part I **Inspector surface matrix (CB-052)**):

### Wire rule trigger storage

[`UiReactWireRule`](../scripts/api/models/ui_react_wire_rule.gd) stores [member UiReactWireRule.trigger] as an integer matching [enum UiReactWireRule.TriggerKind]. The numeric values (`WIRE_TRIGGER_*` constants in that file) are **stable on disk** for existing scenes and resources. They **overlap** with some [enum UiAnimTarget.Trigger] values for historical authoring convenience, but **`trigger` on other resource types** (for example [member UiReactActionTarget.trigger]) is **not** guaranteed to use the same numbering—treat wire triggers as **wire-layer storage**, not a universal trigger enum.

| Control | Allowed wire rule triggers ([`UiReactWireRule.TriggerKind`](../scripts/api/models/ui_react_wire_rule.gd); storage codes `WIRE_TRIGGER_*` in the same file) |
|---------|-------------------------------------------------------------------------------|
| `UiReactItemList` | `SELECTION_CHANGED` (`6`) for §5 rules that bind list selection (`HOVER_*` remain animation-only on the control). |
| `UiReactTree` | `SELECTION_CHANGED` (`6`) for tree-sourced rules. |
| `UiReactLineEdit` | `TEXT_CHANGED` (`5`), `TEXT_ENTERED` (`13`) for line-edit–sourced rules (`FOCUS_*` / `HOVER_*` remain animation-only unless promoted later). |
| `UiReactCheckBox` | Checkbox/toggle as implemented for wiring (see control script). |
| `UiReactOptionButton` | `SELECTION_CHANGED` (`6`) via `item_selected` (`HOVER_*` remain animation-only unless promoted later). **`UiReactWireCopySelectionDetail`** / **`SetStringOnBoolPulse`** use **`UiIntState`** `selected_state` on the rule when row lookup is by index; host’s **`selected_state`** export is **`UiStringState`**—use a **separate** **`UiIntState`** for those rules if needed. |
| `UiReactTabContainer` | `SELECTION_CHANGED` (`6`) via `tab_selected`. Authors may assign the **same** **`UiIntState`** instance as the tab **`selected_state`** export to **`CopySelectionDetail.selected_state`**. Rules run on user **`tab_selected`**; programmatic `current_tab` changes do **not** re-fire `tab_selected`—rely on **`selected_state.changed`** on rules that subscribe to it, or a follow-up if a screen needs parity (**YAGNI**). |

---

## 6. MVP concrete rule types (P5.1)

These concrete subclasses ship in the wiring implementation (**capabilities** fixed; field names may vary slightly in code):

1. **`UiReactWireMapIntToString`** — Map an integer source (e.g. tree `selected_state` index) to a **`UiStringState`** via an **editor-authored map** (replaces “tree index → kind” glue).
2. **`UiReactWireRefreshItemsFromCatalog`** — When filter string + optional category string + **catalog reference** change, write **`UiArrayState`** line payloads. **Catalog data lives in the game project** (Resource or documented constant resource); the addon does **not** ship game catalogs (**Non-goals**). Official **`inventory_screen_demo`** stores demo rows on **`UiReactWireCatalogData.rows`** in the scene—no separate demo **`RefCounted`** const.
3. **`UiReactWireCopySelectionDetail`** — When list selection / items / optional suffix change, format **`UiStringState`** detail text. Optional **`suffix_note_state`** merges a second line; **`clear_suffix_on_selection_change`** (default **true**) clears that suffix when **`selected_state`** changes so transient notes do not stick across rows (helper clears before recomputing detail).
4. **`UiReactWireSetStringOnBoolPulse`** — On **`UiBoolState.value_changed`**, optionally on a **rising edge** to `true`, writes **`UiStringState`** using **`{name}`**, **`{kind}`**, **`{qty}`** placeholders resolved from **`selected_state`** + **`items_state`** (same row dictionaries as copy-detail). Use **`template_no_selection`** when you need a fallback when no row / no name (e.g. **Use**); use **`template_rising`** alone for a fixed line (e.g. **Sort**).
5. **`UiReactWireSyncBoolStateDebugLine`** — Writes **`line_prefix` + `str(bool_state.get_value())`** into a **`UiStringState`** when the bool changes (and once when wires register). For **readout** / demo labels; bind a **`UiReactLabel.text_state`** to the same **`UiStringState`**.
6. **`UiReactWireSortArrayByKey`** — Reorders **`items_state`** when **`items_state`**, **`sort_key_state`**, or optional **`descending_state`** change. **`sort_key_state`** holds the **flat dictionary key** to compare (e.g. `name`, `qty`); **empty** after trim → **no-op** (no `set_value`). **Dictionary** rows compare **`row[key]`** (missing key → `null`, ordered before non-null values in the built-in compare); **non-dictionary** rows compare **`str(a)`** vs **`str(b)`**. **Descending:** when **`descending_state`** is set, **`true`** reverses order after an ascending sort. **Trigger** is ignored for binding—this rule is **state-driven** only (`Resource.changed` on the listed states). **Rule order:** on the **`UiReactItemList`** host, list **`UiReactWireSortArrayByKey` before** **`UiReactWireCopySelectionDetail`** (and similar) so detail/suffix rules see **sorted** rows on the initial **`attach`** pass. Place catalog **`UiReactWireRefreshItemsFromCatalog`** on **filter/tree** hosts **before** this rule in the **authoring** sense: refresh writes **`items_state`**, then this rule’s dependency on **`items_state.changed`** runs sort. **Selection:** resorting does **not** remap **`UiIntState`** selection to the same logical row—authors may clamp, clear, or track by id in game code. **Ties:** equal keys may reorder between frames; do not rely on stable ordering for ties unless you add game-side tie-breakers.

### 6.1 Recipes (no root glue script)

- **Transient suffix under detail:** **`UiReactWireCopySelectionDetail`** with **`suffix_note_state`** + **`clear_suffix_on_selection_change`**. Optionally add **`UiReactWireSetStringOnBoolPulse`** rules that write the **same** **`suffix_note_state`** from action **`UiBoolState`**s (rising edge).
- **Bool pulse feedback:** One **`UiReactWireSetStringOnBoolPulse`** per pulse source; point **`target_string_state`** at the suffix (or any **`UiStringState`**).
- **Debug bool snapshot:** **`UiReactWireSyncBoolStateDebugLine`** + **`UiReactLabel`** + **`text_state`**.
- **Sort filtered rows:** After **`UiReactWireRefreshItemsFromCatalog`** fills **`items_state`**, add **`UiReactWireSortArrayByKey`** on the **`UiReactItemList`** (same **`items_state`**, **`sort_key_state`** bound to your sort key—e.g. **`UiStringState`** driven by an **`UiReactOptionButton`** whose item **text** matches row **keys**, or game-mapped strings).

Official **`inventory_screen_demo`** uses only **`wire_rules`** on **`UiReact*`** nodes—**no** scene root script; **`UiReactWireRuleHelper`** runs on each host (**refresh**, **sort**, **copy detail**, suffix, debug).

---

## 7. Interaction with computed and transactional

- Wires **may read** computed or transactional **state** values.
- Wires **must not** replace **`UiReactComputedService`** wiring for computed **`sources`** (computed resources are bound via **`UiReact*`** exports, not **`wire_rules`**).
- Wires **must not** replace **`UiTransactionalGroup`** / **Apply** / **Cancel** semantics.
- Wires **may** listen to `UiBoolState` (e.g. lock toggles) for **UI-only** side effects.

---

## 8. Diagnostics (P5.1) and dock authoring (P5.2)

**`wire_rules` row validation** (MVP rule types §6): missing / wrong-type **`@export`** state or **`catalog`** refs → **warning** (`UiReactValidatorService`).

**Dependency Graph — Selected wire rule:** the details pane **Checks** row shows the same **`UiReactWiringValidator.validate_wire_rules`** issues as **Diagnostics**, filtered to the selected `wire_rules` index (see [`UiReactDockWireDetails`](../editor_plugin/dock/ui_react_dock_wire_details.gd)). **Cross-node duplicate instance** checks (`validate_wiring_under_root`) stay in the **Diagnostics** list only until issues gain structured rule-instance linkage.

**Cross-node duplicate rule:** the same **`UiReactWireRule`** instance **reference** on **`wire_rules`** of **two different nodes** → **dock warning** (see §3).

**Unused `UiState` `.tres` diagnostics:** `UiState` resources referenced **only** inside `wire_rules` subresources are counted as used (`UiReactStateReferenceCollector`).

**Apply/Cancel** wiring for **`UiTransactionalGroup`** uses **`UiReactButton`** / **`UiReactTextureButton`** (**`transactional_*`** exports + **`UiReactTransactionalSession`**). Footer-only **`wire_rules`** without a motion host stay on **`UiReactTabContainer`**, **`UiReactOptionButton`**, or other §5 controls—the **`Button`** matrix row does not ship **`wire_rules`**. The dock runs **`validate_transactional_under_root`** for duplicate Apply/Cancel roles and related cohort checks.

**Follow-up** (optional backlog): invalid `NodePath` targets when future rules use paths. Stock-take: [`P5_CURRENT_STATE_AUDIT.md`](P5_CURRENT_STATE_AUDIT.md).

**P5.2 — Wire rules UI (editor):** The **Ui React** bottom dock **Wiring** tab includes a **`wire_rules`** list (right split) for the **single** selected §5 host, adds concrete rules from the §6 set, removes/duplicates/reorders entries with **Undo**, and **Inspect rule** opens the Inspector on the same embedded **`UiReactWireRule`** subresources—**no** second on-disk format (**CB-035**). A **Quick edit** strip under the list edits an allowlisted subset of rule fields (**`rule_id`** and a few strings/bools on selected concrete types); full editing remains in the **Inspector**.

---

## 9. Phasing

| Milestone | Contents |
|-----------|----------|
| **P5.1** | `UiReactWireRuleHelper`; `UiReactWireRule` + concrete rules (§6); `wire_rules` on §5 control set; dock diagnostics per §8; **`inventory_screen_demo`** is **inspector-only** (no root glue script). |
| **P5.2** | Dock **form** UI (rule list + **Inspect**) that edits **only** existing `UiReactWireRule` subresources—**no second on-disk format** (**CB-035**). A **graph** view remains optional backlog if ever needed. |

---

## 10. Explicit non-wiring

The following stay **outside** the wiring core: **pricing**, **loot tables**, **crafting recipes**, **network I/O**, and other **game domain** rules. **Escape hatch:** plain `Control` + manual `UiState` binding per README.

---

## 11. SOLID / DRY / KISS / YAGNI (implementation discipline)

- **SRP:** Helper = bind/unbind per host; each rule class = one job; controls = bindings + lifecycle hooks.
- **DRY:** One helper, one rule base type; no parallel “wire services.”
- **KISS:** Ship three concrete rule types before adding more.
- **YAGNI:** No autoload for P5.1 wiring; no generic graph **solver** language in v1 wiring; no second resource file format.

# Editor copy — voice and tone (solo designer)

Use this guide for **any user-visible string** in the Ui React **editor plugin**: Diagnostics (`issue_text`, `fix_hint`), Wiring wire-rule details, graph hints, menus, tooltips, and `push_warning` / `push_error` messages.

**Audience:** Someone using the **Inspector** and the **Ui React** dock—not reading GDScript.

---

## Rules

1. **Issue line (`issue_text` in diagnostics)**  
   One short sentence, **problem first**. Say **where** before **type** when it helps (“On this control’s **Wire rules** row 2, …”). Prefer Godot words they already see: **Inspector**, **Wire rules**, **scene**, **resource**.  
   Avoid implementation jargon (`apply()`, `Callable`, `NodePath`) in the **primary** sentence unless the user must act on that exact token.

2. **Fix line (`fix_hint`)**  
   Start with a **single imperative** they can do without opening scripts: “In the **Inspector**, assign …”, “Click **Rescan** after …”. Optional second short clause only if it removes ambiguity.

3. **Summary line (Diagnostics list)**  
   Built automatically as `Component / Node — issue_text` when the component name is set. Keep `issue_text` readable **on its own**; do not repeat the component name inside `issue_text` unless it avoids confusion.

4. **Technical names**  
   `wire_rules`, `UiIntState`, etc. are fine when they match the Inspector. Optionally add plain words once: “integer selection state (**UiIntState**)”. Do **not** paste URLs or “see §…” into dock strings—normative detail stays in **WIRING_LAYER** / **ACTION_LAYER**.

5. **`push_warning` / `push_error`**  
   Keep the **`Ui React:`** prefix. Two beats: **what happened** + **what to try next**. No stack-trace tone.

---

## Wiring details pane (Wiring tab)

The Wiring tab **details** column uses BBCode in the dock and a **plain-text** twin for clipboard copy. Structural helpers live in **`UiReactDockExplainDetailsPresenter`** (`details_run_in_bb_plain`, `details_block_head_bb_plain`, `details_append_major`).

**Section titles** (run-in titles and block headings): **Title Case**. Keep proper nouns and API tokens as written (`UiState`, `UiReact*`, `UiComputed*`). Copy **menu item titles verbatim** when you quote a context-menu action (e.g. `Rebind computed source…`).

**Body prose** (paragraphs, italic notes, placeholder help): **Sentence case**. Prefer **Inspector** vocabulary—for example **Wire rules** as the row users open. Use `[code]wire_rules[/code]` in BBCode when you mean the **exported property name**.

**Run-in vs block:** Use **`details_run_in_bb_plain`** only for **single-line** summaries (one title + one short clause). Use **`details_block_head_bb_plain`** plus following lines when the section has **multiple sentences**, **bullets**, or **label/value rows**.

**Bullets:** Each item starts with **`• `** (bullet, space).

**Separators:** **`→`** marks a directed pair (flow). **` — `** (spaced em dash) is a clause break or qualifier (e.g. `— unbound`). **`:`** separates a **label** from its **value** in wire-rule report rows (`Label: value`). For scannable **Wire rules** summaries in the graph details, use a line readers can parse at a glance—for example: **`• Rule %d (%s). In: %s. Out: %s.`** (use **`—`** for an empty in/out side).

**Spacing:** Single spaces around **`→`**. Prefer spaced em dashes in prose (**`scope — click`**).

**BBCode ↔ plain:** Every `_set_details_both(bb, plain)` path must carry the **same meaning** in plain as in BBCode; strip tags for plain where you hand-write both strands.

---

## Before / after examples

### Wiring (Diagnostics-only issues)

**Before**

- `issue_text`: `detail_state is required.`  
- `fix_hint`: `Assign UiStringState.`

**After**

- `issue_text`: `This rule’s detail line has nowhere to write text (detail line state is missing).`  
- `fix_hint`: `In the Inspector, open this control’s **Wire rules** row and assign a **UiStringState** (or compatible) to **detail state**.`

*(When emitted via `_wire_rules_issue`, the line still begins with `wire_rules[N]:` for filtering—only the part **after** that prefix is phrased in plain language, or keep the suffix short if space is tight.)*

### Tree data (Diagnostics)

**Before**

- `issue_text`: `tree_items_state is not assigned.`  
- `fix_hint`: `Assign a UiArrayState whose value is an Array of UiReactTreeNode.`

**After**

- `issue_text`: `This tree has no **Tree items state** assigned, so it cannot load rows.`  
- `fix_hint`: `In the Inspector, assign **Tree items state** to a **Ui Array State** whose value is an array of **Ui React Tree Node** resources.`

---

## Checklist before merge

- [ ] Would a designer know **which dock tab** and **which Inspector row** to touch?  
- [ ] Is the **fix** one clear action?  
- [ ] No “see CB-…” as the only guidance.  
- [ ] Wiring issues that must appear in the graph details row still use the `wire_rules[N]:` prefix where required by the filter.

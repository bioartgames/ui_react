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

## Before / after examples

### Wiring (Diagnostics + wire-rule “Checks” row)

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

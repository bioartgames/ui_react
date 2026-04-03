# P5 current-state audit (stock-take)

**Purpose:** Doc-driven pass/fail checklist for **P5.1** exit honesty and gates for **P5.1.b** / **P5.2**. Authority: [`WIRING_LAYER.md`](WIRING_LAYER.md) → [`ROADMAP.md`](ROADMAP.md) → [`CHANGELOG.md`](../CHANGELOG.md).

**Last run:** 2026-04-03 (post–**2.7.0** CB-034 + ui_react hardening batch).

Scoring: **PASS** | **PARTIAL** | **FAIL** | **N/A**.

---

## A. P5.1 core — implementation vs normative spec

| # | Result | Notes |
|---|--------|-------|
| A1 Runner exists | **PASS** | `class_name UiReactWireRunner` in `scripts/controls/ui_react_wire_runner.gd`. |
| A2 Rule base + MVP types | **PASS** | `UiReactWireRule` + map / refresh / copy + `UiReactWireCatalogData` under `scripts/api/models/ui_react_wire_*.gd`. |
| A3 `wire_rules` on §5 set | **PASS** | Five controls export `Array[UiReactWireRule]`: ItemList, Tree, LineEdit, CheckBox, TransactionalActions. |
| A4 One runner / warnings | **PASS** | Runtime warning if multiple runners under `current_scene`; dock warns on duplicate runners. |
| A5 Collection scope | **PASS** | [`WIRING_LAYER.md`](WIRING_LAYER.md) §3 documents **parent-of-runner** subtree (aligned with `get_parent()` walk in code). |
| A6 Deterministic ordering | **PARTIAL** | Stable sort uses node path + rule index + `rule_id`; spec text mentions `resource_path_or_uid` — equivalent intent, different tuple. |
| A7 Teardown | **PASS** | `_exit_tree` disconnects registered callables. |
| A8 Catalog lazy load | **PASS** | `ensure_rows_loaded()` on catalog; refresh rule calls it before filtering. |

---

## B. Example migration (CB-037)

| # | Result | Notes |
|---|--------|-------|
| B1 Scene uses runner + rules | **PASS** | `inventory_screen_demo.tscn`: `WireRunner` + `wire_rules` on tree / filter / list. |
| B2 Root script within exception | **PASS** | `inventory_screen_demo.gd`: tree build, demo Use/Sort + `detail_note_state`, debug labels — no parallel filter/list/detail **data** orchestration. |
| B3 ROADMAP checkbox drift | **RESOLVED** | See [`ROADMAP.md`](ROADMAP.md) P5.1 — migration line marked complete with same exception note. |

---

## C. Diagnostics (CB-034)

| # | Result | Notes |
|---|--------|-------|
| C1 Missing runner | **PASS** | `_validate_wiring_scope`: WARN when `wire_rules` present and no runner. |
| C2 Duplicate runner | **PASS** | Same: WARN when `runners > 1`. |
| C3 Rule export validation | **PASS** | Dock validates MVP rule types: required refs + expected `UiState` / `UiReactWireCatalogData` types (`UiReactWiringValidator.validate_wire_rules`, invoked from the **`UiReactValidatorService`** façade). |
| C4 Scanner / unused-file parity | **PASS** | Stem map + **`BINDINGS_BY_COMPONENT`** live in **`UiReactComponentRegistry`**; **`UiReactScannerService`** resolves component names on nodes. **`UiReactTransactionalActions`** is listed in the registry like other **`UiReact*`** controls. **`UiReactStateReferenceCollector`** uses the same registry for binding paths and registers `UiState` refs from **`wire_rules`**. Future **NodePath**-on-rules (if any) remains follow-up. |
| C5 Runtime vs editor | **PASS** | Both paths surface duplicate-runner concerns; missing runner is editor-first. |

**Interpretation:** **CB-034** (P5.1 editor scope) is **Done**; **CB-041** hub placement is the remaining wiring diagnostic milestone before optional hub authoring.

---

## D. Release / appendix hygiene

| # | Result | Notes |
|---|--------|-------|
| D1 CHANGELOG | **PASS** | **2.7.0** documents P5.1 wiring + **CB-034** completion. |
| D2 Appendix CB-032 / CB-033 / CB-034 | **RESOLVED** | [`ROADMAP.md`](ROADMAP.md) Appendix: **CB-034** **Done** for P5.1 scope; **CB-041** open. |

---

## E–F. Gates: P5.1.b and P5.2

| Milestone | Ready? | Condition |
|-----------|--------|-----------|
| **P5.1.b** (`UiReactWireHub`, **CB-041**) | **Yes (engineering start)** | A/B/C **PASS** for current scope; hub + placement validator **not** built (**CB-041**). |
| **P5.2** (dock rule editor, **CB-035**) | **Proceed** | MVP rule exports are dock-validated; future **NodePath**-on-rules may warrant more checks before graph UX. On-disk model remains **only** `UiReactWireRule` subresources (**PASS**). |

---

## G. Manual smoke

1. Run `inventory_screen_demo.tscn` (project main scene).
2. Tree category → list populates; filter edits list; selection updates detail.
3. List lock toggle → `action_targets` still behave (regression guard for adjacent layers).

---

## Summary

| Goal | Status |
|------|--------|
| **P5.1 core runtime** | **PASS** |
| **inventory_screen_demo migration (exception)** | **PASS** |
| **Dock wiring diagnostics (CB-034 P5.1)** | **PASS** |
| **Start P5.1.b** | **Unblocked** (**CB-041**) |
| **Start P5.2** | **Unblocked**; optional follow-up if new rule shapes add paths |

Re-run this file after major wiring changes; update “Last run” date and §A–§C tables if behavior shifts.

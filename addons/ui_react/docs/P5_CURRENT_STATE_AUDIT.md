# P5 current-state audit (stock-take)

**Purpose:** Doc-driven pass/fail checklist for **P5.1** exit honesty and gate for **P5.2**. Authority: [`WIRING_LAYER.md`](WIRING_LAYER.md) → [`ROADMAP.md`](ROADMAP.md) → [`CHANGELOG.md`](../CHANGELOG.md).

**Last run:** 2026-04-06 (decentralized wiring: **`UiReactWireRuleHelper`**, removal of **`UiReactWireRunner`**; dock duplicate cross-node rule warning).

Scoring: **PASS** | **PARTIAL** | **FAIL** | **N/A**.

---

## A. P5.1 core — implementation vs normative spec

| # | Result | Notes |
|---|--------|-------|
| A1 Helper exists | **PASS** | `class_name UiReactWireRuleHelper` in `scripts/internal/react/ui_react_wire_rule_helper.gd`. |
| A2 Rule base + MVP types | **PASS** | `UiReactWireRule` + map / refresh / copy-detail / bool-pulse / debug-line + `UiReactWireCatalogData` under `scripts/api/models/ui_react_wire_*.gd`. |
| A3 `wire_rules` on §5 set | **PASS** | Seven controls export `Array[UiReactWireRule]`: ItemList, Tree, LineEdit, CheckBox, OptionButton, TabContainer, TransactionalActions ([`ROADMAP.md`](ROADMAP.md) matrix / **CB-052**). |
| A4 Per-host registration | **PASS** | Hosts call `schedule_attach` / `detach` from `_enter_tree` / `_exit_tree`; attach deferred to next `process_frame`. |
| A5 Collection scope | **PASS** | [`WIRING_LAYER.md`](WIRING_LAYER.md) §3: only the host’s own `wire_rules` array. |
| A6 Cross-host ordering | **N/A** | Intentionally **undefined**; local array order + state/dataflow per spec. |
| A7 Teardown | **PASS** | `_exit_tree` → `detach` disconnects registered callables on that host. |
| A8 Catalog lazy load | **PASS** | `ensure_rows_loaded()` on catalog; refresh rule calls it before filtering. |

---

## B. Example migration (CB-037)

| # | Result | Notes |
|---|--------|-------|
| B1 Scene uses rules on controls | **PASS** | `inventory_screen_demo.tscn`: `wire_rules` on tree / filter / list; no `WireRunner` node. |
| B2 No root glue script | **PASS** | `inventory_screen_demo.tscn` only: **`wire_rules`** on list (copy-detail, bool-pulse suffix, debug lines); tree from **`tree_items_state`**. |
| B3 ROADMAP checkbox drift | **RESOLVED** | See [`ROADMAP.md`](ROADMAP.md) P5.1 — migration line marked complete with same exception note. |

---

## C. Diagnostics (CB-034)

| # | Result | Notes |
|---|--------|-------|
| C1 Cross-node duplicate rule | **PASS** | `validate_wiring_under_root`: WARN when the same `UiReactWireRule` instance appears on two different nodes. |
| C2 Rule export validation | **PASS** | Dock validates concrete rule types (§6): required refs + expected `UiState` / `UiReactWireCatalogData` types (`UiReactWiringValidator.validate_wire_rules`, invoked from the **`UiReactValidatorService`** façade). |
| C3 Scanner / unused-file parity | **PASS** | Stem map + **`BINDINGS_BY_COMPONENT`** live in **`UiReactComponentRegistry`**; **`UiReactScannerService`** resolves component names on nodes. **`UiReactTransactionalActions`** is listed in the registry like other **`UiReact*`** controls. **`UiReactStateReferenceCollector`** uses the same registry for binding paths and registers `UiState` refs from **`wire_rules`**. Future **NodePath**-on-rules (if any) remains follow-up. |
| C4 Runtime vs editor | **PASS** | Editor-first validation for duplicate rule refs; per-rule export issues. |

**Interpretation:** **CB-034** (P5.1 editor scope) **Done**. **CB-041** (hub) **Wont** — superseded by per-host helper.

---

## D. Release / appendix hygiene

| # | Result | Notes |
|---|--------|-------|
| D1 CHANGELOG | **PASS** | Unreleased + historical entries; **2.7.0** documents earlier P5.1 wiring ship. |
| D2 Appendix CB-032 / CB-033 / CB-034 | **RESOLVED** | [`ROADMAP.md`](ROADMAP.md) Appendix: **CB-041** **Wont**. |

---

## E–F. Gate: P5.2

| Milestone | Ready? | Condition |
|-----------|--------|-----------|
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
| **inventory_screen_demo fully wired** | **PASS** |
| **Dock wiring diagnostics (CB-034 P5.1)** | **PASS** |
| **Start P5.2** | **Unblocked**; optional follow-up if new rule shapes add paths |

Re-run this file after major wiring changes; update “Last run” date and §A–§C tables if behavior shifts.

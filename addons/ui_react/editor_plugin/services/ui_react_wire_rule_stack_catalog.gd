## Curated multi-rule [UiReactWireRule] **stacks** for the editor [code]CB-063[/code] — static recipes only, no on-disk author library in MVP.
## Mirrors the pattern of [UiReactWireRuleCatalog]; use [method instantiate_stack] to append a stack in one undo step from the Wire → Stacks RMB path.
class_name UiReactWireRuleStackCatalog
extends Object


static func stack_entries() -> Array[Dictionary]:
	return [
		{&"label": &"Inventory detail", &"about": "Sort, copy detail, suffix pulse.", &"id": &"inv_detail"},
		{&"label": &"Filter, sort, detail", &"about": "Refresh from catalog, sort, copy detail.", &"id": &"filter_sort_detail"},
		{&"label": &"Catalog list", &"about": "Refresh from catalog, copy detail.", &"id": &"catalog_list"},
	]


## Returns a new [UiReactWireRule] for each step; [member UiReactWireRule.rule_id] is set. State references are left empty for guided fill.
static func instantiate_stack(idx: int) -> Array[UiReactWireRule]:
	var entries := stack_entries()
	if idx < 0 or idx >= entries.size():
		return []
	var stack_id: StringName = entries[idx][&"id"] as StringName
	match String(stack_id):
		"inv_detail":
			return _stack_from_rules([_make_inv_sort(), _make_inv_copy_detail(), _make_inv_suffix_pulse()])
		"filter_sort_detail":
			return _stack_from_rules([_make_fsd_refresh(), _make_fsd_sort(), _make_fsd_copy_detail()])
		"catalog_list":
			return _stack_from_rules([_make_cl_refresh(), _make_cl_copy_detail()])
		_:
			return []


static func _stack_from_rules(rules: Array) -> Array[UiReactWireRule]:
	var out: Array[UiReactWireRule] = []
	for r in rules:
		if r is UiReactWireRule:
			out.append(r as UiReactWireRule)
	return out


static func _make_inv_sort() -> UiReactWireRule:
	var r: UiReactWireRule = UiReactWireSortArrayByKey.new()
	r.rule_id = "inv_sort"
	return r


static func _make_inv_copy_detail() -> UiReactWireRule:
	var r: UiReactWireRule = UiReactWireCopySelectionDetail.new()
	r.rule_id = "inv_copy_detail"
	return r


static func _make_inv_suffix_pulse() -> UiReactWireRule:
	var r: UiReactWireRule = UiReactWireSetStringOnBoolPulse.new()
	r.rule_id = "inv_suffix_pulse"
	return r


static func _make_fsd_refresh() -> UiReactWireRule:
	var r: UiReactWireRule = UiReactWireRefreshItemsFromCatalog.new()
	r.rule_id = "fsd_refresh"
	return r


static func _make_fsd_sort() -> UiReactWireRule:
	var r: UiReactWireRule = UiReactWireSortArrayByKey.new()
	r.rule_id = "fsd_sort"
	return r


static func _make_fsd_copy_detail() -> UiReactWireRule:
	var r: UiReactWireRule = UiReactWireCopySelectionDetail.new()
	r.rule_id = "fsd_copy_detail"
	return r


static func _make_cl_refresh() -> UiReactWireRule:
	var r: UiReactWireRule = UiReactWireRefreshItemsFromCatalog.new()
	r.rule_id = "cl_refresh"
	return r


static func _make_cl_copy_detail() -> UiReactWireRule:
	var r: UiReactWireRule = UiReactWireCopySelectionDetail.new()
	r.rule_id = "cl_copy_detail"
	return r

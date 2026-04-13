## Concrete [UiReactWireRule] script list for Add menus (**[code]CB-035[/code]**, **[code]CB-058[/code]** follow-on). Single source — keep aligned with [code]docs/WIRING_LAYER.md[/code] §6.
class_name UiReactWireRuleCatalog
extends RefCounted


static func rule_script_entries() -> Array[Dictionary]:
	return [
		{&"label": &"MapIntToString", &"path": &"res://addons/ui_react/scripts/api/models/ui_react_wire_map_int_to_string.gd"},
		{&"label": &"RefreshItemsFromCatalog", &"path": &"res://addons/ui_react/scripts/api/models/ui_react_wire_refresh_items_from_catalog.gd"},
		{&"label": &"CopySelectionDetail", &"path": &"res://addons/ui_react/scripts/api/models/ui_react_wire_copy_selection_detail.gd"},
		{&"label": &"SetStringOnBoolPulse", &"path": &"res://addons/ui_react/scripts/api/models/ui_react_wire_set_string_on_bool_pulse.gd"},
		{&"label": &"SyncBoolStateDebugLine", &"path": &"res://addons/ui_react/scripts/api/models/ui_react_wire_sync_bool_state_debug_line.gd"},
		{&"label": &"SortArrayByKey", &"path": &"res://addons/ui_react/scripts/api/models/ui_react_wire_sort_array_by_key.gd"},
	]


static func instantiate_rule(menu_idx: int) -> UiReactWireRule:
	var entries := rule_script_entries()
	if menu_idx < 0 or menu_idx >= entries.size():
		return null
	var path: String = String(entries[menu_idx][&"path"])
	var s: GDScript = load(path) as GDScript
	if s == null:
		push_warning("Ui React: could not load wire rule script %s" % path)
		return null
	var inst: Variant = s.new()
	if inst == null or not (inst is UiReactWireRule):
		push_warning("Ui React: script did not instantiate a UiReactWireRule: %s" % path)
		return null
	return inst as UiReactWireRule

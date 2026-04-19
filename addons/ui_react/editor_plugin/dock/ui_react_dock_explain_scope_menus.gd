## Pure helpers for scope preset compare / pin lists ([UiReactDockExplainPanel]).
class_name UiReactDockExplainScopeMenus
extends RefCounted


static func scope_pins_sorted_copy(pins: PackedStringArray) -> PackedStringArray:
	var arr: Array[String] = []
	for i in range(pins.size()):
		var s := String(pins[i]).strip_edges()
		if not s.is_empty():
			arr.append(s)
	arr.sort()
	var out: PackedStringArray = PackedStringArray()
	for s2 in arr:
		out.append(s2)
	return out


static func scope_dict_matches_for_update(saved: Dictionary, current: Dictionary) -> bool:
	if int(saved.get("max_nodes", -1)) != int(current.get("max_nodes", -2)):
		return false
	if int(saved.get("max_edges", -1)) != int(current.get("max_edges", -2)):
		return false
	if bool(saved.get("show_binding", true)) != bool(current.get("show_binding", false)):
		return false
	if bool(saved.get("show_computed", true)) != bool(current.get("show_computed", false)):
		return false
	if bool(saved.get("show_wire", true)) != bool(current.get("show_wire", false)):
		return false
	if bool(saved.get("show_all_edge_labels", false)) != bool(current.get("show_all_edge_labels", true)):
		return false
	if bool(saved.get("full_lists", false)) != bool(current.get("full_lists", true)):
		return false
	var pv_s: Variant = saved.get(&"pinned", PackedStringArray())
	var sa: PackedStringArray = pv_s as PackedStringArray if pv_s is PackedStringArray else PackedStringArray()
	var pv_c: Variant = current.get(&"pinned", PackedStringArray())
	var ca: PackedStringArray = pv_c as PackedStringArray if pv_c is PackedStringArray else PackedStringArray()
	var s1 := scope_pins_sorted_copy(sa)
	var s2 := scope_pins_sorted_copy(ca)
	if s1.size() != s2.size():
		return false
	for i in range(s1.size()):
		if s1[i] != s2[i]:
			return false
	var ab1 := String(saved.get(&"about", "")).strip_edges()
	var ab2 := String(current.get(&"about", "")).strip_edges()
	return ab1 == ab2

## Pure helpers for wiring-tab scope preset records ([UiReactDockConfig] JSON).
class_name UiReactDockExplainScopePresets
extends RefCounted


static func load_sorted_presets_raw() -> Array:
	var out: Array = []
	for it: Variant in UiReactDockConfig.load_graph_scope_presets_raw():
		if it is Dictionary:
			out.append((it as Dictionary).duplicate())
	out.sort_custom(
		func(a: Variant, b: Variant) -> bool:
			var da: Dictionary = a as Dictionary
			var db: Dictionary = b as Dictionary
			var na := String(da.get("name", da.get(&"name", ""))).strip_edges().to_lower()
			var nb := String(db.get("name", db.get(&"name", ""))).strip_edges().to_lower()
			return na < nb
	)
	return out


static func find_raw_preset_variant_by_name(preset_name: String) -> Variant:
	var want := preset_name.strip_edges()
	if want.is_empty():
		return null
	for it: Variant in load_sorted_presets_raw():
		if it is Dictionary:
			var nm := String((it as Dictionary).get("name", "")).strip_edges()
			if nm == want:
				return it
	return null


static func stored_about_for_preset_name(preset_name: String) -> String:
	var v := find_raw_preset_variant_by_name(preset_name)
	if v == null or v is not Dictionary:
		return ""
	return String((v as Dictionary).get("about", (v as Dictionary).get(&"about", ""))).strip_edges()

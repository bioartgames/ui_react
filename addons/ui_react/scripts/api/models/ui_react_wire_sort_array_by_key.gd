## Reorders [member items_state] by a dictionary key ([member sort_key_state]) or by [method @GlobalScope.str] for non-dictionary rows ([code]docs/WIRING_LAYER.md[/code] §6).
class_name UiReactWireSortArrayByKey
extends UiReactWireRule

@export var items_state: UiArrayState
@export var sort_key_state: UiStringState
@export var descending_state: UiBoolState


func apply(_source: Node) -> void:
	if not enabled:
		return
	if items_state == null or sort_key_state == null:
		return
	var key := sort_key_state.get_string_value().strip_edges()
	if key.is_empty():
		return
	var working: Array = items_state.get_array_value().duplicate()
	if working.is_empty():
		return
	var desc := false
	if descending_state != null:
		desc = bool(descending_state.get_value())
	working.sort_custom(func(a: Variant, b: Variant) -> bool: return _ascending_less(a, b, key))
	if desc:
		working.reverse()
	items_state.set_value(working)


func _ascending_less(a: Variant, b: Variant, key: String) -> bool:
	if a is Dictionary and b is Dictionary:
		return _less_variant_for_sort((a as Dictionary).get(key), (b as Dictionary).get(key))
	return str(a) < str(b)


func _less_variant_for_sort(va: Variant, vb: Variant) -> bool:
	if va == vb:
		return false
	var a_null := va == null
	var b_null := vb == null
	if a_null and b_null:
		return false
	if a_null:
		return true
	if b_null:
		return false
	var ta := typeof(va)
	var tb := typeof(vb)
	if ta == TYPE_INT and tb == TYPE_INT:
		return int(va) < int(vb)
	if ta == TYPE_FLOAT and tb == TYPE_FLOAT:
		return float(va) < float(tb)
	if ta in [TYPE_INT, TYPE_FLOAT] and tb in [TYPE_INT, TYPE_FLOAT]:
		return float(va) < float(vb)
	if ta == TYPE_STRING and tb == TYPE_STRING:
		return String(va) < String(vb)
	return str(va) < str(vb)

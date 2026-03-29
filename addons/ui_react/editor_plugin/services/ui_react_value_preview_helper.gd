## Scan-time [method UiState.get_value] preview for binding diagnostics (editor-only).
class_name UiReactValuePreviewHelper
extends RefCounted

const PREVIEW_MAX_LEN := 120
const _ARRAY_PREVIEW_ELEMS := 3


static func enrich_issue_from_state(issue: UiReactDiagnosticModel.DiagnosticIssue, state: UiState) -> void:
	if issue == null or state == null:
		return
	if not state.has_method(&"get_value"):
		issue.value_preview = "<unreadable>"
		issue.value_type = ""
		issue.value_truncated = false
		return
	var v: Variant = state.get_value()
	var d := _safe_value_preview(v, PREVIEW_MAX_LEN)
	issue.value_preview = d["preview"]
	issue.value_type = d["type_name"]
	issue.value_truncated = d["truncated"]


static func _value_type_name(v: Variant) -> String:
	if v == null:
		return "null"
	match typeof(v):
		TYPE_BOOL:
			return "bool"
		TYPE_INT:
			return "int"
		TYPE_FLOAT:
			return "float"
		TYPE_STRING:
			return "String"
		TYPE_STRING_NAME:
			return "StringName"
		TYPE_ARRAY:
			return "Array"
		TYPE_DICTIONARY:
			return "Dictionary"
		TYPE_VECTOR2:
			return "Vector2"
		TYPE_VECTOR3:
			return "Vector3"
		TYPE_COLOR:
			return "Color"
		TYPE_OBJECT:
			if v is Object and is_instance_valid(v):
				return (v as Object).get_class()
			return "Object"
		_:
			return "Variant(%d)" % typeof(v)


static func _truncate_string(s: String, max_len: int) -> Dictionary:
	if s.length() <= max_len:
		return {"text": s, "truncated": false}
	return {"text": s.substr(0, max_len) + "…", "truncated": true}


static func _preview_atomic(v: Variant, max_len: int) -> Dictionary:
	var t := _value_type_name(v)
	match typeof(v):
		TYPE_STRING:
			var tr := _truncate_string(v as String, max_len)
			return {"preview": tr["text"], "type_name": t, "truncated": tr["truncated"]}
		TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING_NAME:
			var s := str(v)
			var tr2 := _truncate_string(s, max_len)
			return {"preview": tr2["text"], "type_name": t, "truncated": tr2["truncated"]}
		_:
			var s2 := str(v)
			var tr3 := _truncate_string(s2, max_len)
			return {"preview": tr3["text"], "type_name": t, "truncated": tr3["truncated"]}


static func _preview_array(arr: Array, max_len: int) -> Dictionary:
	var t := "Array"
	if arr.is_empty():
		return {"preview": "[]", "type_name": t, "truncated": false}
	var n := arr.size()
	if n > 16:
		return {"preview": "Array(size=%d)" % n, "type_name": t, "truncated": false}
	var parts: Array[String] = []
	var cap := mini(_ARRAY_PREVIEW_ELEMS, n)
	for i in range(cap):
		var sub := _safe_value_preview(arr[i], max(8, max_len / 4))
		parts.append(sub["preview"])
	var inner := ", ".join(parts)
	var suffix := "" if cap >= n else ", …"
	var preview := "[%s%s]" % [inner, suffix]
	var tr := _truncate_string(preview, max_len)
	return {"preview": tr["text"], "type_name": t, "truncated": tr["truncated"] or cap < n}


static func _preview_dictionary(d: Dictionary, max_len: int) -> Dictionary:
	var t := "Dictionary"
	var n := d.size()
	if n == 0:
		return {"preview": "{}", "type_name": t, "truncated": false}
	if n > 8:
		return {"preview": "Dictionary(size=%d)" % n, "type_name": t, "truncated": false}
	var parts: Array[String] = []
	var i := 0
	for k in d:
		if i >= _ARRAY_PREVIEW_ELEMS:
			break
		var sk := str(k)
		var sub := _safe_value_preview(d[k], max(8, max_len / 4))
		parts.append("%s: %s" % [sk, sub["preview"]])
		i += 1
	var more := "" if i >= n else ", …"
	var preview := "{%s%s}" % [", ".join(parts), more]
	var tr := _truncate_string(preview, max_len)
	return {"preview": tr["text"], "type_name": t, "truncated": tr["truncated"] or i < n}


static func _preview_resource(res: Resource, max_len: int) -> Dictionary:
	var cn := res.get_class()
	var p := res.resource_path
	var preview: String
	if not String(p).is_empty():
		preview = "%s(%s)" % [cn, p]
	else:
		preview = "%s" % cn
	var tr := _truncate_string(preview, max_len)
	return {"preview": tr["text"], "type_name": cn, "truncated": tr["truncated"]}


static func _safe_value_preview(v: Variant, max_len: int) -> Dictionary:
	if v == null:
		return {"preview": "null", "type_name": "null", "truncated": false}
	match typeof(v):
		TYPE_ARRAY:
			return _preview_array(v as Array, max_len)
		TYPE_DICTIONARY:
			return _preview_dictionary(v as Dictionary, max_len)
		TYPE_OBJECT:
			if v is Resource:
				return _preview_resource(v as Resource, max_len)
			if v is Object and is_instance_valid(v):
				var o := v as Object
				var tr := _truncate_string("%s#%d" % [o.get_class(), o.get_instance_id()], max_len)
				return {"preview": tr["text"], "type_name": o.get_class(), "truncated": tr["truncated"]}
			return {"preview": "<invalid object>", "type_name": "Object", "truncated": false}
		_:
			return _preview_atomic(v, max_len)

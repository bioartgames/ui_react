## Validates [UiReact*] bindings and [UiAnimTarget] rows (editor-only; mirrors runtime helpers).
class_name UiReactValidatorService
extends RefCounted

const _VALUE_PREVIEW_MAX_LEN := 120

static func validate_nodes(
	nodes: Array[Node],
	root_for_paths: Node,
) -> Array:
	var issues: Array = []
	for node in nodes:
		if node == null or not (node is Control):
			continue
		var component := UiReactScannerService.get_component_name_from_script(node.get_script() as Script)
		if component.is_empty():
			continue
		var np := root_for_paths.get_path_to(node) if root_for_paths and node.is_inside_tree() else NodePath(String(node.get_path()))
		issues.append_array(_validate_bindings(component, node as Control, np))
		issues.append_array(_validate_anim_targets(component, node as Control, np))
	return issues


static func _validate_bindings(component: String, owner: Control, node_path: NodePath) -> Array:
	var out: Array = []
	var bindings: Array = UiReactScannerService.BINDINGS_BY_COMPONENT.get(component, [])
	for b in bindings:
		var prop: StringName = b.get("property", &"")
		var kind: String = str(b.get("kind", ""))
		var optional: bool = bool(b.get("optional", true))
		if prop == &"":
			continue
		if not prop in owner:
			continue
		var st: Variant = owner.get(prop)
		if st == null:
			if optional:
				out.append(
					UiReactDiagnosticModel.DiagnosticIssue.make_structured(
						UiReactDiagnosticModel.Severity.INFO,
						component,
						str(owner.name),
						"%s is not assigned." % prop,
						"Create a UiState (or typed state) and assign it, or leave empty if you do not need external sync.",
						node_path,
						prop,
						UiReactScannerService.kind_to_suggested_class(kind),
					)
				)
			else:
				out.append(
					UiReactDiagnosticModel.DiagnosticIssue.make_structured(
						UiReactDiagnosticModel.Severity.WARNING,
						component,
						str(owner.name),
						"%s is required but empty." % prop,
						"Assign a UiState resource to this property.",
						node_path,
						prop,
						UiReactScannerService.kind_to_suggested_class(kind),
					)
				)
			continue
		if not (st is UiState):
			out.append(
				UiReactDiagnosticModel.DiagnosticIssue.make_structured(
					UiReactDiagnosticModel.Severity.ERROR,
					component,
					str(owner.name),
					"%s must be a UiState (got %s)." % [prop, _variant_type_name(st)],
					"Assign a UiState or typed Ui*State resource.",
					node_path,
					prop,
					&"",
				)
			)
			continue
		# Loose type hints (informational)
		var u := st as UiState
		match kind:
			"bool":
				if not _value_is_bool_like(u.value):
					var vp_bool: Dictionary = _safe_value_preview(u.value)
					var issue_bool := UiReactDiagnosticModel.DiagnosticIssue.make_structured(
						UiReactDiagnosticModel.Severity.WARNING,
						component,
						str(owner.name),
						"%s expects a bool-like value (got %s)." % [prop, type_string(typeof(u.value))],
						"Set UiState value to true/false or use UiBoolState.",
						node_path,
						prop,
						&"",
					)
					issue_bool.value_preview = vp_bool.get("preview", "")
					issue_bool.value_type = vp_bool.get("type_name", "")
					issue_bool.value_truncated = vp_bool.get("truncated", false)
					out.append(issue_bool)
			"float":
				if u.value != null and not (typeof(u.value) in [TYPE_FLOAT, TYPE_INT]):
					var vp_float: Dictionary = _safe_value_preview(u.value)
					var issue_float := UiReactDiagnosticModel.DiagnosticIssue.make_structured(
						UiReactDiagnosticModel.Severity.WARNING,
						component,
						str(owner.name),
						"%s expects a numeric value." % prop,
						"Use a number in UiState or UiFloatState.",
						node_path,
						prop,
						&"",
					)
					issue_float.value_preview = vp_float.get("preview", "")
					issue_float.value_type = vp_float.get("type_name", "")
					issue_float.value_truncated = vp_float.get("truncated", false)
					out.append(issue_float)
			"string":
				if u.value != null and not _is_valid_string_binding_value(component, prop, u.value):
					var vp_str: Dictionary = _safe_value_preview(u.value)
					var issue_str := UiReactDiagnosticModel.DiagnosticIssue.make_structured(
						UiReactDiagnosticModel.Severity.WARNING,
						component,
						str(owner.name),
						"%s expects string-like value for typical usage." % prop,
						"Use a String in UiState or UiStringState.",
						node_path,
						prop,
						&"",
					)
					issue_str.value_preview = vp_str.get("preview", "")
					issue_str.value_type = vp_str.get("type_name", "")
					issue_str.value_truncated = vp_str.get("truncated", false)
					out.append(issue_str)
			"array":
				if u.value != null and not (u.value is Array):
					var vp_arr: Dictionary = _safe_value_preview(u.value)
					var issue_arr := UiReactDiagnosticModel.DiagnosticIssue.make_structured(
						UiReactDiagnosticModel.Severity.WARNING,
						component,
						str(owner.name),
						"%s expects an Array value." % prop,
						"Set UiState.value to an Array or use UiArrayState.",
						node_path,
						prop,
						&"",
					)
					issue_arr.value_preview = vp_arr.get("preview", "")
					issue_arr.value_type = vp_arr.get("type_name", "")
					issue_arr.value_truncated = vp_arr.get("truncated", false)
					out.append(issue_arr)
	return out


static func _variant_type_name(v: Variant) -> String:
	if v is Object and v:
		return v.get_class()
	return str(typeof(v))


static func _value_is_bool_like(v: Variant) -> bool:
	return typeof(v) == TYPE_BOOL


## Human-readable type label for a [Variant] (for value preview; editor-only).
static func _value_type_name(v: Variant) -> String:
	if v == null:
		return "null"
	var t := typeof(v)
	if t == TYPE_OBJECT:
		if v is Object and v:
			return v.get_class()
		return "Object"
	return type_string(t)


static func _truncate_preview_string(s: String, max_len: int) -> Dictionary:
	if s.length() <= max_len:
		return {"text": s, "truncated": false}
	var cut: int = maxi(0, max_len - 1)
	return {"text": s.substr(0, cut) + "…", "truncated": true}


## Short single-level preview for array elements (avoids deep stringify).
static func _preview_atomic(v: Variant, max_len: int) -> String:
	if v == null:
		return "null"
	var t := typeof(v)
	if t in [TYPE_BOOL, TYPE_INT, TYPE_FLOAT]:
		return str(v)
	if t in [TYPE_STRING, TYPE_STRING_NAME]:
		var raw_s := String(v)
		if raw_s.is_empty():
			return "(empty string)"
		var tr := _truncate_preview_string(raw_s, max_len)
		return tr.text
	if t == TYPE_ARRAY:
		return "Array(size=%d)" % (v as Array).size()
	if t == TYPE_DICTIONARY:
		return "Dictionary(size=%d)" % (v as Dictionary).size()
	if t == TYPE_OBJECT and v is Object and v:
		if v is Resource:
			var rp: String = (v as Resource).resource_path
			if not rp.is_empty():
				return "%s(%s)" % [v.get_class(), rp.get_file()]
			return v.get_class()
		return v.get_class()
	var tr2 := _truncate_preview_string(str(v), max_len)
	return tr2.text


## Safe scan-time preview of [code]UiState.value[/code] for the details pane (strict length cap).
static func _safe_value_preview(v: Variant, max_len: int = _VALUE_PREVIEW_MAX_LEN) -> Dictionary:
	var type_name := _value_type_name(v)
	var truncated := false
	var preview := ""
	if v == null:
		return {"preview": "null", "type_name": "null", "truncated": false}
	var t := typeof(v)
	match t:
		TYPE_BOOL, TYPE_INT, TYPE_FLOAT:
			preview = str(v)
		TYPE_STRING, TYPE_STRING_NAME:
			var raw := String(v)
			if raw.is_empty():
				preview = "(empty string)"
			else:
				var trs := _truncate_preview_string(raw, max_len)
				preview = trs.text
				truncated = trs.truncated
		TYPE_ARRAY:
			var arr := v as Array
			var n := arr.size()
			if n <= 3:
				var atom_max := maxi(8, max_len / maxi(4, n))
				var joined := ""
				for j in range(n):
					if j > 0:
						joined += ", "
					joined += _preview_atomic(arr[j], atom_max)
				var bracketed := "[%s]" % joined
				var trj := _truncate_preview_string(bracketed, max_len)
				preview = trj.text
				truncated = trj.truncated
			else:
				preview = "Array(size=%d)" % n
		TYPE_DICTIONARY:
			preview = "Dictionary(size=%d)" % (v as Dictionary).size()
		TYPE_OBJECT:
			if v is Object and v:
				if v is Resource:
					var rp2: String = (v as Resource).resource_path
					if not rp2.is_empty():
						preview = "%s (%s)" % [v.get_class(), rp2.get_file()]
					else:
						preview = v.get_class()
				else:
					preview = v.get_class()
			else:
				preview = "Object"
		_:
			var trf := _truncate_preview_string(str(v), max_len)
			preview = trf.text
			truncated = trf.truncated
	if preview.is_empty():
		preview = "Value not available"
	return {"preview": preview, "type_name": type_name, "truncated": truncated}


static func _is_valid_string_binding_value(component: String, prop: StringName, value: Variant) -> bool:
	# UiReactLabel intentionally supports recursive text rendering from arrays/nested UiState.
	if component == "UiReactLabel" and prop == &"text_state":
		return true
	return typeof(value) in [TYPE_STRING, TYPE_STRING_NAME]


static func _validate_anim_targets(component: String, owner: Control, node_path: NodePath) -> Array:
	var out: Array = []
	if not &"animation_targets" in owner:
		return out
	var arr: Variant = owner.get(&"animation_targets")
	if not (arr is Array):
		return out
	var targets: Array = arr as Array
	for i in range(targets.size()):
		var anim_target: Variant = targets[i]
		if anim_target == null:
			out.append(
				UiReactDiagnosticModel.DiagnosticIssue.make_structured(
					UiReactDiagnosticModel.Severity.WARNING,
					component,
					str(owner.name),
					"animation_targets[%d] is null." % i,
					"Remove the empty array element or assign a UiAnimTarget.",
					node_path,
					&"animation_targets",
					&"",
				)
			)
			continue
		if not (anim_target is UiAnimTarget):
			continue
		var at := anim_target as UiAnimTarget
		if at.target.is_empty():
			out.append(
				UiReactDiagnosticModel.DiagnosticIssue.make_structured(
					UiReactDiagnosticModel.Severity.WARNING,
					component,
					str(owner.name),
					"UiAnimTarget #%d has no Target NodePath." % i,
					"Assign Target (drag a Control) or remove this entry.",
					node_path,
					&"animation_targets",
					&"",
				)
			)
			continue
		var tn := owner.get_node_or_null(at.target)
		if tn == null:
			out.append(
				UiReactDiagnosticModel.DiagnosticIssue.make_structured(
					UiReactDiagnosticModel.Severity.ERROR,
					component,
					str(owner.name),
					"UiAnimTarget #%d Target '%s' could not be resolved." % [i, at.target],
					"Fix the NodePath relative to this control.",
					node_path,
					&"animation_targets",
					&"",
				)
			)
			continue
		if not (tn is Control):
			out.append(
				UiReactDiagnosticModel.DiagnosticIssue.make_structured(
					UiReactDiagnosticModel.Severity.ERROR,
					component,
					str(owner.name),
					"UiAnimTarget #%d Target is not a Control." % i,
					"Point Target at a Control node.",
					node_path,
					&"animation_targets",
					&"",
				)
			)
	return out

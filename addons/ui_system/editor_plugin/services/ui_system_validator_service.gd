## Validates [UiReact*] bindings and [UiAnimTarget] rows (editor-only; mirrors runtime helpers).
class_name UiSystemValidatorService
extends RefCounted

static func validate_nodes(
	nodes: Array[Node],
	root_for_paths: Node,
) -> Array:
	var issues: Array = []
	for node in nodes:
		if node == null or not (node is Control):
			continue
		var component := UiSystemScannerService.get_component_name_from_script(node.get_script() as Script)
		if component.is_empty():
			continue
		var np := root_for_paths.get_path_to(node) if root_for_paths and node.is_inside_tree() else NodePath(String(node.get_path()))
		issues.append_array(_validate_bindings(component, node as Control, np))
		issues.append_array(_validate_anim_targets(component, node as Control, np))
	return issues


static func _validate_bindings(component: String, owner: Control, node_path: NodePath) -> Array:
	var out: Array = []
	var bindings: Array = UiSystemScannerService.BINDINGS_BY_COMPONENT.get(component, [])
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
					UiSystemDiagnosticModel.DiagnosticIssue.make_structured(
						UiSystemDiagnosticModel.Severity.INFO,
						component,
						str(owner.name),
						"%s is not assigned." % prop,
						"Create a UiState (or typed state) and assign it, or leave empty if you do not need external sync.",
						node_path,
						prop,
						UiSystemScannerService.kind_to_suggested_class(kind),
					)
				)
			else:
				out.append(
					UiSystemDiagnosticModel.DiagnosticIssue.make_structured(
						UiSystemDiagnosticModel.Severity.WARNING,
						component,
						str(owner.name),
						"%s is required but empty." % prop,
						"Assign a UiState resource to this property.",
						node_path,
						prop,
						UiSystemScannerService.kind_to_suggested_class(kind),
					)
				)
			continue
		if not (st is UiState):
			out.append(
				UiSystemDiagnosticModel.DiagnosticIssue.make_structured(
					UiSystemDiagnosticModel.Severity.ERROR,
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
					out.append(
						UiSystemDiagnosticModel.DiagnosticIssue.make_structured(
							UiSystemDiagnosticModel.Severity.WARNING,
							component,
							str(owner.name),
							"%s expects a bool-like value (got %s)." % [prop, type_string(typeof(u.value))],
							"Set UiState value to true/false or use UiBoolState.",
							node_path,
							&"",
							&"",
						)
					)
			"float":
				if u.value != null and not (typeof(u.value) in [TYPE_FLOAT, TYPE_INT]):
					out.append(
						UiSystemDiagnosticModel.DiagnosticIssue.make_structured(
							UiSystemDiagnosticModel.Severity.WARNING,
							component,
							str(owner.name),
							"%s expects a numeric value." % prop,
							"Use a number in UiState or UiFloatState.",
							node_path,
							&"",
							&"",
						)
					)
			"string":
				if u.value != null and not _is_valid_string_binding_value(component, prop, u.value):
					out.append(
						UiSystemDiagnosticModel.DiagnosticIssue.make_structured(
							UiSystemDiagnosticModel.Severity.WARNING,
							component,
							str(owner.name),
							"%s expects string-like value for typical usage." % prop,
							"Use a String in UiState or UiStringState.",
							node_path,
							&"",
							&"",
						)
					)
			"array":
				if u.value != null and not (u.value is Array):
					out.append(
						UiSystemDiagnosticModel.DiagnosticIssue.make_structured(
							UiSystemDiagnosticModel.Severity.WARNING,
							component,
							str(owner.name),
							"%s expects an Array value." % prop,
							"Set UiState.value to an Array or use UiArrayState.",
							node_path,
							&"",
							&"",
						)
					)
	return out


static func _variant_type_name(v: Variant) -> String:
	if v is Object and v:
		return v.get_class()
	return str(typeof(v))


static func _value_is_bool_like(v: Variant) -> bool:
	return typeof(v) == TYPE_BOOL


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
				UiSystemDiagnosticModel.DiagnosticIssue.make_structured(
					UiSystemDiagnosticModel.Severity.WARNING,
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
				UiSystemDiagnosticModel.DiagnosticIssue.make_structured(
					UiSystemDiagnosticModel.Severity.WARNING,
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
				UiSystemDiagnosticModel.DiagnosticIssue.make_structured(
					UiSystemDiagnosticModel.Severity.ERROR,
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
				UiSystemDiagnosticModel.DiagnosticIssue.make_structured(
					UiSystemDiagnosticModel.Severity.ERROR,
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

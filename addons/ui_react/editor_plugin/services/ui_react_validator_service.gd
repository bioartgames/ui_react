## Validates [UiReact*] bindings and [UiAnimTarget] rows (editor-only; mirrors runtime helpers).
class_name UiReactValidatorService
extends RefCounted

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


static func _expected_binding_state_class(component: String, prop: StringName, kind: String, owner: Control) -> StringName:
	if component == "UiReactItemList" and prop == &"selected_state":
		if owner is ItemList and (owner as ItemList).select_mode == ItemList.SELECT_SINGLE:
			return &"UiIntState"
		return &"UiArrayState"
	return UiReactScannerService.kind_to_suggested_class(kind)


static func _binding_type_ok(u: UiState, expected: StringName, component: String, prop: StringName) -> bool:
	if component == "UiReactLabel" and prop == &"text_state":
		return u is UiStringState or u is UiArrayState
	if expected.is_empty():
		return true
	match String(expected):
		"UiBoolState":
			return u is UiBoolState
		"UiIntState":
			return u.get_class() == &"UiIntState"
		"UiFloatState":
			return u is UiFloatState
		"UiStringState":
			return u is UiStringState
		"UiArrayState":
			return u is UiArrayState
		_:
			return true


static func _expected_type_phrase(component: String, prop: StringName, expected: StringName) -> String:
	if component == "UiReactLabel" and prop == &"text_state":
		return "UiStringState or UiArrayState"
	if expected.is_empty():
		return "a concrete UiState subclass"
	return str(expected)


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
		var expected: StringName = _expected_binding_state_class(component, prop, kind, owner)
		var suggested: StringName = UiReactScannerService.kind_to_suggested_class(kind)
		if component == "UiReactItemList" and prop == &"selected_state":
			suggested = expected
		var st: Variant = owner.get(prop)
		if st == null:
			if optional:
				out.append(
					UiReactDiagnosticModel.DiagnosticIssue.make_structured(
						UiReactDiagnosticModel.Severity.INFO,
						component,
						str(owner.name),
						"%s is not assigned." % prop,
						"Create a concrete Ui*State resource and assign it, or leave empty if you do not need external sync.",
						node_path,
						prop,
						suggested,
					)
				)
			else:
				out.append(
					UiReactDiagnosticModel.DiagnosticIssue.make_structured(
						UiReactDiagnosticModel.Severity.WARNING,
						component,
						str(owner.name),
						"%s is required but empty." % prop,
						"Assign a UiState subclass resource to this property.",
						node_path,
						prop,
						suggested,
					)
				)
			continue
		if not (st is UiState):
			out.append(
				UiReactDiagnosticModel.DiagnosticIssue.make_structured(
					UiReactDiagnosticModel.Severity.ERROR,
					component,
					str(owner.name),
					"%s must be a UiState subclass (got %s)." % [prop, _variant_type_name(st)],
					"Assign a concrete UiBoolState, UiIntState, UiFloatState, UiStringState, or UiArrayState resource.",
					node_path,
					prop,
					suggested,
				)
			)
			continue
		var u := st as UiState
		if component == "UiReactItemList" and prop == &"selected_state" and owner is ItemList:
			if (owner as ItemList).select_mode == ItemList.SELECT_SINGLE and u is UiFloatState:
				out.append(
					UiReactDiagnosticModel.DiagnosticIssue.make_structured(
						UiReactDiagnosticModel.Severity.ERROR,
						component,
						str(owner.name),
						"%s cannot use UiFloatState in single-select mode." % prop,
						"Use UiIntState (int indices only). Float is not accepted for list selection.",
						node_path,
						prop,
						&"UiIntState",
					)
				)
				continue
		if not _binding_type_ok(u, expected, component, prop):
			var phrase: String = _expected_type_phrase(component, prop, expected)
			out.append(
				UiReactDiagnosticModel.DiagnosticIssue.make_structured(
					UiReactDiagnosticModel.Severity.ERROR,
					component,
					str(owner.name),
					"%s expects %s (got %s)." % [prop, phrase, u.get_class()],
					"Assign a resource of the expected type.",
					node_path,
					prop,
					suggested,
				)
			)
	return out


static func _variant_type_name(v: Variant) -> String:
	if v is Object and v:
		return v.get_class()
	return str(typeof(v))


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

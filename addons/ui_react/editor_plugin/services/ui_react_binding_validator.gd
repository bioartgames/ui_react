## Validates [UiReact*] [UiState] binding exports (editor diagnostics).
class_name UiReactBindingValidator
extends RefCounted

const _VALUE_PREVIEW_HELPER := preload("res://addons/ui_react/editor_plugin/services/ui_react_value_preview_helper.gd")


static func validate_bindings(
	component: String, owner: Control, node_path: NodePath
) -> Array[UiReactDiagnosticModel.DiagnosticIssue]:
	var out: Array[UiReactDiagnosticModel.DiagnosticIssue] = []
	var bindings: Array = UiReactComponentRegistry.BINDINGS_BY_COMPONENT.get(component, [])
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
		var property_value: Variant = owner.get(prop)
		if property_value == null:
			if optional:
				out.append(
					UiReactDiagnosticModel.DiagnosticIssue.make_structured(
						UiReactDiagnosticModel.Severity.INFO,
						component,
						str(owner.name),
						"Inspector property %s has no resource assigned." % prop,
						"Create a Ui*State resource and assign it here, or leave empty if you do not need reactive sync for this slot.",
						node_path,
						prop,
						suggested,
						UiReactDiagnosticModel.IssueKind.GENERIC,
						"",
					)
				)
			else:
				out.append(
					UiReactDiagnosticModel.DiagnosticIssue.make_structured(
						UiReactDiagnosticModel.Severity.WARNING,
						component,
						str(owner.name),
						"%s is required for this control but is empty." % prop,
						"In the Inspector, assign a compatible Ui*State resource to this property.",
						node_path,
						prop,
						suggested,
						UiReactDiagnosticModel.IssueKind.GENERIC,
						"",
					)
				)
			continue
		if not (property_value is UiState):
			out.append(
				UiReactDiagnosticModel.DiagnosticIssue.make_structured(
					UiReactDiagnosticModel.Severity.ERROR,
					component,
					str(owner.name),
					"%s must be a Ui*State resource (found %s)." % [prop, UiReactValidatorCommon.variant_type_name(property_value)],
					"In the Inspector, assign a concrete state resource (bool/int/float/string/array/computed/transactional) that matches this binding slot.",
					node_path,
					prop,
					suggested,
					UiReactDiagnosticModel.IssueKind.GENERIC,
					"",
				)
			)
			continue
		var ui_state := property_value as UiState
		if component == "UiReactItemList" and prop == &"selected_state" and owner is ItemList:
			var is_single := (owner as ItemList).select_mode == ItemList.SELECT_SINGLE
			var is_float_like := ui_state is UiFloatState
			if not is_float_like and ui_state is UiTransactionalState:
				is_float_like = (ui_state as UiTransactionalState).matches_expected_binding_class(&"UiFloatState")
			if is_single and is_float_like:
				var issue_il := UiReactDiagnosticModel.DiagnosticIssue.make_structured(
					UiReactDiagnosticModel.Severity.ERROR,
					component,
					str(owner.name),
					"%s cannot use a float-based state in single-select list mode." % prop,
					"Use UiIntState (row indices are integers). Assign it in the Inspector for Selected state.",
					node_path,
					prop,
					&"UiIntState",
					UiReactDiagnosticModel.IssueKind.GENERIC,
					"",
				)
				_append_binding_issue_with_preview(out, issue_il, ui_state)
				continue
		if not _binding_type_ok(ui_state, expected, component, prop):
			var phrase: String = _expected_type_phrase(component, prop, expected)
			var issue_bt := UiReactDiagnosticModel.DiagnosticIssue.make_structured(
				UiReactDiagnosticModel.Severity.ERROR,
				component,
				str(owner.name),
				"%s expects %s (this resource is %s)." % [prop, phrase, ui_state.get_class()],
				"In the Inspector, replace the resource on this property with one of the expected types.",
				node_path,
				prop,
				suggested,
				UiReactDiagnosticModel.IssueKind.GENERIC,
				"",
			)
			_append_binding_issue_with_preview(out, issue_bt, ui_state)
	return out


static func _expected_binding_state_class(component: String, prop: StringName, kind: String, owner: Control) -> StringName:
	if component == "UiReactItemList" and prop == &"selected_state":
		if owner is ItemList and (owner as ItemList).select_mode == ItemList.SELECT_SINGLE:
			return &"UiIntState"
		return &"UiArrayState"
	return UiReactScannerService.kind_to_suggested_class(kind)


static func _binding_type_ok(ui_state: UiState, expected: StringName, component: String, prop: StringName) -> bool:
	if (component == "UiReactLabel" or component == "UiReactRichTextLabel") and prop == &"text_state":
		if ui_state is UiStringState or ui_state is UiArrayState:
			return true
		return ui_state is UiTransactionalState and (
			(ui_state as UiTransactionalState).matches_expected_binding_class(&"UiStringState")
			or (ui_state as UiTransactionalState).matches_expected_binding_class(&"UiArrayState")
		)
	if ui_state is UiTransactionalState:
		return (ui_state as UiTransactionalState).matches_expected_binding_class(expected)
	if expected.is_empty():
		return true
	match String(expected):
		"UiBoolState":
			return ui_state is UiBoolState
		"UiIntState":
			return ui_state is UiIntState
		"UiFloatState":
			return ui_state is UiFloatState
		"UiStringState":
			return ui_state is UiStringState
		"UiArrayState":
			return ui_state is UiArrayState
		_:
			return true


static func _append_binding_issue_with_preview(
	out: Array[UiReactDiagnosticModel.DiagnosticIssue],
	issue: UiReactDiagnosticModel.DiagnosticIssue,
	ui_state: UiState,
) -> void:
	_VALUE_PREVIEW_HELPER.enrich_issue_from_state(issue, ui_state)
	out.append(issue)


static func _expected_type_phrase(component: String, prop: StringName, expected: StringName) -> String:
	if (component == "UiReactLabel" or component == "UiReactRichTextLabel") and prop == &"text_state":
		return "UiStringState, UiComputedStringState, UiArrayState, or UiTransactionalState (string/array payload)"
	if expected.is_empty():
		return "a concrete UiState subclass"
	return str(expected)

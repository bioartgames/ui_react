## Lists empty registry binding exports compatible with a donor [UiState] for Dependency Graph **new link** (**[code]CB-058[/code]** phase 2b); optional-only **clear** for slice1 disconnect.
class_name UiReactGraphNewBindingService
extends RefCounted


static func binding_export_is_optional(component: String, prop: StringName) -> bool:
	if component.is_empty() or prop == &"":
		return false
	var bindings: Array = UiReactComponentRegistry.BINDINGS_BY_COMPONENT.get(component, [])
	for b in bindings:
		if b.get("property", &"") == prop:
			return bool(b.get("optional", true))
	return false


static func try_commit_clear_binding_export(
	host: Control,
	component: String,
	prop: StringName,
	actions: UiReactActionController,
) -> bool:
	if host == null or actions == null or prop == &"":
		return false
	if not binding_export_is_optional(component, prop):
		push_warning(
			"Ui React: cannot clear %s from the graph because it is required for this control. Clear it in the Inspector only if the registry marks it optional."
			% str(prop)
		)
		return false
	if not prop in host:
		return false
	if host.get(prop) == null:
		return false
	actions.assign_property_variant(host, prop, null, "Ui React: Clear %s (graph)" % str(prop))
	return true


## Registry binding matrix for the graph details **Connections** section ([code]CB-018A.5[/code]).
static func list_registry_binding_rows(host: Control, component: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if host == null or component.is_empty():
		return out
	var bindings: Array = UiReactComponentRegistry.BINDINGS_BY_COMPONENT.get(component, [])
	var segs := str(host.get_path()).split("/")
	var host_tail := segs[segs.size() - 1] if segs.size() > 0 else str(host.name)
	for b in bindings:
		var prop: StringName = b.get("property", &"")
		if prop == &"":
			continue
		var kind: String = str(b.get("kind", ""))
		var bound := prop in host and host.get(prop) != null
		var value_label := ""
		if bound:
			var v: Variant = host.get(prop)
			if v is UiState:
				var st := v as UiState
				var rp := str(st.resource_path)
				value_label = rp.get_file() if not rp.is_empty() else ("embedded @ %s" % host_tail)
			elif v is Resource:
				var rpp := str((v as Resource).resource_path)
				value_label = rpp.get_file() if not rpp.is_empty() else "embedded resource"
			else:
				value_label = str(v)
		out.append({&"property": prop, &"kind": kind, &"bound": bound, &"value_label": value_label})
	return out


static func list_assignable_empty_exports(host: Control, component: String, donor: UiState) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if host == null or donor == null or component.is_empty():
		return out
	var bindings: Array = UiReactComponentRegistry.BINDINGS_BY_COMPONENT.get(component, [])
	for b in bindings:
		var prop: StringName = b.get("property", &"")
		if prop == &"" or not prop in host:
			continue
		if host.get(prop) != null:
			continue
		var kind: String = str(b.get("kind", ""))
		var expected: StringName = UiReactBindingValidator._expected_binding_state_class(
			component, prop, kind, host
		)
		if not UiReactBindingValidator._binding_type_ok(donor, expected, component, prop):
			continue
		out.append({&"property": prop, &"label": "%s (%s)" % [str(prop), kind]})
	return out


static func try_commit_assign(
	host: Control,
	component: String,
	prop: StringName,
	donor: UiState,
	actions: UiReactActionController,
) -> bool:
	if host == null or actions == null or donor == null or prop == &"":
		return false
	if not prop in host:
		return false
	if host.get(prop) != null:
		push_warning(
			"Ui React: cannot assign to %s because it already has a resource. Clear or replace that binding in the Inspector first."
			% str(prop)
		)
		return false
	var kind: String = ""
	var bindings: Array = UiReactComponentRegistry.BINDINGS_BY_COMPONENT.get(component, [])
	for b in bindings:
		if b.get("property", &"") == prop:
			kind = str(b.get("kind", ""))
			break
	var expected: StringName = UiReactBindingValidator._expected_binding_state_class(
		component, prop, kind, host
	)
	if not UiReactBindingValidator._binding_type_ok(donor, expected, component, prop):
		push_warning(
			"Ui React: that state type does not match %s for this control. Drag a compatible UiState or fix the binding kind in the Inspector."
			% str(prop)
		)
		return false
	actions.assign_property_variant(
		host,
		prop,
		donor,
		"Ui React: Assign %s (graph)" % str(prop)
	)
	return true

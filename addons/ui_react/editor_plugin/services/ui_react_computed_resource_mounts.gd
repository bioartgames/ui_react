## Finds scene [Control] + [code]computed_context[/code] for a file-backed [UiComputed*] resource (**[code]CB-058[/code]** follow-on).
class_name UiReactComputedResourceMounts
extends RefCounted


static func _same_resource_instance_or_path(a: Variant, b: Resource) -> bool:
	if a == null or b == null:
		return false
	if a == b:
		return true
	if a is Resource:
		var pa := (a as Resource).resource_path
		var pb := b.resource_path
		if not pa.is_empty() and pa == pb:
			return true
	return false


static func mounts_for_computed_resource(root: Node, target: Resource) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if root == null or target == null:
		return out
	if not (target is UiComputedStringState or target is UiComputedBoolState):
		return out
	for n in UiReactScannerService.collect_react_nodes(root):
		if not (n is Control):
			continue
		var host := n as Control
		var comp := UiReactScannerService.get_component_name_from_script(host.get_script() as Script)
		if comp.is_empty():
			continue
		var hp := str(root.get_path_to(host))
		var bindings: Array = UiReactComponentRegistry.BINDINGS_BY_COMPONENT.get(comp, [])
		for b in bindings:
			var prop: StringName = b.get("property", &"")
			if prop == &"" or not prop in host:
				continue
			var v: Variant = host.get(prop)
			if _same_resource_instance_or_path(v, target) and (
				v is UiComputedStringState or v is UiComputedBoolState
			):
				out.append({&"host_path": hp, &"computed_context": "bind:%s" % str(prop)})
	return out


static func bind_prop_from_context(computed_context: String) -> StringName:
	if computed_context.begins_with("bind:"):
		return StringName(computed_context.substr(5))
	return &""


static func try_commit_make_computed_unique_at_bind(
	host: Control,
	prop: StringName,
	actions: UiReactActionController,
) -> bool:
	if host == null or actions == null or prop == &"" or not prop in host:
		return false
	var v: Variant = host.get(prop)
	if not (v is UiComputedStringState or v is UiComputedBoolState):
		return false
	var d: Resource = (v as Resource).duplicate(true)
	if d == null:
		return false
	actions.assign_property_variant(host, prop, d, "Ui React: Make computed unique (%s)" % str(prop))
	return true

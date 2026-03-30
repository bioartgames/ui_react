## Collects [code]res://[/code] paths of external [UiState] resources bound on [UiReact*] nodes in a scene.
class_name UiReactStateReferenceCollector
extends RefCounted


static func collect_referenced_state_paths_for_scene(root: Node) -> Dictionary:
	var out: Dictionary = {}
	if root == null:
		return out
	for n in UiReactScannerService.collect_react_nodes(root):
		add_bound_state_paths_from_react_node(n, out)
	return out


static func add_bound_state_paths_from_react_node(node: Node, out_paths: Dictionary) -> void:
	if not (node is Control):
		return
	var owner := node as Control
	var component := UiReactScannerService.get_component_name_from_script(owner.get_script() as Script)
	if component.is_empty():
		return
	var bindings: Array = UiReactScannerService.BINDINGS_BY_COMPONENT.get(component, [])
	for b in bindings:
		var prop: StringName = b.get("property", &"")
		if prop == &"" or not prop in owner:
			continue
		var property_value: Variant = owner.get(prop)
		if property_value is UiState:
			_register_state_path(property_value as UiState, out_paths)
	if component == "UiReactTabContainer":
		var cfg: Variant = owner.get(&"tab_config")
		if cfg is UiTabContainerCfg:
			_add_tab_container_cfg_paths(cfg as UiTabContainerCfg, out_paths)


static func _register_state_path(state: UiState, out_paths: Dictionary) -> void:
	if state == null:
		return
	var p := state.resource_path
	if p.is_empty():
		return
	out_paths[p] = true


static func _add_tab_container_cfg_paths(cfg: UiTabContainerCfg, out_paths: Dictionary) -> void:
	_register_state_path(cfg.tabs_state, out_paths)
	_register_state_path(cfg.disabled_tabs_state, out_paths)
	_register_state_path(cfg.visible_tabs_state, out_paths)
	for s in cfg.tab_content_states:
		if s is UiState:
			_register_state_path(s as UiState, out_paths)

extends RefCounted
class_name UiReactLiveDebugHarvester
## Passive **`UiState`** discovery for **`CB-018C`**: scans running **`UiReact*`** hosts using **preload** of **`UiReactScannerService`**, **`UiReactComponentRegistry`**, **`UiReactWireRuleIntrospection`**, and **`UiReactComputedService`** — intentional runtime bridge to **`editor_plugin/`** tables (avoid broader `scripts/` → editor coupling elsewhere).


const LIVE_DEBUG_BR: Variant = preload("res://addons/ui_react/scripts/runtime/ui_react_live_debug_bridge.gd")

const UiReactScannerService := preload("res://addons/ui_react/editor_plugin/services/ui_react_scanner_service.gd")
const UiReactComponentRegistry := preload("res://addons/ui_react/editor_plugin/ui_react_component_registry.gd")
const UiReactWireRuleIntrospection := preload(
	"res://addons/ui_react/editor_plugin/services/ui_react_wire_rule_introspection.gd"
)
const UiReactComputedService := preload(
	"res://addons/ui_react/scripts/internal/react/ui_react_computed_service.gd"
)
const UiReactGraphNodeIds := preload(
	"res://addons/ui_react/scripts/internal/react/ui_react_graph_node_ids.gd"
)

const COMPUTED_SOURCES_MAX_DEPTH := 8

const LIVE_DEBUG_MAX_STATE_SUBSCRIPTIONS := 256

var _entry_by_oid: Dictionary = {}

var _cap_warn_emitted: bool = false


func clear_subscriptions() -> void:
	var snap := _entry_by_oid.duplicate()
	_entry_by_oid.clear()
	_cap_warn_emitted = false
	for k in snap.keys():
		var ent: Variant = snap[k]
		if ent is not Dictionary:
			continue
		var w: WeakRef = ent.get(&"weak_state", null) as WeakRef
		if w == null:
			continue
		var cb: Callable = ent.get(&"callable", Callable()) as Callable
		var st_raw: Variant = w.get_ref()
		if not (st_raw is UiState):
			continue
		var st := st_raw as UiState
		if st.value_changed.is_connected(cb):
			st.value_changed.disconnect(cb)


func rebuild(root: Node) -> void:
	clear_subscriptions()
	if root == null or not bool(LIVE_DEBUG_BR.call(&"is_effective_enabled")):
		return
	for host in UiReactScannerService.collect_react_nodes(root):
		if host is Control:
			_harvest_control(root, host as Control)


func _harvest_control(root: Node, ctl: Control) -> void:
	var scr := ctl.get_script() as Script
	var component := UiReactScannerService.get_component_name_from_script(scr)
	if component.is_empty():
		component = UiReactLiveDebugHarvester._component_from_registry_stem_fallback(scr)
	if component.is_empty():
		return
	var hp_np := UiReactGraphNodeIds.host_path_from_root(root, ctl)
	var hp_str := str(hp_np)

	var binds: Variant = UiReactComponentRegistry.BINDINGS_BY_COMPONENT.get(component, [])
	for bdict in binds as Array:
		if bdict is not Dictionary:
			continue
		var pname: Variant = bdict.get(&"property", &"")
		if pname == null or str(pname) == "":
			continue
		if not (pname is StringName):
			pname = StringName(str(pname))
		var prop_sn := pname as StringName
		if prop_sn != &"" and prop_sn in ctl:
			var st_var: Variant = ctl.get(prop_sn)
			if st_var is UiState:
				var st := st_var as UiState
				var ctx := "bind:%s" % str(prop_sn)
				_try_attach_state(st, hp_str, ctx)
				_harvest_nested_computed_sources(st, hp_str, ctx)

	if &"wire_rules" in ctl:
		var wr_raw: Variant = ctl.get(&"wire_rules")
		if wr_raw is Array:
			var idx := 0
			for r in wr_raw as Array:
				if r is UiReactWireRule:
					var rr := r as UiReactWireRule
					for io in UiReactWireRuleIntrospection.list_io(rr):
						var ust_raw: Variant = io.get(&"state", null)
						if ust_raw is UiState:
							var ust := ust_raw as UiState
							var pnm := str(io.get(&"property", ""))
							var w_ctx := "wire:%d:%s" % [idx, pnm]
							_try_attach_state(ust, hp_str, w_ctx)
							_harvest_nested_computed_sources(ust, hp_str, "wire[%d]" % idx)
				idx += 1


func _harvest_nested_computed_sources(head: UiState, hp_str: String, base_ctx: String, depth: int = 0) -> void:
	if depth >= COMPUTED_SOURCES_MAX_DEPTH:
		return
	if not UiReactComputedService.supports_computed_wiring(head):
		return
	var raw: Variant = head.get(&"sources")
	if typeof(raw) != TYPE_ARRAY:
		return
	var si := 0
	for it in raw as Array:
		if it is UiState:
			var dep := it as UiState
			var seg := "%s.src[%d]" % [base_ctx, si]
			_try_attach_state(dep, hp_str, seg)
			_harvest_nested_computed_sources(dep, hp_str, seg, depth + 1)
		si += 1


func _try_attach_state(st: UiState, host_str: String, prop_hint: String) -> void:
	if st == null or not is_instance_valid(st):
		return
	var okey := str(st.get_instance_id())
	if _entry_by_oid.has(okey):
		return
	if _entry_by_oid.size() >= LIVE_DEBUG_MAX_STATE_SUBSCRIPTIONS:
		if not _cap_warn_emitted:
			_cap_warn_emitted = true
			push_warning(
				(
					"Ui React live debug: state subscription cap %d reached; some states will not be traced."
					% LIVE_DEBUG_MAX_STATE_SUBSCRIPTIONS
				)
			)
		return
	var wref := weakref(st)
	var cb := func (nv: Variant, ov: Variant) -> void:
		var lr: UiState = wref.get_ref() as UiState
		if lr == null:
			return
		LIVE_DEBUG_BR.call(&"maybe_state_value_changed", lr, nv, ov, host_str, prop_hint)

	st.value_changed.connect(cb)
	_entry_by_oid[okey] = {&"weak_state": wref, &"callable": cb}


static func _component_from_registry_stem_fallback(script: Script) -> String:
	if script == null:
		return ""
	var path := script.resource_path
	var base := path.get_file().get_basename()
	return String(UiReactComponentRegistry.SCRIPT_STEM_TO_COMPONENT.get(base, ""))




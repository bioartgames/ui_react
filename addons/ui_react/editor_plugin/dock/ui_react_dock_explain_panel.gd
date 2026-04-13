## Editor dock tab: declarative dependency graph ([code]CB-018A[/code]) + visual graph ([code]CB-018A.5[/code]: graph-only, per-anchor narrative in details).
class_name UiReactDockExplainPanel
extends MarginContainer

const _ExplainBuilderScript := preload("res://addons/ui_react/editor_plugin/services/ui_react_explain_graph_builder.gd")
const _ComputedRebindScript := preload("res://addons/ui_react/editor_plugin/services/ui_react_computed_graph_rebind.gd")
const _WireGraphEditScript := preload("res://addons/ui_react/editor_plugin/services/ui_react_wire_graph_edit_service.gd")
const _WireRuleCatalogScript := preload("res://addons/ui_react/editor_plugin/services/ui_react_wire_rule_catalog.gd")
const _ComputedMountsScript := preload("res://addons/ui_react/editor_plugin/services/ui_react_computed_resource_mounts.gd")
const _NewBindingScript := preload("res://addons/ui_react/editor_plugin/services/ui_react_graph_new_binding_service.gd")
const _ResolverScript := preload("res://addons/ui_react/editor_plugin/services/ui_react_graph_node_state_resolver.gd")
const _ExplainLayoutScript := preload("res://addons/ui_react/editor_plugin/services/ui_react_explain_graph_layout.gd")
const _ExplainGraphViewScript := preload("res://addons/ui_react/editor_plugin/dock/ui_react_explain_graph_view.gd")
const _WireRulesSectionScript := preload("res://addons/ui_react/editor_plugin/dock/ui_react_dock_wire_rules_section.gd")
const _SnapScript := preload("res://addons/ui_react/editor_plugin/models/ui_react_explain_graph_snapshot.gd")
const _GraphFactoryScript := preload("res://addons/ui_react/editor_plugin/services/ui_react_graph_resource_factory.gd")
const _DockThemeScript := preload("res://addons/ui_react/editor_plugin/dock/ui_react_dock_theme.gd")
const _SEL_NONE := 0
const _SEL_NODE := 1
const _SEL_EDGE := 2

const _DETAILS_GRAPH_HELP_BB := (
	"Pan: middle-drag · zoom: wheel · RMB: View or actions · double-click: Inspector (same as Focus).\n"
	+ "Shift+drag on a selected edge: reconnect. Ctrl+Shift+drag: new link. Delete: clear edge when allowed.\n"
	+ "Node outline shape encodes role (control / state / computed); see Key above."
)
const _DETAILS_GRAPH_HELP_PLAIN := (
	"Pan: middle-drag · zoom: wheel · RMB: View or actions · double-click: Inspector (same as Focus).\n"
	+ "Shift+drag on a selected edge: reconnect. Ctrl+Shift+drag: new link. Delete: clear edge when allowed.\n"
	+ "Node outline shape encodes role (control / state / computed); see Key above."
)

const _REBIND_NONE := 0
const _REBIND_BINDING := 1
const _REBIND_WIRE_IN := 2
const _REBIND_WIRE_OUT := 3
const _REBIND_COMPUTED_SOURCE := 4

const _SCOPE_MIN_NODES := 20
const _SCOPE_MAX_NODES := 2000
const _SCOPE_MIN_EDGES := 40
const _SCOPE_MAX_EDGES := 4000

const _LEGEND_WRAP_THRESHOLD_PX := 520
const _LEGEND_GROUP_FONT_COLOR := Color(0.72, 0.74, 0.8, 0.92)
## Subtle outline so non-focus node swatches separate from the dock bar (focus chip keeps [member UiReactExplainGraphView.GRAPH_LEGEND_FOCUS_BORDER] at 2px).
const _LEGEND_NODE_CHIP_BORDER := Color(1, 1, 1, 0.42)
## Raised chip behind edge color strips so binding/computed/wire reads on dark UI.
const _LEGEND_EDGE_SWATCH_BG := Color(0.11, 0.12, 0.14, 0.72)
const _LEGEND_EDGE_SWATCH_BORDER := Color(1, 1, 1, 0.38)

## Selection [PopupMenu] ids — [method _fill_selection_actions_popup] / [method _on_selection_action_id].
const _SEL_ACT_REBIND_BINDING := 1101
const _SEL_ACT_REBIND_WIRE_IN := 1102
const _SEL_ACT_REBIND_WIRE_OUT := 1103
const _SEL_ACT_REBIND_COMPUTED_SRC := 1104
const _SEL_ACT_CLEAR_OPT_BINDING := 1110
const _SEL_ACT_REMOVE_COMPUTED_DEP := 1111
const _SEL_ACT_CLEAR_WIRE_LINK := 1112
const _SEL_ACT_MOVE_SRC_UP := 1120
const _SEL_ACT_MOVE_SRC_DOWN := 1121
const _SEL_ACT_REMOVE_SRC_SLOT := 1122
const _SEL_ACT_CREATE_ASSIGN_BINDING := 1130
## Wire rules + Focus — [method _fill_selection_actions_popup] / [method _on_selection_action_id].
const _SEL_ACT_FOCUS_INSPECTOR := 1180
const _SEL_ACT_WIRE_ADD_BASE := 1210
const _SEL_ACT_WIRE_REFRESH_LIST := 1220
const _SEL_ACT_WIRE_COPY_RULE_REPORT := 1221
const _SEL_ACT_COPY_DETAILS := 1199

## Empty-canvas [PopupMenu] ids — [method _fill_canvas_view_popup] / [method _on_canvas_view_menu_id].
const _CV_REFRESH := 3001
const _CV_FIT := 3002
const _CV_CREATE_STATE_BASE := 3100
const _CV_TOGGLE_FULL_LISTS := 3201
const _CV_TOGGLE_BINDING := 3202
const _CV_TOGGLE_COMPUTED := 3203
const _CV_TOGGLE_WIRE := 3204
const _CV_TOGGLE_EDGE_LABELS := 3205
const _CV_TOGGLE_LEGEND := 3206
const _CV_PRESET_DEFAULT := 3300
const _CV_PRESET_NAMED_BASE := 3310
const _CV_SCOPE_SAVE := 3500
const _CV_SCOPE_MANAGE := 3501
const _CV_SCOPE_PIN := 3502

var _plugin: EditorPlugin
var _actions: UiReactActionController
var _request_dock_refresh: Callable = Callable()

var _hint: RichTextLabel
var _hidden_chrome_host: Control
var _cb_full_lists: CheckBox
var _visual_host: VBoxContainer
var _graph_body_split: VSplitContainer
var _below_graph_column: VBoxContainer
var _graph_split_restored: bool = false
var _graph_split_restore_attempts: int = 0
var _legend_host: VBoxContainer
var _legend_nodes_row: HBoxContainer
var _legend_edges_row: HBoxContainer
var _legend_mid_spacer: Control
var _legend_group_nodes_label: Label
var _legend_group_edges_label: Label
var _cb_bind: CheckBox
var _cb_computed: CheckBox
var _cb_wire: CheckBox
var _cb_edge_labels: CheckBox
var _graph_view: Control
var _details_scroll: ScrollContainer
var _details: RichTextLabel
## [UiReactDockWireRulesSection]
var _wire_rules_section: Variant = null
var _selection_actions_context_popup: PopupMenu
var _canvas_view_context_popup: PopupMenu
var _canvas_view_preset_names: PackedStringArray

var _wire_payload_box: VBoxContainer
var _wire_rule_id_row: HBoxContainer
var _wire_rule_id_edit: LineEdit
var _btn_wire_rule_id_apply: Button
var _wire_enabled_row: HBoxContainer
var _wire_enabled_cb: CheckBox
var _wire_trigger_row: HBoxContainer
var _wire_trigger_option: OptionButton
var _wire_payload_block_commit: bool = false

var _rebind_file_dialog: EditorFileDialog
var _rebind_kind: int = _REBIND_NONE
var _rebind_host_path: String = ""
var _rebind_property: String = ""
var _rebind_wire_host_path: String = ""
var _rebind_wire_rule_index: int = -1
var _rebind_wire_prop: StringName = &""
var _rebind_computed_context: String = ""
var _rebind_computed_source_index: int = -1

var _newlink_binding_popup: PopupMenu
var _newlink_pick_host: Control
var _newlink_pick_component: String = ""
var _newlink_pick_donor: UiState
var _newlink_pick_candidates: Array = []

var _newlink_mixed_popup: PopupMenu
var _newlink_mixed_donor_st: UiState
var _newlink_mixed_host: Control
var _newlink_mixed_component: String = ""
var _newlink_mixed_binding_cands: Array = []
var _newlink_wire_filter_indices: PackedInt32Array = PackedInt32Array()
var _newlink_no_wire_dialog: AcceptDialog

var _newlink_mount_popup: PopupMenu
var _newlink_mount_donor_st: UiState
var _newlink_mount_list: Array = []

var _auto_refresh_timer: Timer

var _last_snap: Variant = null
var _last_focus_id: String = ""
## Scene-relative path for the graph scope host ([method refresh] selection); for wire list focus guard.
var _last_focus_host_path: String = ""
var _last_layout: Dictionary = {}
var _narrative_cache: Dictionary = {}
var _show_full_lists: bool = false

var _selection_kind: int = _SEL_NONE
var _graph_selected_node_id: String = ""
var _graph_selected_edge_index: int = -1
var _last_edge_from_id: String = ""
var _last_edge_to_id: String = ""
var _last_edge_kind: int = -1
var _last_edge_label: String = ""
var _last_details_plain: String = ""

var _create_state_save_dialog: EditorFileDialog
var _create_state_class_pending: String = ""
var _create_and_assign_mode: bool = false
var _create_assign_host_path: String = ""
var _create_assign_prop: StringName = &""
var _create_assign_component: String = ""
var _create_assign_expected_class: StringName = &""

var _scope_preset_option: OptionButton
var _scope_save_name_dialog: AcceptDialog
var _scope_save_name_edit: LineEdit
var _scope_manage_dialog: AcceptDialog
var _scope_manage_list: ItemList
var _layout_max_nodes: int = 200
var _layout_max_edges: int = 400
var _pinned_node_ids: PackedStringArray = PackedStringArray()
var _scope_presets_cache: Array = []
var _scope_preset_block_select: bool = false
## When true, next [AcceptDialog] confirm from Save scope preset also pins [member _graph_selected_node_id].
var _pin_pending_after_save: bool = false


func setup(
	plugin: EditorPlugin,
	actions: UiReactActionController,
	request_dock_refresh: Callable = Callable(),
) -> void:
	_plugin = plugin
	_actions = actions
	_request_dock_refresh = request_dock_refresh
	_build_ui()
	if _details:
		_DockThemeScript.apply_richtext_content(_details, _plugin)
	if _hint:
		_DockThemeScript.apply_richtext_content(_hint, _plugin)
	_apply_graph_body_split_editor_theme()
	_apply_legend_font_sizes()
	_apply_wire_payload_label_font_sizes()
	if _legend_host:
		_legend_host.visible = bool(
			ProjectSettings.get_setting(UiReactDockConfig.KEY_GRAPH_LEGEND_VISIBLE, true)
		)
	_rebuild_scope_preset_dropdown()
	_sync_active_scope_preset_from_settings(true)
	if not tree_exiting.is_connected(_on_explain_panel_tree_exiting):
		tree_exiting.connect(_on_explain_panel_tree_exiting)
	call_deferred(&"_restore_graph_body_split_offset")
	var ei := _plugin.get_editor_interface()
	if not ei.get_selection().selection_changed.is_connected(_on_editor_selection_changed):
		ei.get_selection().selection_changed.connect(_on_editor_selection_changed)


func refresh() -> void:
	if _graph_view == null:
		return
	_set_idle()
	if _plugin == null:
		_set_hint_visible(true)
		_set_hint("Plugin not ready.")
		_clear_stale_snapshot()
		return
	var ei := _plugin.get_editor_interface()
	var root := ei.get_edited_scene_root()
	if root == null:
		_set_hint_visible(true)
		_set_hint("Open a scene to build the dependency graph.")
		_clear_stale_snapshot()
		return
	var sel: Array[Node] = ei.get_selection().get_selected_nodes()
	if sel.size() != 1:
		_set_hint_visible(true)
		_set_hint("Select exactly one [code]UiReact*[/code] node in the edited scene.")
		_clear_stale_snapshot()
		return
	var n: Node = sel[0]
	if not (n is Control):
		_set_hint_visible(true)
		_set_hint("Selection must be a [code]Control[/code] ([code]UiReact*[/code]).")
		_clear_stale_snapshot()
		return
	if not UiReactScannerService.is_react_node(n):
		_set_hint_visible(true)
		_set_hint("Selection is not a [code]UiReact*[/code] control (no ui_react_* script stem).")
		_clear_stale_snapshot()
		return
	if not (n == root or root.is_ancestor_of(n)):
		_set_hint_visible(true)
		_set_hint("Selection must be part of the current edited scene.")
		_clear_stale_snapshot()
		return

	_set_hint_visible(false)
	_narrative_cache.clear()
	var snap = _ExplainBuilderScript.build(root, n as Control)
	_last_snap = snap
	var hp: NodePath = _ExplainBuilderScript._host_path_from_root(root, n as Control)
	_last_focus_id = _ExplainBuilderScript._control_id(hp)
	_last_focus_host_path = str(hp)

	_apply_visual_from_snap_safe(snap, _last_focus_id)


func _on_editor_selection_changed() -> void:
	if _auto_refresh_timer == null:
		return
	_auto_refresh_timer.stop()
	_auto_refresh_timer.start()


func _on_debounced_auto_refresh() -> void:
	if not is_visible_in_tree():
		return
	refresh()


func _apply_visual_from_snap_safe(snap: Variant, focus_id: String) -> void:
	if _graph_view == null:
		return
	var layout: Dictionary = _ExplainLayoutScript.layout_snapshot(
		snap,
		focus_id,
		_layout_max_nodes,
		_layout_max_edges,
		_pinned_node_ids,
	)
	_last_layout = layout
	var centers: Dictionary = layout.get(&"node_centers", {}) as Dictionary
	if centers.is_empty():
		_graph_view.clear_graph()
		_set_details_empty()
		_set_hint_visible(true)
		_set_hint("No nodes in scope for this layout. Lower layout caps, widen bindings, or Refresh after edits.")
		_sync_wire_rules_section()
		return
	(_graph_view as Object).call(&"set_layout", layout)
	_push_visual_filters()
	if _graph_view.has_method(&"select_node_by_id"):
		_graph_view.call(&"select_node_by_id", focus_id)


func _push_visual_filters() -> void:
	if _graph_view == null:
		return
	var b := _cb_bind == null or _cb_bind.button_pressed
	var c := _cb_computed == null or _cb_computed.button_pressed
	var w := _cb_wire == null or _cb_wire.button_pressed
	var lbl := _cb_edge_labels != null and _cb_edge_labels.button_pressed
	(_graph_view as Object).call(&"set_edge_filters", b, c, w, lbl)


func _on_fit_pressed() -> void:
	if _graph_view and _graph_view.has_method(&"reset_view"):
		_graph_view.call(&"reset_view")


func _on_graph_node(id: String) -> void:
	_graph_selected_node_id = id
	_graph_selected_edge_index = -1
	_selection_kind = _SEL_NODE
	_update_focus_button_state()
	_fill_node_details(id)
	_sync_wire_rules_section()


func _on_graph_edge(from_id: String, to_id: String, kind: int, label: String, edge_index: int) -> void:
	_graph_selected_node_id = ""
	_graph_selected_edge_index = edge_index
	_last_edge_from_id = from_id
	_last_edge_to_id = to_id
	_last_edge_kind = kind
	_last_edge_label = label
	_selection_kind = _SEL_EDGE
	_update_focus_button_state()
	_fill_edge_details(from_id, to_id, kind, label, edge_index)
	_sync_wire_rules_section()


func _on_graph_cleared() -> void:
	_graph_selected_node_id = ""
	_graph_selected_edge_index = -1
	_selection_kind = _SEL_NONE
	_update_focus_button_state()
	_set_details_placeholder()
	_sync_wire_rules_section()


func _update_focus_button_state() -> void:
	_sync_wire_rule_id_row()


func _can_pin_node_from_canvas_menu() -> bool:
	return _selection_kind == _SEL_NODE and not _graph_selected_node_id.is_empty()


func _resolve_wire_rules_host_control() -> Control:
	if _plugin == null:
		return null
	var ei := _plugin.get_editor_interface()
	var root := ei.get_edited_scene_root()
	if root == null:
		return null
	if _selection_kind == _SEL_EDGE and _last_edge_kind == _SnapScript.EdgeKind.WIRE_FLOW:
		var edges: Array = _last_layout.get(&"draw_edges", []) as Array
		var idx := _graph_selected_edge_index
		if idx < 0 or idx >= edges.size():
			pass
		else:
			var ev: Variant = edges[idx]
			if ev is Dictionary:
				var wh := str((ev as Dictionary).get(&"wire_host_path", ""))
				if not wh.is_empty() and root.has_node(NodePath(wh)):
					var n: Node = root.get_node(NodePath(wh))
					if n is Control and (&"wire_rules" in n):
						return n as Control
	if _selection_kind == _SEL_NODE and _graph_selected_node_id.begins_with("ctrl:"):
		var pstr := _graph_selected_node_id.substr(5)
		if root.has_node(NodePath(pstr)):
			var n2: Node = root.get_node(NodePath(pstr))
			if n2 is Control and (&"wire_rules" in n2):
				return n2 as Control
	var sel: Array[Node] = ei.get_selection().get_selected_nodes()
	if sel.size() == 1:
		var n3: Node = sel[0]
		if (&"wire_rules" in n3) and n3 is Control and (n3 == root or root.is_ancestor_of(n3)):
			return n3 as Control
	return null


func _resolve_control_host_from_node(node_id: String, d: Dictionary) -> Control:
	if _plugin == null:
		return null
	var ei := _plugin.get_editor_interface()
	var root := ei.get_edited_scene_root()
	if root == null:
		return null
	var path_str := str(d.get(&"control_path", ""))
	if path_str.is_empty() and node_id.begins_with("ctrl:"):
		path_str = node_id.substr(5)
	if path_str.is_empty() or not root.has_node(NodePath(path_str)):
		return null
	var n: Node = root.get_node(NodePath(path_str))
	if n is Control and UiReactScannerService.is_react_node(n as Control):
		return n as Control
	return null


func _sync_wire_rules_section() -> void:
	if _wire_rules_section == null or _plugin == null:
		return
	var sec: Object = _wire_rules_section as Object
	var ei := _plugin.get_editor_interface()
	var root := ei.get_edited_scene_root()
	if root == null:
		sec.call(&"set_target_host", null, null)
		return
	var h := _resolve_wire_rules_host_control()
	if h != null:
		sec.call(&"set_target_host", h, root)
	else:
		sec.call(&"set_target_host", null, null)


func _after_wire_rules_section_commit() -> void:
	if _request_dock_refresh.is_valid():
		_request_dock_refresh.call()
	refresh()


## Graph RMB context menu — same builder as former Actions… MenuButton.
func _fill_selection_actions_popup(popup: PopupMenu) -> void:
	popup.clear()
	const TT_REBIND_BINDING := (
		"Choose another .tres for this binding (undoable). Wire flows: use Rebind wire in/out."
	)
	const TT_REBIND_WIRE_IN := (
		"Choose another input-slot state on this wire row (undoable). Not for computed-only edges."
	)
	const TT_REBIND_WIRE_OUT := (
		"Choose another output-slot state on this wire row (undoable). Not for computed-only edges."
	)
	const TT_REBIND_COMPUTED := (
		"Replace one sources[] entry (undoable). Refresh the graph if this stays disabled."
	)
	const TT_CLEAR_BINDING := "Clear optional binding here; required slots need the Inspector."
	const TT_REMOVE_COMPUTED := "Clear this sources[] slot (undoable). Refresh if context is missing."
	const TT_CLEAR_WIRE := "Clear both wire endpoints in one undo (both must be set)."
	const TT_MOVE_UP := "Swap with previous sources[] entry (undoable)."
	const TT_MOVE_DOWN := "Swap with next sources[] entry (undoable)."
	const TT_REMOVE_SLOT := "Remove index and compact sources[] (undoable)."
	const TT_CREATE_ASSIGN := "New matching .tres on an empty optional binding (undoable)."
	const TT_COPY := "Copy plain-text details to the clipboard."
	const TT_FOCUS := "Open the related scene node or resource in the Inspector when possible."
	const TT_WIRE_REFRESH := "Reload wire list after external edits or Undo."
	const TT_WIRE_COPY_REP := "Copy selected rule report."

	if _selection_kind != _SEL_NONE:
		popup.add_item("Focus in Inspector", _SEL_ACT_FOCUS_INSPECTOR)
		popup.set_item_tooltip(popup.item_count - 1, TT_FOCUS)

	var wire_host := _resolve_wire_rules_host_control()
	if wire_host != null:
		if popup.item_count > 0:
			popup.add_separator()
		var wentries := _WireRuleCatalogScript.rule_script_entries()
		for j: int in range(wentries.size()):
			popup.add_item(
				"Add wire: %s" % String(wentries[j][&"label"]),
				_SEL_ACT_WIRE_ADD_BASE + j,
			)
		popup.add_item("Refresh wire list", _SEL_ACT_WIRE_REFRESH_LIST)
		popup.set_item_tooltip(popup.item_count - 1, TT_WIRE_REFRESH)
		popup.add_item("Copy rule report", _SEL_ACT_WIRE_COPY_RULE_REPORT)
		popup.set_item_tooltip(popup.item_count - 1, TT_WIRE_COPY_REP)
		var cr_i := popup.get_item_index(_SEL_ACT_WIRE_COPY_RULE_REPORT)
		if cr_i >= 0:
			var sec2: Object = _wire_rules_section as Object
			var sel_ix: int = int(sec2.call(&"get_selected_rule_index"))
			popup.set_item_disabled(cr_i, sel_ix < 0)

	var n_before_edge := popup.item_count
	var any_edge_item_will := (
		_can_rebind_binding_edge()
		or _can_rebind_wire_endpoint(true)
		or _can_rebind_wire_endpoint(false)
		or _can_rebind_computed_source()
		or _can_disconnect_binding_edge()
		or _can_disconnect_computed_source()
		or _can_disconnect_wire_edge()
		or _can_move_computed_source_up()
		or _can_move_computed_source_down()
		or _can_remove_computed_source_slot()
		or _can_create_and_assign_binding_edge()
	)
	if n_before_edge > 0 and any_edge_item_will:
		popup.add_separator()

	var rebind_added := false
	if _can_rebind_binding_edge():
		popup.add_item("Rebind to resource…", _SEL_ACT_REBIND_BINDING)
		popup.set_item_tooltip(popup.item_count - 1, TT_REBIND_BINDING)
		rebind_added = true
	if _can_rebind_wire_endpoint(true):
		popup.add_item("Rebind wire input…", _SEL_ACT_REBIND_WIRE_IN)
		popup.set_item_tooltip(popup.item_count - 1, TT_REBIND_WIRE_IN)
		rebind_added = true
	if _can_rebind_wire_endpoint(false):
		popup.add_item("Rebind wire output…", _SEL_ACT_REBIND_WIRE_OUT)
		popup.set_item_tooltip(popup.item_count - 1, TT_REBIND_WIRE_OUT)
		rebind_added = true
	if _can_rebind_computed_source():
		popup.add_item("Rebind computed source…", _SEL_ACT_REBIND_COMPUTED_SRC)
		popup.set_item_tooltip(popup.item_count - 1, TT_REBIND_COMPUTED)
		rebind_added = true

	var disc_will := (
		_can_disconnect_binding_edge()
		or _can_disconnect_computed_source()
		or _can_disconnect_wire_edge()
	)
	var slot_will := (
		_can_move_computed_source_up()
		or _can_move_computed_source_down()
		or _can_remove_computed_source_slot()
	)
	var ca_will := _can_create_and_assign_binding_edge()
	if rebind_added and (disc_will or slot_will or ca_will):
		popup.add_separator()

	var disc_added := false
	if _can_disconnect_binding_edge():
		popup.add_item("Clear optional binding", _SEL_ACT_CLEAR_OPT_BINDING)
		popup.set_item_tooltip(popup.item_count - 1, TT_CLEAR_BINDING)
		disc_added = true
	if _can_disconnect_computed_source():
		popup.add_item("Remove computed dependency", _SEL_ACT_REMOVE_COMPUTED_DEP)
		popup.set_item_tooltip(popup.item_count - 1, TT_REMOVE_COMPUTED)
		disc_added = true
	if _can_disconnect_wire_edge():
		popup.add_item("Clear wire link", _SEL_ACT_CLEAR_WIRE_LINK)
		popup.set_item_tooltip(popup.item_count - 1, TT_CLEAR_WIRE)
		disc_added = true

	if disc_added and slot_will:
		popup.add_separator()

	if _can_move_computed_source_up():
		popup.add_item("Move source up", _SEL_ACT_MOVE_SRC_UP)
		popup.set_item_tooltip(popup.item_count - 1, TT_MOVE_UP)
	if _can_move_computed_source_down():
		popup.add_item("Move source down", _SEL_ACT_MOVE_SRC_DOWN)
		popup.set_item_tooltip(popup.item_count - 1, TT_MOVE_DOWN)
	if _can_remove_computed_source_slot():
		popup.add_item("Remove source slot", _SEL_ACT_REMOVE_SRC_SLOT)
		popup.set_item_tooltip(popup.item_count - 1, TT_REMOVE_SLOT)

	if ca_will:
		if popup.item_count > 0:
			popup.add_separator()
		popup.add_item("Create & assign…", _SEL_ACT_CREATE_ASSIGN_BINDING)
		popup.set_item_tooltip(popup.item_count - 1, TT_CREATE_ASSIGN)

	popup.add_separator()
	popup.add_item("Copy details", _SEL_ACT_COPY_DETAILS)
	popup.set_item_tooltip(popup.item_count - 1, TT_COPY)


func _on_selection_action_id(id: int) -> void:
	var nw := _WireRuleCatalogScript.rule_script_entries().size()
	if id == _SEL_ACT_FOCUS_INSPECTOR:
		_on_focus_inspector_pressed()
		return
	if id == _SEL_ACT_WIRE_REFRESH_LIST:
		if _wire_rules_section != null:
			(_wire_rules_section as Object).call(&"refresh_from_host")
		return
	if id == _SEL_ACT_WIRE_COPY_RULE_REPORT:
		if _wire_rules_section != null:
			(_wire_rules_section as Object).call(&"copy_selected_report_to_clipboard")
		return
	if id >= _SEL_ACT_WIRE_ADD_BASE and id < _SEL_ACT_WIRE_ADD_BASE + nw:
		var cidx := id - _SEL_ACT_WIRE_ADD_BASE
		if _wire_rules_section != null:
			(_wire_rules_section as Object).call(&"append_rule_from_catalog_index", cidx)
		return
	match id:
		_SEL_ACT_REBIND_BINDING:
			_on_rebind_binding_pressed()
		_SEL_ACT_REBIND_WIRE_IN:
			_on_rebind_wire_in_pressed()
		_SEL_ACT_REBIND_WIRE_OUT:
			_on_rebind_wire_out_pressed()
		_SEL_ACT_REBIND_COMPUTED_SRC:
			_on_rebind_computed_source_pressed()
		_SEL_ACT_CLEAR_OPT_BINDING:
			_on_clear_optional_binding_pressed()
		_SEL_ACT_REMOVE_COMPUTED_DEP:
			_on_remove_computed_dependency_pressed()
		_SEL_ACT_CLEAR_WIRE_LINK:
			_on_clear_wire_link_pressed()
		_SEL_ACT_MOVE_SRC_UP:
			_on_move_computed_source_up_pressed()
		_SEL_ACT_MOVE_SRC_DOWN:
			_on_move_computed_source_down_pressed()
		_SEL_ACT_REMOVE_SRC_SLOT:
			_on_remove_computed_source_slot_pressed()
		_SEL_ACT_CREATE_ASSIGN_BINDING:
			_on_create_assign_binding_pressed()
		_SEL_ACT_COPY_DETAILS:
			_on_copy_details_pressed()
		_:
			pass


func _sync_hidden_preset_option_index() -> void:
	if _scope_preset_option == null:
		return
	var active: String = String(UiReactDockConfig.get_active_graph_scope_preset_name()).strip_edges()
	_scope_preset_block_select = true
	if active.is_empty() or active.to_lower() == "default":
		_scope_preset_option.select(0)
		_scope_preset_block_select = false
		return
	for i in range(_scope_preset_option.item_count):
		if str(_scope_preset_option.get_item_metadata(i)) == active:
			_scope_preset_option.select(i)
			_scope_preset_block_select = false
			return
	_scope_preset_option.select(0)
	_scope_preset_block_select = false


func _apply_scope_preset_by_name(preset_name: String) -> void:
	_rebuild_scope_preset_dropdown()
	var name := preset_name.strip_edges()
	UiReactDockConfig.set_active_graph_scope_preset_name(name)
	if name.is_empty() or name.to_lower() == "default":
		_apply_scope_dict_to_ui(_default_scope_dict())
	else:
		var found := false
		for it: Variant in _scope_presets_cache:
			if it is Dictionary:
				var pd: Dictionary = _preset_from_variant(it)
				if String(pd.get("name", "")) == name:
					_apply_scope_dict_to_ui(pd)
					found = true
					break
		if not found:
			_apply_scope_dict_to_ui(_default_scope_dict())
			UiReactDockConfig.set_active_graph_scope_preset_name("")
	_sync_hidden_preset_option_index()
	refresh()


func _fill_canvas_view_popup(popup: PopupMenu) -> void:
	popup.clear()
	_canvas_view_preset_names.clear()
	popup.add_item("Refresh", _CV_REFRESH)
	popup.set_item_tooltip(popup.item_count - 1, "Rebuild graph from current selection and scene.")
	popup.add_item("Fit view", _CV_FIT)
	popup.set_item_tooltip(popup.item_count - 1, "Reset pan/zoom on the graph.")
	popup.add_separator()
	var cnames: PackedStringArray = _GraphFactoryScript.factory_state_class_names()
	for ci in range(cnames.size()):
		var csn := String(cnames[ci])
		popup.add_item("New %s…" % csn, _CV_CREATE_STATE_BASE + ci)
	popup.add_separator()

	popup.add_item("Full lists", _CV_TOGGLE_FULL_LISTS)
	popup.set_item_tooltip(popup.item_count - 1, "Uncap upstream/downstream lines in the details pane.")
	popup.set_item_as_checkable(popup.item_count - 1, true)
	popup.set_item_checked(popup.item_count - 1, _cb_full_lists != null and _cb_full_lists.button_pressed)
	popup.add_item("Show binding edges", _CV_TOGGLE_BINDING)
	popup.set_item_tooltip(popup.item_count - 1, "Toggle binding edges (state → control property).")
	popup.set_item_as_checkable(popup.item_count - 1, true)
	popup.set_item_checked(popup.item_count - 1, _cb_bind != null and _cb_bind.button_pressed)
	popup.add_item("Show computed edges", _CV_TOGGLE_COMPUTED)
	popup.set_item_tooltip(popup.item_count - 1, "Toggle computed-source edges.")
	popup.set_item_as_checkable(popup.item_count - 1, true)
	popup.set_item_checked(popup.item_count - 1, _cb_computed != null and _cb_computed.button_pressed)
	popup.add_item("Show wire edges", _CV_TOGGLE_WIRE)
	popup.set_item_tooltip(popup.item_count - 1, "Toggle wire-rule flow edges.")
	popup.set_item_as_checkable(popup.item_count - 1, true)
	popup.set_item_checked(popup.item_count - 1, _cb_wire != null and _cb_wire.button_pressed)
	popup.add_item("All edge labels", _CV_TOGGLE_EDGE_LABELS)
	popup.set_item_tooltip(
		popup.item_count - 1, "Short labels on every edge; selection still expands below."
	)
	popup.set_item_as_checkable(popup.item_count - 1, true)
	popup.set_item_checked(popup.item_count - 1, _cb_edge_labels != null and _cb_edge_labels.button_pressed)
	popup.add_item("Show legend", _CV_TOGGLE_LEGEND)
	popup.set_item_tooltip(popup.item_count - 1, "Show the node/edge color key above the graph.")
	popup.set_item_as_checkable(popup.item_count - 1, true)
	popup.set_item_checked(popup.item_count - 1, _legend_host != null and _legend_host.visible)
	popup.add_separator()
	popup.add_item("Preset: Default", _CV_PRESET_DEFAULT)
	popup.set_item_tooltip(popup.item_count - 1, "Built-in scope (not a saved preset).")
	var names: Array[String] = []
	for it: Variant in UiReactDockConfig.load_graph_scope_presets_raw():
		if it is Dictionary:
			var nm := String((it as Dictionary).get("name", "")).strip_edges()
			if not nm.is_empty() and nm.to_lower() != "default":
				names.append(nm)
	names.sort()
	for i in range(names.size()):
		var nm2: String = names[i]
		popup.add_item("Preset: %s" % nm2, _CV_PRESET_NAMED_BASE + i)
		_canvas_view_preset_names.append(nm2)
	popup.add_separator()
	popup.add_item("Save scope preset as…", _CV_SCOPE_SAVE)
	popup.set_item_tooltip(popup.item_count - 1, "Save current scope settings as a named preset.")
	popup.add_item("Manage scope presets…", _CV_SCOPE_MANAGE)
	popup.set_item_tooltip(popup.item_count - 1, "Delete saved scope presets.")
	popup.add_item("Pin node", _CV_SCOPE_PIN)
	popup.set_item_tooltip(
		popup.item_count - 1,
		"Pin the selection to the active preset; Default prompts to save a named preset first.",
	)
	var pin_idx := popup.get_item_index(_CV_SCOPE_PIN)
	if pin_idx >= 0:
		popup.set_item_disabled(pin_idx, not _can_pin_node_from_canvas_menu())


func _on_canvas_view_menu_id(id: int) -> void:
	if _canvas_view_context_popup == null:
		return
	var n_create := _GraphFactoryScript.factory_state_class_names().size()
	if id == _CV_REFRESH:
		refresh()
		return
	if id == _CV_FIT:
		_on_fit_pressed()
		return
	if id >= _CV_CREATE_STATE_BASE and id < _CV_CREATE_STATE_BASE + n_create:
		_on_create_state_menu_id(id - _CV_CREATE_STATE_BASE)
		return
	if id == _CV_TOGGLE_FULL_LISTS:
		if _cb_full_lists != null:
			var on := not _cb_full_lists.button_pressed
			_cb_full_lists.button_pressed = on
			_on_full_lists_toggled(on)
		return
	if id == _CV_TOGGLE_BINDING:
		if _cb_bind != null:
			_cb_bind.button_pressed = not _cb_bind.button_pressed
			_push_visual_filters()
			refresh()
		return
	if id == _CV_TOGGLE_COMPUTED:
		if _cb_computed != null:
			_cb_computed.button_pressed = not _cb_computed.button_pressed
			_push_visual_filters()
			refresh()
		return
	if id == _CV_TOGGLE_WIRE:
		if _cb_wire != null:
			_cb_wire.button_pressed = not _cb_wire.button_pressed
			_push_visual_filters()
			refresh()
		return
	if id == _CV_TOGGLE_EDGE_LABELS:
		if _cb_edge_labels != null:
			_cb_edge_labels.button_pressed = not _cb_edge_labels.button_pressed
			_push_visual_filters()
			refresh()
		return
	if id == _CV_TOGGLE_LEGEND:
		if _legend_host != null:
			_legend_host.visible = not _legend_host.visible
			UiReactDockConfig.save_ui_preference(
				UiReactDockConfig.KEY_GRAPH_LEGEND_VISIBLE, _legend_host.visible
			)
		return
	if id == _CV_PRESET_DEFAULT:
		_apply_scope_preset_by_name("")
		return
	if id >= _CV_PRESET_NAMED_BASE:
		var pi := id - _CV_PRESET_NAMED_BASE
		if pi >= 0 and pi < _canvas_view_preset_names.size():
			_apply_scope_preset_by_name(_canvas_view_preset_names[pi])
		return
	if id == _CV_SCOPE_SAVE:
		_on_scope_save_as_pressed()
		return
	if id == _CV_SCOPE_MANAGE:
		_on_scope_manage_pressed()
		return
	if id == _CV_SCOPE_PIN:
		_on_pin_node_pressed()
		return


func _on_canvas_view_menu_requested(at_local: Vector2) -> void:
	if _canvas_view_context_popup == null or _graph_view == null:
		return
	_fill_canvas_view_popup(_canvas_view_context_popup)
	var gp: Vector2 = _graph_view.get_screen_transform() * at_local
	_canvas_view_context_popup.position = Vector2i(gp)
	_canvas_view_context_popup.popup()


func _on_graph_context_menu_requested(at_local: Vector2) -> void:
	if _selection_actions_context_popup == null or _graph_view == null:
		return
	_fill_selection_actions_popup(_selection_actions_context_popup)
	var gp: Vector2 = _graph_view.get_screen_transform() * at_local
	_selection_actions_context_popup.position = Vector2i(gp)
	_selection_actions_context_popup.popup()


func _can_disconnect_binding_edge() -> bool:
	if not _can_rebind_binding_edge():
		return false
	var ei := _plugin.get_editor_interface()
	var root := ei.get_edited_scene_root()
	if root == null:
		return false
	var edges: Array = _last_layout.get(&"draw_edges", []) as Array
	var idx := _graph_selected_edge_index
	if idx < 0 or idx >= edges.size():
		return false
	var ev: Variant = edges[idx]
	if ev is not Dictionary:
		return false
	var ed: Dictionary = ev as Dictionary
	var hp := str(ed.get(&"host_path", ""))
	var bp := str(ed.get(&"binding_property", ""))
	if bp.is_empty():
		bp = str(ed.get(&"label", ""))
	if hp.is_empty() or bp.is_empty():
		return false
	if not root.has_node(NodePath(hp)):
		return false
	var n: Node = root.get_node(NodePath(hp))
	if not (n is Control):
		return false
	var host := n as Control
	var comp := UiReactScannerService.get_component_name_from_script(host.get_script() as Script)
	if comp.is_empty():
		return false
	var prop_sn := StringName(bp)
	if not UiReactGraphNewBindingService.binding_export_is_optional(comp, prop_sn):
		return false
	return host.get(prop_sn) != null


func _can_disconnect_computed_source() -> bool:
	return _can_rebind_computed_source()


func _can_disconnect_wire_edge() -> bool:
	if not _can_rebind_wire_endpoint(true) or not _can_rebind_wire_endpoint(false):
		return false
	var ei := _plugin.get_editor_interface()
	var root := ei.get_edited_scene_root()
	if root == null:
		return false
	var edges: Array = _last_layout.get(&"draw_edges", []) as Array
	var idx := _graph_selected_edge_index
	if idx < 0 or idx >= edges.size():
		return false
	var ev: Variant = edges[idx]
	if ev is not Dictionary:
		return false
	var ed: Dictionary = ev as Dictionary
	var wh := str(ed.get(&"wire_host_path", ""))
	var wi := int(ed.get(&"wire_rule_index", -1))
	var win := str(ed.get(&"wire_in_property", ""))
	var wout := str(ed.get(&"wire_out_property", ""))
	if wh.is_empty() or not root.has_node(NodePath(wh)):
		return false
	var host: Node = root.get_node(NodePath(wh))
	if not (host is Control):
		return false
	var arr := _WireGraphEditScript.duplicate_wire_rules_array(host as Control)
	if wi < 0 or wi >= arr.size():
		return false
	var rule: Variant = arr[wi]
	if rule == null or not (rule is UiReactWireRule):
		return false
	var ip := StringName(win)
	var op := StringName(wout)
	if not ip in rule or not op in rule:
		return false
	return (rule as Object).get(ip) != null and (rule as Object).get(op) != null


func _current_computed_edge_sources_size() -> int:
	if not _can_rebind_computed_source():
		return -1
	var ei := _plugin.get_editor_interface()
	var root := ei.get_edited_scene_root()
	if root == null:
		return -1
	var edges: Array = _last_layout.get(&"draw_edges", []) as Array
	var idx := _graph_selected_edge_index
	if idx < 0 or idx >= edges.size():
		return -1
	var ed: Dictionary = edges[idx] as Dictionary
	var hp := str(ed.get(&"host_path", ""))
	var ctx := str(ed.get(&"computed_context", ""))
	if hp.is_empty() or not root.has_node(NodePath(hp)):
		return -1
	var n: Node = root.get_node(NodePath(hp))
	if not (n is Control):
		return -1
	var c: Variant = _ComputedRebindScript.try_resolve_computed(n as Control, ctx)
	if c == null:
		return -1
	var raw: Variant = c.get(&"sources")
	if typeof(raw) != TYPE_ARRAY:
		return -1
	return (raw as Array).size()


func _can_move_computed_source_up() -> bool:
	if not _can_rebind_computed_source():
		return false
	var si := _computed_source_index_from_selection()
	return si > 0


func _can_move_computed_source_down() -> bool:
	if not _can_rebind_computed_source():
		return false
	var si := _computed_source_index_from_selection()
	var sz := _current_computed_edge_sources_size()
	return si >= 0 and sz > 0 and si < sz - 1


func _can_remove_computed_source_slot() -> bool:
	return _can_rebind_computed_source() and _current_computed_edge_sources_size() > 0


func _computed_source_index_from_selection() -> int:
	if _selection_kind != _SEL_EDGE or _graph_selected_edge_index < 0:
		return -1
	var edges: Array = _last_layout.get(&"draw_edges", []) as Array
	var idx := _graph_selected_edge_index
	if idx < 0 or idx >= edges.size():
		return -1
	var ed: Dictionary = edges[idx] as Dictionary
	return int(ed.get(&"computed_source_index", -1))


func _sync_wire_rule_id_row() -> void:
	if _wire_payload_box == null:
		return
	var show_row := false
	var rid := ""
	var en := true
	var trig_ord := int(UiReactWireRule.TriggerKind.SELECTION_CHANGED)
	if (
		_plugin != null
		and _selection_kind == _SEL_EDGE
		and _last_edge_kind == _SnapScript.EdgeKind.WIRE_FLOW
	):
		var ei := _plugin.get_editor_interface()
		var root := ei.get_edited_scene_root()
		if root != null:
			var edges: Array = _last_layout.get(&"draw_edges", []) as Array
			var idx := _graph_selected_edge_index
			if idx >= 0 and idx < edges.size():
				var ev: Variant = edges[idx]
				if ev is Dictionary:
					var ed: Dictionary = ev as Dictionary
					if _edge_allows_wire_rebind(ed, root, true) and _edge_allows_wire_rebind(ed, root, false):
						var wh := str(ed.get(&"wire_host_path", ""))
						var wi := int(ed.get(&"wire_rule_index", -1))
						if not wh.is_empty() and root.has_node(NodePath(wh)):
							var host_n: Node = root.get_node(NodePath(wh))
							if host_n is Control:
								var arr := _WireGraphEditScript.duplicate_wire_rules_array(
									host_n as Control
								)
								if wi >= 0 and wi < arr.size() and arr[wi] is UiReactWireRule:
									var rule := arr[wi] as UiReactWireRule
									rid = rule.rule_id
									en = rule.enabled
									trig_ord = int(rule.trigger)
									show_row = true
	_wire_payload_box.visible = show_row
	if _wire_rule_id_edit != null and show_row:
		if _wire_rule_id_edit.text != rid:
			_wire_rule_id_edit.text = rid
	if _wire_enabled_cb != null and show_row:
		_wire_payload_block_commit = true
		_wire_enabled_cb.button_pressed = en
		_wire_payload_block_commit = false
	if _wire_trigger_option != null and show_row:
		var pick := -1
		for ti in range(_wire_trigger_option.item_count):
			if _wire_trigger_option.get_item_id(ti) == trig_ord:
				pick = ti
				break
		_wire_payload_block_commit = true
		if pick >= 0:
			_wire_trigger_option.select(pick)
		_wire_payload_block_commit = false


func _attempt_graph_edge_disconnect() -> void:
	if _plugin == null or _actions == null:
		return
	if _selection_kind != _SEL_EDGE or _graph_selected_edge_index < 0:
		return
	var root := _plugin.get_editor_interface().get_edited_scene_root()
	if root == null:
		return
	var edges: Array = _last_layout.get(&"draw_edges", []) as Array
	var idx := _graph_selected_edge_index
	if idx < 0 or idx >= edges.size():
		return
	var ev: Variant = edges[idx]
	if ev is not Dictionary:
		return
	var ed: Dictionary = ev as Dictionary
	var k := int(ed.get(&"kind", -1))
	var committed := false
	if k == _SnapScript.EdgeKind.BINDING:
		if not _can_disconnect_binding_edge():
			push_warning(
				"Ui React: clear binding only for optional exports with a current assignment (use Inspector for required slots)."
			)
			return
		var hp := str(ed.get(&"host_path", ""))
		var bp := str(ed.get(&"binding_property", ""))
		if bp.is_empty():
			bp = str(ed.get(&"label", ""))
		var host_n: Node = root.get_node(NodePath(hp))
		var comp := UiReactScannerService.get_component_name_from_script((host_n as Control).get_script() as Script)
		committed = UiReactGraphNewBindingService.try_commit_clear_binding_export(
			host_n as Control, comp, StringName(bp), _actions
		)
	elif k == _SnapScript.EdgeKind.COMPUTED_SOURCE:
		if not _can_disconnect_computed_source():
			push_warning("Ui React: cannot clear this computed source (refresh the graph or check host path).")
			return
		var hp_c := str(ed.get(&"host_path", ""))
		var ctx := str(ed.get(&"computed_context", ""))
		var csi := int(ed.get(&"computed_source_index", -1))
		var host_c: Node = root.get_node(NodePath(hp_c))
		committed = _ComputedRebindScript.try_commit_clear_source(host_c as Control, ctx, csi, _actions)
	elif k == _SnapScript.EdgeKind.WIRE_FLOW:
		if not _can_disconnect_wire_edge():
			push_warning(
				"Ui React: clear wire link only when both input and output slots are set on this edge (use Inspector otherwise)."
			)
			return
		var wh := str(ed.get(&"wire_host_path", ""))
		var wi := int(ed.get(&"wire_rule_index", -1))
		var win := StringName(str(ed.get(&"wire_in_property", "")))
		var wout := StringName(str(ed.get(&"wire_out_property", "")))
		var host_w: Node = root.get_node(NodePath(wh))
		committed = _WireGraphEditScript.try_commit_wire_edge_disconnect(
			host_w as Control, wi, win, wout, _actions
		)
	else:
		push_warning("Ui React: Delete clears binding, computed-source, or wire-flow edges only.")
		return
	if not committed:
		return
	if _request_dock_refresh.is_valid():
		_request_dock_refresh.call()
	refresh()


func _on_clear_optional_binding_pressed() -> void:
	if _selection_kind != _SEL_EDGE or _last_edge_kind != _SnapScript.EdgeKind.BINDING:
		return
	_attempt_graph_edge_disconnect()


func _on_remove_computed_dependency_pressed() -> void:
	if _selection_kind != _SEL_EDGE or _last_edge_kind != _SnapScript.EdgeKind.COMPUTED_SOURCE:
		return
	_attempt_graph_edge_disconnect()


func _on_clear_wire_link_pressed() -> void:
	if _selection_kind != _SEL_EDGE or _last_edge_kind != _SnapScript.EdgeKind.WIRE_FLOW:
		return
	_attempt_graph_edge_disconnect()


func _on_move_computed_source_up_pressed() -> void:
	if _plugin == null or _actions == null:
		return
	if not _can_move_computed_source_up():
		return
	var root := _plugin.get_editor_interface().get_edited_scene_root()
	if root == null:
		return
	var edges: Array = _last_layout.get(&"draw_edges", []) as Array
	var idx := _graph_selected_edge_index
	if idx < 0 or idx >= edges.size():
		return
	var ed: Dictionary = edges[idx] as Dictionary
	var hp := str(ed.get(&"host_path", ""))
	var ctx := str(ed.get(&"computed_context", ""))
	var si := int(ed.get(&"computed_source_index", -1))
	var host_n: Node = root.get_node(NodePath(hp))
	if not _ComputedRebindScript.try_commit_swap_sources(
		host_n as Control, ctx, si, si - 1, _actions
	):
		return
	if _request_dock_refresh.is_valid():
		_request_dock_refresh.call()
	refresh()


func _on_move_computed_source_down_pressed() -> void:
	if _plugin == null or _actions == null:
		return
	if not _can_move_computed_source_down():
		return
	var root := _plugin.get_editor_interface().get_edited_scene_root()
	if root == null:
		return
	var edges: Array = _last_layout.get(&"draw_edges", []) as Array
	var idx := _graph_selected_edge_index
	if idx < 0 or idx >= edges.size():
		return
	var ed: Dictionary = edges[idx] as Dictionary
	var hp := str(ed.get(&"host_path", ""))
	var ctx := str(ed.get(&"computed_context", ""))
	var si := int(ed.get(&"computed_source_index", -1))
	var host_n: Node = root.get_node(NodePath(hp))
	if not _ComputedRebindScript.try_commit_swap_sources(
		host_n as Control, ctx, si, si + 1, _actions
	):
		return
	if _request_dock_refresh.is_valid():
		_request_dock_refresh.call()
	refresh()


func _on_remove_computed_source_slot_pressed() -> void:
	if _plugin == null or _actions == null:
		return
	if not _can_remove_computed_source_slot():
		return
	var root := _plugin.get_editor_interface().get_edited_scene_root()
	if root == null:
		return
	var edges: Array = _last_layout.get(&"draw_edges", []) as Array
	var idx := _graph_selected_edge_index
	if idx < 0 or idx >= edges.size():
		return
	var ed: Dictionary = edges[idx] as Dictionary
	var hp := str(ed.get(&"host_path", ""))
	var ctx := str(ed.get(&"computed_context", ""))
	var si := int(ed.get(&"computed_source_index", -1))
	var host_n: Node = root.get_node(NodePath(hp))
	if not _ComputedRebindScript.try_commit_remove_source_at(
		host_n as Control, ctx, si, _actions
	):
		return
	if _request_dock_refresh.is_valid():
		_request_dock_refresh.call()
	refresh()


func _on_wire_rule_id_apply_pressed() -> void:
	if _plugin == null or _actions == null or _wire_rule_id_edit == null:
		return
	if _selection_kind != _SEL_EDGE or _last_edge_kind != _SnapScript.EdgeKind.WIRE_FLOW:
		return
	var ei := _plugin.get_editor_interface()
	var root := ei.get_edited_scene_root()
	if root == null:
		return
	var edges: Array = _last_layout.get(&"draw_edges", []) as Array
	var idx := _graph_selected_edge_index
	if idx < 0 or idx >= edges.size():
		return
	var ed: Dictionary = edges[idx] as Dictionary
	if not _edge_allows_wire_rebind(ed, root, true) or not _edge_allows_wire_rebind(ed, root, false):
		return
	var wh := str(ed.get(&"wire_host_path", ""))
	var wi := int(ed.get(&"wire_rule_index", -1))
	var host_n: Node = root.get_node(NodePath(wh))
	if not _WireGraphEditScript.try_commit_wire_rule_id(
		host_n as Control, wi, _wire_rule_id_edit.text, _actions
	):
		return
	if _request_dock_refresh.is_valid():
		_request_dock_refresh.call()
	refresh()


func _on_wire_enabled_toggled(pressed: bool) -> void:
	if _wire_payload_block_commit or _plugin == null or _actions == null:
		return
	if _selection_kind != _SEL_EDGE or _last_edge_kind != _SnapScript.EdgeKind.WIRE_FLOW:
		return
	var ei := _plugin.get_editor_interface()
	var root := ei.get_edited_scene_root()
	if root == null:
		return
	var edges: Array = _last_layout.get(&"draw_edges", []) as Array
	var idx := _graph_selected_edge_index
	if idx < 0 or idx >= edges.size():
		return
	var ed: Dictionary = edges[idx] as Dictionary
	if not _edge_allows_wire_rebind(ed, root, true) or not _edge_allows_wire_rebind(ed, root, false):
		return
	var wh := str(ed.get(&"wire_host_path", ""))
	var wi := int(ed.get(&"wire_rule_index", -1))
	var host_n: Node = root.get_node(NodePath(wh))
	if not _WireGraphEditScript.try_commit_wire_rule_enabled(
		host_n as Control, wi, pressed, _actions
	):
		_wire_payload_block_commit = true
		_wire_enabled_cb.button_pressed = not pressed
		_wire_payload_block_commit = false
		return
	if _request_dock_refresh.is_valid():
		_request_dock_refresh.call()
	refresh()


func _on_wire_trigger_selected(index: int) -> void:
	if _wire_payload_block_commit or _plugin == null or _actions == null or _wire_trigger_option == null:
		return
	if _selection_kind != _SEL_EDGE or _last_edge_kind != _SnapScript.EdgeKind.WIRE_FLOW:
		return
	var ord := _wire_trigger_option.get_item_id(index)
	var ei := _plugin.get_editor_interface()
	var root := ei.get_edited_scene_root()
	if root == null:
		return
	var edges: Array = _last_layout.get(&"draw_edges", []) as Array
	var idx := _graph_selected_edge_index
	if idx < 0 or idx >= edges.size():
		return
	var ed: Dictionary = edges[idx] as Dictionary
	if not _edge_allows_wire_rebind(ed, root, true) or not _edge_allows_wire_rebind(ed, root, false):
		return
	var wh := str(ed.get(&"wire_host_path", ""))
	var wi := int(ed.get(&"wire_rule_index", -1))
	var host_n: Node = root.get_node(NodePath(wh))
	if not _WireGraphEditScript.try_commit_wire_rule_trigger(
		host_n as Control, wi, ord, _actions
	):
		return
	if _request_dock_refresh.is_valid():
		_request_dock_refresh.call()
	refresh()


func _edge_allows_binding_rebind(ed: Dictionary, root: Node) -> bool:
	if root == null:
		return false
	var hp := str(ed.get(&"host_path", ""))
	var bp := str(ed.get(&"binding_property", ""))
	if bp.is_empty():
		bp = str(ed.get(&"label", ""))
	if hp.is_empty() or bp.is_empty():
		return false
	if not root.has_node(NodePath(hp)):
		return false
	var n: Node = root.get_node(NodePath(hp))
	if not (n is Control):
		return false
	return StringName(bp) in n


func _edge_allows_wire_rebind(ed: Dictionary, root: Node, for_input: bool) -> bool:
	if root == null:
		return false
	var wh := str(ed.get(&"wire_host_path", ""))
	var wi := int(ed.get(&"wire_rule_index", -1))
	var win := str(ed.get(&"wire_in_property", ""))
	var wout := str(ed.get(&"wire_out_property", ""))
	var prop_str := win if for_input else wout
	if wh.is_empty() or wi < 0 or prop_str.is_empty():
		return false
	if not root.has_node(NodePath(wh)):
		return false
	var host: Node = root.get_node(NodePath(wh))
	if not (host is Control):
		return false
	var ctl := host as Control
	if not (&"wire_rules" in ctl):
		return false
	var wr: Variant = ctl.get(&"wire_rules")
	if wr == null:
		return false
	var arr: Array = wr as Array if wr is Array else []
	if wi >= arr.size():
		return false
	var rule_var: Variant = arr[wi]
	if rule_var == null or not (rule_var is UiReactWireRule):
		return false
	var rule := rule_var as UiReactWireRule
	return StringName(prop_str) in rule


func _edge_allows_computed_rebind(ed: Dictionary, root: Node) -> bool:
	if root == null:
		return false
	var cc := str(ed.get(&"computed_context", ""))
	var hp := str(ed.get(&"host_path", ""))
	var si := int(ed.get(&"computed_source_index", -1))
	if cc.is_empty() or hp.is_empty() or si < 0:
		return false
	if not root.has_node(NodePath(hp)):
		return false
	var n: Node = root.get_node(NodePath(hp))
	if not (n is Control):
		return false
	var c: Variant = _ComputedRebindScript.try_resolve_computed(n as Control, cc)
	if c == null:
		return false
	var raw: Variant = c.get(&"sources")
	if typeof(raw) != TYPE_ARRAY:
		return false
	var arr: Array = raw as Array
	return si < arr.size()


func _can_rebind_binding_edge() -> bool:
	if _plugin == null or _actions == null:
		return false
	if _selection_kind != _SEL_EDGE or _last_edge_kind != _SnapScript.EdgeKind.BINDING:
		return false
	var ei := _plugin.get_editor_interface()
	var root := ei.get_edited_scene_root()
	if root == null:
		return false
	var edges: Array = _last_layout.get(&"draw_edges", []) as Array
	var idx := _graph_selected_edge_index
	if idx < 0 or idx >= edges.size():
		return false
	var ev: Variant = edges[idx]
	if ev is not Dictionary:
		return false
	return _edge_allows_binding_rebind(ev as Dictionary, root)


func _can_rebind_wire_endpoint(for_input: bool) -> bool:
	if _plugin == null or _actions == null:
		return false
	if _selection_kind != _SEL_EDGE or _last_edge_kind != _SnapScript.EdgeKind.WIRE_FLOW:
		return false
	var ei := _plugin.get_editor_interface()
	var root := ei.get_edited_scene_root()
	if root == null:
		return false
	var edges: Array = _last_layout.get(&"draw_edges", []) as Array
	var idx := _graph_selected_edge_index
	if idx < 0 or idx >= edges.size():
		return false
	var ev: Variant = edges[idx]
	if ev is not Dictionary:
		return false
	return _edge_allows_wire_rebind(ev as Dictionary, root, for_input)


func _can_rebind_computed_source() -> bool:
	if _plugin == null or _actions == null:
		return false
	if _selection_kind != _SEL_EDGE or _last_edge_kind != _SnapScript.EdgeKind.COMPUTED_SOURCE:
		return false
	var ei := _plugin.get_editor_interface()
	var root := ei.get_edited_scene_root()
	if root == null:
		return false
	var edges: Array = _last_layout.get(&"draw_edges", []) as Array
	var idx := _graph_selected_edge_index
	if idx < 0 or idx >= edges.size():
		return false
	var ev: Variant = edges[idx]
	if ev is not Dictionary:
		return false
	return _edge_allows_computed_rebind(ev as Dictionary, root)


func _reconnect_can_start(edge_idx: int, node_id: String) -> bool:
	if _plugin == null or _actions == null:
		return false
	var ei := _plugin.get_editor_interface()
	var root := ei.get_edited_scene_root()
	if root == null:
		return false
	var edges: Array = _last_layout.get(&"draw_edges", []) as Array
	if edge_idx < 0 or edge_idx >= edges.size():
		return false
	var ev: Variant = edges[edge_idx]
	if ev is not Dictionary:
		return false
	var ed: Dictionary = ev as Dictionary
	var k := int(ed.get(&"kind", -1))
	if k == _SnapScript.EdgeKind.BINDING:
		return node_id == str(ed.get(&"from_id", "")) and _edge_allows_binding_rebind(ed, root)
	if k == _SnapScript.EdgeKind.COMPUTED_SOURCE:
		return node_id == str(ed.get(&"from_id", "")) and _edge_allows_computed_rebind(ed, root)
	if k == _SnapScript.EdgeKind.WIRE_FLOW:
		var fid := str(ed.get(&"from_id", ""))
		var tid := str(ed.get(&"to_id", ""))
		if node_id == fid:
			return _edge_allows_wire_rebind(ed, root, true)
		if node_id == tid:
			return _edge_allows_wire_rebind(ed, root, false)
	return false


func _reconnect_can_start_cb(edge_idx: int, node_id: String) -> bool:
	return _reconnect_can_start(edge_idx, node_id)


func _reconnect_is_valid_drop(edge_idx: int, origin_id: String, target_id: String) -> bool:
	if origin_id == target_id or target_id.is_empty():
		return false
	if _plugin == null:
		return false
	var ei := _plugin.get_editor_interface()
	var root := ei.get_edited_scene_root()
	if root == null:
		return false
	var nb: Dictionary = _last_layout.get(&"node_by_id", {}) as Dictionary
	var centers: Dictionary = _last_layout.get(&"node_centers", {}) as Dictionary
	if not nb.has(target_id) or not centers.has(target_id):
		return false
	var td: Dictionary = nb[target_id] as Dictionary
	var nk := int(td.get(&"kind", -1))
	if nk != _SnapScript.NodeKind.UI_STATE and nk != _SnapScript.NodeKind.UI_COMPUTED:
		return false
	var new_st: UiState = _ResolverScript.try_resolve_uistate(root, target_id, nb)
	var old_st: UiState = _ResolverScript.try_resolve_uistate(root, origin_id, nb)
	if new_st == null or old_st == null:
		return false
	if new_st == old_st:
		return false
	return true


func _reconnect_is_valid_target_cb(edge_idx: int, origin_id: String, target_id: String) -> bool:
	return _reconnect_is_valid_drop(edge_idx, origin_id, target_id)


func _newlink_can_start_cb(node_id: String) -> bool:
	return _newlink_can_start(node_id)


func _newlink_can_start(node_id: String) -> bool:
	if _plugin == null or _actions == null:
		return false
	var root := _plugin.get_editor_interface().get_edited_scene_root()
	if root == null:
		return false
	var nb: Dictionary = _last_layout.get(&"node_by_id", {}) as Dictionary
	if not nb.has(node_id):
		return false
	var d: Dictionary = nb[node_id] as Dictionary
	var nk := int(d.get(&"kind", -1))
	if nk != _SnapScript.NodeKind.UI_STATE and nk != _SnapScript.NodeKind.UI_COMPUTED:
		return false
	return _ResolverScript.try_resolve_uistate(root, node_id, nb) != null


func _newlink_is_valid_drop_cb(donor_id: String, target_id: String) -> bool:
	return _newlink_is_valid_drop(donor_id, target_id)


func _newlink_is_valid_drop(donor_id: String, target_id: String) -> bool:
	if donor_id == target_id or donor_id.is_empty() or target_id.is_empty():
		return false
	if _plugin == null:
		return false
	var root := _plugin.get_editor_interface().get_edited_scene_root()
	if root == null:
		return false
	var nb: Dictionary = _last_layout.get(&"node_by_id", {}) as Dictionary
	var centers: Dictionary = _last_layout.get(&"node_centers", {}) as Dictionary
	if not nb.has(donor_id) or not nb.has(target_id):
		return false
	if not centers.has(target_id):
		return false
	var donor_st: UiState = _ResolverScript.try_resolve_uistate(root, donor_id, nb)
	if donor_st == null:
		return false
	var td: Dictionary = nb[target_id] as Dictionary
	var tk := int(td.get(&"kind", -1))
	if tk == _SnapScript.NodeKind.CONTROL:
		var cp := str(td.get(&"control_path", ""))
		if cp.is_empty() or not root.has_node(NodePath(cp)):
			return false
		var n: Node = root.get_node(NodePath(cp))
		if not (n is Control):
			return false
		var host := n as Control
		var comp := UiReactScannerService.get_component_name_from_script(host.get_script() as Script)
		if comp.is_empty():
			return false
		var dd: Dictionary = nb[donor_id] as Dictionary
		var dk := int(dd.get(&"kind", -1))
		var cands: Array = _NewBindingScript.list_assignable_empty_exports(host, comp, donor_st)
		var has_bind := not cands.is_empty()
		var has_wire := (&"wire_rules" in host) and dk == _SnapScript.NodeKind.UI_STATE
		return has_bind or has_wire
	if tk == _SnapScript.NodeKind.UI_COMPUTED:
		var ehp := str(td.get(&"embedded_host_path", ""))
		var ctx := str(td.get(&"embedded_context", ""))
		if not ehp.is_empty() and not ctx.is_empty():
			if not root.has_node(NodePath(ehp)):
				return false
			var hn: Node = root.get_node(NodePath(ehp))
			if not (hn is Control):
				return false
			return _ComputedRebindScript.can_fill_or_append_computed_sources(hn as Control, ctx)
		var fp := str(td.get(&"state_file_path", ""))
		if fp.is_empty():
			return false
		var res: Resource = load(fp)
		if not (res is UiComputedStringState or res is UiComputedBoolState):
			return false
		var mounts: Array = _ComputedMountsScript.mounts_for_computed_resource(root, res)
		if mounts.is_empty():
			return false
		var m0: Dictionary = mounts[0]
		var mhp := str(m0.get(&"host_path", ""))
		var mctx := str(m0.get(&"computed_context", ""))
		if mhp.is_empty() or mctx.is_empty() or not root.has_node(NodePath(mhp)):
			return false
		var h0: Node = root.get_node(NodePath(mhp))
		if not (h0 is Control):
			return false
		return _ComputedRebindScript.can_fill_or_append_computed_sources(h0 as Control, mctx)
	return false


func _ensure_newlink_binding_popup() -> PopupMenu:
	if _newlink_binding_popup != null:
		return _newlink_binding_popup
	_newlink_binding_popup = PopupMenu.new()
	var bc: Control = _plugin.get_editor_interface().get_base_control()
	bc.add_child(_newlink_binding_popup)
	_newlink_binding_popup.id_pressed.connect(_on_newlink_binding_menu_id)
	return _newlink_binding_popup


func _open_newlink_binding_picker(host: Control, component: String, donor: UiState, candidates: Array) -> void:
	_newlink_pick_host = host
	_newlink_pick_component = component
	_newlink_pick_donor = donor
	_newlink_pick_candidates = candidates.duplicate()
	var m := _ensure_newlink_binding_popup()
	m.clear()
	for i: int in range(_newlink_pick_candidates.size()):
		var row: Variant = _newlink_pick_candidates[i]
		var lab := str((row as Dictionary).get(&"label", ""))
		m.add_item(lab, i)
	var mp: Vector2i = DisplayServer.mouse_get_position()
	m.position = mp
	m.popup()


func _on_newlink_binding_menu_id(menu_id: int) -> void:
	if _newlink_pick_host == null or _newlink_pick_donor == null:
		return
	if menu_id < 0 or menu_id >= _newlink_pick_candidates.size():
		return
	var row: Dictionary = _newlink_pick_candidates[menu_id] as Dictionary
	var prop: StringName = row[&"property"] as StringName
	if not _NewBindingScript.try_commit_assign(
		_newlink_pick_host, _newlink_pick_component, prop, _newlink_pick_donor, _actions
	):
		_newlink_pick_host = null
		_newlink_pick_donor = null
		_newlink_pick_candidates.clear()
		return
	if _request_dock_refresh.is_valid():
		_request_dock_refresh.call()
	refresh()
	_newlink_pick_host = null
	_newlink_pick_donor = null
	_newlink_pick_candidates.clear()


func _on_graph_newlink_drag_ended(donor_id: String, target_id: String) -> void:
	if _plugin == null or _actions == null or donor_id.is_empty() or target_id.is_empty():
		return
	if not _newlink_is_valid_drop(donor_id, target_id):
		return
	var root := _plugin.get_editor_interface().get_edited_scene_root()
	if root == null:
		return
	var nb: Dictionary = _last_layout.get(&"node_by_id", {}) as Dictionary
	var donor_st: UiState = _ResolverScript.try_resolve_uistate(root, donor_id, nb)
	if donor_st == null:
		return
	var td: Dictionary = nb[target_id] as Dictionary
	var tk := int(td.get(&"kind", -1))
	var committed := false
	if tk == _SnapScript.NodeKind.CONTROL:
		var cp := str(td.get(&"control_path", ""))
		if cp.is_empty() or not root.has_node(NodePath(cp)):
			return
		var n: Node = root.get_node(NodePath(cp))
		if not (n is Control):
			return
		var host := n as Control
		var comp := UiReactScannerService.get_component_name_from_script(host.get_script() as Script)
		var dd: Dictionary = nb[donor_id] as Dictionary
		var dk := int(dd.get(&"kind", -1))
		var cands: Array = _NewBindingScript.list_assignable_empty_exports(host, comp, donor_st)
		var has_bind := not cands.is_empty()
		var has_wire := (&"wire_rules" in host) and dk == _SnapScript.NodeKind.UI_STATE
		if has_bind and has_wire:
			_open_newlink_mixed_popup(host, comp, donor_st, cands)
			return
		if has_bind:
			if cands.size() == 1:
				var prop: StringName = (cands[0] as Dictionary)[&"property"] as StringName
				committed = _NewBindingScript.try_commit_assign(host, comp, prop, donor_st, _actions)
			else:
				_open_newlink_binding_picker(host, comp, donor_st, cands)
				return
		elif has_wire:
			_open_newlink_wire_rules_only_popup(host, donor_st)
			return
		else:
			push_warning("Ui React: no empty binding slot or wire_rules host for this drop.")
			return
	elif tk == _SnapScript.NodeKind.UI_COMPUTED:
		var ehp := str(td.get(&"embedded_host_path", ""))
		var ctx := str(td.get(&"embedded_context", ""))
		if not ehp.is_empty() and not ctx.is_empty():
			if not root.has_node(NodePath(ehp)):
				return
			var hn: Node = root.get_node(NodePath(ehp))
			if not (hn is Control):
				return
			committed = _ComputedRebindScript.try_commit_append_or_fill_source(
				hn as Control, ctx, donor_st, _actions
			)
		else:
			var fp := str(td.get(&"state_file_path", ""))
			if fp.is_empty():
				push_warning("Ui React: could not resolve file-backed computed target.")
				return
			var res: Resource = load(fp)
			if not (res is UiComputedStringState or res is UiComputedBoolState):
				return
			var mounts: Array = _ComputedMountsScript.mounts_for_computed_resource(
				root, res as Resource
			)
			if mounts.is_empty():
				push_warning(
					"Ui React: file-backed computed is not referenced from this scene (open the .tres or bind it on a host)."
				)
				return
			if mounts.size() == 1:
				committed = _commit_newlink_computed_append_to_mount(
					root, mounts[0] as Dictionary, donor_st
				)
			else:
				_open_newlink_computed_mount_picker(root, donor_st, mounts)
				return
	if not committed:
		return
	if _request_dock_refresh.is_valid():
		_request_dock_refresh.call()
	refresh()


func _commit_newlink_computed_append_to_mount(
	root: Node, mount: Dictionary, donor_st: UiState
) -> bool:
	var mhp := str(mount.get(&"host_path", ""))
	var mctx := str(mount.get(&"computed_context", ""))
	if mhp.is_empty() or mctx.is_empty() or not root.has_node(NodePath(mhp)):
		return false
	var host_n: Node = root.get_node(NodePath(mhp))
	if not (host_n is Control):
		return false
	var host := host_n as Control
	var prop := _ComputedMountsScript.bind_prop_from_context(mctx)
	if prop != &"":
		var cur: Variant = host.get(prop)
		if cur is Resource and not (cur as Resource).resource_path.is_empty():
			if not _ComputedMountsScript.try_commit_make_computed_unique_at_bind(
				host, prop, _actions
			):
				return false
	return _ComputedRebindScript.try_commit_append_or_fill_source(host, mctx, donor_st, _actions)


func _ensure_newlink_mixed_popup() -> PopupMenu:
	if _newlink_mixed_popup != null:
		return _newlink_mixed_popup
	_newlink_mixed_popup = PopupMenu.new()
	var bc: Control = _plugin.get_editor_interface().get_base_control()
	bc.add_child(_newlink_mixed_popup)
	_newlink_mixed_popup.id_pressed.connect(_on_newlink_mixed_menu_id)
	return _newlink_mixed_popup


func _ensure_newlink_no_wire_dialog() -> AcceptDialog:
	if _newlink_no_wire_dialog != null:
		return _newlink_no_wire_dialog
	_newlink_no_wire_dialog = AcceptDialog.new()
	_newlink_no_wire_dialog.title = "No compatible wire rules"
	_newlink_no_wire_dialog.dialog_text = (
		"No wire rule templates accept this state on the first input export. "
		+ "Try a different donor state or add a rule from the graph context menu."
	)
	add_child(_newlink_no_wire_dialog)
	return _newlink_no_wire_dialog


func _show_newlink_no_wire_rules_dialog() -> void:
	var d := _ensure_newlink_no_wire_dialog()
	d.popup_centered()


func _open_newlink_mixed_popup(host: Control, component: String, donor: UiState, cands: Array) -> void:
	_newlink_mixed_host = host
	_newlink_mixed_component = component
	_newlink_mixed_donor_st = donor
	_newlink_mixed_binding_cands = cands.duplicate()
	var filtered: PackedInt32Array = _WireGraphEditScript.filter_rule_template_indices_for_donor(donor)
	_newlink_wire_filter_indices = filtered
	var m := _ensure_newlink_mixed_popup()
	m.clear()
	var id := 0
	for row in cands:
		var lab := str((row as Dictionary).get(&"label", ""))
		m.add_item("Binding: %s" % lab, id)
		id += 1
	var entries := _WireRuleCatalogScript.rule_script_entries()
	if filtered.is_empty():
		if cands.is_empty():
			_show_newlink_no_wire_rules_dialog()
			return
	else:
		if not cands.is_empty():
			m.add_separator()
		var wire_base := id
		for k: int in range(filtered.size()):
			var ci := int(filtered[k])
			m.add_item("New wire: %s" % String(entries[ci][&"label"]), wire_base + k)
	var mp: Vector2i = DisplayServer.mouse_get_position()
	m.position = mp
	m.popup()


func _open_newlink_wire_rules_only_popup(host: Control, donor: UiState) -> void:
	_newlink_mixed_host = host
	_newlink_mixed_component = ""
	_newlink_mixed_donor_st = donor
	_newlink_mixed_binding_cands.clear()
	var filtered2: PackedInt32Array = _WireGraphEditScript.filter_rule_template_indices_for_donor(donor)
	_newlink_wire_filter_indices = filtered2
	if filtered2.is_empty():
		_show_newlink_no_wire_rules_dialog()
		return
	var m := _ensure_newlink_mixed_popup()
	m.clear()
	var entries := _WireRuleCatalogScript.rule_script_entries()
	for k: int in range(filtered2.size()):
		var ci := int(filtered2[k])
		m.add_item("New wire: %s" % String(entries[ci][&"label"]), k)
	var mp: Vector2i = DisplayServer.mouse_get_position()
	m.position = mp
	m.popup()


func _on_newlink_mixed_menu_id(menu_id: int) -> void:
	if _newlink_mixed_host == null or _newlink_mixed_donor_st == null:
		return
	var nbind := _newlink_mixed_binding_cands.size()
	var committed := false
	if nbind > 0:
		if menu_id >= 0 and menu_id < nbind:
			var row: Dictionary = _newlink_mixed_binding_cands[menu_id] as Dictionary
			var prop: StringName = row[&"property"] as StringName
			committed = _NewBindingScript.try_commit_assign(
				_newlink_mixed_host,
				_newlink_mixed_component,
				prop,
				_newlink_mixed_donor_st,
				_actions
			)
		else:
			var widx := menu_id - nbind
			if widx < 0 or widx >= _newlink_wire_filter_indices.size():
				_newlink_mixed_host = null
				_newlink_mixed_donor_st = null
				_newlink_mixed_binding_cands.clear()
				_newlink_mixed_component = ""
				_newlink_wire_filter_indices = PackedInt32Array()
				return
			var catalog_i := int(_newlink_wire_filter_indices[widx])
			committed = _WireGraphEditScript.try_commit_append_wire_rule_with_in(
				_newlink_mixed_host, catalog_i, _newlink_mixed_donor_st, _actions
			)
	else:
		if menu_id < 0 or menu_id >= _newlink_wire_filter_indices.size():
			_newlink_mixed_host = null
			_newlink_mixed_donor_st = null
			_newlink_mixed_binding_cands.clear()
			_newlink_mixed_component = ""
			_newlink_wire_filter_indices = PackedInt32Array()
			return
		var catalog_i2 := int(_newlink_wire_filter_indices[menu_id])
		committed = _WireGraphEditScript.try_commit_append_wire_rule_with_in(
			_newlink_mixed_host, catalog_i2, _newlink_mixed_donor_st, _actions
		)
	_newlink_mixed_host = null
	_newlink_mixed_donor_st = null
	_newlink_mixed_binding_cands.clear()
	_newlink_mixed_component = ""
	_newlink_wire_filter_indices = PackedInt32Array()
	if not committed:
		return
	if _request_dock_refresh.is_valid():
		_request_dock_refresh.call()
	refresh()


func _ensure_newlink_mount_popup() -> PopupMenu:
	if _newlink_mount_popup != null:
		return _newlink_mount_popup
	_newlink_mount_popup = PopupMenu.new()
	var bc2: Control = _plugin.get_editor_interface().get_base_control()
	bc2.add_child(_newlink_mount_popup)
	_newlink_mount_popup.id_pressed.connect(_on_newlink_mount_menu_id)
	return _newlink_mount_popup


func _open_newlink_computed_mount_picker(root: Node, donor_st: UiState, mounts: Array) -> void:
	_newlink_mount_donor_st = donor_st
	_newlink_mount_list = mounts.duplicate()
	var m := _ensure_newlink_mount_popup()
	m.clear()
	for i: int in range(mounts.size()):
		var md: Dictionary = mounts[i] as Dictionary
		m.add_item("%s  |  %s" % [str(md.get(&"host_path", "")), str(md.get(&"computed_context", ""))], i)
	var mp2: Vector2i = DisplayServer.mouse_get_position()
	m.position = mp2
	m.popup()


func _on_newlink_mount_menu_id(menu_id: int) -> void:
	if _newlink_mount_donor_st == null:
		return
	var ei := _plugin.get_editor_interface()
	var root := ei.get_edited_scene_root()
	if root == null:
		return
	if menu_id < 0 or menu_id >= _newlink_mount_list.size():
		_newlink_mount_donor_st = null
		_newlink_mount_list.clear()
		return
	var mount: Dictionary = _newlink_mount_list[menu_id] as Dictionary
	var committed := _commit_newlink_computed_append_to_mount(root, mount, _newlink_mount_donor_st)
	_newlink_mount_donor_st = null
	_newlink_mount_list.clear()
	if not committed:
		return
	if _request_dock_refresh.is_valid():
		_request_dock_refresh.call()
	refresh()


func _on_graph_edge_disconnect_requested(edge_idx: int) -> void:
	if edge_idx != _graph_selected_edge_index:
		return
	_attempt_graph_edge_disconnect()


func _try_commit_binding_rebind_from_edge(ed: Dictionary, ui_st: UiState, root: Node) -> bool:
	var hp := str(ed.get(&"host_path", ""))
	var bp := str(ed.get(&"binding_property", ""))
	if bp.is_empty():
		bp = str(ed.get(&"label", ""))
	if hp.is_empty() or bp.is_empty():
		return false
	if not root.has_node(NodePath(hp)):
		push_warning("Ui React: rebind host path is no longer valid: %s" % hp)
		return false
	var n: Node = root.get_node(NodePath(hp))
	if not (n is Control):
		return false
	var prop_sn := StringName(bp)
	if not prop_sn in n:
		push_warning("Ui React: host no longer has export %s" % bp)
		return false
	_actions.assign_property_variant(n, prop_sn, ui_st, "Ui React: Rebind %s" % bp)
	return true


func _try_commit_wire_rebind_from_edge(ed: Dictionary, for_input: bool, ui_st: UiState, root: Node) -> bool:
	var wh := str(ed.get(&"wire_host_path", ""))
	var wi := int(ed.get(&"wire_rule_index", -1))
	var win := str(ed.get(&"wire_in_property", ""))
	var wout := str(ed.get(&"wire_out_property", ""))
	var wprop := StringName(win if for_input else wout)
	if wh.is_empty() or wi < 0 or wprop == &"":
		return false
	if not root.has_node(NodePath(wh)):
		push_warning("Ui React: wire host path is no longer valid: %s" % wh)
		return false
	var host_n: Node = root.get_node(NodePath(wh))
	if not (host_n is Control):
		return false
	var host := host_n as Control
	if not (&"wire_rules" in host):
		push_warning("Ui React: host has no wire_rules: %s" % wh)
		return false
	return _WireGraphEditScript.try_commit_wire_slot_rebind(host, wi, wprop, ui_st, _actions)


func _on_graph_reconnect_drag_ended(edge_idx: int, origin_id: String, target_id: String) -> void:
	if _plugin == null or _actions == null or target_id.is_empty():
		return
	if not _reconnect_is_valid_drop(edge_idx, origin_id, target_id):
		return
	var root := _plugin.get_editor_interface().get_edited_scene_root()
	if root == null:
		return
	var edges: Array = _last_layout.get(&"draw_edges", []) as Array
	if edge_idx < 0 or edge_idx >= edges.size():
		return
	var ev: Variant = edges[edge_idx]
	if ev is not Dictionary:
		return
	var ed: Dictionary = ev as Dictionary
	var nb: Dictionary = _last_layout.get(&"node_by_id", {}) as Dictionary
	var new_st: UiState = _ResolverScript.try_resolve_uistate(root, target_id, nb)
	if new_st == null:
		return
	var k := int(ed.get(&"kind", -1))
	var committed := false
	if k == _SnapScript.EdgeKind.BINDING:
		committed = _try_commit_binding_rebind_from_edge(ed, new_st, root)
	elif k == _SnapScript.EdgeKind.COMPUTED_SOURCE:
		var hp_c := str(ed.get(&"host_path", ""))
		var ctx := str(ed.get(&"computed_context", ""))
		var csi := int(ed.get(&"computed_source_index", -1))
		if not root.has_node(NodePath(hp_c)):
			push_warning("Ui React: rebind host path is no longer valid: %s" % hp_c)
			return
		var host_c: Node = root.get_node(NodePath(hp_c))
		if not (host_c is Control):
			return
		committed = _ComputedRebindScript.try_commit_replace_source(
			host_c as Control, ctx, csi, new_st, _actions
		)
	elif k == _SnapScript.EdgeKind.WIRE_FLOW:
		var for_input := origin_id == str(ed.get(&"from_id", ""))
		committed = _try_commit_wire_rebind_from_edge(ed, for_input, new_st, root)
	if not committed:
		return
	if _request_dock_refresh.is_valid():
		_request_dock_refresh.call()
	refresh()


func _on_rebind_binding_pressed() -> void:
	if not _can_rebind_binding_edge():
		return
	var edges: Array = _last_layout.get(&"draw_edges", []) as Array
	var ed: Dictionary = edges[_graph_selected_edge_index] as Dictionary
	_rebind_kind = _REBIND_BINDING
	_rebind_host_path = str(ed.get(&"host_path", ""))
	_rebind_property = str(ed.get(&"binding_property", ""))
	if _rebind_property.is_empty():
		_rebind_property = str(ed.get(&"label", ""))
	var dlg := _ensure_rebind_file_dialog()
	dlg.title = "Pick UiState resource"
	dlg.popup_centered_ratio(0.6)


func _on_rebind_wire_in_pressed() -> void:
	if not _can_rebind_wire_endpoint(true):
		return
	var edges: Array = _last_layout.get(&"draw_edges", []) as Array
	var ed: Dictionary = edges[_graph_selected_edge_index] as Dictionary
	_rebind_kind = _REBIND_WIRE_IN
	_rebind_wire_host_path = str(ed.get(&"wire_host_path", ""))
	_rebind_wire_rule_index = int(ed.get(&"wire_rule_index", -1))
	_rebind_wire_prop = StringName(str(ed.get(&"wire_in_property", "")))
	var dlg := _ensure_rebind_file_dialog()
	dlg.title = "Pick UiState for wire input"
	dlg.popup_centered_ratio(0.6)


func _on_rebind_wire_out_pressed() -> void:
	if not _can_rebind_wire_endpoint(false):
		return
	var edges: Array = _last_layout.get(&"draw_edges", []) as Array
	var ed: Dictionary = edges[_graph_selected_edge_index] as Dictionary
	_rebind_kind = _REBIND_WIRE_OUT
	_rebind_wire_host_path = str(ed.get(&"wire_host_path", ""))
	_rebind_wire_rule_index = int(ed.get(&"wire_rule_index", -1))
	_rebind_wire_prop = StringName(str(ed.get(&"wire_out_property", "")))
	var dlg := _ensure_rebind_file_dialog()
	dlg.title = "Pick UiState for wire output"
	dlg.popup_centered_ratio(0.6)


func _on_rebind_computed_source_pressed() -> void:
	if not _can_rebind_computed_source():
		return
	var edges: Array = _last_layout.get(&"draw_edges", []) as Array
	var ed: Dictionary = edges[_graph_selected_edge_index] as Dictionary
	_rebind_kind = _REBIND_COMPUTED_SOURCE
	_rebind_host_path = str(ed.get(&"host_path", ""))
	_rebind_computed_context = str(ed.get(&"computed_context", ""))
	_rebind_computed_source_index = int(ed.get(&"computed_source_index", -1))
	var dlg := _ensure_rebind_file_dialog()
	dlg.title = "Pick UiState for computed source"
	dlg.popup_centered_ratio(0.6)


func _ensure_rebind_file_dialog() -> EditorFileDialog:
	if _rebind_file_dialog != null:
		return _rebind_file_dialog
	var dlg := EditorFileDialog.new()
	dlg.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	dlg.access = EditorFileDialog.ACCESS_RESOURCES
	dlg.title = "Pick UiState resource"
	dlg.add_filter("*.tres", "Tres resources")
	dlg.file_selected.connect(_on_rebind_file_selected)
	var base: Control = _plugin.get_editor_interface().get_base_control()
	base.add_child(dlg)
	_rebind_file_dialog = dlg
	return dlg


func _on_rebind_file_selected(path: String) -> void:
	if _plugin == null or _actions == null:
		return
	var root := _plugin.get_editor_interface().get_edited_scene_root()
	if root == null:
		return
	var res: Resource = load(path)
	if res == null:
		push_warning("Ui React: could not load resource: %s" % path)
		return
	if not (res is UiState):
		push_warning("Ui React: selected file is not a UiState: %s" % path)
		return
	var ui_st := res as UiState
	var committed := false
	match _rebind_kind:
		_REBIND_BINDING:
			var edges_b: Array = _last_layout.get(&"draw_edges", []) as Array
			var idx_b := _graph_selected_edge_index
			if idx_b < 0 or idx_b >= edges_b.size():
				return
			var ed_b: Variant = edges_b[idx_b]
			if ed_b is not Dictionary:
				return
			committed = _try_commit_binding_rebind_from_edge(ed_b as Dictionary, ui_st, root)
		_REBIND_WIRE_IN, _REBIND_WIRE_OUT:
			var edges_w: Array = _last_layout.get(&"draw_edges", []) as Array
			var idx_w := _graph_selected_edge_index
			if idx_w < 0 or idx_w >= edges_w.size():
				return
			var ed_w: Variant = edges_w[idx_w]
			if ed_w is not Dictionary:
				return
			var for_in := _rebind_kind == _REBIND_WIRE_IN
			committed = _try_commit_wire_rebind_from_edge(ed_w as Dictionary, for_in, ui_st, root)
		_REBIND_COMPUTED_SOURCE:
			var hp_c := _rebind_host_path
			var ctx := _rebind_computed_context
			var csi := _rebind_computed_source_index
			if hp_c.is_empty() or ctx.is_empty() or csi < 0:
				return
			if not root.has_node(NodePath(hp_c)):
				push_warning("Ui React: rebind host path is no longer valid: %s" % hp_c)
				return
			var host_c: Node = root.get_node(NodePath(hp_c))
			if not (host_c is Control):
				return
			committed = _ComputedRebindScript.try_commit_replace_source(
				host_c as Control,
				ctx,
				csi,
				ui_st,
				_actions
			)
		_:
			return
	if not committed:
		return
	_rebind_kind = _REBIND_NONE
	if _request_dock_refresh.is_valid():
		_request_dock_refresh.call()
	refresh()


func _set_details_placeholder() -> void:
	_set_details_both(
		"[i]Select a node or edge in the graph to see details.[/i]\n\n" + _DETAILS_GRAPH_HELP_BB,
		"Select a node or edge in the graph to see details.\n\n" + _DETAILS_GRAPH_HELP_PLAIN,
	)


func _set_details_empty() -> void:
	_set_details_both(
		"[i]No graph in scope. Refresh after changing bindings or selection.[/i]\n\n" + _DETAILS_GRAPH_HELP_BB,
		"No graph in scope. Refresh after changing bindings or selection.\n\n" + _DETAILS_GRAPH_HELP_PLAIN,
	)


func _set_details_both(bb: String, plain: String) -> void:
	if _details:
		_details.text = bb
	_last_details_plain = plain


func _plain_from_bbcode_line(line: String) -> String:
	var t := line
	t = t.replace("[b]", "").replace("[/b]", "")
	t = t.replace("[i]", "").replace("[/i]", "")
	t = t.replace("[code]", "").replace("[/code]", "")
	return t


func _get_narrative_cached(anchor_id: String) -> Variant:
	return _get_narrative_cached_ex(anchor_id, PackedStringArray(), PackedStringArray())


func _join_sorted_ids(ids: PackedStringArray) -> String:
	var arr: Array[String] = []
	for i in ids.size():
		arr.append(String(ids[i]))
	arr.sort()
	return ",".join(arr)


func _narrative_cache_key(
	anchor_id: String, up_ex: PackedStringArray, down_ex: PackedStringArray
) -> String:
	if up_ex.is_empty() and down_ex.is_empty():
		return anchor_id
	return "%s|u:%s|d:%s" % [anchor_id, _join_sorted_ids(up_ex), _join_sorted_ids(down_ex)]


func _get_narrative_cached_ex(
	anchor_id: String, up_ex: PackedStringArray, down_ex: PackedStringArray
) -> Variant:
	var cache_key := _narrative_cache_key(anchor_id, up_ex, down_ex)
	if _narrative_cache.has(cache_key):
		return _narrative_cache[cache_key]
	if _plugin == null or _last_snap == null:
		return null
	var ei := _plugin.get_editor_interface()
	var root := ei.get_edited_scene_root()
	if root == null:
		return null
	var snap: UiReactExplainGraphSnapshot = _last_snap as UiReactExplainGraphSnapshot
	var raw: Variant = UiReactExplainGraphBuilder.compute_narrative(
		root,
		snap,
		anchor_id,
		_show_full_lists,
		up_ex,
		down_ex
	)
	var narr: Object = raw as Object
	if narr != null:
		_narrative_cache[cache_key] = narr
	return narr


func _snapshot_has_node_id(node_id: String) -> bool:
	if _last_snap == null or node_id.is_empty():
		return false
	var snap: UiReactExplainGraphSnapshot = _last_snap as UiReactExplainGraphSnapshot
	for nd: Variant in snap.nodes:
		if nd is Dictionary and str((nd as Dictionary).get(&"id", "")) == node_id:
			return true
	return false


func _edge_anchor_id(from_id: String, to_id: String) -> String:
	if _snapshot_has_node_id(from_id):
		return from_id
	return to_id


## Returns [upstream_exclude, downstream_exclude] for edge Graph context display lines only.
func _edge_graph_context_display_excludes(
	from_id: String, to_id: String, _kind: int, anchor_id: String
) -> Array:
	var up_ex := PackedStringArray()
	var down_ex := PackedStringArray()
	if anchor_id == from_id and not to_id.is_empty() and to_id != anchor_id:
		down_ex.append(to_id)
	elif anchor_id == to_id and not from_id.is_empty() and from_id != anchor_id:
		up_ex.append(from_id)
	return [up_ex, down_ex]


func _on_full_lists_toggled(pressed: bool) -> void:
	_show_full_lists = pressed
	_narrative_cache.clear()
	if _selection_kind == _SEL_NODE and not _graph_selected_node_id.is_empty():
		_fill_node_details(_graph_selected_node_id)
	elif _selection_kind == _SEL_EDGE:
		_fill_edge_details(
			_last_edge_from_id,
			_last_edge_to_id,
			_last_edge_kind,
			_last_edge_label,
			_graph_selected_edge_index
		)


func _narrative_anchor_kind(anchor_id: String) -> int:
	if anchor_id.is_empty():
		return -1
	var nb: Dictionary = _last_layout.get(&"node_by_id", {}) as Dictionary
	var d: Dictionary = nb.get(anchor_id, {}) as Dictionary
	if d.is_empty():
		return -1
	return int(d.get(&"kind", -1))


func _narrative_upstream_heading_bb_plain(anchor_kind: int) -> PackedStringArray:
	if anchor_kind == _SnapScript.NodeKind.CONTROL:
		return PackedStringArray(
			[
				"\n[b]Upstream[/b] (in this snapshot — state/computed feeding this control’s bindings):\n",
				"\nUpstream (in this snapshot — state/computed feeding this control's bindings):\n",
			]
		)
	return PackedStringArray(
		[
			"\n[b]Upstream[/b] (in this snapshot — declarative reach toward this resource):\n",
			"\nUpstream (in this snapshot — declarative reach toward this resource):\n",
		]
	)


func _narrative_downstream_heading_bb_plain(anchor_kind: int) -> PackedStringArray:
	if anchor_kind == _SnapScript.NodeKind.CONTROL:
		return PackedStringArray(
			[
				"\n[b]Downstream[/b] (in this snapshot — states/computed or controls reached via this control’s bindings):\n",
				"\nDownstream (in this snapshot — states/computed or controls reached via this control's bindings):\n",
			]
		)
	return PackedStringArray(
		[
			"\n[b]Downstream[/b] (in this snapshot — states/computed or controls this resource feeds):\n",
			"\nDownstream (in this snapshot — states/computed or controls this resource feeds):\n",
		]
	)


func _append_reachability_from_narrative(narr: Object) -> PackedStringArray:
	var bb := ""
	var plain := ""
	if narr == null:
		return PackedStringArray([bb, plain])
	var n_narr := narr as UiReactExplainGraphNarrative
	if n_narr == null:
		return PackedStringArray([bb, plain])
	var ak := _narrative_anchor_kind(n_narr.anchor_id)
	var up_h := _narrative_upstream_heading_bb_plain(ak)
	bb += up_h[0]
	plain += up_h[1]
	if n_narr.upstream_display_lines.is_empty():
		if ak == _SnapScript.NodeKind.CONTROL:
			var msg := "[i]No upstream in this snapshot—only direct bindings feed this control.[/i]\n"
			bb += msg
			plain += _plain_from_bbcode_line(msg)
		elif ak == _SnapScript.NodeKind.UI_STATE or ak == _SnapScript.NodeKind.UI_COMPUTED:
			var msg_r := "[i]No upstream in this snapshot—no declarative sources reach this resource.[/i]\n"
			bb += msg_r
			plain += _plain_from_bbcode_line(msg_r)
		else:
			var msg2 := "[i]No upstream in this snapshot.[/i]\n"
			bb += msg2
			plain += _plain_from_bbcode_line(msg2)
	else:
		for line2: String in n_narr.upstream_display_lines:
			bb += line2
			plain += _plain_from_bbcode_line(line2)
	var down_h := _narrative_downstream_heading_bb_plain(ak)
	bb += down_h[0]
	plain += down_h[1]
	var dsl: PackedStringArray = n_narr.downstream_state_display_lines
	var dcl: PackedStringArray = n_narr.downstream_control_display_lines
	if dsl.is_empty() and dcl.is_empty():
		bb += "(none)\n"
		plain += "(none)\n"
	else:
		if not dsl.is_empty():
			bb += "[b]States / computed[/b]\n"
			plain += "States / computed\n"
			for line3: String in dsl:
				bb += line3
				plain += _plain_from_bbcode_line(line3)
		if not dcl.is_empty():
			bb += "[b]Controls[/b]\n"
			plain += "Controls\n"
			for line4: String in dcl:
				bb += line4
				plain += _plain_from_bbcode_line(line4)
	return PackedStringArray([bb, plain])


func _details_declarative_footer_bb_plain() -> PackedStringArray:
	var bb := "\n" + _DETAILS_DECLARATIVE_ONE_LINER_BB
	var plain := "\n" + _plain_from_bbcode_line(_DETAILS_DECLARATIVE_ONE_LINER_BB)
	return PackedStringArray([bb, plain])


func _append_cycle_section_bb_plain(anchor_id: String) -> PackedStringArray:
	if _last_snap == null:
		return PackedStringArray(["", ""])
	var snap: UiReactExplainGraphSnapshot = _last_snap as UiReactExplainGraphSnapshot
	var is_hub := anchor_id == _last_focus_id
	var cap := 999999 if (is_hub or _show_full_lists) else _CYCLE_SUMMARY_CAP
	var matching: Array[Dictionary] = []
	for c: Variant in snap.cycle_candidates:
		if c is not Dictionary:
			continue
		var cd: Dictionary = c as Dictionary
		if is_hub:
			matching.append(cd)
		else:
			var ids := cd.get(&"node_ids", PackedStringArray()) as PackedStringArray
			if _id_in_packed(ids, anchor_id):
				matching.append(cd)
	if matching.is_empty():
		return PackedStringArray(["", ""])
	var bb := "\n[b]Cycle candidates[/b] (static, state/computed edges only):\n"
	var plain := "\nCycle candidates (static, state/computed edges only):\n"
	var n_show := mini(matching.size(), cap)
	for i in n_show:
		var sm := str(matching[i].get(&"summary", "?"))
		bb += "• [code]%s[/code]\n" % sm
		plain += "• %s\n" % sm
	var more := matching.size() - n_show
	if more > 0:
		bb += "• [i]+%d more[/i]\n" % more
		plain += "• +%d more\n" % more
	return PackedStringArray([bb, plain])


func _mismatch_banner_bb_plain(narr: Object) -> PackedStringArray:
	if narr == null:
		return PackedStringArray(["", ""])
	var layout_nb: Dictionary = _last_layout.get(&"node_by_id", {}) as Dictionary
	var missing := false
	for i in narr.upstream_node_ids.size():
		var idu := String(narr.upstream_node_ids[i])
		if not layout_nb.has(idu):
			missing = true
			break
	if not missing:
		for j in narr.downstream_node_ids.size():
			var idd := String(narr.downstream_node_ids[j])
			if not layout_nb.has(idd):
				missing = true
				break
	var stats: Dictionary = _last_layout.get(&"graph_stats", {}) as Dictionary
	var truncated := bool(stats.get(&"truncated", false))
	if not missing and not truncated:
		return PackedStringArray(["", ""])
	var bb := "[b]Canvas note[/b]\n"
	var plain := "Canvas note\n"
	if missing:
		bb += "Some nodes in this narrative are [b]not drawn[/b] (layout scope, caps, or edge filters).\n"
		plain += "Some nodes in this narrative are not drawn (layout scope, caps, or edge filters).\n"
	if truncated:
		bb += "This graph layout is [b]truncated[/b] (node/edge caps).\n"
		plain += "This graph layout is truncated (node/edge caps).\n"
	bb += "\n"
	plain += "\n"
	return PackedStringArray([bb, plain])


const _INCIDENT_EDGE_CAP := 8
const _OTHER_EDGES_AT_ANCHOR_CAP := 6
const _ORPHAN_LAYER := -512
const _CYCLE_SUMMARY_CAP := 2
## Declarative-scope one-liner appended after human reachability in the details pane.
const _DETAILS_DECLARATIVE_ONE_LINER_BB := (
	"[i]Declarative snapshot only (not a runtime trace); cycle summaries are static candidates.[/i]\n"
)


func _id_in_packed(ids: PackedStringArray, needle: String) -> bool:
	for i in ids.size():
		if String(ids[i]) == needle:
			return true
	return false


func _incident_edge_sig(ed: Dictionary) -> String:
	return "%s|%s|%d|%s" % [
		str(ed.get(&"from_id", "")),
		str(ed.get(&"to_id", "")),
		int(ed.get(&"kind", -1)),
		str(ed.get(&"label", "")),
	]


## When true, omit binding **Where to edit** (healthy path resolves to a Control in the edited scene).
func _edge_binding_skip_inspector_blurb(ed: Dictionary) -> bool:
	var hp := str(ed.get(&"host_path", ""))
	if hp.is_empty():
		return false
	if _plugin == null:
		return false
	var ei := _plugin.get_editor_interface()
	var root := ei.get_edited_scene_root()
	if root == null:
		return false
	if not root.has_node(NodePath(hp)):
		return false
	var hn: Node = root.get_node(NodePath(hp))
	return hn is Control


func _optional_binding_dock_hint_bb_plain(ed: Dictionary, bp: StringName) -> PackedStringArray:
	var hp := str(ed.get(&"host_path", ""))
	if hp.is_empty() or _plugin == null:
		return PackedStringArray(["", ""])
	var ei := _plugin.get_editor_interface()
	var root := ei.get_edited_scene_root()
	if root == null or not root.has_node(NodePath(hp)):
		return PackedStringArray(["", ""])
	var hn: Node = root.get_node(NodePath(hp))
	if not hn is Control:
		return PackedStringArray(["", ""])
	var comp2 := UiReactScannerService.get_component_name_from_script((hn as Control).get_script() as Script)
	if not UiReactGraphNewBindingService.binding_export_is_optional(comp2, bp):
		return PackedStringArray(["", ""])
	var msg := "[i]Optional export — [b]Clear optional binding[/b] is available in the dock action row (undoable).[/i]\n"
	return PackedStringArray([msg, _plain_from_bbcode_line(msg)])


func _other_edges_at_anchor_bb_plain(
	anchor_id: String, selected_edge_index: int
) -> PackedStringArray:
	if anchor_id.is_empty():
		return PackedStringArray(["", ""])
	var edges: Array = _last_layout.get(&"draw_edges", []) as Array
	if selected_edge_index < 0 or selected_edge_index >= edges.size():
		return PackedStringArray(["", ""])
	var sel_ev: Variant = edges[selected_edge_index]
	if sel_ev is not Dictionary:
		return PackedStringArray(["", ""])
	var sel_sig := _incident_edge_sig(sel_ev as Dictionary)
	var others: Array[Dictionary] = []
	for i: int in range(edges.size()):
		if i == selected_edge_index:
			continue
		var ev2: Variant = edges[i]
		if ev2 is not Dictionary:
			continue
		var ed2: Dictionary = ev2 as Dictionary
		if _incident_edge_sig(ed2) == sel_sig:
			continue
		var fid := str(ed2.get(&"from_id", ""))
		var tid := str(ed2.get(&"to_id", ""))
		if fid == anchor_id or tid == anchor_id:
			others.append(ed2)
	if others.is_empty():
		return PackedStringArray(["", ""])
	others.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			var ka := int(a.get(&"kind", -1))
			var kb := int(b.get(&"kind", -1))
			if ka != kb:
				return ka < kb
			var fa := str(a.get(&"from_id", ""))
			var fb := str(b.get(&"from_id", ""))
			if fa != fb:
				return fa < fb
			return str(a.get(&"to_id", "")) < str(b.get(&"to_id", ""))
	)
	var bb := "\n[b]Other edges at this anchor[/b]\n"
	var plain := "\nOther edges at this anchor\n"
	var cap := _OTHER_EDGES_AT_ANCHOR_CAP
	var n_show := mini(others.size(), cap)
	for j: int in n_show:
		var pair := _format_incident_edge_bb_plain(others[j])
		bb += pair[0] + "\n"
		plain += pair[1] + "\n"
	var overflow := others.size() - n_show
	if overflow > 0:
		bb += "[i]+%d more in this graph[/i]\n" % overflow
		plain += "+%d more in this graph\n" % overflow
	bb += "\n"
	plain += "\n"
	return PackedStringArray([bb, plain])


func _find_binding_edge_for_prop(incident: Array[Dictionary], node_id: String, prop: String) -> Dictionary:
	for ed: Dictionary in incident:
		if int(ed.get(&"kind", -1)) != _SnapScript.EdgeKind.BINDING:
			continue
		if str(ed.get(&"to_id", "")) != node_id:
			continue
		var bp := str(ed.get(&"binding_property", ""))
		var lab := str(ed.get(&"label", ""))
		if bp == prop or lab == prop:
			return ed
	return {}


func _connections_section_bb_plain(node_id: String, d: Dictionary, edges: Array) -> PackedStringArray:
	if int(d.get(&"kind", -1)) != _SnapScript.NodeKind.CONTROL or not node_id.begins_with("ctrl:"):
		return PackedStringArray(["", ""])
	var bb := "\n[b]Connections[/b]\n"
	var plain := "\nConnections\n"
	var host := _resolve_control_host_from_node(node_id, d)
	var incident: Array[Dictionary] = []
	for e: Variant in edges:
		if e is not Dictionary:
			continue
		var ed0: Dictionary = e as Dictionary
		if str(ed0.get(&"from_id", "")) == node_id or str(ed0.get(&"to_id", "")) == node_id:
			incident.append(ed0)
	incident.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			var ka := int(a.get(&"kind", -1))
			var kb := int(b.get(&"kind", -1))
			if ka != kb:
				return ka < kb
			var fa := str(a.get(&"from_id", ""))
			var fb := str(b.get(&"from_id", ""))
			if fa != fb:
				return fa < fb
			return str(a.get(&"to_id", "")) < str(b.get(&"to_id", ""))
	)
	if host == null:
		bb += "• [i]Could not list binding slots (control missing).[/i]\n"
		plain += "• Could not list binding slots (control missing).\n"
		return PackedStringArray([bb, plain])
	var comp := UiReactScannerService.get_component_name_from_script(host.get_script() as Script)
	var rows: Array[Dictionary] = UiReactGraphNewBindingService.list_registry_binding_rows(host, comp)
	var consumed: Dictionary = {}
	if rows.is_empty():
		var any_bind := false
		for ed1: Dictionary in incident:
			if int(ed1.get(&"kind", -1)) != _SnapScript.EdgeKind.BINDING:
				continue
			if str(ed1.get(&"to_id", "")) != node_id:
				continue
			any_bind = true
			consumed[_incident_edge_sig(ed1)] = true
			var pair0 := _format_incident_edge_bb_plain(ed1)
			bb += pair0[0] + "\n"
			plain += pair0[1] + "\n"
		if not any_bind:
			bb += "[i]No registry bindings listed for this component in this snapshot.[/i]\n"
			plain += "No registry bindings listed for this component in this snapshot.\n"
	else:
		for row: Dictionary in rows:
			var prop_sn: StringName = row.get(&"property", &"") as StringName
			var ps := str(prop_sn)
			var is_bound := bool(row.get(&"bound", false))
			if not is_bound:
				bb += "• [code]%s[/code] — unbound\n" % ps
				plain += "• %s — unbound\n" % ps
			else:
				var vl := str(row.get(&"value_label", ""))
				bb += "• [code]%s[/code] → [code]%s[/code]\n" % [ps, vl]
				plain += "• %s → %s\n" % [ps, vl]
				var bed := _find_binding_edge_for_prop(incident, node_id, ps)
				if not bed.is_empty():
					consumed[_incident_edge_sig(bed)] = true
					var pair1 := _format_incident_edge_bb_plain(bed)
					var subb := pair1[0].strip_edges()
					if subb.begins_with("• "):
						subb = subb.substr(2)
					bb += "  " + subb + "\n"
					var subp := pair1[1].strip_edges()
					if subp.begins_with("• "):
						subp = subp.substr(2)
					plain += "  " + subp + "\n"
	var others: Array[Dictionary] = []
	for ed2: Dictionary in incident:
		if consumed.has(_incident_edge_sig(ed2)):
			continue
		others.append(ed2)
	if not others.is_empty():
		bb += "\n[b]Other edges[/b]\n"
		plain += "\nOther edges\n"
		for ed3: Dictionary in others:
			var pair2 := _format_incident_edge_bb_plain(ed3)
			bb += pair2[0] + "\n"
			plain += pair2[1] + "\n"
	return PackedStringArray([bb, plain])


func _wire_rules_summary_bb_plain(host: Control) -> PackedStringArray:
	if host == null or not (&"wire_rules" in host):
		return PackedStringArray(["", ""])
	var wr: Variant = host.get(&"wire_rules")
	if wr == null or wr is not Array:
		return PackedStringArray(["", ""])
	var arr: Array = wr as Array
	if arr.is_empty():
		return PackedStringArray(["", ""])
	var bb := "\n[b]Wire rules[/b]\n"
	var plain := "\nWire rules\n"
	for i in arr.size():
		var rule_var: Variant = arr[i]
		if rule_var == null or not (rule_var is UiReactWireRule):
			bb += "• (invalid row %d)\n" % i
			plain += "• (invalid row %d)\n" % i
			continue
		var rule := rule_var as UiReactWireRule
		var trig_label := _WireGraphEditScript.wire_trigger_kind_label(int(rule.trigger))
		var io_list := UiReactWireRuleIntrospection.list_io(rule)
		var ins: Array[String] = []
		var outs: Array[String] = []
		for entry: Dictionary in io_list:
			var role := str(entry.get(&"role", ""))
			var prop := str(entry.get(&"property", ""))
			var st: Variant = entry.get(&"state", null)
			var frag := prop
			if st != null and st is UiState:
				var us := st as UiState
				var rp := str(us.resource_path)
				if not rp.is_empty():
					frag = rp.get_file()
			if frag.is_empty():
				frag = "?"
			if role == "in":
				ins.append(frag)
			elif role == "out":
				outs.append(frag)
		var in_str := ", ".join(ins)
		var out_str := ", ".join(outs)
		bb += "• rule %d: %s — in: %s → out: %s\n" % [i, trig_label, in_str, out_str]
		plain += "• rule %d: %s — in: %s → out: %s\n" % [i, trig_label, in_str, out_str]
	return PackedStringArray([bb, plain])


func _format_incident_edge_bb_plain(ed: Dictionary) -> PackedStringArray:
	var fa := str(ed.get(&"from_id", ""))
	var ta := str(ed.get(&"to_id", ""))
	var k := int(ed.get(&"kind", -1))
	var lab := str(ed.get(&"label", ""))
	var tag := _edge_short_token(k)
	var s_from := _short_label_for_node_id(fa)
	var s_to := _short_label_for_node_id(ta)
	var bb := "• [code][%s][/code] %s → %s" % [tag, s_from, s_to]
	var plain := "• [%s] %s → %s" % [tag, s_from, s_to]
	if not lab.is_empty():
		bb += "  ([code]%s[/code])" % lab
		plain += " (%s)" % lab
	return PackedStringArray([bb, plain])


func _focus_relation_blurb_bb_plain(node_id: String, layout_focus_id: String, node_layer: Dictionary) -> PackedStringArray:
	var bb := "[b]Relative to layout center[/b]\n"
	var plain := "Relative to layout center\n"
	if node_id == layout_focus_id:
		bb += "At layout center — this is the focus control column in this layout.\n\n"
		plain += "At layout center — this is the focus control column in this layout.\n\n"
	else:
		if not node_layer.has(node_id):
			bb += "Weakly connected in this layout — present in scope but not on the main upstream/downstream spine used for layering.\n\n"
			plain += "Weakly connected in this layout — present in scope but not on the main upstream/downstream spine used for layering.\n\n"
		else:
			var L := int(node_layer[node_id])
			if L == _ORPHAN_LAYER:
				bb += "Weakly connected in this layout — present in scope but not on the main upstream/downstream spine used for layering.\n\n"
				plain += "Weakly connected in this layout — present in scope but not on the main upstream/downstream spine used for layering.\n\n"
			elif L < 0:
				bb += "Upstream side — closer to sources that feed the focus control's bindings (left side of this layout).\n\n"
				plain += "Upstream side — closer to sources that feed the focus control's bindings (left side of this layout).\n\n"
			elif L > 0:
				bb += "Downstream side — reachable from states bound to the focus (right side of this layout).\n\n"
				plain += "Downstream side — reachable from states bound to the focus (right side of this layout).\n\n"
			else:
				bb += "Same layout tier as the focus column — neighbors in this horizontal band.\n\n"
				plain += "Same layout tier as the focus column — neighbors in this horizontal band.\n\n"
	return PackedStringArray([bb, plain])


func _node_headline_bb_plain(node_id: String, d: Dictionary, focus_id: String) -> PackedStringArray:
	if node_id == focus_id:
		var bb := "[b]Focus control[/b]\n"
		bb += "This is the [code]UiReact*[/code] control you selected when refreshing this graph.\n\n"
		var plain := "Focus control\n"
		plain += "This is the UiReact* control you selected when refreshing this graph.\n\n"
		return PackedStringArray([bb, plain])
	var nk := int(d.get(&"kind", -1))
	var short_l := str(d.get(&"short_label", ""))
	var label_disp := short_l if not short_l.is_empty() else node_id
	var bb2 := "[b]%s[/b] — " % label_disp
	var plain2 := "%s — " % label_disp
	match nk:
		_SnapScript.NodeKind.CONTROL:
			bb2 += "[code]UiReact*[/code] control in this scoped graph.\n\n"
			plain2 += "UiReact* control in this scoped graph.\n\n"
		_SnapScript.NodeKind.UI_STATE:
			bb2 += "[code]UiState[/code] resource node (bindings, wires, or computed inputs).\n\n"
			plain2 += "UiState resource node (bindings, wires, or computed inputs).\n\n"
		_SnapScript.NodeKind.UI_COMPUTED:
			bb2 += "[code]UiComputed*[/code] resource node (aggregates [code]sources[/code]).\n\n"
			plain2 += "UiComputed* resource node (aggregates sources).\n\n"
		_:
			bb2 += "Node in this scoped graph.\n\n"
			plain2 += "Node in this scoped graph.\n\n"
	return PackedStringArray([bb2, plain2])


func _fill_node_details(node_id: String) -> void:
	if node_id.is_empty():
		return
	var narr: Object = _get_narrative_cached(node_id) as Object
	var nb: Dictionary = _last_layout.get(&"node_by_id", {}) as Dictionary
	var d: Dictionary = nb.get(node_id, {}) as Dictionary
	var edges: Array = _last_layout.get(&"draw_edges", []) as Array
	var layout_focus := str(_last_layout.get(&"focus_id", ""))
	var node_layer: Dictionary = _last_layout.get(&"node_layer", {}) as Dictionary
	var nk := int(d.get(&"kind", -1))

	var bb := ""
	var plain := ""
	if narr != null and nk == _SnapScript.NodeKind.CONTROL:
		for line0: String in (narr as UiReactExplainGraphNarrative).bound_state_lines:
			bb += line0
			plain += _plain_from_bbcode_line(line0)

	var conn := _connections_section_bb_plain(node_id, d, edges)
	bb += conn[0]
	plain += conn[1]

	if nk == _SnapScript.NodeKind.CONTROL:
		var wh := _resolve_control_host_from_node(node_id, d)
		if wh != null:
			var wrs := _wire_rules_summary_bb_plain(wh)
			bb += wrs[0]
			plain += wrs[1]

	if narr != null:
		bb += "\n[b]Graph context[/b]\n"
		plain += "\nGraph context\n"
		var reach := _append_reachability_from_narrative(narr)
		bb += reach[0]
		plain += reach[1]
		var cyc := _append_cycle_section_bb_plain(node_id)
		bb += cyc[0]
		plain += cyc[1]
		var mm := _mismatch_banner_bb_plain(narr)
		bb += mm[0]
		plain += mm[1]
		var disc := _details_declarative_footer_bb_plain()
		bb += disc[0]
		plain += disc[1]

	var skip_on_canvas := node_id == layout_focus and nk == _SnapScript.NodeKind.CONTROL
	if not skip_on_canvas:
		bb += "[b]On canvas[/b]\n"
		plain += "On canvas\n"
		var hl := _node_headline_bb_plain(node_id, d, layout_focus)
		bb += hl[0]
		plain += hl[1]

	var incident: Array[Dictionary] = []
	for e: Variant in edges:
		if e is not Dictionary:
			continue
		var ed: Dictionary = e as Dictionary
		if str(ed.get(&"from_id", "")) == node_id or str(ed.get(&"to_id", "")) == node_id:
			incident.append(ed)
	incident.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			var ka := int(a.get(&"kind", -1))
			var kb := int(b.get(&"kind", -1))
			if ka != kb:
				return ka < kb
			var fa := str(a.get(&"from_id", ""))
			var fb := str(b.get(&"from_id", ""))
			if fa != fb:
				return fa < fb
			return str(a.get(&"to_id", "")) < str(b.get(&"to_id", ""))
	)

	if nk != _SnapScript.NodeKind.CONTROL:
		bb += "[b]Incident edges[/b]\n"
		plain += "Incident edges\n"
		if incident.is_empty():
			bb += "No edges touch this node in the scoped graph (or it is isolated after filters).\n\n"
			plain += "No edges touch this node in the scoped graph (or it is isolated after filters).\n\n"
		else:
			var n_show := mini(incident.size(), _INCIDENT_EDGE_CAP)
			for i in n_show:
				var pair := _format_incident_edge_bb_plain(incident[i])
				bb += pair[0] + "\n"
				plain += pair[1] + "\n"
			bb += "\n"
			plain += "\n"
			var overflow := incident.size() - n_show
			if overflow > 0:
				bb += "[i]+%d more in this graph[/i]\n\n" % overflow
				plain += "+%d more in this graph\n\n" % overflow

	if node_id != layout_focus:
		var rel := _focus_relation_blurb_bb_plain(node_id, layout_focus, node_layer)
		bb += rel[0]
		plain += rel[1]

	bb += "[b]Technical[/b]\n"
	plain += "Technical\n"
	var short_l := str(d.get(&"short_label", ""))
	var full_l := str(d.get(&"label", ""))
	if not short_l.is_empty():
		bb += "Short label: [code]%s[/code]\n" % short_l
		plain += "Short label: %s\n" % short_l
	if nk == _SnapScript.NodeKind.CONTROL:
		var cp := str(d.get(&"control_path", ""))
		if not cp.is_empty():
			bb += "Scene path: [code]%s[/code]\n" % cp
			plain += "Scene path: %s\n" % cp
	elif nk == _SnapScript.NodeKind.UI_STATE or nk == _SnapScript.NodeKind.UI_COMPUTED:
		var fp := str(d.get(&"state_file_path", ""))
		if not fp.is_empty():
			bb += "Resource: [code]%s[/code]\n" % fp
			plain += "Resource: %s\n" % fp
		else:
			var eh := str(d.get(&"embedded_host_path", ""))
			var ec := str(d.get(&"embedded_context", ""))
			if not eh.is_empty():
				bb += "Embedded — host: [code]%s[/code] context: [code]%s[/code]\n" % [eh, ec]
				plain += "Embedded — host: %s context: %s\n" % [eh, ec]
	if not full_l.is_empty():
		bb += "Full label: %s\n" % full_l
		plain += "Full label: %s\n" % full_l
	bb += "Technical id: [code]%s[/code]\n" % node_id
	plain += "Technical id: %s\n" % node_id

	_set_details_both(bb, plain)


func _edge_details_summary_bb_plain(
	from_id: String, to_id: String, kind: int, label: String, edge_index: int
) -> PackedStringArray:
	var edges: Array = _last_layout.get(&"draw_edges", []) as Array
	var ed: Dictionary = {}
	if edge_index >= 0 and edge_index < edges.size():
		var ev: Variant = edges[edge_index]
		if ev is Dictionary:
			ed = ev as Dictionary
	var from_short := _short_label_for_node_id(from_id)
	var to_short := _short_label_for_node_id(to_id)
	var bb := ""
	var plain := ""
	match kind:
		_SnapScript.EdgeKind.BINDING:
			var bp0 := str(ed.get(&"binding_property", label))
			bb = "[b]Property binding[/b] — [code]%s[/code] → [code]%s[/code], export [code]%s[/code]\n\n" % [
				from_short,
				to_short,
				bp0,
			]
			plain = "Property binding — %s → %s, export %s\n\n" % [from_short, to_short, bp0]
		_SnapScript.EdgeKind.COMPUTED_SOURCE:
			bb = "[b]Computed source[/b] — [code]%s[/code] → [code]%s[/code]\n" % [from_short, to_short]
			bb += "[code]%s[/code] feeds an entry in the computed resource [code]%s[/code]'s [code]sources[/code] array.\n\n" % [
				from_short,
				to_short,
			]
			plain = "Computed source — %s → %s\n" % [from_short, to_short]
			plain += "%s feeds an entry in the computed resource %s's sources array.\n\n" % [from_short, to_short]
		_SnapScript.EdgeKind.WIRE_FLOW:
			bb = "[b]Wire flow[/b] — [code]%s[/code] → [code]%s[/code]\n" % [from_short, to_short]
			bb += "A [code]wire_rules[/code] row connects input [code]%s[/code] to output [code]%s[/code] (each endpoint is a state or computed resource in this snapshot).\n\n" % [
				from_short,
				to_short,
			]
			plain = "Wire flow — %s → %s\n" % [from_short, to_short]
			plain += "A wire_rules row connects input %s to output %s (each endpoint is a state or computed resource in this snapshot).\n\n" % [
				from_short,
				to_short,
			]
		_:
			bb = "[b]Edge[/b]\nDeclarative dependency between two snapshot nodes.\n\n"
			plain = "Edge\nDeclarative dependency between two snapshot nodes.\n\n"

	var show_endpoints := not (
		kind == _SnapScript.EdgeKind.BINDING
		or kind == _SnapScript.EdgeKind.COMPUTED_SOURCE
		or kind == _SnapScript.EdgeKind.WIRE_FLOW
	)
	if show_endpoints:
		bb += "[b]Endpoints[/b]\n"
		bb += "From: [code]%s[/code]  →  To: [code]%s[/code]\n" % [from_short, to_short]
		if not label.is_empty():
			bb += "Detail: [code]%s[/code]\n" % label
		bb += "\n"
		plain += "Endpoints\n"
		plain += "From: %s  →  To: %s\n" % [from_short, to_short]
		if not label.is_empty():
			plain += "Detail: %s\n" % label
		plain += "\n"

	if kind == _SnapScript.EdgeKind.BINDING:
		var hp := str(ed.get(&"host_path", ""))
		var bp := str(ed.get(&"binding_property", ""))
		if bp.is_empty():
			bp = str(ed.get(&"label", label))
		if not _edge_binding_skip_inspector_blurb(ed):
			bb += "[b]Where to edit[/b]\n"
			plain += "Where to edit\n"
			if hp.is_empty():
				bb += "[i]No control path on this edge in the snapshot—use [b]Focus in Inspector[/b] or refresh the graph.[/i]\n\n"
				plain += "No control path on this edge in the snapshot—use Focus in Inspector or refresh the graph.\n\n"
			else:
				bb += "Inspector on control [code]%s[/code], export [code]%s[/code].\n\n" % [hp, bp]
				plain += "Inspector on control %s, export %s.\n\n" % [hp, bp]
		var opt_hint := _optional_binding_dock_hint_bb_plain(ed, StringName(bp))
		bb += opt_hint[0]
		plain += opt_hint[1]
	elif kind == _SnapScript.EdgeKind.COMPUTED_SOURCE:
		var hp2 := str(ed.get(&"host_path", ""))
		var si := int(ed.get(&"computed_source_index", -1))
		bb += "[b]Where to edit[/b]\nComputed [code]sources[/code]"
		var plain_w := "Where to edit\nComputed sources"
		if si >= 0:
			bb += " (index [code]%d[/code])" % si
			plain_w += " (index %d)" % si
		bb += " on the owning control"
		plain_w += " on the owning control"
		if not hp2.is_empty():
			bb += " [code]%s[/code]" % hp2
			plain_w += " %s" % hp2
		bb += ".\n\n"
		plain += plain_w + ".\n\n"
		var cc := str(ed.get(&"computed_context", ""))
		if not cc.is_empty():
			bb += "[b]Computed owner[/b]\n[code]%s[/code], [code]sources[%d][/code] — target for [b]Rebind computed source…[/b] or [b]Remove computed dependency[/b].\n\n" % [
				cc,
				si,
			]
			plain += "Computed owner\n%s, sources[%d] — target for Rebind computed source… or Remove computed dependency.\n\n" % [cc, si]
	elif kind == _SnapScript.EdgeKind.WIRE_FLOW:
		var wh := str(ed.get(&"wire_host_path", ""))
		var wi := int(ed.get(&"wire_rule_index", -1))
		bb += "[b]Where to edit[/b]\n"
		var plain_w2 := "Where to edit\n"
		if not wh.is_empty():
			bb += "Control [code]%s[/code], [code]wire_rules[/code]" % wh
			plain_w2 += "Control %s, wire_rules" % wh
			if wi >= 0:
				bb += " row [code]%d[/code]" % wi
				plain_w2 += " row %d" % wi
			bb += ".\n\n"
			plain_w2 += ".\n\n"
			plain += plain_w2
		var win := str(ed.get(&"wire_in_property", ""))
		var wout := str(ed.get(&"wire_out_property", ""))
		if not win.is_empty() and not wout.is_empty():
			bb += "[b]Rule exports[/b]\n"
			bb += "Input export [code]%s[/code] → output export [code]%s[/code] (dock action row: rebind input/output).\n\n" % [
				win,
				wout,
			]
			plain += "Rule exports\n"
			plain += "Input export %s → output export %s (dock action row: rebind input/output).\n\n" % [win, wout]

	if from_id == _last_focus_id or to_id == _last_focus_id:
		bb += "[b]Relation to focus[/b]\nTouches the focus control directly.\n\n"
		plain += "Relation to focus\nTouches the focus control directly.\n\n"
	return PackedStringArray([bb, plain])


func _fill_edge_details(from_id: String, to_id: String, kind: int, label: String, edge_index: int) -> void:
	var anchor_id := _edge_anchor_id(from_id, to_id)
	var ex: Array = _edge_graph_context_display_excludes(from_id, to_id, kind, anchor_id)
	var narr: Object = _get_narrative_cached_ex(
		anchor_id, ex[0] as PackedStringArray, ex[1] as PackedStringArray
	) as Object
	var token := _edge_short_token(kind)
	var summ := _edge_details_summary_bb_plain(from_id, to_id, kind, label, edge_index)
	var bb := summ[0]
	var plain := summ[1]
	var sib := _other_edges_at_anchor_bb_plain(anchor_id, edge_index)
	bb += sib[0]
	plain += sib[1]
	if narr != null:
		bb += "\n[b]Graph context[/b]\n"
		plain += "\nGraph context\n"
		var reach := _append_reachability_from_narrative(narr)
		bb += reach[0]
		plain += reach[1]
		var disc2 := _details_declarative_footer_bb_plain()
		bb += disc2[0]
		plain += disc2[1]
		var cyc := _append_cycle_section_bb_plain(anchor_id)
		bb += cyc[0]
		plain += cyc[1]
		var mm := _mismatch_banner_bb_plain(narr)
		bb += mm[0]
		plain += mm[1]

	bb += "[b]Technical[/b]\nKind token: [code]%s[/code]\nFrom id: [code]%s[/code]\nTo id: [code]%s[/code]\n" % [token, from_id, to_id]
	plain += "Technical\nKind token: %s\nFrom id: %s\nTo id: %s\n" % [token, from_id, to_id]

	_set_details_both(bb, plain)
	_sync_wire_rule_id_row()
	_try_focus_wire_rule_list_from_edge(kind, edge_index)


func _try_focus_wire_rule_list_from_edge(kind: int, edge_index: int) -> void:
	if _wire_rules_section == null:
		return
	if kind != _SnapScript.EdgeKind.WIRE_FLOW:
		return
	var edges: Array = _last_layout.get(&"draw_edges", []) as Array
	if edge_index < 0 or edge_index >= edges.size():
		return
	var ev: Variant = edges[edge_index]
	if ev is not Dictionary:
		return
	var edf: Dictionary = ev as Dictionary
	var wi := int(edf.get(&"wire_rule_index", -1))
	if wi >= 0:
		(_wire_rules_section as Object).call(&"focus_rule_index", wi)


func _edge_short_token(kind: int) -> String:
	match kind:
		_SnapScript.EdgeKind.BINDING:
			return "bind"
		_SnapScript.EdgeKind.COMPUTED_SOURCE:
			return "computed"
		_SnapScript.EdgeKind.WIRE_FLOW:
			return "wire"
	return "edge"


func _short_label_for_node_id(node_id: String) -> String:
	var nb: Dictionary = _last_layout.get(&"node_by_id", {}) as Dictionary
	var d: Dictionary = nb.get(node_id, {}) as Dictionary
	if d.is_empty():
		return node_id
	return str(d.get(&"short_label", d.get(&"label", node_id)))


func _on_focus_inspector_pressed() -> void:
	if _plugin == null:
		return
	var ei := _plugin.get_editor_interface()
	var root := ei.get_edited_scene_root()
	if root == null:
		return
	if _selection_kind == _SEL_NODE and not _graph_selected_node_id.is_empty():
		_focus_node_in_editor(_graph_selected_node_id, ei, root)
	elif _selection_kind == _SEL_EDGE and _graph_selected_edge_index >= 0:
		_focus_edge_in_editor(_graph_selected_edge_index, ei, root)


func _on_graph_inspector_focus_selection_requested() -> void:
	_on_focus_inspector_pressed()


func _focus_node_in_editor(node_id: String, ei: EditorInterface, root: Node) -> void:
	if node_id.begins_with("ctrl:"):
		var path_str := node_id.substr(5)
		var np := NodePath(path_str)
		if root.has_node(np):
			var n: Node = root.get_node(np)
			if n is Control:
				ei.get_selection().clear()
				ei.get_selection().add_node(n)
				if ei.has_method(&"edit_node"):
					ei.call(&"edit_node", n as Node)
				return
	elif node_id.begins_with("state:"):
		var nb: Dictionary = _last_layout.get(&"node_by_id", {}) as Dictionary
		var d: Dictionary = nb.get(node_id, {}) as Dictionary
		var fp := str(d.get(&"state_file_path", ""))
		if fp.is_empty():
			_set_details_both(
				"[i]Embedded state has no resource file — select the owning [code]UiReact*[/code] control in the Scene tree, then open its state in the Inspector.[/i]",
				"Embedded state has no resource file — select the owning UiReact* control in the Scene tree."
			)
			return
		if ResourceLoader.exists(fp):
			var res: Resource = load(fp)
			if res != null and ei.has_method(&"edit_resource"):
				ei.call(&"edit_resource", res)
				return
	_set_details_both(
		"[i]Could not open this resource in the Inspector.[/i]",
		"Could not open this resource in the Inspector."
	)


func _focus_edge_in_editor(edge_index: int, ei: EditorInterface, root: Node) -> void:
	var edges: Array = _last_layout.get(&"draw_edges", []) as Array
	if edge_index < 0 or edge_index >= edges.size():
		return
	var ev: Variant = edges[edge_index]
	if ev is not Dictionary:
		return
	var ed: Dictionary = ev as Dictionary
	var kind := int(ed.get(&"kind", -1))
	if kind == _SnapScript.EdgeKind.BINDING:
		var hp := str(ed.get(&"host_path", ""))
		if not hp.is_empty() and root.has_node(NodePath(hp)):
			var n: Node = root.get_node(NodePath(hp))
			if n is Control:
				ei.get_selection().clear()
				ei.get_selection().add_node(n)
				if ei.has_method(&"edit_node"):
					ei.call(&"edit_node", n)
				return
	elif kind == _SnapScript.EdgeKind.WIRE_FLOW:
		var wh := str(ed.get(&"wire_host_path", ""))
		if not wh.is_empty() and root.has_node(NodePath(wh)):
			var n2: Node = root.get_node(NodePath(wh))
			if n2 is Control:
				ei.get_selection().clear()
				ei.get_selection().add_node(n2)
				if ei.has_method(&"edit_node"):
					ei.call(&"edit_node", n2)
				return
	elif kind == _SnapScript.EdgeKind.COMPUTED_SOURCE:
		var to_id := str(ed.get(&"to_id", ""))
		if not to_id.is_empty():
			_focus_node_in_editor(to_id, ei, root)
			return


func _on_copy_details_pressed() -> void:
	if not _last_details_plain.is_empty():
		DisplayServer.clipboard_set(_last_details_plain)


func _editor_richtext_normal_font_size() -> int:
	if _plugin == null:
		return 13
	var t := _DockThemeScript.editor_theme(_plugin)
	if t != null and t.has_font_size(&"normal_font_size", &"RichTextLabel"):
		return t.get_font_size(&"normal_font_size", &"RichTextLabel")
	return 13


## Wire payload row labels match editor [Label]; legend **item** labels match [RichTextLabel] body, **group** labels use [method _editor_label_font_size].
func _editor_label_font_size() -> int:
	if _plugin == null:
		return 12
	var t := _DockThemeScript.editor_theme(_plugin)
	if t != null and t.has_font_size(&"font_size", &"Label"):
		return t.get_font_size(&"font_size", &"Label")
	return 12


func _apply_legend_font_sizes() -> void:
	if _legend_host == null or _plugin == null:
		return
	var item_fs := _editor_richtext_normal_font_size()
	var grp_fs := maxi(_editor_label_font_size() - 1, 10)
	if _legend_group_nodes_label != null:
		_legend_group_nodes_label.add_theme_font_size_override(&"font_size", grp_fs)
		_legend_group_nodes_label.add_theme_color_override(&"font_color", _LEGEND_GROUP_FONT_COLOR)
	if _legend_group_edges_label != null:
		_legend_group_edges_label.add_theme_font_size_override(&"font_size", grp_fs)
		_legend_group_edges_label.add_theme_color_override(&"font_color", _LEGEND_GROUP_FONT_COLOR)
	_apply_legend_item_label_font_sizes_recursive(_legend_host, item_fs)


func _apply_legend_item_label_font_sizes_recursive(root: Node, item_fs: int) -> void:
	for ch: Node in root.get_children():
		if ch is Label:
			if ch != _legend_group_nodes_label and ch != _legend_group_edges_label:
				(ch as Label).add_theme_font_size_override(&"font_size", item_fs)
		_apply_legend_item_label_font_sizes_recursive(ch, item_fs)


func _apply_wire_payload_label_font_sizes() -> void:
	if _plugin == null:
		return
	var fs := _editor_label_font_size()
	for row: Node in [_wire_rule_id_row, _wire_enabled_row, _wire_trigger_row]:
		if row == null:
			continue
		for ch: Node in (row as Node).get_children():
			if ch is Label:
				(ch as Label).add_theme_font_size_override(&"font_size", fs)


func _apply_graph_body_split_editor_theme() -> void:
	if _graph_body_split == null or _plugin == null:
		return
	_graph_body_split.add_theme_constant_override(&"minimum_grab_thickness", 10)
	_graph_body_split.add_theme_constant_override(&"autohide", 0)
	_DockThemeScript.apply_split_bar(_graph_body_split, _plugin)


func _restore_graph_body_split_offset() -> void:
	if _graph_split_restored or _graph_body_split == null:
		return
	var saved: Variant = ProjectSettings.get_setting(UiReactDockConfig.KEY_GRAPH_BODY_VSPLIT_OFFSET, -1)
	var off := int(saved)
	if off < 0:
		_graph_split_restored = true
		return
	_graph_split_restore_attempts = 0
	call_deferred(&"_apply_graph_body_split_offset_clamped", off)


## Deferred until [VSplitContainer] has a valid height; see [member _graph_split_restore_attempts].
func _apply_graph_body_split_offset_clamped(off: int) -> void:
	if _graph_body_split == null:
		return
	var h := int(_graph_body_split.size.y)
	if h <= 1:
		_graph_split_restore_attempts += 1
		if _graph_split_restore_attempts < 12:
			call_deferred(&"_apply_graph_body_split_offset_clamped", off)
		else:
			_graph_split_restored = true
		return
	var graph_min := int(_graph_view.custom_minimum_size.y) if _graph_view else 120
	var col_min := int(_details_scroll.custom_minimum_size.y) if _details_scroll else 120
	var max_off := maxi(graph_min, h - col_min)
	var clamped := clampi(off, graph_min, max_off)
	_graph_body_split.split_offset = clamped
	_graph_split_restored = true
	_graph_split_restore_attempts = 0


func _on_explain_panel_tree_exiting() -> void:
	if _graph_body_split == null:
		return
	UiReactDockConfig.save_ui_preference(
		UiReactDockConfig.KEY_GRAPH_BODY_VSPLIT_OFFSET, _graph_body_split.split_offset
	)


func _add_legend_edge_sample(
	row: HBoxContainer, col: Color, line_height_px: float, text: String, tip: String
) -> void:
	var inner_h := maxf(2.0, line_height_px)
	var wrap := Panel.new()
	wrap.custom_minimum_size = Vector2(30, maxf(8.0, inner_h + 6.0))
	wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sb_wrap := StyleBoxFlat.new()
	sb_wrap.bg_color = _LEGEND_EDGE_SWATCH_BG
	sb_wrap.set_border_width_all(1)
	sb_wrap.border_color = _LEGEND_EDGE_SWATCH_BORDER
	sb_wrap.set_corner_radius_all(2)
	wrap.add_theme_stylebox_override(&"panel", sb_wrap)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.add_child(center)
	var line := ColorRect.new()
	line.custom_minimum_size = Vector2(22, inner_h)
	line.color = col
	center.add_child(line)
	row.add_child(wrap)
	var lab := Label.new()
	lab.text = text
	lab.tooltip_text = tip
	row.add_child(lab)


func _add_legend_node_chip(
	row: HBoxContainer,
	col: Color,
	kind: int,
	text: String,
	is_focus_host: bool = false,
	tooltip_text: String = "",
) -> void:
	var chip := Panel.new()
	chip.custom_minimum_size = Vector2(28, 12)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(_ExplainLayoutScript.fill_corner_radius_px(kind))
	if is_focus_host:
		sb.set_border_width_all(2)
		sb.border_color = _ExplainGraphViewScript.GRAPH_LEGEND_FOCUS_BORDER
	else:
		sb.set_border_width_all(1)
		sb.border_color = _LEGEND_NODE_CHIP_BORDER
	chip.add_theme_stylebox_override(&"panel", sb)
	row.add_child(chip)
	var lab := Label.new()
	lab.text = text
	lab.tooltip_text = tooltip_text
	row.add_child(lab)


func _on_legend_host_resized() -> void:
	if _legend_host == null or _legend_nodes_row == null or _legend_edges_row == null:
		return
	var wide := _legend_host.size.x >= float(_LEGEND_WRAP_THRESHOLD_PX)
	if wide:
		_legend_host.add_theme_constant_override(&"separation", 0)
		if _legend_edges_row.get_parent() != _legend_nodes_row:
			if _legend_edges_row.get_parent() == _legend_host:
				_legend_host.remove_child(_legend_edges_row)
			if _legend_mid_spacer.get_parent() != _legend_nodes_row:
				_legend_nodes_row.add_child(_legend_mid_spacer)
			_legend_mid_spacer.visible = true
			_legend_nodes_row.add_child(_legend_edges_row)
	else:
		_legend_host.add_theme_constant_override(&"separation", 6)
		if _legend_edges_row.get_parent() != _legend_host:
			if _legend_edges_row.get_parent() == _legend_nodes_row:
				_legend_nodes_row.remove_child(_legend_edges_row)
			if _legend_mid_spacer.get_parent() == _legend_nodes_row:
				_legend_nodes_row.remove_child(_legend_mid_spacer)
			_legend_mid_spacer.visible = false
			_legend_host.add_child(_legend_edges_row)
			_legend_host.move_child(_legend_nodes_row, 0)


func _clamp_layout_caps() -> void:
	_layout_max_nodes = clampi(_layout_max_nodes, _SCOPE_MIN_NODES, _SCOPE_MAX_NODES)
	_layout_max_edges = clampi(_layout_max_edges, _SCOPE_MIN_EDGES, _SCOPE_MAX_EDGES)


func _default_scope_dict() -> Dictionary:
	return {
		&"name": "",
		&"max_nodes": 200,
		&"max_edges": 400,
		&"show_binding": true,
		&"show_computed": true,
		&"show_wire": true,
		&"show_all_edge_labels": false,
		&"full_lists": false,
		&"pinned": PackedStringArray(),
	}


func _preset_from_variant(v: Variant) -> Dictionary:
	var d := _default_scope_dict()
	if v is not Dictionary:
		return d
	var src: Dictionary = v as Dictionary
	var n := String(src.get("name", "")).strip_edges()
	d[&"name"] = n
	d[&"max_nodes"] = clampi(int(src.get("max_nodes", 200)), _SCOPE_MIN_NODES, _SCOPE_MAX_NODES)
	d[&"max_edges"] = clampi(int(src.get("max_edges", 400)), _SCOPE_MIN_EDGES, _SCOPE_MAX_EDGES)
	d[&"show_binding"] = bool(src.get("show_binding", true))
	d[&"show_computed"] = bool(src.get("show_computed", true))
	d[&"show_wire"] = bool(src.get("show_wire", true))
	d[&"show_all_edge_labels"] = bool(src.get("show_all_edge_labels", false))
	d[&"full_lists"] = bool(src.get("full_lists", false))
	var pins: Variant = src.get("pinned", PackedStringArray())
	var ps: PackedStringArray = PackedStringArray()
	if pins is Array:
		for it in pins as Array:
			var s := String(it).strip_edges()
			if not s.is_empty():
				ps.append(s)
	elif pins is PackedStringArray:
		ps = pins as PackedStringArray
	var seen_pin: Dictionary = {}
	var deduped: PackedStringArray = PackedStringArray()
	for i in range(ps.size()):
		var pid := String(ps[i]).strip_edges()
		if pid.is_empty() or seen_pin.has(pid):
			continue
		seen_pin[pid] = true
		deduped.append(pid)
	d[&"pinned"] = deduped
	return d


func _capture_current_scope_settings(preset_name: String) -> Dictionary:
	var pins_copy: PackedStringArray = PackedStringArray()
	for i in range(_pinned_node_ids.size()):
		pins_copy.append(String(_pinned_node_ids[i]))
	return {
		&"name": preset_name,
		&"max_nodes": _layout_max_nodes,
		&"max_edges": _layout_max_edges,
		&"show_binding": _cb_bind != null and _cb_bind.button_pressed,
		&"show_computed": _cb_computed != null and _cb_computed.button_pressed,
		&"show_wire": _cb_wire != null and _cb_wire.button_pressed,
		&"show_all_edge_labels": _cb_edge_labels != null and _cb_edge_labels.button_pressed,
		&"full_lists": _show_full_lists,
		&"pinned": pins_copy,
	}


func _apply_scope_dict_to_ui(d: Dictionary) -> void:
	_layout_max_nodes = clampi(int(d.get("max_nodes", 200)), _SCOPE_MIN_NODES, _SCOPE_MAX_NODES)
	_layout_max_edges = clampi(int(d.get("max_edges", 400)), _SCOPE_MIN_EDGES, _SCOPE_MAX_EDGES)
	if _cb_bind:
		_cb_bind.button_pressed = bool(d.get("show_binding", true))
	if _cb_computed:
		_cb_computed.button_pressed = bool(d.get("show_computed", true))
	if _cb_wire:
		_cb_wire.button_pressed = bool(d.get("show_wire", true))
	if _cb_edge_labels:
		_cb_edge_labels.button_pressed = bool(d.get("show_all_edge_labels", false))
	var fl := bool(d.get("full_lists", false))
	_show_full_lists = fl
	if _cb_full_lists:
		_cb_full_lists.button_pressed = fl
	var pv: Variant = d.get("pinned", PackedStringArray())
	if pv is PackedStringArray:
		_pinned_node_ids = pv
	elif pv is Array:
		_pinned_node_ids = PackedStringArray()
		for it in pv as Array:
			var s := String(it).strip_edges()
			if not s.is_empty():
				_pinned_node_ids.append(s)
	else:
		_pinned_node_ids = PackedStringArray()
	_clamp_layout_caps()
	if _graph_view != null:
		_push_visual_filters()


func _rebuild_scope_preset_dropdown() -> void:
	if _scope_preset_option == null:
		return
	_scope_preset_block_select = true
	_scope_preset_option.clear()
	_scope_preset_option.add_item("Default")
	_scope_preset_option.set_item_metadata(0, "")
	_scope_presets_cache = UiReactDockConfig.load_graph_scope_presets_raw()
	var names: Array[String] = []
	for it: Variant in _scope_presets_cache:
		if it is Dictionary:
			var nm := String((it as Dictionary).get("name", "")).strip_edges()
			if not nm.is_empty() and nm.to_lower() != "default":
				names.append(nm)
	names.sort()
	var idx := 1
	for nm2 in names:
		_scope_preset_option.add_item(nm2)
		_scope_preset_option.set_item_metadata(idx, nm2)
		idx += 1
	_scope_preset_block_select = false


func _sync_active_scope_preset_from_settings(_select_dropdown: bool) -> void:
	_rebuild_scope_preset_dropdown()
	var active: String = String(UiReactDockConfig.get_active_graph_scope_preset_name()).strip_edges()
	if active.is_empty() or active.to_lower() == "default":
		_apply_scope_dict_to_ui(_default_scope_dict())
		_sync_hidden_preset_option_index()
		return
	var found: Dictionary = {}
	for it: Variant in _scope_presets_cache:
		if it is Dictionary:
			var pd: Dictionary = _preset_from_variant(it)
			if String(pd.get("name", "")) == active:
				found = pd
				break
	if found.is_empty():
		_apply_scope_dict_to_ui(_default_scope_dict())
		UiReactDockConfig.set_active_graph_scope_preset_name("")
		_sync_hidden_preset_option_index()
		return
	_apply_scope_dict_to_ui(found)
	_sync_hidden_preset_option_index()


func _persist_presets_array(arr: Array) -> void:
	UiReactDockConfig.save_graph_scope_presets_raw(arr)
	_rebuild_scope_preset_dropdown()


func _on_scope_preset_selected(index: int) -> void:
	if _scope_preset_block_select or _scope_preset_option == null:
		return
	var meta: Variant = _scope_preset_option.get_item_metadata(index)
	_apply_scope_preset_by_name(str(meta).strip_edges())


func _on_scope_save_as_pressed() -> void:
	if _scope_save_name_dialog == null or _scope_save_name_edit == null:
		return
	_pin_pending_after_save = false
	_scope_save_name_dialog.title = "Save scope preset"
	_scope_save_name_dialog.dialog_text = ""
	_scope_save_name_edit.text = ""
	_scope_save_name_dialog.popup_centered()


func _commit_upsert_preset_activate(rec: Dictionary) -> void:
	var raw_name := String(rec.get(&"name", "")).strip_edges()
	if raw_name.is_empty() or raw_name.to_lower() == "default":
		push_warning("Ui React: choose a non-empty preset name other than “Default”.")
		return
	var arr: Array = UiReactDockConfig.load_graph_scope_presets_raw()
	var replaced := false
	var out: Array = []
	for it: Variant in arr:
		if it is Dictionary:
			var old: Dictionary = _preset_from_variant(it)
			if String(old.get("name", "")) == raw_name:
				out.append(rec)
				replaced = true
			else:
				out.append(old)
	if not replaced:
		out.append(rec)
	_persist_presets_array(out)
	UiReactDockConfig.set_active_graph_scope_preset_name(raw_name)
	_sync_active_scope_preset_from_settings(true)
	refresh()


func _on_scope_save_name_canceled() -> void:
	_pin_pending_after_save = false
	if _scope_save_name_dialog:
		_scope_save_name_dialog.title = "Save scope preset"
		_scope_save_name_dialog.dialog_text = ""


func _on_scope_save_name_confirmed() -> void:
	var raw_name := _scope_save_name_edit.text.strip_edges() if _scope_save_name_edit else ""
	if raw_name.is_empty() or raw_name.to_lower() == "default":
		push_warning("Ui React: choose a non-empty preset name other than “Default”.")
		return
	var rec := _capture_current_scope_settings(raw_name)
	if _pin_pending_after_save:
		_pin_pending_after_save = false
		if _selection_kind == _SEL_NODE and not _graph_selected_node_id.is_empty():
			var pins: PackedStringArray = PackedStringArray()
			var pins_v: Variant = rec.get(&"pinned", PackedStringArray())
			if pins_v is PackedStringArray:
				pins = (pins_v as PackedStringArray).duplicate()
			elif pins_v is Array:
				for it in pins_v as Array:
					var ps := String(it).strip_edges()
					if not ps.is_empty():
						pins.append(ps)
			var sid := _graph_selected_node_id
			var seen: Dictionary = {}
			for i in range(pins.size()):
				seen[pins[i]] = true
			if not seen.has(sid):
				pins.append(sid)
				rec[&"pinned"] = pins
	if _scope_save_name_dialog:
		_scope_save_name_dialog.title = "Save scope preset"
		_scope_save_name_dialog.dialog_text = ""
	_commit_upsert_preset_activate(rec)


func _on_scope_manage_pressed() -> void:
	if _scope_manage_list == null or _scope_manage_dialog == null:
		return
	_scope_manage_list.clear()
	for it: Variant in UiReactDockConfig.load_graph_scope_presets_raw():
		if it is Dictionary:
			var nm := String((it as Dictionary).get("name", "")).strip_edges()
			if not nm.is_empty():
				_scope_manage_list.add_item(nm)
	_scope_manage_dialog.popup_centered()


func _on_scope_manage_delete_pressed() -> void:
	if _scope_manage_list == null:
		return
	var sel: PackedInt32Array = _scope_manage_list.get_selected_items()
	if sel.is_empty():
		return
	var del_name := _scope_manage_list.get_item_text(sel[0])
	var arr: Array = UiReactDockConfig.load_graph_scope_presets_raw()
	var out: Array = []
	for it: Variant in arr:
		if it is Dictionary:
			var nm := String((it as Dictionary).get("name", "")).strip_edges()
			if nm != del_name:
				out.append(_preset_from_variant(it))
	_persist_presets_array(out)
	if UiReactDockConfig.get_active_graph_scope_preset_name() == del_name:
		UiReactDockConfig.set_active_graph_scope_preset_name("")
	_sync_active_scope_preset_from_settings(true)
	_on_scope_manage_pressed()
	refresh()


func _on_pin_node_pressed() -> void:
	if _selection_kind != _SEL_NODE or _graph_selected_node_id.is_empty():
		push_warning("Ui React: select a graph node to pin.")
		return
	var active: String = String(UiReactDockConfig.get_active_graph_scope_preset_name()).strip_edges()
	if active.is_empty() or active.to_lower() == "default":
		_pin_pending_after_save = true
		if _scope_save_name_dialog != null and _scope_save_name_edit != null:
			_scope_save_name_dialog.title = "Save scope preset and pin node"
			_scope_save_name_dialog.dialog_text = (
				"Creates a named preset from the current scope settings and adds the selected graph node to its pin list."
			)
			_scope_save_name_edit.text = "Pinned scope"
			_scope_save_name_dialog.popup_centered()
		return
	var pid := _graph_selected_node_id
	for i in range(_pinned_node_ids.size()):
		if _pinned_node_ids[i] == pid:
			return
	_pinned_node_ids.append(pid)
	var arr: Array = UiReactDockConfig.load_graph_scope_presets_raw()
	var out: Array = []
	var updated := false
	for it: Variant in arr:
		if it is Dictionary:
			var pd: Dictionary = _preset_from_variant(it)
			if String(pd.get("name", "")) == active:
				pd[&"pinned"] = _pinned_node_ids.duplicate()
				updated = true
			out.append(pd)
	if not updated:
		out.append(_capture_current_scope_settings(active))
	_persist_presets_array(out)
	refresh()


func _on_create_state_menu_id(menu_id: int) -> void:
	var names: PackedStringArray = _GraphFactoryScript.factory_state_class_names()
	if menu_id < 0 or menu_id >= names.size():
		return
	_create_state_class_pending = String(names[menu_id])
	_create_and_assign_mode = false
	_popup_create_state_save_dialog(false)


func _on_create_assign_binding_pressed() -> void:
	if not _can_create_and_assign_binding_edge():
		return
	var ei := _plugin.get_editor_interface()
	var root := ei.get_edited_scene_root()
	if root == null:
		return
	var edges: Array = _last_layout.get(&"draw_edges", []) as Array
	var idx := _graph_selected_edge_index
	if idx < 0 or idx >= edges.size():
		return
	var ed: Dictionary = edges[idx] as Dictionary
	var hp := str(ed.get(&"host_path", ""))
	var bp := str(ed.get(&"binding_property", ""))
	if bp.is_empty():
		bp = str(ed.get(&"label", ""))
	var host: Node = root.get_node(NodePath(hp))
	if not (host is Control):
		return
	var host_c := host as Control
	var comp := UiReactScannerService.get_component_name_from_script(host_c.get_script() as Script)
	var prop_sn := StringName(bp)
	var kind := ""
	var bindings: Array = UiReactComponentRegistry.BINDINGS_BY_COMPONENT.get(comp, [])
	for b in bindings:
		if b.get("property", &"") == prop_sn:
			kind = str(b.get("kind", ""))
			break
	var expected := UiReactBindingValidator._expected_binding_state_class(comp, prop_sn, kind, host_c)
	_create_assign_host_path = hp
	_create_assign_prop = prop_sn
	_create_assign_component = comp
	_create_assign_expected_class = expected
	_create_state_class_pending = String(expected)
	_create_and_assign_mode = true
	_popup_create_state_save_dialog(true)


func _popup_create_state_save_dialog(_for_assign: bool) -> void:
	var dlg := _ensure_create_state_save_dialog()
	var out_dir := _GraphFactoryScript.output_dir_from_project_settings()
	var err := UiReactStateFactoryService.ensure_output_dir(out_dir)
	if err != OK:
		push_error("Ui React: could not create output folder: %s" % out_dir)
		return
	var base_node := "state"
	var base_prop := _create_state_class_pending.to_lower()
	if _for_assign and not _create_assign_host_path.is_empty():
		var root := _plugin.get_editor_interface().get_edited_scene_root()
		if root != null and root.has_node(NodePath(_create_assign_host_path)):
			var hn: Node = root.get_node(NodePath(_create_assign_host_path))
			base_node = str(hn.name)
			base_prop = str(_create_assign_prop)
	var path := UiReactStateFactoryService.build_unique_file_path(out_dir, base_node, base_prop)
	dlg.title = "Save new %s" % _create_state_class_pending
	dlg.current_path = path
	dlg.popup_centered_ratio(0.55)


func _ensure_create_state_save_dialog() -> EditorFileDialog:
	if _create_state_save_dialog != null:
		return _create_state_save_dialog
	var dlg := EditorFileDialog.new()
	dlg.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	dlg.access = EditorFileDialog.ACCESS_RESOURCES
	dlg.add_filter("*.tres", "Resource")
	dlg.file_selected.connect(_on_create_state_file_selected)
	_plugin.get_editor_interface().get_base_control().add_child(dlg)
	_create_state_save_dialog = dlg
	return dlg


func _on_create_state_file_selected(path: String) -> void:
	var cls := _create_state_class_pending
	_create_state_class_pending = ""
	var assign_mode := _create_and_assign_mode
	_create_and_assign_mode = false
	if cls.is_empty() or _plugin == null:
		return
	var loaded := _GraphFactoryScript.save_new_state_at_path(StringName(cls), path)
	if loaded == null:
		push_error("Ui React: failed to save resource.")
		return
	if not (loaded is UiState):
		push_error("Ui React: saved resource is not UiState.")
		return
	var ui_st := loaded as UiState
	if assign_mode:
		if _actions == null:
			return
		var root := _plugin.get_editor_interface().get_edited_scene_root()
		if root == null or not root.has_node(NodePath(_create_assign_host_path)):
			return
		var hn: Node = root.get_node(NodePath(_create_assign_host_path))
		if not (hn is Control):
			return
		if not UiReactGraphNewBindingService.try_commit_assign(
			hn as Control, _create_assign_component, _create_assign_prop, ui_st, _actions
		):
			push_warning("Ui React: create and assign failed (type or slot).")
			return
	_create_assign_host_path = ""
	_create_assign_prop = &""
	_create_assign_component = ""
	_create_assign_expected_class = &""
	_plugin.get_editor_interface().get_resource_filesystem().scan()
	if _request_dock_refresh.is_valid():
		_request_dock_refresh.call()
	refresh()


func _can_create_and_assign_binding_edge() -> bool:
	if _plugin == null or _actions == null:
		return false
	if _selection_kind != _SEL_EDGE or _last_edge_kind != _SnapScript.EdgeKind.BINDING:
		return false
	var ei := _plugin.get_editor_interface()
	var root := ei.get_edited_scene_root()
	if root == null:
		return false
	var edges: Array = _last_layout.get(&"draw_edges", []) as Array
	var idx := _graph_selected_edge_index
	if idx < 0 or idx >= edges.size():
		return false
	var ed: Dictionary = edges[idx] as Dictionary
	if not _edge_allows_binding_rebind(ed, root):
		return false
	var hp := str(ed.get(&"host_path", ""))
	var bp := str(ed.get(&"binding_property", ""))
	if bp.is_empty():
		bp = str(ed.get(&"label", ""))
	if hp.is_empty() or bp.is_empty():
		return false
	if not root.has_node(NodePath(hp)):
		return false
	var n: Node = root.get_node(NodePath(hp))
	if not (n is Control):
		return false
	var host := n as Control
	var comp := UiReactScannerService.get_component_name_from_script(host.get_script() as Script)
	if comp.is_empty():
		return false
	var prop_sn := StringName(bp)
	if not UiReactGraphNewBindingService.binding_export_is_optional(comp, prop_sn):
		return false
	if host.get(prop_sn) != null:
		return false
	var kind := ""
	var bindings: Array = UiReactComponentRegistry.BINDINGS_BY_COMPONENT.get(comp, [])
	for b in bindings:
		if b.get("property", &"") == prop_sn:
			kind = str(b.get("kind", ""))
			break
	var expected := UiReactBindingValidator._expected_binding_state_class(comp, prop_sn, kind, host)
	if not _GraphFactoryScript.is_factory_supported_class(String(expected)):
		return false
	return true


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_theme_constant_override(&"margin_left", 8)
	add_theme_constant_override(&"margin_right", 8)
	add_theme_constant_override(&"margin_top", 8)
	add_theme_constant_override(&"margin_bottom", 8)

	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(v)

	_hint = RichTextLabel.new()
	_hint.bbcode_enabled = true
	_hint.fit_content = false
	_hint.scroll_active = false
	_hint.custom_minimum_size = Vector2(0, 36)
	_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hint.visible = false
	v.add_child(_hint)

	_auto_refresh_timer = Timer.new()
	_auto_refresh_timer.wait_time = 0.15
	_auto_refresh_timer.one_shot = true
	_auto_refresh_timer.timeout.connect(_on_debounced_auto_refresh)
	add_child(_auto_refresh_timer)

	_hidden_chrome_host = Control.new()
	_hidden_chrome_host.visible = false
	_hidden_chrome_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hidden_chrome_host.custom_minimum_size = Vector2.ZERO
	v.add_child(_hidden_chrome_host)

	_scope_preset_option = OptionButton.new()
	_scope_preset_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scope_preset_option.tooltip_text = "Scope layout, filters, and pins (project settings)."
	_scope_preset_option.item_selected.connect(_on_scope_preset_selected)
	_hidden_chrome_host.add_child(_scope_preset_option)

	_cb_full_lists = CheckBox.new()
	_cb_full_lists.text = "Full lists"
	_cb_full_lists.tooltip_text = "Uncap upstream/downstream lines in the details pane."
	_cb_full_lists.button_pressed = false
	_cb_full_lists.toggled.connect(_on_full_lists_toggled)
	_hidden_chrome_host.add_child(_cb_full_lists)

	_cb_bind = CheckBox.new()
	_cb_bind.text = "Binding"
	_cb_bind.button_pressed = true
	_cb_bind.tooltip_text = "Toggle binding edges (state → control property)."
	_cb_bind.toggled.connect(func(_on: bool) -> void: _push_visual_filters())
	_hidden_chrome_host.add_child(_cb_bind)

	_cb_computed = CheckBox.new()
	_cb_computed.text = "Computed"
	_cb_computed.button_pressed = true
	_cb_computed.tooltip_text = "Toggle computed-source edges."
	_cb_computed.toggled.connect(func(_on2: bool) -> void: _push_visual_filters())
	_hidden_chrome_host.add_child(_cb_computed)

	_cb_wire = CheckBox.new()
	_cb_wire.text = "Wire"
	_cb_wire.button_pressed = true
	_cb_wire.tooltip_text = "Toggle wire-rule flow edges."
	_cb_wire.toggled.connect(func(_on3: bool) -> void: _push_visual_filters())
	_hidden_chrome_host.add_child(_cb_wire)

	_cb_edge_labels = CheckBox.new()
	_cb_edge_labels.text = "All edge labels"
	_cb_edge_labels.button_pressed = false
	_cb_edge_labels.tooltip_text = "Short labels on every edge; selection still expands below."
	_cb_edge_labels.toggled.connect(func(_on4: bool) -> void: _push_visual_filters())
	_hidden_chrome_host.add_child(_cb_edge_labels)

	_scope_save_name_dialog = AcceptDialog.new()
	_scope_save_name_dialog.title = "Save scope preset"
	_scope_save_name_dialog.ok_button_text = "Save"
	var svb := VBoxContainer.new()
	_scope_save_name_edit = LineEdit.new()
	_scope_save_name_edit.placeholder_text = "Preset name (not “Default”)"
	_scope_save_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	svb.add_child(_scope_save_name_edit)
	_scope_save_name_dialog.add_child(svb)
	_scope_save_name_dialog.confirmed.connect(_on_scope_save_name_confirmed)
	_scope_save_name_dialog.canceled.connect(_on_scope_save_name_canceled)
	add_child(_scope_save_name_dialog)

	_scope_manage_dialog = AcceptDialog.new()
	_scope_manage_dialog.title = "Manage scope presets"
	_scope_manage_dialog.ok_button_text = "Close"
	var mvb := VBoxContainer.new()
	_scope_manage_list = ItemList.new()
	_scope_manage_list.custom_minimum_size = Vector2(0, 120)
	_scope_manage_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mvb.add_child(_scope_manage_list)
	var del_btn := Button.new()
	del_btn.text = "Delete selected"
	del_btn.pressed.connect(_on_scope_manage_delete_pressed)
	mvb.add_child(del_btn)
	_scope_manage_dialog.add_child(mvb)
	add_child(_scope_manage_dialog)

	_visual_host = VBoxContainer.new()
	_visual_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_visual_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_visual_host.custom_minimum_size = Vector2(0, 220)
	v.add_child(_visual_host)

	_legend_host = VBoxContainer.new()
	_legend_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_legend_host.add_theme_constant_override(&"separation", 6)
	_legend_host.visible = true
	_legend_host.resized.connect(_on_legend_host_resized)
	_visual_host.add_child(_legend_host)

	_legend_nodes_row = HBoxContainer.new()
	_legend_nodes_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_legend_nodes_row.add_theme_constant_override(&"separation", 8)
	_legend_group_nodes_label = Label.new()
	_legend_group_nodes_label.text = "Nodes"
	_legend_nodes_row.add_child(_legend_group_nodes_label)

	_add_legend_node_chip(
		_legend_nodes_row,
		_ExplainGraphViewScript.GRAPH_NODE_FILL_FOCUS_HOST,
		_SnapScript.NodeKind.CONTROL,
		"Focus control",
		true,
		"The UiReact host you picked when refreshing; layout is centered on this control."
	)
	_add_legend_node_chip(
		_legend_nodes_row,
		_ExplainGraphViewScript.GRAPH_NODE_FILL_CONTROL,
		_SnapScript.NodeKind.CONTROL,
		"Control",
		false,
		"Other UiReact hosts in this scoped graph."
	)
	_add_legend_node_chip(
		_legend_nodes_row,
		_ExplainGraphViewScript.GRAPH_NODE_FILL_STATE,
		_SnapScript.NodeKind.UI_STATE,
		"State",
		false,
		"UiState resources (bindings, wires, computed inputs)."
	)
	_add_legend_node_chip(
		_legend_nodes_row,
		_ExplainGraphViewScript.GRAPH_NODE_FILL_COMPUTED,
		_SnapScript.NodeKind.UI_COMPUTED,
		"Computed",
		false,
		"UiComputed resources (sources[] aggregation)."
	)

	_legend_mid_spacer = Control.new()
	_legend_mid_spacer.custom_minimum_size = Vector2(24, 0)
	_legend_mid_spacer.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_legend_mid_spacer.visible = false

	_legend_edges_row = HBoxContainer.new()
	_legend_edges_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_legend_edges_row.add_theme_constant_override(&"separation", 8)
	_legend_group_edges_label = Label.new()
	_legend_group_edges_label.text = "Edges"
	_legend_edges_row.add_child(_legend_group_edges_label)
	_add_legend_edge_sample(
		_legend_edges_row,
		_ExplainGraphViewScript.GRAPH_EDGE_COLOR_BINDING,
		3.0,
		"Binding",
		"Inspector binding export: state feeds a control property."
	)
	_add_legend_edge_sample(
		_legend_edges_row,
		_ExplainGraphViewScript.GRAPH_EDGE_COLOR_COMPUTED,
		3.0,
		"Computed src",
		"sources[] entry: upstream state feeds a computed resource."
	)
	_add_legend_edge_sample(
		_legend_edges_row,
		_ExplainGraphViewScript.GRAPH_EDGE_COLOR_WIRE,
		4.0,
		"Wire",
		"wire_rules row: input state(s) drive output state(s)."
	)

	_legend_host.add_child(_legend_nodes_row)
	_legend_host.add_child(_legend_edges_row)
	call_deferred(&"_on_legend_host_resized")

	_graph_view = _ExplainGraphViewScript.new()
	_graph_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_graph_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_graph_view.custom_minimum_size = Vector2(280, 200)
	_graph_view.node_selected.connect(_on_graph_node)
	_graph_view.edge_selected.connect(_on_graph_edge)
	_graph_view.inspector_focus_selection_requested.connect(_on_graph_inspector_focus_selection_requested)
	_graph_view.selection_cleared.connect(_on_graph_cleared)
	_graph_view.reconnect_drag_ended.connect(_on_graph_reconnect_drag_ended)
	_graph_view.newlink_drag_ended.connect(_on_graph_newlink_drag_ended)
	_graph_view.edge_disconnect_requested.connect(_on_graph_edge_disconnect_requested)
	_graph_view.context_menu_requested.connect(_on_graph_context_menu_requested)
	_graph_view.canvas_view_menu_requested.connect(_on_canvas_view_menu_requested)
	_graph_view.set_reconnect_handlers(
		Callable(self, &"_reconnect_can_start_cb"),
		Callable(self, &"_reconnect_is_valid_target_cb")
	)
	_graph_view.set_newlink_handlers(
		Callable(self, &"_newlink_can_start_cb"),
		Callable(self, &"_newlink_is_valid_drop_cb")
	)
	_graph_view.tooltip_text = ""

	_graph_body_split = VSplitContainer.new()
	_graph_body_split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_graph_body_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_graph_body_split.custom_minimum_size = Vector2(0, 220)
	_graph_body_split.tooltip_text = "Drag to resize the graph and the details column."
	_visual_host.add_child(_graph_body_split)
	_graph_body_split.add_child(_graph_view)

	_below_graph_column = VBoxContainer.new()
	_below_graph_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_below_graph_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_graph_body_split.add_child(_below_graph_column)

	_details_scroll = ScrollContainer.new()
	_details_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_details_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_details_scroll.custom_minimum_size = Vector2(0, 120)
	_details_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_details_scroll.tooltip_text = "Details for the selected graph item."
	_below_graph_column.add_child(_details_scroll)

	_details = RichTextLabel.new()
	_details.bbcode_enabled = true
	_details.scroll_active = false
	_details.fit_content = true
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_details.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_details_scroll.add_child(_details)
	_set_details_placeholder()

	_wire_rules_section = _WireRulesSectionScript.new()
	_wire_rules_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_wire_rules_section.setup(
		_plugin,
		_actions,
		Callable(self, &"_after_wire_rules_section_commit"),
	)
	_below_graph_column.add_child(_wire_rules_section)

	_wire_payload_box = VBoxContainer.new()
	_wire_payload_box.visible = false
	_wire_payload_box.add_theme_constant_override(&"separation", 4)
	_wire_payload_box.tooltip_text = "Edit the selected wire row (mirrors Inspector)."
	_below_graph_column.add_child(_wire_payload_box)

	_wire_rule_id_row = HBoxContainer.new()
	_wire_rule_id_row.add_theme_constant_override(&"separation", 6)
	_wire_payload_box.add_child(_wire_rule_id_row)
	var rl := Label.new()
	rl.text = "rule_id:"
	_wire_rule_id_row.add_child(rl)
	_wire_rule_id_edit = LineEdit.new()
	_wire_rule_id_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_wire_rule_id_edit.placeholder_text = "Wire rule id"
	_wire_rule_id_edit.text_submitted.connect(func(_t: String) -> void: _on_wire_rule_id_apply_pressed())
	_wire_rule_id_row.add_child(_wire_rule_id_edit)
	_btn_wire_rule_id_apply = Button.new()
	_btn_wire_rule_id_apply.text = "Apply"
	_btn_wire_rule_id_apply.tooltip_text = "Save rule_id on this wire_rules row (undoable)."
	_btn_wire_rule_id_apply.pressed.connect(_on_wire_rule_id_apply_pressed)
	_wire_rule_id_row.add_child(_btn_wire_rule_id_apply)

	_wire_enabled_row = HBoxContainer.new()
	_wire_enabled_row.add_theme_constant_override(&"separation", 6)
	_wire_payload_box.add_child(_wire_enabled_row)
	var el := Label.new()
	el.text = "enabled:"
	_wire_enabled_row.add_child(el)
	_wire_enabled_cb = CheckBox.new()
	_wire_enabled_cb.text = "Rule runs when enabled"
	_wire_enabled_cb.tooltip_text = "Enable or pause this rule (undoable)."
	_wire_enabled_cb.toggled.connect(_on_wire_enabled_toggled)
	_wire_enabled_row.add_child(_wire_enabled_cb)

	_wire_trigger_row = HBoxContainer.new()
	_wire_trigger_row.add_theme_constant_override(&"separation", 6)
	_wire_payload_box.add_child(_wire_trigger_row)
	var tl := Label.new()
	tl.text = "trigger:"
	_wire_trigger_row.add_child(tl)
	_wire_trigger_option = OptionButton.new()
	_wire_trigger_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_wire_trigger_option.tooltip_text = "When the rule's source fires (see WIRING_LAYER.md)."
	var tords: PackedInt32Array = _WireGraphEditScript.wire_trigger_kind_ordinals_in_ui_order()
	for j in range(tords.size()):
		var oid: int = int(tords[j])
		_wire_trigger_option.add_item(_WireGraphEditScript.wire_trigger_kind_label(oid), oid)
	_wire_trigger_option.item_selected.connect(_on_wire_trigger_selected)
	_wire_trigger_row.add_child(_wire_trigger_option)

	var base_ctl := _plugin.get_editor_interface().get_base_control()
	_selection_actions_context_popup = PopupMenu.new()
	base_ctl.add_child(_selection_actions_context_popup)
	_selection_actions_context_popup.id_pressed.connect(_on_selection_action_id)
	_canvas_view_context_popup = PopupMenu.new()
	base_ctl.add_child(_canvas_view_context_popup)
	_canvas_view_context_popup.id_pressed.connect(_on_canvas_view_menu_id)


func _set_hint_visible(on: bool) -> void:
	if _hint:
		_hint.visible = on
		var h := 36 if on else 0
		_hint.custom_minimum_size = Vector2(0, h)


func _clear_stale_snapshot() -> void:
	_last_snap = null
	_last_layout.clear()
	_last_focus_id = ""
	_narrative_cache.clear()
	_graph_selected_node_id = ""
	_graph_selected_edge_index = -1
	_last_edge_from_id = ""
	_last_edge_to_id = ""
	_last_edge_kind = -1
	_last_edge_label = ""
	_last_focus_host_path = ""
	_selection_kind = _SEL_NONE
	_update_focus_button_state()
	_sync_wire_rules_section()
	if _graph_view:
		_graph_view.clear_graph()
	_set_details_placeholder()


func _set_hint(t: String) -> void:
	if _hint:
		_hint.text = t


func _set_idle() -> void:
	pass

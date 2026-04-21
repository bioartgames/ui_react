## ProjectSettings keys, defaults, and load/save for [UiReactDock] UI preferences.
class_name UiReactDockConfig
extends RefCounted

const SCAN_MODE_SELECTION := 0
const SCAN_MODE_SCENE := 1

const GROUP_FLAT := 0
const GROUP_BY_NODE := 1
const GROUP_BY_SEVERITY := 2

const KEY_SCAN_MODE := "ui_react/plugin_scan_mode"
const KEY_SHOW_ERRORS := "ui_react/plugin_show_errors"
const KEY_SHOW_WARNINGS := "ui_react/plugin_show_warnings"
const KEY_SHOW_INFO := "ui_react/plugin_show_info"
const KEY_AUTO_REFRESH := "ui_react/plugin_auto_refresh"
const KEY_STATE_OUTPUT_PATH := "ui_react/plugin_state_output_path"
const KEY_GROUP_MODE := "ui_react/plugin_group_mode"
const KEY_IGNORED_UNUSED_STATE_PATHS := "ui_react/plugin_ignored_unused_state_paths"
const KEY_GRAPH_SCOPE_PRESETS := "ui_react/plugin_graph_scope_presets_json"
const KEY_GRAPH_ACTIVE_SCOPE_PRESET := "ui_react/plugin_graph_active_scope_preset_name"
## Vertical split offset (px) between Dependency Graph canvas and details column; [code]-1[/code] = use engine default.
const KEY_GRAPH_BODY_VSPLIT_OFFSET := "ui_react/plugin_graph_body_vsplit_offset"
## Whether the graph color key row is visible by default (toggle persists).
const KEY_GRAPH_LEGEND_VISIBLE := "ui_react/plugin_graph_legend_visible"
## Last dock tab: [code]0[/code] Diagnostics, [code]1[/code] Wiring.
const KEY_DOCK_LAST_TAB := "ui_react/plugin_dock_last_tab"
## Last edited scene [code]scene_file_path[/code] when Wiring session was captured.
const KEY_WIRING_LAST_SCENE_PATH := "ui_react/plugin_wiring_last_scene_path"
## Scene-root-relative [code]NodePath[/code] string for Wiring scope [code]Control[/code].
const KEY_WIRING_LAST_SCOPE_NODE_PATH := "ui_react/plugin_wiring_last_scope_node_path"
## Last graph node id ([code]ctrl:[/code]… / [code]state:[/code]…) when selection was a node; empty otherwise.
const KEY_WIRING_LAST_GRAPH_NODE_ID := "ui_react/plugin_wiring_last_graph_node_id"

const DEF_DOCK_LAST_TAB := 0

const DEF_SHOW_ERRORS := true
const DEF_SHOW_WARNINGS := true
const DEF_SHOW_INFO := true
const DEF_AUTO_REFRESH := true


static func save_ui_preference(key: String, value: Variant) -> void:
	ProjectSettings.set_setting(key, value)
	var err := ProjectSettings.save()
	if err != OK:
		push_warning(
			"Ui React: could not save project settings for %s. Use Project → Project Settings… → Save, then retry the dock action."
			% key
		)


static func save_wiring_restore_state(scene_path: String, scope_node_path: String, graph_node_id: String) -> void:
	ProjectSettings.set_setting(KEY_WIRING_LAST_SCENE_PATH, scene_path)
	ProjectSettings.set_setting(KEY_WIRING_LAST_SCOPE_NODE_PATH, scope_node_path)
	ProjectSettings.set_setting(KEY_WIRING_LAST_GRAPH_NODE_ID, graph_node_id)
	var err := ProjectSettings.save()
	if err != OK:
		push_warning(
			"Ui React: could not save wiring session restore data. Save Project Settings from the Project menu, then reopen the Wiring tab."
		)


static func register_default_project_settings() -> void:
	var added_defaults := false
	if not ProjectSettings.has_setting(KEY_STATE_OUTPUT_PATH):
		ProjectSettings.set_setting(KEY_STATE_OUTPUT_PATH, UiReactStateFactoryService.DEFAULT_OUTPUT_DIR)
		added_defaults = true
	if not ProjectSettings.has_setting(KEY_SCAN_MODE):
		ProjectSettings.set_setting(KEY_SCAN_MODE, SCAN_MODE_SELECTION)
		added_defaults = true
	if not ProjectSettings.has_setting(KEY_SHOW_ERRORS):
		ProjectSettings.set_setting(KEY_SHOW_ERRORS, DEF_SHOW_ERRORS)
		added_defaults = true
	if not ProjectSettings.has_setting(KEY_SHOW_WARNINGS):
		ProjectSettings.set_setting(KEY_SHOW_WARNINGS, DEF_SHOW_WARNINGS)
		added_defaults = true
	if not ProjectSettings.has_setting(KEY_SHOW_INFO):
		ProjectSettings.set_setting(KEY_SHOW_INFO, DEF_SHOW_INFO)
		added_defaults = true
	if not ProjectSettings.has_setting(KEY_AUTO_REFRESH):
		ProjectSettings.set_setting(KEY_AUTO_REFRESH, DEF_AUTO_REFRESH)
		added_defaults = true
	if not ProjectSettings.has_setting(KEY_GROUP_MODE):
		ProjectSettings.set_setting(KEY_GROUP_MODE, GROUP_FLAT)
		added_defaults = true
	if not ProjectSettings.has_setting(KEY_IGNORED_UNUSED_STATE_PATHS):
		ProjectSettings.set_setting(KEY_IGNORED_UNUSED_STATE_PATHS, PackedStringArray())
		added_defaults = true
	if not ProjectSettings.has_setting(KEY_GRAPH_SCOPE_PRESETS):
		ProjectSettings.set_setting(KEY_GRAPH_SCOPE_PRESETS, "[]")
		added_defaults = true
	if not ProjectSettings.has_setting(KEY_GRAPH_ACTIVE_SCOPE_PRESET):
		ProjectSettings.set_setting(KEY_GRAPH_ACTIVE_SCOPE_PRESET, "")
		added_defaults = true
	if not ProjectSettings.has_setting(KEY_GRAPH_BODY_VSPLIT_OFFSET):
		ProjectSettings.set_setting(KEY_GRAPH_BODY_VSPLIT_OFFSET, -1)
		added_defaults = true
	if not ProjectSettings.has_setting(KEY_GRAPH_LEGEND_VISIBLE):
		ProjectSettings.set_setting(KEY_GRAPH_LEGEND_VISIBLE, true)
		added_defaults = true
	if not ProjectSettings.has_setting(KEY_DOCK_LAST_TAB):
		ProjectSettings.set_setting(KEY_DOCK_LAST_TAB, DEF_DOCK_LAST_TAB)
		added_defaults = true
	if not ProjectSettings.has_setting(KEY_WIRING_LAST_SCENE_PATH):
		ProjectSettings.set_setting(KEY_WIRING_LAST_SCENE_PATH, "")
		added_defaults = true
	if not ProjectSettings.has_setting(KEY_WIRING_LAST_SCOPE_NODE_PATH):
		ProjectSettings.set_setting(KEY_WIRING_LAST_SCOPE_NODE_PATH, "")
		added_defaults = true
	if not ProjectSettings.has_setting(KEY_WIRING_LAST_GRAPH_NODE_ID):
		ProjectSettings.set_setting(KEY_WIRING_LAST_GRAPH_NODE_ID, "")
		added_defaults = true
	if added_defaults:
		var err := ProjectSettings.save()
		if err != OK:
			push_warning(
				"Ui React: could not save default Ui React project settings. Save Project Settings manually, then restart the editor if it persists."
			)


static func load_into(dock: UiReactDock) -> void:
	dock._suppress_pref_save = true

	var mode_raw: Variant = ProjectSettings.get_setting(KEY_SCAN_MODE, SCAN_MODE_SELECTION)
	var mode_id: int = int(mode_raw) if typeof(mode_raw) in [TYPE_INT, TYPE_FLOAT] else SCAN_MODE_SELECTION
	if mode_id != SCAN_MODE_SELECTION and mode_id != SCAN_MODE_SCENE:
		mode_id = SCAN_MODE_SELECTION
	if dock._mode_option:
		var idx := dock._mode_option.get_item_index(mode_id)
		if idx >= 0:
			dock._mode_option.select(idx)
		else:
			dock._mode_option.select(dock._mode_option.get_item_index(SCAN_MODE_SELECTION))

	var group_raw: Variant = ProjectSettings.get_setting(KEY_GROUP_MODE, GROUP_FLAT)
	var group_id: int = int(group_raw) if typeof(group_raw) in [TYPE_INT, TYPE_FLOAT] else GROUP_FLAT
	if group_id != GROUP_FLAT and group_id != GROUP_BY_NODE and group_id != GROUP_BY_SEVERITY:
		group_id = GROUP_FLAT
	if dock._group_option:
		var gidx := dock._group_option.get_item_index(group_id)
		if gidx >= 0:
			dock._group_option.select(gidx)
		else:
			dock._group_option.select(dock._group_option.get_item_index(GROUP_FLAT))

	if dock._filter_err:
		dock._filter_err.button_pressed = bool(ProjectSettings.get_setting(KEY_SHOW_ERRORS, DEF_SHOW_ERRORS))
	if dock._filter_warn:
		dock._filter_warn.button_pressed = bool(ProjectSettings.get_setting(KEY_SHOW_WARNINGS, DEF_SHOW_WARNINGS))
	if dock._filter_info:
		dock._filter_info.button_pressed = bool(ProjectSettings.get_setting(KEY_SHOW_INFO, DEF_SHOW_INFO))
	if dock._auto_refresh:
		dock._auto_refresh.button_pressed = bool(ProjectSettings.get_setting(KEY_AUTO_REFRESH, DEF_AUTO_REFRESH))
	if dock._path_edit:
		dock._path_edit.text = UiReactStateFactoryService.default_output_dir()

	var tab_raw: Variant = ProjectSettings.get_setting(KEY_DOCK_LAST_TAB, DEF_DOCK_LAST_TAB)
	var tab_id: int = int(tab_raw) if typeof(tab_raw) in [TYPE_INT, TYPE_FLOAT] else DEF_DOCK_LAST_TAB
	if tab_id != 0 and tab_id != 1:
		tab_id = DEF_DOCK_LAST_TAB
	if dock._tabs:
		dock._tabs.current_tab = tab_id
		dock._last_tab_for_persist = tab_id

	dock._suppress_pref_save = false


static func load_ignored_unused_state_paths_dict() -> Dictionary:
	var raw: Variant = ProjectSettings.get_setting(KEY_IGNORED_UNUSED_STATE_PATHS, PackedStringArray())
	if raw is PackedStringArray:
		var out: Dictionary = {}
		for p in raw as PackedStringArray:
			var s := String(p).strip_edges()
			if not s.is_empty():
				out[s] = true
		return out
	return {}


static func load_graph_scope_presets_raw() -> Array:
	var raw := String(ProjectSettings.get_setting(KEY_GRAPH_SCOPE_PRESETS, "[]"))
	var j := JSON.new()
	var err := j.parse(raw)
	if err != OK:
		return []
	var root: Variant = j.data
	if root is Array:
		return root as Array
	return []


static func save_graph_scope_presets_raw(arr: Array) -> void:
	var serial: Array = []
	for it: Variant in arr:
		if it is not Dictionary:
			continue
		var d: Dictionary = it as Dictionary
		var nm := String(d.get("name", d.get(&"name", ""))).strip_edges()
		if nm.is_empty() or nm.to_lower() == "default":
			continue
		var pin_arr: Array = []
		var pins: Variant = d.get("pinned", d.get(&"pinned", []))
		if pins is PackedStringArray:
			for p in pins as PackedStringArray:
				pin_arr.append(String(p))
		elif pins is Array:
			for p in pins as Array:
				var ps := String(p).strip_edges()
				if ps.is_empty():
					continue
				if not pin_arr.has(ps):
					pin_arr.append(ps)
		var pin_dedup: Array = []
		var pin_seen: Dictionary = {}
		for p2 in pin_arr:
			var pk := String(p2).strip_edges()
			if pk.is_empty() or pin_seen.has(pk):
				continue
			pin_seen[pk] = true
			pin_dedup.append(pk)
		var about_s := String(d.get("about", d.get(&"about", ""))).strip_edges()
		serial.append(
			{
				"name": nm,
				"max_nodes": int(d.get("max_nodes", d.get(&"max_nodes", 200))),
				"max_edges": int(d.get("max_edges", d.get(&"max_edges", 400))),
				"show_binding": bool(d.get("show_binding", d.get(&"show_binding", true))),
				"show_computed": bool(d.get("show_computed", d.get(&"show_computed", true))),
				"show_wire": bool(d.get("show_wire", d.get(&"show_wire", true))),
				"show_all_edge_labels": bool(
					d.get("show_all_edge_labels", d.get(&"show_all_edge_labels", false))
				),
				"full_lists": bool(d.get("full_lists", d.get(&"full_lists", false))),
				"pinned": pin_dedup,
				"about": about_s,
			}
		)
	serial.sort_custom(
		func(a: Variant, b: Variant) -> bool:
			return String((a as Dictionary).get("name", "")) < String((b as Dictionary).get("name", ""))
	)
	ProjectSettings.set_setting(KEY_GRAPH_SCOPE_PRESETS, JSON.stringify(serial))
	var err := ProjectSettings.save()
	if err != OK:
		push_warning(
			"Ui React: could not save graph scope presets. Save Project Settings from the Project menu and try your preset change again."
		)


static func get_active_graph_scope_preset_name() -> String:
	return String(ProjectSettings.get_setting(KEY_GRAPH_ACTIVE_SCOPE_PRESET, ""))


static func set_active_graph_scope_preset_name(preset_name: String) -> void:
	ProjectSettings.set_setting(KEY_GRAPH_ACTIVE_SCOPE_PRESET, preset_name.strip_edges())
	var err := ProjectSettings.save()
	if err != OK:
		push_warning(
			"Ui React: could not save the active graph scope preset name. Save Project Settings from the Project menu and retry."
		)


static func save_ignored_unused_state_paths_dict(paths: Dictionary) -> void:
	var seen: Dictionary = {}
	for k in paths.keys():
		var s := String(k).strip_edges()
		if not s.is_empty():
			seen[s] = true
	var arr := PackedStringArray()
	for k2 in seen.keys():
		arr.append(String(k2))
	arr.sort()
	ProjectSettings.set_setting(KEY_IGNORED_UNUSED_STATE_PATHS, arr)
	var err := ProjectSettings.save()
	if err != OK:
		push_warning(
			"Ui React: could not save ignored unused-state paths. Save Project Settings from the Project menu and retry Ignore."
		)

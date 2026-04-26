## ProjectSettings keys, defaults, migration, and session/layout state for [UiReactDock].
class_name UiReactDockConfig
extends RefCounted

const _EditorBottomPanelShortcut := preload(
	"res://addons/ui_react/editor_plugin/services/ui_react_editor_bottom_panel_shortcut.gd"
)

const SCAN_MODE_SELECTION := 0
const SCAN_MODE_SCENE := 1

const GROUP_FLAT := 0
const GROUP_BY_NODE := 1
const GROUP_BY_SEVERITY := 2

const SETTINGS_SCHEMA_VERSION := 3
const KEY_SETTINGS_SCHEMA_VERSION := "ui_react/settings/schema_version"

# User-facing project settings (v2 namespace).
const KEY_SCAN_MODE := "ui_react/settings/diagnostics/scan_mode"
const KEY_SHOW_ERRORS := "ui_react/settings/diagnostics/show_errors"
const KEY_SHOW_WARNINGS := "ui_react/settings/diagnostics/show_warnings"
const KEY_SHOW_INFO := "ui_react/settings/diagnostics/show_info"
const KEY_AUTO_REFRESH := "ui_react/settings/diagnostics/auto_refresh"
const KEY_GROUP_MODE := "ui_react/settings/diagnostics/group_mode"
const KEY_STATE_OUTPUT_PATH := "ui_react/settings/resources/output_path"
const KEY_IGNORED_UNUSED_STATE_PATHS := "ui_react/settings/diagnostics/ignored_unused_state_paths"
const KEY_GRAPH_LEGEND_VISIBLE := "ui_react/settings/graph/legend_visible"
const KEY_EDITOR_BOTTOM_PANEL_SHORTCUT_JSON := "ui_react/settings/shortcuts/bottom_panel_json"
const KEY_OPEN_DIAGNOSTICS_SHORTCUT_JSON := "ui_react/settings/shortcuts/open_diagnostics_json"
const KEY_OPEN_WIRING_SHORTCUT_JSON := "ui_react/settings/shortcuts/open_wiring_json"

# Internal/session state (stored in editor layout metadata, not ProjectSettings).
const SESSION_LAST_TAB := "last_tab"
const SESSION_WIRING_LAST_SCENE_PATH := "wiring_last_scene_path"
const SESSION_WIRING_LAST_SCOPE_NODE_PATH := "wiring_last_scope_node_path"
const SESSION_WIRING_LAST_GRAPH_NODE_ID := "wiring_last_graph_node_id"
const SESSION_GRAPH_BODY_VSPLIT_OFFSET := "graph_body_vsplit_offset"
const SESSION_GRAPH_SCOPE_PRESETS_JSON := "graph_scope_presets_json"
const SESSION_GRAPH_ACTIVE_SCOPE_PRESET_NAME := "graph_active_scope_preset_name"

# Legacy v1 keys for one-time migration/cleanup.
const OLD_KEY_SCAN_MODE := "ui_react/plugin_scan_mode"
const OLD_KEY_SHOW_ERRORS := "ui_react/plugin_show_errors"
const OLD_KEY_SHOW_WARNINGS := "ui_react/plugin_show_warnings"
const OLD_KEY_SHOW_INFO := "ui_react/plugin_show_info"
const OLD_KEY_AUTO_REFRESH := "ui_react/plugin_auto_refresh"
const OLD_KEY_STATE_OUTPUT_PATH := "ui_react/plugin_state_output_path"
const OLD_KEY_GROUP_MODE := "ui_react/plugin_group_mode"
const OLD_KEY_IGNORED_UNUSED_STATE_PATHS := "ui_react/plugin_ignored_unused_state_paths"
const OLD_KEY_GRAPH_SCOPE_PRESETS := "ui_react/plugin_graph_scope_presets_json"
const OLD_KEY_GRAPH_ACTIVE_SCOPE_PRESET := "ui_react/plugin_graph_active_scope_preset_name"
const OLD_KEY_GRAPH_BODY_VSPLIT_OFFSET := "ui_react/plugin_graph_body_vsplit_offset"
const OLD_KEY_GRAPH_LEGEND_VISIBLE := "ui_react/plugin_graph_legend_visible"
const OLD_KEY_DOCK_LAST_TAB := "ui_react/plugin_dock_last_tab"
const OLD_KEY_WIRING_LAST_SCENE_PATH := "ui_react/plugin_wiring_last_scene_path"
const OLD_KEY_WIRING_LAST_SCOPE_NODE_PATH := "ui_react/plugin_wiring_last_scope_node_path"
const OLD_KEY_WIRING_LAST_GRAPH_NODE_ID := "ui_react/plugin_wiring_last_graph_node_id"
const OLD_KEY_EDITOR_BOTTOM_PANEL_SHORTCUT_JSON := "ui_react/plugin_editor_bottom_panel_shortcut_json"
const OLD_KEY_GRAPH_BODY_HSPLIT_OFFSET := "ui_react/plugin_graph_body_hsplit_offset"

const DEF_DOCK_LAST_TAB := 0
const DEF_SHOW_ERRORS := true
const DEF_SHOW_WARNINGS := true
const DEF_SHOW_INFO := true
const DEF_AUTO_REFRESH := true

static var _session_state: Dictionary = {
	SESSION_LAST_TAB: DEF_DOCK_LAST_TAB,
	SESSION_WIRING_LAST_SCENE_PATH: "",
	SESSION_WIRING_LAST_SCOPE_NODE_PATH: "",
	SESSION_WIRING_LAST_GRAPH_NODE_ID: "",
	SESSION_GRAPH_BODY_VSPLIT_OFFSET: -1,
	SESSION_GRAPH_SCOPE_PRESETS_JSON: "[]",
	SESSION_GRAPH_ACTIVE_SCOPE_PRESET_NAME: "",
}


static func migrate_project_settings_to_v2_clean_break() -> void:
	var from_schema := int(ProjectSettings.get_setting(KEY_SETTINGS_SCHEMA_VERSION, 0))
	if from_schema >= SETTINGS_SCHEMA_VERSION:
		return

	var changed := false
	changed = _migrate_key_if_needed(OLD_KEY_STATE_OUTPUT_PATH, KEY_STATE_OUTPUT_PATH) or changed
	changed = _migrate_key_if_needed(OLD_KEY_SCAN_MODE, KEY_SCAN_MODE) or changed
	changed = _migrate_key_if_needed(OLD_KEY_SHOW_ERRORS, KEY_SHOW_ERRORS) or changed
	changed = _migrate_key_if_needed(OLD_KEY_SHOW_WARNINGS, KEY_SHOW_WARNINGS) or changed
	changed = _migrate_key_if_needed(OLD_KEY_SHOW_INFO, KEY_SHOW_INFO) or changed
	changed = _migrate_key_if_needed(OLD_KEY_AUTO_REFRESH, KEY_AUTO_REFRESH) or changed
	changed = _migrate_key_if_needed(OLD_KEY_GROUP_MODE, KEY_GROUP_MODE) or changed
	changed = _migrate_key_if_needed(OLD_KEY_IGNORED_UNUSED_STATE_PATHS, KEY_IGNORED_UNUSED_STATE_PATHS) or changed
	changed = _migrate_key_if_needed(OLD_KEY_GRAPH_LEGEND_VISIBLE, KEY_GRAPH_LEGEND_VISIBLE) or changed
	changed = _migrate_key_if_needed(OLD_KEY_EDITOR_BOTTOM_PANEL_SHORTCUT_JSON, KEY_EDITOR_BOTTOM_PANEL_SHORTCUT_JSON) or changed
	if (
		not ProjectSettings.has_setting(KEY_OPEN_DIAGNOSTICS_SHORTCUT_JSON)
		and not ProjectSettings.has_setting(KEY_OPEN_WIRING_SHORTCUT_JSON)
		and ProjectSettings.has_setting(KEY_EDITOR_BOTTOM_PANEL_SHORTCUT_JSON)
	):
		var legacy_raw := String(ProjectSettings.get_setting(KEY_EDITOR_BOTTOM_PANEL_SHORTCUT_JSON, ""))
		ProjectSettings.set_setting(KEY_OPEN_DIAGNOSTICS_SHORTCUT_JSON, legacy_raw)
		ProjectSettings.set_setting(KEY_OPEN_WIRING_SHORTCUT_JSON, legacy_raw)
		changed = true

	if ProjectSettings.has_setting(OLD_KEY_DOCK_LAST_TAB):
		_session_state[SESSION_LAST_TAB] = int(ProjectSettings.get_setting(OLD_KEY_DOCK_LAST_TAB, DEF_DOCK_LAST_TAB))
	if ProjectSettings.has_setting(OLD_KEY_WIRING_LAST_SCENE_PATH):
		_session_state[SESSION_WIRING_LAST_SCENE_PATH] = String(ProjectSettings.get_setting(OLD_KEY_WIRING_LAST_SCENE_PATH, ""))
	if ProjectSettings.has_setting(OLD_KEY_WIRING_LAST_SCOPE_NODE_PATH):
		_session_state[SESSION_WIRING_LAST_SCOPE_NODE_PATH] = String(ProjectSettings.get_setting(OLD_KEY_WIRING_LAST_SCOPE_NODE_PATH, ""))
	if ProjectSettings.has_setting(OLD_KEY_WIRING_LAST_GRAPH_NODE_ID):
		_session_state[SESSION_WIRING_LAST_GRAPH_NODE_ID] = String(ProjectSettings.get_setting(OLD_KEY_WIRING_LAST_GRAPH_NODE_ID, ""))
	if ProjectSettings.has_setting(OLD_KEY_GRAPH_BODY_VSPLIT_OFFSET):
		_session_state[SESSION_GRAPH_BODY_VSPLIT_OFFSET] = int(ProjectSettings.get_setting(OLD_KEY_GRAPH_BODY_VSPLIT_OFFSET, -1))
	if ProjectSettings.has_setting(OLD_KEY_GRAPH_SCOPE_PRESETS):
		_session_state[SESSION_GRAPH_SCOPE_PRESETS_JSON] = String(ProjectSettings.get_setting(OLD_KEY_GRAPH_SCOPE_PRESETS, "[]"))
	if ProjectSettings.has_setting(OLD_KEY_GRAPH_ACTIVE_SCOPE_PRESET):
		_session_state[SESSION_GRAPH_ACTIVE_SCOPE_PRESET_NAME] = String(ProjectSettings.get_setting(OLD_KEY_GRAPH_ACTIVE_SCOPE_PRESET, ""))

	for old_key in [
		OLD_KEY_STATE_OUTPUT_PATH,
		OLD_KEY_SCAN_MODE,
		OLD_KEY_SHOW_ERRORS,
		OLD_KEY_SHOW_WARNINGS,
		OLD_KEY_SHOW_INFO,
		OLD_KEY_AUTO_REFRESH,
		OLD_KEY_GROUP_MODE,
		OLD_KEY_IGNORED_UNUSED_STATE_PATHS,
		OLD_KEY_GRAPH_SCOPE_PRESETS,
		OLD_KEY_GRAPH_ACTIVE_SCOPE_PRESET,
		OLD_KEY_GRAPH_BODY_VSPLIT_OFFSET,
		OLD_KEY_GRAPH_BODY_HSPLIT_OFFSET,
		OLD_KEY_GRAPH_LEGEND_VISIBLE,
		OLD_KEY_DOCK_LAST_TAB,
		OLD_KEY_WIRING_LAST_SCENE_PATH,
		OLD_KEY_WIRING_LAST_SCOPE_NODE_PATH,
		OLD_KEY_WIRING_LAST_GRAPH_NODE_ID,
		OLD_KEY_EDITOR_BOTTOM_PANEL_SHORTCUT_JSON,
	]:
		if ProjectSettings.has_setting(old_key):
			ProjectSettings.set_setting(old_key, null)
			changed = true

	if from_schema < 3:
		ProjectSettings.set_setting(KEY_EDITOR_BOTTOM_PANEL_SHORTCUT_JSON, null)
		ProjectSettings.set_setting(
			KEY_OPEN_DIAGNOSTICS_SHORTCUT_JSON,
			_EditorBottomPanelShortcut.spec_to_json(_EditorBottomPanelShortcut.default_open_diagnostics_spec())
		)
		ProjectSettings.set_setting(
			KEY_OPEN_WIRING_SHORTCUT_JSON,
			_EditorBottomPanelShortcut.spec_to_json(_EditorBottomPanelShortcut.default_open_wiring_spec())
		)
		changed = true

	ProjectSettings.set_setting(KEY_SETTINGS_SCHEMA_VERSION, SETTINGS_SCHEMA_VERSION)
	changed = true
	if changed:
		var err := ProjectSettings.save()
		if err != OK:
			push_warning("Ui React: could not save settings migration. Save Project Settings manually.")


static func _migrate_key_if_needed(old_key: String, new_key: String) -> bool:
	if not ProjectSettings.has_setting(old_key):
		return false
	if ProjectSettings.has_setting(new_key):
		return false
	ProjectSettings.set_setting(new_key, ProjectSettings.get_setting(old_key, null))
	return true


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
	if not ProjectSettings.has_setting(KEY_GRAPH_LEGEND_VISIBLE):
		ProjectSettings.set_setting(KEY_GRAPH_LEGEND_VISIBLE, true)
		added_defaults = true
	if not ProjectSettings.has_setting(KEY_OPEN_DIAGNOSTICS_SHORTCUT_JSON):
		ProjectSettings.set_setting(
			KEY_OPEN_DIAGNOSTICS_SHORTCUT_JSON,
			_EditorBottomPanelShortcut.spec_to_json(_EditorBottomPanelShortcut.default_open_diagnostics_spec())
		)
		added_defaults = true
	if not ProjectSettings.has_setting(KEY_OPEN_WIRING_SHORTCUT_JSON):
		ProjectSettings.set_setting(
			KEY_OPEN_WIRING_SHORTCUT_JSON,
			_EditorBottomPanelShortcut.spec_to_json(_EditorBottomPanelShortcut.default_open_wiring_spec())
		)
		added_defaults = true
	if not ProjectSettings.has_setting(KEY_SETTINGS_SCHEMA_VERSION):
		ProjectSettings.set_setting(KEY_SETTINGS_SCHEMA_VERSION, SETTINGS_SCHEMA_VERSION)
		added_defaults = true
	if added_defaults:
		var err := ProjectSettings.save()
		if err != OK:
			push_warning("Ui React: could not save default project settings.")


static func save_ui_preference(key: String, value: Variant) -> void:
	ProjectSettings.set_setting(key, value)
	var err := ProjectSettings.save()
	if err != OK:
		push_warning("Ui React: could not save project setting %s." % key)


static func get_open_diagnostics_shortcut_json() -> String:
	return String(ProjectSettings.get_setting(KEY_OPEN_DIAGNOSTICS_SHORTCUT_JSON, ""))


static func get_open_wiring_shortcut_json() -> String:
	return String(ProjectSettings.get_setting(KEY_OPEN_WIRING_SHORTCUT_JSON, ""))


static func load_into(dock: UiReactDock) -> void:
	dock._suppress_pref_save = true

	var mode_id := int(ProjectSettings.get_setting(KEY_SCAN_MODE, SCAN_MODE_SELECTION))
	if mode_id != SCAN_MODE_SELECTION and mode_id != SCAN_MODE_SCENE:
		mode_id = SCAN_MODE_SELECTION
	if dock._mode_option:
		var idx := dock._mode_option.get_item_index(mode_id)
		dock._mode_option.select(idx if idx >= 0 else dock._mode_option.get_item_index(SCAN_MODE_SELECTION))

	var group_id := int(ProjectSettings.get_setting(KEY_GROUP_MODE, GROUP_FLAT))
	if group_id != GROUP_FLAT and group_id != GROUP_BY_NODE and group_id != GROUP_BY_SEVERITY:
		group_id = GROUP_FLAT
	if dock._group_option:
		var gidx := dock._group_option.get_item_index(group_id)
		dock._group_option.select(gidx if gidx >= 0 else dock._group_option.get_item_index(GROUP_FLAT))

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

	var tab_id := int(_session_state.get(SESSION_LAST_TAB, DEF_DOCK_LAST_TAB))
	if tab_id != 0 and tab_id != 1:
		tab_id = DEF_DOCK_LAST_TAB
	if dock._tabs:
		dock._tabs.current_tab = tab_id
		dock._last_tab_for_persist = tab_id

	dock._suppress_pref_save = false


static func save_last_tab_session(tab_idx: int) -> void:
	_session_state[SESSION_LAST_TAB] = tab_idx


static func save_wiring_restore_state(scene_path: String, scope_node_path: String, graph_node_id: String) -> void:
	_session_state[SESSION_WIRING_LAST_SCENE_PATH] = scene_path
	_session_state[SESSION_WIRING_LAST_SCOPE_NODE_PATH] = scope_node_path
	_session_state[SESSION_WIRING_LAST_GRAPH_NODE_ID] = graph_node_id


static func get_wiring_restore_state() -> Dictionary:
	return {
		"scene_path": String(_session_state.get(SESSION_WIRING_LAST_SCENE_PATH, "")),
		"scope_node_path": String(_session_state.get(SESSION_WIRING_LAST_SCOPE_NODE_PATH, "")),
		"graph_node_id": String(_session_state.get(SESSION_WIRING_LAST_GRAPH_NODE_ID, "")),
	}


static func get_graph_body_vsplit_offset() -> int:
	return int(_session_state.get(SESSION_GRAPH_BODY_VSPLIT_OFFSET, -1))


static func save_graph_body_vsplit_offset(split_offset: int) -> void:
	_session_state[SESSION_GRAPH_BODY_VSPLIT_OFFSET] = split_offset


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
	var raw := String(_session_state.get(SESSION_GRAPH_SCOPE_PRESETS_JSON, "[]"))
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
				"show_all_edge_labels": bool(d.get("show_all_edge_labels", d.get(&"show_all_edge_labels", false))),
				"full_lists": bool(d.get("full_lists", d.get(&"full_lists", false))),
				"pinned": pin_dedup,
				"about": about_s,
			}
		)
	serial.sort_custom(func(a: Variant, b: Variant) -> bool: return String((a as Dictionary).get("name", "")) < String((b as Dictionary).get("name", "")))
	_session_state[SESSION_GRAPH_SCOPE_PRESETS_JSON] = JSON.stringify(serial)


static func get_active_graph_scope_preset_name() -> String:
	return String(_session_state.get(SESSION_GRAPH_ACTIVE_SCOPE_PRESET_NAME, ""))


static func set_active_graph_scope_preset_name(preset_name: String) -> void:
	_session_state[SESSION_GRAPH_ACTIVE_SCOPE_PRESET_NAME] = preset_name.strip_edges()


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
		push_warning("Ui React: could not save ignored unused-state paths.")


static func export_session_state() -> Dictionary:
	return _session_state.duplicate(true)


static func import_session_state(state: Dictionary) -> void:
	for k in state.keys():
		if state[k] != null:
			_session_state[k] = state[k]

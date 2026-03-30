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

const DEF_SHOW_ERRORS := true
const DEF_SHOW_WARNINGS := true
const DEF_SHOW_INFO := true
const DEF_AUTO_REFRESH := true


static func save_ui_preference(key: String, value: Variant) -> void:
	ProjectSettings.set_setting(key, value)
	var err := ProjectSettings.save()
	if err != OK:
		push_warning("UiReactDockConfig: could not save project settings (%s)" % key)


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
	if added_defaults:
		var err := ProjectSettings.save()
		if err != OK:
			push_warning("UiReactDockConfig: could not save default project settings")


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

	dock._suppress_pref_save = false

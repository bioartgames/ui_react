extends GutTest

const _SCHEMA_KEY := "ui_react/settings/schema_version"
const _EXPECTED_SCHEMA_VERSION := 3

var _backup: Dictionary = {}


func before_each() -> void:
	for k in [
		_SCHEMA_KEY,
		UiReactDockConfig.OLD_KEY_SCAN_MODE,
		UiReactDockConfig.KEY_SCAN_MODE,
		UiReactDockConfig.OLD_KEY_STATE_OUTPUT_PATH,
		UiReactDockConfig.KEY_STATE_OUTPUT_PATH,
		UiReactDockConfig.KEY_EDITOR_BOTTOM_PANEL_SHORTCUT_JSON,
		UiReactDockConfig.KEY_OPEN_DIAGNOSTICS_SHORTCUT_JSON,
		UiReactDockConfig.KEY_OPEN_WIRING_SHORTCUT_JSON,
		UiReactDockConfig.KEY_IGNORED_UNUSED_STATE_PATHS,
	]:
		_backup[k] = ProjectSettings.get_setting(k, null)


func after_each() -> void:
	for k in _backup.keys():
		ProjectSettings.set_setting(String(k), _backup[k])
	ProjectSettings.save()


func test_migrate_project_settings_to_v2_clean_break_moves_values() -> void:
	ProjectSettings.set_setting(_SCHEMA_KEY, 0)
	ProjectSettings.set_setting(UiReactDockConfig.OLD_KEY_SCAN_MODE, UiReactDockConfig.SCAN_MODE_SCENE)
	ProjectSettings.set_setting(UiReactDockConfig.OLD_KEY_STATE_OUTPUT_PATH, "res://tmp/out/")
	ProjectSettings.set_setting(UiReactDockConfig.KEY_SCAN_MODE, null)
	ProjectSettings.set_setting(UiReactDockConfig.KEY_STATE_OUTPUT_PATH, null)

	UiReactDockConfig.migrate_project_settings_to_v2_clean_break()

	assert_eq(int(ProjectSettings.get_setting(_SCHEMA_KEY, 0)), _EXPECTED_SCHEMA_VERSION)
	assert_eq(int(ProjectSettings.get_setting(UiReactDockConfig.KEY_SCAN_MODE, -1)), UiReactDockConfig.SCAN_MODE_SCENE)
	assert_eq(String(ProjectSettings.get_setting(UiReactDockConfig.KEY_STATE_OUTPUT_PATH, "")), "res://tmp/out/")
	assert_true(ProjectSettings.get_setting(UiReactDockConfig.OLD_KEY_SCAN_MODE, null) == null)
	assert_true(ProjectSettings.get_setting(UiReactDockConfig.OLD_KEY_STATE_OUTPUT_PATH, null) == null)


func test_dual_shortcut_keys_seed_from_legacy_bottom_panel_then_v3_alt12() -> void:
	ProjectSettings.set_setting(_SCHEMA_KEY, 0)
	ProjectSettings.set_setting(UiReactDockConfig.KEY_OPEN_DIAGNOSTICS_SHORTCUT_JSON, null)
	ProjectSettings.set_setting(UiReactDockConfig.KEY_OPEN_WIRING_SHORTCUT_JSON, null)
	ProjectSettings.set_setting(
		UiReactDockConfig.KEY_EDITOR_BOTTOM_PANEL_SHORTCUT_JSON,
		"{\"v\":1,\"enabled\":true,\"keycode\":85,\"alt\":true,\"shift\":false,\"ctrl\":false,\"meta\":false}"
	)

	UiReactDockConfig.migrate_project_settings_to_v2_clean_break()

	var d := String(ProjectSettings.get_setting(UiReactDockConfig.KEY_OPEN_DIAGNOSTICS_SHORTCUT_JSON, ""))
	var w := String(ProjectSettings.get_setting(UiReactDockConfig.KEY_OPEN_WIRING_SHORTCUT_JSON, ""))
	assert_true(d.contains("\"keycode\":" + str(KEY_1)))
	assert_true(w.contains("\"keycode\":" + str(KEY_2)))


func test_v3_migration_clears_bottom_panel_key_and_resets_open_shortcuts() -> void:
	ProjectSettings.set_setting(_SCHEMA_KEY, 2)
	ProjectSettings.set_setting(
		UiReactDockConfig.KEY_EDITOR_BOTTOM_PANEL_SHORTCUT_JSON,
		"{\"v\":1,\"enabled\":true,\"keycode\":85,\"alt\":true,\"shift\":false,\"ctrl\":false,\"meta\":false}"
	)
	ProjectSettings.set_setting(
		UiReactDockConfig.KEY_OPEN_DIAGNOSTICS_SHORTCUT_JSON,
		"{\"v\":1,\"enabled\":true,\"keycode\":68,\"alt\":true,\"shift\":false,\"ctrl\":false,\"meta\":false}"
	)
	ProjectSettings.set_setting(
		UiReactDockConfig.KEY_OPEN_WIRING_SHORTCUT_JSON,
		"{\"v\":1,\"enabled\":true,\"keycode\":71,\"alt\":true,\"shift\":false,\"ctrl\":false,\"meta\":false}"
	)

	UiReactDockConfig.migrate_project_settings_to_v2_clean_break()

	assert_eq(int(ProjectSettings.get_setting(_SCHEMA_KEY, 0)), _EXPECTED_SCHEMA_VERSION)
	assert_true(
		not ProjectSettings.has_setting(UiReactDockConfig.KEY_EDITOR_BOTTOM_PANEL_SHORTCUT_JSON)
		or ProjectSettings.get_setting(UiReactDockConfig.KEY_EDITOR_BOTTOM_PANEL_SHORTCUT_JSON, "__x__") == null
	)
	var d := String(ProjectSettings.get_setting(UiReactDockConfig.KEY_OPEN_DIAGNOSTICS_SHORTCUT_JSON, ""))
	var w := String(ProjectSettings.get_setting(UiReactDockConfig.KEY_OPEN_WIRING_SHORTCUT_JSON, ""))
	assert_true(d.contains("\"keycode\":" + str(KEY_1)))
	assert_true(w.contains("\"keycode\":" + str(KEY_2)))

extends GutTest


func test_known_control_script_resolves_by_class_name() -> void:
	var s: Script = load("res://addons/ui_react/scripts/controls/ui_react_button.gd") as Script
	assert_ne(s, null)
	assert_eq(UiReactScannerService.get_component_name_from_script(s), "UiReactButton")


func test_non_component_script_under_ui_react_path_returns_empty() -> void:
	var s: Script = load("res://addons/ui_react/scripts/internal/react/ui_react_state_binding_helper.gd") as Script
	assert_ne(s, null)
	assert_eq(UiReactScannerService.get_component_name_from_script(s), "")


func test_null_script_returns_empty() -> void:
	assert_eq(UiReactScannerService.get_component_name_from_script(null), "")

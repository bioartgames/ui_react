@tool
extends VBoxContainer

signal settings_applied

var _ignored_list: ItemList
var _ignored_unused_local: Dictionary = {}


func _ready() -> void:
	_build_ui()
	reload_from_project_settings()


func _build_ui() -> void:
	if get_child_count() > 0:
		return
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	var title := Label.new()
	title.text = "Ui React Settings"
	title.add_theme_font_size_override("font_size", 18)
	add_child(title)

	var ignored := _section("Ignored Unused-State Paths")
	var ignored_help := Label.new()
	ignored_help.text = "Paths hidden from unused-state diagnostics."
	ignored_help.tooltip_text = (
		"Remove entries to show those unused-state issues again during diagnostics."
	)
	ignored.add_child(ignored_help)
	_ignored_list = ItemList.new()
	_ignored_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ignored_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_ignored_list.custom_minimum_size = Vector2(0, 180)
	_ignored_list.select_mode = ItemList.SELECT_MULTI
	_ignored_list.tooltip_text = "Persisted ignored resource paths."
	ignored.add_child(_ignored_list)
	var ignored_actions := HBoxContainer.new()
	ignored_actions.add_theme_constant_override("separation", 8)
	var remove_selected_button := Button.new()
	remove_selected_button.text = "Remove Selected"
	remove_selected_button.tooltip_text = "Remove selected paths from the ignored list."
	remove_selected_button.pressed.connect(_on_remove_selected_ignored_pressed)
	ignored_actions.add_child(remove_selected_button)
	var clear_all_button := Button.new()
	clear_all_button.text = "Clear All"
	clear_all_button.tooltip_text = "Clear all ignored paths."
	clear_all_button.pressed.connect(_on_clear_all_ignored_pressed)
	ignored_actions.add_child(clear_all_button)
	ignored.add_child(ignored_actions)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	var apply_btn := Button.new()
	apply_btn.text = "Apply"
	apply_btn.tooltip_text = "Save these Ui React settings."
	apply_btn.pressed.connect(apply_to_project_settings)
	actions.add_child(apply_btn)
	var revert_btn := Button.new()
	revert_btn.text = "Revert"
	revert_btn.tooltip_text = "Discard unsaved edits in this tab."
	revert_btn.pressed.connect(reload_from_project_settings)
	actions.add_child(revert_btn)
	var reset_btn := Button.new()
	reset_btn.text = "Reset defaults"
	reset_btn.tooltip_text = "Clear all ignored paths. Open-tab shortcuts use internal Project Settings keys (defaults Alt+1 / Alt+2); edit JSON there if needed."
	reset_btn.pressed.connect(_on_reset_defaults_pressed)
	actions.add_child(reset_btn)
	add_child(actions)


func _section(name: String) -> VBoxContainer:
	var sec := VBoxContainer.new()
	sec.add_theme_constant_override("separation", 6)
	var h := Label.new()
	h.text = name
	h.add_theme_font_size_override("font_size", 14)
	sec.add_child(h)
	add_child(sec)
	return sec


func reload_from_project_settings() -> void:
	if _ignored_list == null:
		return
	_ignored_unused_local = UiReactDockConfig.load_ignored_unused_state_paths_dict()
	_rebuild_ignored_paths_list()


func apply_to_project_settings() -> void:
	UiReactDockConfig.save_ignored_unused_state_paths_dict(_ignored_unused_local)
	emit_signal("settings_applied")


func _on_reset_defaults_pressed() -> void:
	_ignored_unused_local.clear()
	_rebuild_ignored_paths_list()
	apply_to_project_settings()
	reload_from_project_settings()


func _on_remove_selected_ignored_pressed() -> void:
	if _ignored_list == null:
		return
	var selected := _ignored_list.get_selected_items()
	for idx in selected:
		if idx < 0 or idx >= _ignored_list.item_count:
			continue
		var p := _ignored_list.get_item_text(idx)
		_ignored_unused_local.erase(p)
	_rebuild_ignored_paths_list()


func _on_clear_all_ignored_pressed() -> void:
	_ignored_unused_local.clear()
	_rebuild_ignored_paths_list()


func _rebuild_ignored_paths_list() -> void:
	if _ignored_list == null:
		return
	_ignored_list.clear()
	var keys: Array = _ignored_unused_local.keys()
	keys.sort_custom(func(a: Variant, b: Variant) -> bool: return String(a) < String(b))
	for k in keys:
		_ignored_list.add_item(String(k))

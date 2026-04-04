extends Control
## Inventory demo: [UiReactTree] ([member UiReactTree.tree_items_state]) + filtered list + [UiReactWireRunner] / [code]wire_rules[/code] (see [code]docs/WIRING_LAYER.md[/code]).
## List lock: [code]action_targets[/code] on the item list. Demo-only: action notes + debug labels.

@export var selected_state: UiIntState
@export var items_state: UiArrayState
@export var detail_note_state: UiStringState
@export var actions_disabled_state: UiBoolState
@export var use_pressed_state: UiBoolState
@export var sort_pressed_state: UiBoolState

@onready var _texture_use: TextureButton = $MainHBox/RightColumn/ActionButtons/UseButton
@onready var _texture_sort: TextureButton = $MainHBox/RightColumn/ActionButtons/SortButton
@onready var _pressed_use_label: Label = $MainHBox/RightColumn/PressedUseLabel
@onready var _pressed_sort_label: Label = $MainHBox/RightColumn/PressedSortLabel
@onready var _disabled_actions_label: Label = $MainHBox/RightColumn/DisabledActionsLabel


func _ready() -> void:
	if selected_state:
		if not selected_state.value_changed.is_connected(_on_selected_clear_note):
			selected_state.value_changed.connect(_on_selected_clear_note)
	if use_pressed_state:
		if not use_pressed_state.value_changed.is_connected(_on_use_pressed_changed):
			use_pressed_state.value_changed.connect(_on_use_pressed_changed)
	if sort_pressed_state:
		if not sort_pressed_state.value_changed.is_connected(_on_sort_pressed_changed):
			sort_pressed_state.value_changed.connect(_on_sort_pressed_changed)
	if actions_disabled_state:
		if not actions_disabled_state.value_changed.is_connected(_on_actions_disabled_changed):
			actions_disabled_state.value_changed.connect(_on_actions_disabled_changed)
	_refresh_action_labels()


func _on_selected_clear_note(_nv: Variant, _ov: Variant) -> void:
	if detail_note_state:
		detail_note_state.set_value("")


func _on_use_pressed_changed(new_val: Variant, _old_val: Variant) -> void:
	if not bool(new_val):
		return
	if detail_note_state == null:
		return
	var name_str := ""
	if selected_state and items_state and int(selected_state.get_value()) >= 0:
		var li := int(selected_state.get_value())
		var rows: Variant = items_state.get_value()
		if rows is Array:
			var arr: Array = rows as Array
			if li >= 0 and li < arr.size():
				var entry: Variant = arr[li]
				if entry is Dictionary:
					name_str = str((entry as Dictionary).get("name", ""))
	if name_str.is_empty():
		detail_note_state.set_value("[Demo] Use — select an item first.")
	else:
		detail_note_state.set_value("[Demo] Use — queued for “%s”." % name_str)
	_refresh_action_labels()


func _on_actions_disabled_changed(_new_val: Variant, _old_val: Variant) -> void:
	_refresh_action_labels()


func _on_sort_pressed_changed(new_val: Variant, _old_val: Variant) -> void:
	if not bool(new_val):
		return
	if detail_note_state:
		detail_note_state.set_value("[Demo] Sort — no-op (texture button pressed_state).")
	_refresh_action_labels()


func _refresh_action_labels() -> void:
	var pu: UiBoolState = _texture_use.pressed_state as UiBoolState
	var ps: UiBoolState = _texture_sort.pressed_state as UiBoolState
	var ds: UiBoolState = _texture_use.disabled_state as UiBoolState
	if _pressed_use_label:
		_pressed_use_label.text = "use pressed_state: %s" % (str(pu.get_value()) if pu else "—")
	if _pressed_sort_label:
		_pressed_sort_label.text = "sort pressed_state: %s" % (str(ps.get_value()) if ps else "—")
	if _disabled_actions_label:
		_disabled_actions_label.text = "actions disabled_state: %s" % (str(ds.get_value()) if ds else "—")

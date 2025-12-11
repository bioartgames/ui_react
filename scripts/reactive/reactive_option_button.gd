extends OptionButton
class_name ReactiveOptionButton

@export var selected_state: State
@export var disabled_state: State
var _updating: bool = false

func _ready() -> void:
	item_selected.connect(_on_item_selected)
	if selected_state:
		selected_state.value_changed.connect(_on_selected_state_changed)
		_on_selected_state_changed(selected_state.value, selected_state.value)
	if disabled_state:
		disabled_state.value_changed.connect(_on_disabled_state_changed)
		_on_disabled_state_changed(disabled_state.value, disabled_state.value)

func _on_item_selected(index: int) -> void:
	if not selected_state or _updating:
		return
	var new_value: Variant = get_item_text(index)
	if selected_state.value == new_value:
		return
	_updating = true
	selected_state.set_value(new_value)
	_updating = false

func _on_selected_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _updating:
		return
	var index := -1
	if new_value is String:
		index = _find_item_by_text(new_value)
	else:
		index = int(new_value)
	if index < 0 or index >= item_count:
		return
	if get_selected_id() == index or selected == index:
		return
	_updating = true
	select(index)
	_updating = false

func _on_disabled_state_changed(new_value: Variant, _old_value: Variant) -> void:
	disabled = bool(new_value)

func _find_item_by_text(text_value: String) -> int:
	for i in item_count:
		if get_item_text(i) == text_value:
			return i
	return -1

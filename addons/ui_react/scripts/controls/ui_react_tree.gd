extends Tree
class_name UiReactTree

## Two-way binding for single selection: pre-order index over **visible** rows (see class doc). **-1** means nothing selected.
@export var selected_state: UiIntState

## **Optional** — Inspector-driven tweens (selection, hover). Leave empty for no automatic animations.
@export var animation_targets: Array[UiAnimTarget] = []

## **Optional** — Action layer presets ([code]docs/ACTION_LAYER.md[/code]).
@export var action_targets: Array[UiReactActionTarget] = []

var _updating: bool = false
var _is_initializing: bool = true

func _ready() -> void:
	select_mode = SELECT_SINGLE
	item_selected.connect(_on_tree_item_selected)
	nothing_selected.connect(_on_tree_nothing_selected)
	if selected_state:
		selected_state.value_changed.connect(_on_selected_state_changed)
		_on_selected_state_changed(selected_state.get_value(), selected_state.get_value())
	_validate_animation_targets()
	UiReactStateBindingHelper.deferred_finish_initialization(self)

## Validates animation targets and filters out invalid ones.
func _validate_animation_targets() -> void:
	var trigger_map: Dictionary = UiReactAnimTargetHelper.apply_validated_targets(self, "UiReactTree")
	UiReactActionTargetHelper.apply_validated_actions_and_merge_triggers(self, "UiReactTree", trigger_map)

	if trigger_map.has(UiAnimTarget.Trigger.SELECTION_CHANGED):
		UiReactAnimTargetHelper.connect_if_absent(item_selected, _on_trigger_selection_changed)
		UiReactAnimTargetHelper.connect_if_absent(nothing_selected, _on_trigger_selection_nothing)
	if trigger_map.has(UiAnimTarget.Trigger.HOVER_ENTER):
		UiReactAnimTargetHelper.connect_if_absent(mouse_entered, _on_trigger_hover_enter)
	if trigger_map.has(UiAnimTarget.Trigger.HOVER_EXIT):
		UiReactAnimTargetHelper.connect_if_absent(mouse_exited, _on_trigger_hover_exit)

	UiReactActionTargetHelper.sync_initial_state(self, "UiReactTree", action_targets)

func _finish_initialization() -> void:
	_is_initializing = false

func _on_trigger_selection_changed() -> void:
	if _is_initializing:
		return
	_trigger_animations(UiAnimTarget.Trigger.SELECTION_CHANGED)

func _on_trigger_selection_nothing() -> void:
	if _is_initializing:
		return
	_trigger_animations(UiAnimTarget.Trigger.SELECTION_CHANGED)

func _on_trigger_hover_enter() -> void:
	_trigger_animations(UiAnimTarget.Trigger.HOVER_ENTER)

func _on_trigger_hover_exit() -> void:
	_trigger_animations(UiAnimTarget.Trigger.HOVER_EXIT)

func _trigger_animations(trigger_type: UiAnimTarget.Trigger) -> void:
	UiReactAnimTargetHelper.trigger_animations(self, animation_targets, trigger_type)
	UiReactActionTargetHelper.run_actions(self, "UiReactTree", action_targets, trigger_type)

## Visible pre-order: depth-first using [method TreeItem.get_next_visible]. If [member hide_root] is [code]true[/code], the engine root is omitted; counting starts at its first child.
func _flatten_visible_preorder() -> Array[TreeItem]:
	var root := get_root()
	if root == null:
		return []
	var start: TreeItem
	if hide_root:
		start = root.get_first_child()
	else:
		start = root
	if start == null:
		return []
	var out: Array[TreeItem] = []
	var cur: TreeItem = start
	while cur != null:
		out.append(cur)
		cur = cur.get_next_visible(false)
	return out

func _flat_index_for_item(item: TreeItem) -> int:
	if item == null:
		return -1
	var flat := _flatten_visible_preorder()
	for i in range(flat.size()):
		if flat[i] == item:
			return i
	return -1

func _item_for_flat_index(idx: int) -> TreeItem:
	if idx < 0:
		return null
	var flat := _flatten_visible_preorder()
	if idx >= flat.size():
		return null
	return flat[idx]

func _sync_state_from_tree_selection() -> void:
	if not selected_state or _updating:
		return
	var sel := get_selected()
	var idx := _flat_index_for_item(sel)
	if selected_state.get_value() == idx:
		return
	_updating = true
	selected_state.set_value(idx)
	_updating = false

func _on_tree_item_selected() -> void:
	_sync_state_from_tree_selection()

func _on_tree_nothing_selected() -> void:
	if not selected_state or _updating:
		return
	if selected_state.get_value() == -1:
		return
	_updating = true
	selected_state.set_value(-1)
	_updating = false

func _on_selected_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _updating:
		return
	if not selected_state:
		return
	var idx := int(new_value)
	if idx == -1:
		_updating = true
		deselect_all()
		_updating = false
		return
	var item := _item_for_flat_index(idx)
	if item == null:
		_updating = true
		deselect_all()
		if selected_state.get_value() != -1:
			selected_state.set_value(-1)
		_updating = false
		return
	_updating = true
	set_selected(item, 0)
	_updating = false

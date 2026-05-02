extends Tree
class_name UiReactTree

const _TREE_NODE_SCRIPT: Script = preload("res://addons/ui_react/scripts/api/models/ui_react_tree_node.gd")
const _UiReactHostWireTree := preload("res://addons/ui_react/scripts/internal/react/ui_react_host_wire_tree.gd")
const _UiReactExitTeardown := preload("res://addons/ui_react/scripts/internal/react/ui_react_control_exit_teardown.gd")

var _bind := UiReactTwoWayBindingDriver.new()
var _local_signal_scope: UiReactSubscriptionScope
var _tree_items_state: UiArrayState
var _selected_state: UiIntState
var _last_tree_items_signature: String = ""
var _have_tree_items_structure_sig: bool = false

## Hierarchical row data. Assign a [UiArrayState] whose [member UiArrayState.value] is an [Array] of [UiReactTreeNode].
## Top-level nodes are created as children of the tree root (with [member hide_root] [code]true[/code], the root row is hidden; visible index [code]0[/code] is the first top-level row).
@export var tree_items_state: UiArrayState:
	get:
		return _tree_items_state
	set(v):
		if _tree_items_state == v:
			return
		if is_node_ready():
			_disconnect_all_states()
		_tree_items_state = v
		if is_node_ready():
			_connect_all_states()

## Two-way binding for single selection: pre-order index over **visible** rows (see class doc). **-1** means nothing selected.
@export var selected_state: UiIntState:
	get:
		return _selected_state
	set(v):
		if _selected_state == v:
			return
		if is_node_ready():
			_disconnect_all_states()
		_selected_state = v
		if is_node_ready():
			_connect_all_states()

## **Optional** — Inspector-driven tweens (selection, hover). Leave empty for no automatic animations.
@export var animation_targets: Array[UiAnimTarget] = []

## **Optional** — Action layer presets ([code]docs/ACTION_LAYER.md[/code]).
@export var action_targets: Array[UiReactActionTarget] = []

## **Optional** — Feedback ([code]docs/FEEDBACK_LAYER.md[/code]): one-shot audio / controller rumble on triggers.
@export var audio_targets: Array[UiReactAudioFeedbackTarget] = []

## **Optional** — Feedback ([code]docs/FEEDBACK_LAYER.md[/code]): [method Input.start_joy_vibration] on triggers.
@export var haptic_targets: Array[UiReactHapticFeedbackTarget] = []

## **Optional** — Wiring rules ([code]docs/WIRING_LAYER.md[/code] §5). Applied by [UiReactWireRuleHelper] via [UiReactHostWireTree].
@export var wire_rules: Array[UiReactWireRule] = []


func _enter_tree() -> void:
	_UiReactHostWireTree.on_enter(self)


func _reactive_teardown() -> void:
	UiReactActionTargetHelper.teardown_for_control_exit(self)
	UiReactFeedbackTargetHelper.teardown_for_control_exit(self)
	_disconnect_local_control_signals()
	_UiReactExitTeardown.teardown_wire_host(
		Callable(self, "_disconnect_all_states"),
		func() -> void: _UiReactHostWireTree.on_exit(self)
	)


func _disconnect_local_control_signals() -> void:
	if _local_signal_scope != null:
		_local_signal_scope.dispose()
		_local_signal_scope = null


func _exit_tree() -> void:
	_reactive_teardown()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_reactive_teardown()


func _ready() -> void:
	select_mode = SELECT_SINGLE
	if _local_signal_scope != null:
		_local_signal_scope.dispose()
	_local_signal_scope = UiReactSubscriptionScope.new()
	_local_signal_scope.connect_bound(item_selected, _on_tree_item_selected)
	_local_signal_scope.connect_bound(nothing_selected, _on_tree_nothing_selected)
	_disconnect_all_states()
	_connect_all_states()
	_validate_animation_targets()
	UiReactStateBindingHelper.deferred_finish_initialization(self)


func _disconnect_all_states() -> void:
	if _tree_items_state != null:
		UiReactControlStateWire.unbind_value_changed(self, _tree_items_state, &"tree_items_state", _on_tree_items_state_changed, false)
	if _selected_state != null:
		UiReactControlStateWire.unbind_value_changed(self, _selected_state, &"selected_state", _on_selected_state_changed, false)


func _connect_all_states() -> void:
	if _tree_items_state != null:
		UiReactControlStateWire.bind_value_changed(self, _tree_items_state, &"tree_items_state", _on_tree_items_state_changed, false)
	if _selected_state != null:
		UiReactControlStateWire.bind_value_changed(self, _selected_state, &"selected_state", _on_selected_state_changed, false)


func _on_tree_items_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _bind.updating:
		return
	if not _tree_items_state:
		return
	if new_value == null:
		return
	if not (new_value is Array):
		UiReactStateBindingHelper.warn_setup(
			"UiReactTree",
			self,
			"tree_items_state must use an Array value of UiReactTreeNode.",
			"Set tree_items_state to an Array payload via UiArrayState.",
		)
		return
	var arr: Array = new_value as Array
	var new_sig := _compute_tree_items_signature(arr)
	if _have_tree_items_structure_sig and new_sig == _last_tree_items_signature:
		_bind.updating = true
		_sync_selection_ui_to_state()
		_bind.updating = false
		_clamp_selected_state_to_visible_rows()
		_validate_row_slots_vs_visible_count()
		return
	_bind.updating = true
	clear()
	# After [method Tree.clear], [method Tree.get_root] can be null. Top-level rows use [method Tree.create_item] with a null parent (attached under the tree root).
	for entry in arr:
		if is_instance_of(entry, _TREE_NODE_SCRIPT):
			_build_subtree(null, entry as Resource)
		else:
			push_warning("UiReactTree: skipping non-UiReactTreeNode entry in tree_items_state.")
	_last_tree_items_signature = new_sig
	_have_tree_items_structure_sig = true
	_sync_selection_ui_to_state()
	_bind.updating = false
	_clamp_selected_state_to_visible_rows()
	_validate_row_slots_vs_visible_count()


func _compute_tree_items_signature(entries: Array) -> String:
	var parts: PackedStringArray = PackedStringArray()
	parts.resize(entries.size())
	for i in range(entries.size()):
		var entry: Variant = entries[i]
		if is_instance_of(entry, _TREE_NODE_SCRIPT):
			parts[i] = _tree_node_structure_signature(entry as Resource)
		else:
			parts[i] = "x\u001finvalid\u001fx"
	return "\u001d".join(parts)


func _tree_icon_signature_part(ic: Variant) -> String:
	if ic is Texture2D:
		var tpath := (ic as Texture2D).resource_path
		if not tpath.is_empty():
			return "texpath:" + tpath
		return "texid:" + str((ic as Texture2D).get_instance_id())
	if typeof(ic) == TYPE_STRING:
		var ps := str(ic).strip_edges()
		return "path:" + ps if not ps.is_empty() else "icon:null"
	return "icon:null"


func _tree_node_structure_signature(node: Resource) -> String:
	if not is_instance_of(node, _TREE_NODE_SCRIPT):
		return "x\u001finvalid\u001fx"
	var label: String = str(node.get(&"text"))
	var icon_part := _tree_icon_signature_part(node.get(&"icon"))
	var ch: Variant = node.get(&"children")
	var child_blob := ""
	if typeof(ch) == TYPE_ARRAY:
		var subs: PackedStringArray = PackedStringArray()
		for child in ch as Array:
			if child != null and is_instance_of(child, _TREE_NODE_SCRIPT):
				subs.append(_tree_node_structure_signature(child as Resource))
			elif child == null:
				subs.append("x\u001fnullchild\u001fx")
			else:
				subs.append("x\u001finvalidchild\u001fx")
		child_blob = "\u001e".join(subs)
	return label + "\u001f" + icon_part + "\u001f" + child_blob


func _build_subtree(parent_item: Variant, node: Resource) -> void:
	if not is_instance_of(node, _TREE_NODE_SCRIPT):
		return
	var item: TreeItem
	if parent_item == null:
		item = create_item(null)
	else:
		item = create_item(parent_item as TreeItem)
	var label: String = str(node.get(&"text"))
	item.set_text(0, label)
	var ic: Variant = node.get(&"icon")
	if ic is Texture2D:
		item.set_icon(0, ic as Texture2D)
	else:
		push_warning("UiReactTree: UiReactTreeNode '%s' has null icon." % label)
	var ch: Variant = node.get(&"children")
	if typeof(ch) != TYPE_ARRAY:
		return
	for child in ch as Array:
		if child == null:
			push_warning("UiReactTree: null child under '%s'." % label)
			continue
		if is_instance_of(child, _TREE_NODE_SCRIPT):
			_build_subtree(item, child as Resource)


func _sync_selection_ui_to_state() -> void:
	if not _selected_state:
		return
	var v: Variant = _selected_state.get_value()
	deselect_all()
	if v is int:
		var idx: int = v
		if idx >= 0:
			var item := _item_for_flat_index(idx)
			if item != null:
				set_selected(item, 0)


func _clamp_selected_state_to_visible_rows() -> void:
	if not _selected_state:
		return
	var v: Variant = _selected_state.get_value()
	if v is int:
		var idx: int = v
		if idx == -1:
			return
		var n: int = get_visible_row_count()
		if n == 0 or idx < 0 or idx >= n:
			_selected_state.set_value(-1)


func _validate_row_slots_vs_visible_count() -> void:
	var n: int = get_visible_row_count()
	if n <= 0:
		return
	for anim_target in animation_targets:
		if anim_target == null:
			continue
		var s: int = anim_target.selection_slot
		if s >= 0 and s >= n:
			push_warning(
				"UiReactTree: animation_targets has selection_slot %d but visible row count is %d. Fix slots or tree data."
				% [s, n]
			)


## Number of visible rows in preorder (same walk as [method get_animation_selection_index] / [member selected_state] indices).
func get_visible_row_count() -> int:
	return _flatten_visible_preorder().size()


## Validates animation targets and filters out invalid ones.
func _validate_animation_targets() -> void:
	var trigger_map: Dictionary = UiReactAnimTargetHelper.apply_validated_targets(self, "UiReactTree")
	_validate_row_slots_vs_visible_count()
	UiReactActionTargetHelper.apply_validated_actions_and_merge_triggers(self, "UiReactTree", trigger_map)
	UiReactFeedbackTargetHelper.apply_validated_audio_and_haptic_and_merge_triggers(self, "UiReactTree", trigger_map)

	if trigger_map.has(UiAnimTarget.Trigger.SELECTION_CHANGED):
		_local_signal_scope.connect_bound(item_selected, _on_trigger_selection_changed)
		_local_signal_scope.connect_bound(nothing_selected, _on_trigger_selection_nothing)
	if trigger_map.has(UiAnimTarget.Trigger.HOVER_ENTER):
		_local_signal_scope.connect_bound(mouse_entered, _on_trigger_hover_enter)
	if trigger_map.has(UiAnimTarget.Trigger.HOVER_EXIT):
		_local_signal_scope.connect_bound(mouse_exited, _on_trigger_hover_exit)

	UiReactActionTargetHelper.sync_initial_state(self, "UiReactTree", action_targets)
	UiReactFeedbackTargetHelper.sync_initial_state(self, "UiReactTree", audio_targets, haptic_targets)


func _finish_initialization() -> void:
	_bind.finish_initialization()


func _on_trigger_selection_changed() -> void:
	if _bind.initializing:
		return
	_trigger_animations(UiAnimTarget.Trigger.SELECTION_CHANGED)


func _on_trigger_selection_nothing() -> void:
	if _bind.initializing:
		return
	_trigger_animations(UiAnimTarget.Trigger.SELECTION_CHANGED)


func _on_trigger_hover_enter() -> void:
	_trigger_animations(UiAnimTarget.Trigger.HOVER_ENTER)


func _on_trigger_hover_exit() -> void:
	_trigger_animations(UiAnimTarget.Trigger.HOVER_EXIT)


func _trigger_animations(trigger_type: UiAnimTarget.Trigger) -> void:
	UiReactAnimTargetHelper.trigger_animations(self, animation_targets, trigger_type)
	UiReactActionTargetHelper.run_actions(self, "UiReactTree", action_targets, trigger_type)
	UiReactFeedbackTargetHelper.run_audio_feedback(self, "UiReactTree", audio_targets, trigger_type)
	UiReactFeedbackTargetHelper.run_haptic_feedback(self, "UiReactTree", haptic_targets, trigger_type)


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


## Visible pre-order index for [member UiAnimTarget.selection_slot] filtering on this tree's [member animation_targets].
func get_animation_selection_index() -> int:
	return _flat_index_for_item(get_selected())


func _item_for_flat_index(idx: int) -> TreeItem:
	if idx < 0:
		return null
	var flat := _flatten_visible_preorder()
	if idx >= flat.size():
		return null
	return flat[idx]


func _sync_state_from_tree_selection() -> void:
	if not _selected_state or _bind.updating:
		return
	var sel := get_selected()
	var idx := _flat_index_for_item(sel)
	if _selected_state.get_value() == idx:
		return
	_bind.updating = true
	_selected_state.set_value(idx)
	_bind.updating = false


func _on_tree_item_selected() -> void:
	_sync_state_from_tree_selection()


func _on_tree_nothing_selected() -> void:
	if not _selected_state or _bind.updating:
		return
	if _selected_state.get_value() == -1:
		return
	_bind.updating = true
	_selected_state.set_value(-1)
	_bind.updating = false


func _on_selected_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _bind.updating:
		return
	if not _selected_state:
		return
	var idx := int(new_value)
	if idx == -1:
		_bind.updating = true
		deselect_all()
		_bind.updating = false
		return
	var item := _item_for_flat_index(idx)
	if item == null:
		_bind.updating = true
		deselect_all()
		if _selected_state.get_value() != -1:
			_selected_state.set_value(-1)
		_bind.updating = false
		return
	_bind.updating = true
	set_selected(item, 0)
	_bind.updating = false

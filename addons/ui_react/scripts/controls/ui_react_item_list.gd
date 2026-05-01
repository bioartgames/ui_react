extends ItemList
class_name UiReactItemList

const _UiReactHostWireTree := preload("res://addons/ui_react/scripts/internal/react/ui_react_host_wire_tree.gd")
const _UiReactExitTeardown := preload("res://addons/ui_react/scripts/internal/react/ui_react_control_exit_teardown.gd")

const _ICON_PATH_CACHE_MAX: int = 64

var _bind := UiReactTwoWayBindingDriver.new()
var _local_signal_scope: UiReactSubscriptionScope
var _items_state: UiArrayState
var _selected_state: UiState

## `String` (normalized res path) -> [Texture2D]; FIFO-capped when paths rotate.
var _icon_path_cache: Dictionary = {}
var _icon_path_cache_order: Array[String] = []

## Per-row stable signatures for cheap rebuild skip (see [method _entry_signature]).
var _last_items_signatures: PackedStringArray = PackedStringArray()

## **Optional** — list row contents from a [UiArrayState] (or assign an [Array] payload).
## Each element is either stringified with [method @GlobalScope.str], or a [Dictionary] with **label** or **text**, and optional **icon** ([Texture2D] or [code]res://[/code] path string).
@export var items_state: UiArrayState:
	get:
		return _items_state
	set(v):
		if _items_state == v:
			return
		_clear_icon_path_cache()
		_last_items_signatures = PackedStringArray()
		if is_node_ready():
			_disconnect_all_states()
		_items_state = v
		if is_node_ready():
			_connect_all_states()

## Two-way binding for selection (see script for value shape). **Assign** [UiIntState] (single-select) or [UiArrayState] (multi-select).
@export var selected_state: UiState:
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

## **Optional** — Inspector-driven tweens (selection, hover) and row-play presets ([method play_selected_row_animation]).
## Use [member UiAnimTarget.selection_slot] [code]>= 0[/code] to tie a target to a list row for [method play_selected_row_animation] / [method play_preamble_reset_only]; [code]-1[/code] for entries that are not row-scoped (e.g. hover-only).
@export var animation_targets: Array[UiAnimTarget] = []

## **Optional** — Action layer rows (focus, visibility, [code]mouse_filter[/code], UI bool flags). See [code]docs/ACTION_LAYER.md[/code].
@export var action_targets: Array[UiReactActionTarget] = []

## **Optional** — Wiring rules ([code]docs/WIRING_LAYER.md[/code] §5). Applied by [UiReactWireRuleHelper] via [UiReactHostWireTree].
@export var wire_rules: Array[UiReactWireRule] = []

var _row_play_in_progress: bool = false

const _WARN_SINGLE_SELECT_EXPECT_INT := "UiReactItemList: expected int for single-select selected_state"


func _enter_tree() -> void:
	_UiReactHostWireTree.on_enter(self)


func _reactive_teardown() -> void:
	UiReactActionTargetHelper.teardown_for_control_exit(self)
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
	if _local_signal_scope != null:
		_local_signal_scope.dispose()
	_local_signal_scope = UiReactSubscriptionScope.new()
	_local_signal_scope.connect_bound(item_selected, _on_item_selected)
	_local_signal_scope.connect_bound(item_activated, _on_item_activated)
	_disconnect_all_states()
	_connect_all_states()
	_validate_animation_targets()
	UiReactStateBindingHelper.deferred_finish_initialization(self)


func _disconnect_all_states() -> void:
	if _items_state != null:
		UiReactControlStateWire.unbind_value_changed(self, _items_state, &"items_state", _on_items_state_changed, false)
	if _selected_state != null:
		UiReactControlStateWire.unbind_value_changed(self, _selected_state, &"selected_state", _on_selected_state_changed, false)


func _connect_all_states() -> void:
	if _items_state != null:
		UiReactControlStateWire.bind_value_changed(self, _items_state, &"items_state", _on_items_state_changed, false)
	if _selected_state != null:
		UiReactControlStateWire.bind_value_changed(self, _selected_state, &"selected_state", _on_selected_state_changed, false)


## Validates animation targets and filters out invalid ones.
## Called automatically in [method _ready].
func _validate_animation_targets() -> void:
	var trigger_map: Dictionary = UiReactAnimTargetHelper.apply_validated_targets(self, "UiReactItemList")
	_validate_row_slots_vs_item_count()
	UiReactActionTargetHelper.apply_validated_actions_and_merge_triggers(self, "UiReactItemList", trigger_map)

	# Connect signals based on which triggers are used
	if trigger_map.has(UiAnimTarget.Trigger.SELECTION_CHANGED):
		_local_signal_scope.connect_bound(item_selected, _on_trigger_selection_changed)
	if trigger_map.has(UiAnimTarget.Trigger.HOVER_ENTER):
		_local_signal_scope.connect_bound(mouse_entered, _on_trigger_hover_enter)
	if trigger_map.has(UiAnimTarget.Trigger.HOVER_EXIT):
		_local_signal_scope.connect_bound(mouse_exited, _on_trigger_hover_exit)

	UiReactActionTargetHelper.sync_initial_state(self, "UiReactItemList", action_targets)


func _validate_row_slots_vs_item_count() -> void:
	if item_count <= 0:
		return
	for anim_target in animation_targets:
		if anim_target == null:
			continue
		var s: int = anim_target.selection_slot
		if s >= 0 and s >= item_count:
			push_warning(
				"UiReactItemList: animation_targets has selection_slot %d but item_count is %d. Fix slots or list items."
				% [s, item_count]
			)


## Selection index for [member UiAnimTarget.selection_slot] filtering on this list's [member animation_targets].
func get_animation_selection_index() -> int:
	var sel: PackedInt32Array = get_selected_items()
	if sel.is_empty():
		return -1
	return int(sel[0])


## Plays every [member animation_targets] entry with [member UiAnimTarget.selection_slot] equal to the current selection (optional preamble per resource), in array order.
func play_selected_row_animation() -> void:
	if _row_play_in_progress:
		return
	_row_play_in_progress = true
	var sel: PackedInt32Array = get_selected_items()
	if sel.is_empty():
		push_warning("UiReactItemList: play_selected_row_animation called with no selection.")
		_row_play_in_progress = false
		return
	var i: int = int(sel[0])
	if i < 0 or i >= item_count:
		push_warning("UiReactItemList: play_selected_row_animation selected index %d out of range for item_count %d." % [i, item_count])
		_row_play_in_progress = false
		return
	var row_targets: Array[UiAnimTarget] = UiReactAnimTargetHelper.collect_animation_targets_for_row_slot(animation_targets, i)
	if row_targets.is_empty():
		push_warning(
			"UiReactItemList: no animation_targets with selection_slot == %d for play_selected_row_animation." % i
		)
		_row_play_in_progress = false
		return
	for t in row_targets:
		await t.apply_with_preamble(self)
	_row_play_in_progress = false


## Runs only preamble [code]RESET[/code] for each [member animation_targets] entry with [member UiAnimTarget.selection_slot] matching the selection, in array order.
func play_preamble_reset_only() -> void:
	if _row_play_in_progress:
		return
	_row_play_in_progress = true
	var sel: PackedInt32Array = get_selected_items()
	if sel.is_empty():
		push_warning("UiReactItemList: play_preamble_reset_only called with no selection.")
		_row_play_in_progress = false
		return
	var i: int = int(sel[0])
	if i < 0 or i >= item_count:
		_row_play_in_progress = false
		return
	var row_targets: Array[UiAnimTarget] = UiReactAnimTargetHelper.collect_animation_targets_for_row_slot(animation_targets, i)
	if row_targets.is_empty():
		push_warning(
			"UiReactItemList: no animation_targets with selection_slot == %d for play_preamble_reset_only." % i
		)
		_row_play_in_progress = false
		return
	for t in row_targets:
		await t.apply_preamble_reset_only(self)
	_row_play_in_progress = false


## Finishes initialization, allowing animations to trigger on selection changes.
func _finish_initialization() -> void:
	_bind.finish_initialization()


## Handles SELECTION_CHANGED trigger animations.
func _on_trigger_selection_changed(_index: int) -> void:
	# Skip animations during initialization
	if _bind.initializing:
		return

	_trigger_animations(UiAnimTarget.Trigger.SELECTION_CHANGED)


## Handles HOVER_ENTER trigger animations.
func _on_trigger_hover_enter() -> void:
	_trigger_animations(UiAnimTarget.Trigger.HOVER_ENTER)


## Handles HOVER_EXIT trigger animations.
func _on_trigger_hover_exit() -> void:
	_trigger_animations(UiAnimTarget.Trigger.HOVER_EXIT)


## Triggers animations for targets matching the specified trigger type.
## [param trigger_type]: The trigger type to match.
func _trigger_animations(trigger_type: UiAnimTarget.Trigger) -> void:
	UiReactAnimTargetHelper.trigger_animations(self, animation_targets, trigger_type)
	UiReactActionTargetHelper.run_actions(self, "UiReactItemList", action_targets, trigger_type)


func _add_item_from_entry(entry: Variant) -> void:
	if entry is Dictionary:
		var d: Dictionary = entry as Dictionary
		var label_text := ""
		if d.has("label"):
			label_text = str(d["label"])
		elif d.has("text"):
			label_text = str(d["text"])
		else:
			label_text = str(entry)
		var icon_tex: Texture2D = null
		if d.has("icon"):
			icon_tex = _coerce_entry_icon(d["icon"])
		add_item(label_text, icon_tex)
		return
	add_item(str(entry))


func _coerce_entry_icon(v: Variant) -> Texture2D:
	if v is Texture2D:
		return v as Texture2D
	if typeof(v) == TYPE_STRING:
		var p := str(v).strip_edges()
		if p.is_empty():
			return null
		if _icon_path_cache.has(p):
			return _icon_path_cache[p] as Texture2D
		var res: Resource = ResourceLoader.load(p)
		if res is Texture2D:
			var tex := res as Texture2D
			_icon_path_cache_store(p, tex)
			return tex
	return null


func _icon_path_cache_store(path_key: String, tex: Texture2D) -> void:
	if _icon_path_cache.has(path_key):
		return
	while _icon_path_cache_order.size() >= _ICON_PATH_CACHE_MAX:
		var oldest: String = _icon_path_cache_order.pop_front()
		_icon_path_cache.erase(oldest)
	_icon_path_cache_order.append(path_key)
	_icon_path_cache[path_key] = tex


func _clear_icon_path_cache() -> void:
	_icon_path_cache.clear()
	_icon_path_cache_order.clear()


## Test-only: distinct normalized icon path keys cached (FIFO-capped).
func debug_icon_path_cache_entry_count_for_tests() -> int:
	return _icon_path_cache.size()


func _entry_signature(entry: Variant) -> String:
	if entry is Dictionary:
		var d: Dictionary = entry as Dictionary
		var label_text := ""
		if d.has("label"):
			label_text = str(d["label"])
		elif d.has("text"):
			label_text = str(d["text"])
		else:
			label_text = str(entry)
		var icon_part := "icon:null"
		if d.has("icon"):
			var ic: Variant = d["icon"]
			if ic is Texture2D:
				var tpath := (ic as Texture2D).resource_path
				if not tpath.is_empty():
					icon_part = "texpath:" + tpath
				else:
					icon_part = "texid:" + str((ic as Texture2D).get_instance_id())
			elif typeof(ic) == TYPE_STRING:
				var ps := str(ic).strip_edges()
				icon_part = "path:" + ps if not ps.is_empty() else "icon:null"
		return "d\u001f" + label_text + "\u001f" + icon_part
	return "s\u001f" + str(entry)


func _signatures_for_items_array(arr: Array) -> PackedStringArray:
	var sigs: PackedStringArray = PackedStringArray()
	sigs.resize(arr.size())
	for i in range(arr.size()):
		sigs[i] = _entry_signature(arr[i])
	return sigs


func _signatures_equal(a: PackedStringArray, b: PackedStringArray) -> bool:
	if a.size() != b.size():
		return false
	for i in range(a.size()):
		if a[i] != b[i]:
			return false
	return true


func _on_items_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _bind.updating:
		return
	if not _items_state:
		return
	if new_value == null:
		return
	if not (new_value is Array):
		UiReactStateBindingHelper.warn_setup(
			"UiReactItemList",
			self,
			"items_state must use an Array value.",
			"Set items_state to an Array payload (e.g. [\"A\", \"B\"]) via UiArrayState.",
		)
		return
	var arr: Array = new_value as Array
	var new_sigs := _signatures_for_items_array(arr)
	if (
		new_sigs.size() == _last_items_signatures.size()
		and new_sigs.size() == item_count
		and _signatures_equal(new_sigs, _last_items_signatures)
	):
		_last_items_signatures = new_sigs
		_bind.updating = true
		_sync_selection_ui_to_state()
		_bind.updating = false
		_clamp_selection_state_if_needed()
		_validate_row_slots_vs_item_count()
		return
	_bind.updating = true
	clear()
	for entry in arr:
		_add_item_from_entry(entry)
	_last_items_signatures = new_sigs
	_sync_selection_ui_to_state()
	_bind.updating = false
	_clamp_selection_state_if_needed()
	_validate_row_slots_vs_item_count()


func _sync_selection_ui_to_state() -> void:
	if not _selected_state:
		return
	var v: Variant = _selected_state.get_value()
	deselect_all()
	if v is int:
		var idx: int = v
		if idx >= 0 and idx < item_count:
			select(idx)
	elif v is Array:
		if select_mode == ItemList.SELECT_SINGLE:
			return
		for idx in _indices_from_variant_array(v):
			select(idx)


func _clamp_selection_state_if_needed() -> void:
	if not _selected_state:
		return
	var v: Variant = _selected_state.get_value()
	if v is int:
		var idx: int = v
		if idx == -1:
			return
		if item_count == 0 or idx < 0 or idx >= item_count:
			_selected_state.set_value(-1)
	elif v is Array and select_mode != ItemList.SELECT_SINGLE:
		var filtered: Array = []
		for item in v:
			if item is int:
				var i: int = item
				if i >= 0 and i < item_count:
					filtered.append(i)
		if filtered != v:
			_selected_state.set_value(filtered)


func _on_item_selected(_index: int) -> void:
	if not _selected_state or _bind.updating:
		return

	# ItemList returns PackedInt32Array; keep native type to avoid conversion overhead.
	var selected_items: PackedInt32Array = get_selected_items()
	var new_value: Variant

	if select_mode == ItemList.SELECT_SINGLE:
		# Single selection: store index or -1 if nothing selected
		new_value = selected_items[0] if selected_items.size() > 0 else -1
	else:
		# Multi selection: store array of indices ([PackedInt32Array] -> [Array] for [UiArrayState])
		new_value = Array(selected_items)

	if _selected_state.get_value() == new_value:
		return

	_bind.updating = true
	_selected_state.set_value(new_value)
	_bind.updating = false


func _on_item_activated(index: int) -> void:
	# Also trigger selection changed on activation
	_on_item_selected(index)


func _on_selected_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _bind.updating:
		return

	if new_value is Array:
		if select_mode == ItemList.SELECT_SINGLE:
			push_warning("UiReactItemList: single-select selected_state expects int, not Array")
			return
		var indices: Array[int] = _indices_from_variant_array(new_value)
		_bind.updating = true
		deselect_all()
		for idx in indices:
			select(idx)
		_bind.updating = false
	elif new_value is int:
		if select_mode != ItemList.SELECT_SINGLE:
			return
		var index: int = new_value
		if index < 0:
			_bind.updating = true
			deselect_all()
			_bind.updating = false
			return
		if index >= item_count:
			return
		_bind.updating = true
		deselect_all()
		if index >= 0:
			select(index)
		_bind.updating = false
	elif select_mode == ItemList.SELECT_SINGLE:
		push_warning(_WARN_SINGLE_SELECT_EXPECT_INT)


func _indices_from_variant_array(raw: Array) -> Array[int]:
	var indices: Array[int] = []
	for item in raw:
		if item is int:
			var idx: int = item
			if idx >= 0 and idx < item_count:
				indices.append(idx)
	return indices

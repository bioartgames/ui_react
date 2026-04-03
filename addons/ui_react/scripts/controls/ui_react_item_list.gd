extends ItemList
class_name UiReactItemList

var _bind := UiReactTwoWayBindingDriver.new()
var _selected_state: UiState
var _items_state: UiArrayState

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

## **Optional** — list row contents from a [UiArrayState] (or assign an [Array] payload).
## Each element is either stringified with [method @GlobalScope.str], or a [Dictionary] with **label** or **text**, and optional **icon** ([Texture2D] or [code]res://[/code] path string).
@export var items_state: UiArrayState:
	get:
		return _items_state
	set(v):
		if _items_state == v:
			return
		if is_node_ready():
			_disconnect_all_states()
		_items_state = v
		if is_node_ready():
			_connect_all_states()

## **Optional** — Inspector-driven tweens (selection, hover). Leave empty for no automatic animations.
@export var animation_targets: Array[UiAnimTarget] = []

## **Optional** — Action layer rows (focus, visibility, [code]mouse_filter[/code], UI bool flags). See [code]docs/ACTION_LAYER.md[/code].
@export var action_targets: Array[UiReactActionTarget] = []

## **Optional** — Wiring rules ([code]docs/WIRING_LAYER.md[/code] §5). Applied by [UiReactWireRunner] in the scene.
@export var wire_rules: Array[UiReactWireRule] = []

const _WARN_SINGLE_SELECT_EXPECT_INT := "UiReactItemList: expected int for single-select selected_state"

func _ready() -> void:
	item_selected.connect(_on_item_selected)
	item_activated.connect(_on_item_activated)
	_disconnect_all_states()
	_connect_all_states()
	_validate_animation_targets()
	UiReactStateBindingHelper.deferred_finish_initialization(self)


func _disconnect_all_states() -> void:
	if _items_state != null and _items_state.value_changed.is_connected(_on_items_state_changed):
		_items_state.value_changed.disconnect(_on_items_state_changed)
	if _selected_state != null and _selected_state.value_changed.is_connected(_on_selected_state_changed):
		_selected_state.value_changed.disconnect(_on_selected_state_changed)


func _connect_all_states() -> void:
	if _items_state != null:
		_items_state.value_changed.connect(_on_items_state_changed)
		_on_items_state_changed(_items_state.get_value(), _items_state.get_value())
	if _selected_state != null:
		_selected_state.value_changed.connect(_on_selected_state_changed)
		_on_selected_state_changed(_selected_state.get_value(), _selected_state.get_value())


## Validates animation targets and filters out invalid ones.
## Called automatically in [method _ready].
func _validate_animation_targets() -> void:
	var trigger_map: Dictionary = UiReactAnimTargetHelper.apply_validated_targets(self, "UiReactItemList")
	UiReactActionTargetHelper.apply_validated_actions_and_merge_triggers(self, "UiReactItemList", trigger_map)

	# Connect signals based on which triggers are used
	if trigger_map.has(UiAnimTarget.Trigger.SELECTION_CHANGED):
		UiReactAnimTargetHelper.connect_if_absent(item_selected, _on_trigger_selection_changed)
	if trigger_map.has(UiAnimTarget.Trigger.HOVER_ENTER):
		UiReactAnimTargetHelper.connect_if_absent(mouse_entered, _on_trigger_hover_enter)
	if trigger_map.has(UiAnimTarget.Trigger.HOVER_EXIT):
		UiReactAnimTargetHelper.connect_if_absent(mouse_exited, _on_trigger_hover_exit)

	UiReactActionTargetHelper.sync_initial_state(self, "UiReactItemList", action_targets)


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
		var res: Resource = ResourceLoader.load(p)
		if res is Texture2D:
			return res as Texture2D
	return null


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
	_bind.updating = true
	clear()
	for entry in new_value as Array:
		_add_item_from_entry(entry)
	_sync_selection_ui_to_state()
	_bind.updating = false
	_clamp_selection_state_if_needed()


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

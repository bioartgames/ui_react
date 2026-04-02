extends ItemList
class_name UiReactItemList

## Two-way binding for selection (see script for value shape). **Assign** [UiIntState] (single-select) or [UiArrayState] (multi-select).
@export var selected_state: UiState
## **Optional** — list row contents from a [UiArrayState] (or assign an [Array] payload).
## Each element is either stringified with [method @GlobalScope.str], or a [Dictionary] with **label** or **text**, and optional **icon** ([Texture2D] or [code]res://[/code] path string).
@export var items_state: UiArrayState

## **Optional** — Inspector-driven tweens (selection, hover). Leave empty for no automatic animations.
@export var animation_targets: Array[UiAnimTarget] = []

const _WARN_SINGLE_SELECT_EXPECT_INT := "UiReactItemList: expected int for single-select selected_state"

var _updating: bool = false
var _is_initializing: bool = true

func _ready() -> void:
	item_selected.connect(_on_item_selected)
	item_activated.connect(_on_item_activated)
	if items_state:
		items_state.value_changed.connect(_on_items_state_changed)
		_on_items_state_changed(items_state.get_value(), items_state.get_value())
	if selected_state:
		selected_state.value_changed.connect(_on_selected_state_changed)
		_on_selected_state_changed(selected_state.get_value(), selected_state.get_value())
	_validate_animation_targets()
	UiReactStateBindingHelper.deferred_finish_initialization(self)

## Validates animation targets and filters out invalid ones.
## Called automatically in [method _ready].
func _validate_animation_targets() -> void:
	var trigger_map: Dictionary = UiReactAnimTargetHelper.apply_validated_targets(self, "UiReactItemList")

	# Connect signals based on which triggers are used
	if trigger_map.has(UiAnimTarget.Trigger.SELECTION_CHANGED):
		UiReactAnimTargetHelper.connect_if_absent(item_selected, _on_trigger_selection_changed)
	if trigger_map.has(UiAnimTarget.Trigger.HOVER_ENTER):
		UiReactAnimTargetHelper.connect_if_absent(mouse_entered, _on_trigger_hover_enter)
	if trigger_map.has(UiAnimTarget.Trigger.HOVER_EXIT):
		UiReactAnimTargetHelper.connect_if_absent(mouse_exited, _on_trigger_hover_exit)

## Finishes initialization, allowing animations to trigger on selection changes.
func _finish_initialization() -> void:
	_is_initializing = false

## Handles SELECTION_CHANGED trigger animations.
func _on_trigger_selection_changed(_index: int) -> void:
	# Skip animations during initialization
	if _is_initializing:
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
	if _updating:
		return
	if not items_state:
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
	_updating = true
	clear()
	for entry in new_value as Array:
		_add_item_from_entry(entry)
	_sync_selection_ui_to_state()
	_updating = false
	_clamp_selection_state_if_needed()


func _sync_selection_ui_to_state() -> void:
	if not selected_state:
		return
	var v: Variant = selected_state.get_value()
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
	if not selected_state:
		return
	var v: Variant = selected_state.get_value()
	if v is int:
		var idx: int = v
		if idx == -1:
			return
		if item_count == 0 or idx < 0 or idx >= item_count:
			selected_state.set_value(-1)
	elif v is Array and select_mode != ItemList.SELECT_SINGLE:
		var filtered: Array = []
		for item in v:
			if item is int:
				var i: int = item
				if i >= 0 and i < item_count:
					filtered.append(i)
		if filtered != v:
			selected_state.set_value(filtered)


func _on_item_selected(_index: int) -> void:
	if not selected_state or _updating:
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

	if selected_state.get_value() == new_value:
		return
	
	_updating = true
	selected_state.set_value(new_value)
	_updating = false

func _on_item_activated(index: int) -> void:
	# Also trigger selection changed on activation
	_on_item_selected(index)

func _on_selected_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _updating:
		return
	
	if new_value is Array:
		if select_mode == ItemList.SELECT_SINGLE:
			push_warning("UiReactItemList: single-select selected_state expects int, not Array")
			return
		var indices: Array[int] = _indices_from_variant_array(new_value)
		_updating = true
		deselect_all()
		for idx in indices:
			select(idx)
		_updating = false
	elif new_value is int:
		if select_mode != ItemList.SELECT_SINGLE:
			return
		var index: int = new_value
		if index < 0:
			_updating = true
			deselect_all()
			_updating = false
			return
		if index >= item_count:
			return
		_updating = true
		deselect_all()
		if index >= 0:
			select(index)
		_updating = false
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

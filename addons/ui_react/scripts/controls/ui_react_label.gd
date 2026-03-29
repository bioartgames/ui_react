extends Label
class_name UiReactLabel

## Two-way binding for displayed text ([String] or nested structures — see [method _as_text]). **Assign** [UiStringState] or [UiArrayState] (composite / nested [UiState] in arrays).
@export var text_state: UiState

## **Optional** — Inspector-driven tweens (text, hover). Leave empty for no automatic animations.
@export var animation_targets: Array[UiAnimTarget] = []

var _updating: bool = false
var _nested_states: Array[UiState] = []
var _is_initializing: bool = true

func _ready() -> void:
	if text_state:
		text_state.value_changed.connect(_on_text_state_changed)
		_on_text_state_changed(text_state.get_value(), text_state.get_value())
	_validate_animation_targets()
	UiReactStateBindingHelper.deferred_finish_initialization(self)

## Validates animation targets and filters out invalid ones.
## Called automatically in [method _ready].
func _validate_animation_targets() -> void:
	var trigger_map: Dictionary = UiReactAnimTargetHelper.apply_validated_targets(self, "UiReactLabel")

	# Connect signals based on which triggers are used
	if trigger_map.has(UiAnimTarget.Trigger.HOVER_ENTER):
		UiReactAnimTargetHelper.connect_if_absent(mouse_entered, _on_trigger_hover_enter)
	if trigger_map.has(UiAnimTarget.Trigger.HOVER_EXIT):
		UiReactAnimTargetHelper.connect_if_absent(mouse_exited, _on_trigger_hover_exit)

## Finishes initialization, allowing animations to trigger on text changes.
func _finish_initialization() -> void:
	_is_initializing = false

## Handles TEXT_CHANGED trigger animations.
func _on_trigger_text_changed(_new_value: Variant, _old_value: Variant) -> void:
	# Skip animations during initialization
	if _is_initializing:
		return
	
	_trigger_animations(UiAnimTarget.Trigger.TEXT_CHANGED)

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

func _on_text_state_changed(new_value: Variant, old_value: Variant) -> void:
	if _updating:
		return
	_rebind_nested_states(new_value)
	var new_text := _as_text(new_value)
	if text == new_text:
		return
	_updating = true

	text = new_text
	
	# Trigger animations if configured
	if animation_targets.size() > 0:
		_on_trigger_text_changed(new_value, old_value)

	_updating = false

func _rebind_nested_states(value: Variant) -> void:
	for s in _nested_states:
		if is_instance_valid(s) and s.value_changed.is_connected(_on_nested_changed):
			s.value_changed.disconnect(_on_nested_changed)
	_nested_states.clear()
	if value is Array:
		for v in value:
			if v is UiState:
				var nested_state: UiState = v
				if not nested_state.value_changed.is_connected(_on_nested_changed):
					nested_state.value_changed.connect(_on_nested_changed)
				_nested_states.append(nested_state)

func _on_nested_changed(_new_value: Variant, _old_value: Variant) -> void:
	if text_state:
		_on_text_state_changed(text_state.get_value(), text_state.get_value())

func _as_text(value: Variant) -> String:
	return UiReactStateBindingHelper.as_text_recursive(value)

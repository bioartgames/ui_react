extends LineEdit
class_name UiReactLineEdit

## Two-way binding for text ([String]). **Assign** for reactive sync.
@export var text_state: UiStringState

## **Optional** — Inspector-driven tweens (text, focus, hover). Leave empty for no automatic animations.
@export var animation_targets: Array[UiAnimTarget] = []

## **Optional** — Action layer presets ([code]docs/ACTION_LAYER.md[/code]).
@export var action_targets: Array[UiReactActionTarget] = []

## **Optional** — Wiring rules ([code]docs/WIRING_LAYER.md[/code] §5).
@export var wire_rules: Array[UiReactWireRule] = []

var _updating: bool = false
var _is_initializing: bool = true

func _ready() -> void:
	text_changed.connect(_on_text_changed)
	if text_state:
		text_state.value_changed.connect(_on_text_state_changed)
		_on_text_state_changed(text_state.get_value(), text_state.get_value())
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	_validate_animation_targets()
	UiReactStateBindingHelper.deferred_finish_initialization(self)

## Validates animation targets and filters out invalid ones.
## Called automatically in [method _ready].
func _validate_animation_targets() -> void:
	var trigger_map: Dictionary = UiReactAnimTargetHelper.apply_validated_targets(self, "UiReactLineEdit")
	UiReactActionTargetHelper.apply_validated_actions_and_merge_triggers(self, "UiReactLineEdit", trigger_map)

	# Connect signals based on which triggers are used
	if trigger_map.has(UiAnimTarget.Trigger.TEXT_ENTERED):
		UiReactAnimTargetHelper.connect_if_absent(text_submitted, _on_trigger_text_entered)
	if trigger_map.has(UiAnimTarget.Trigger.HOVER_ENTER):
		UiReactAnimTargetHelper.connect_if_absent(mouse_entered, _on_trigger_hover_enter)
	if trigger_map.has(UiAnimTarget.Trigger.HOVER_EXIT):
		UiReactAnimTargetHelper.connect_if_absent(mouse_exited, _on_trigger_hover_exit)

## Finishes initialization, allowing animations to trigger on text changes.
func _finish_initialization() -> void:
	_is_initializing = false

## Handles TEXT_CHANGED trigger animations.
func _on_trigger_text_changed(_new_text: String) -> void:
	# Skip animations during initialization
	if _is_initializing:
		return
	
	_trigger_animations(UiAnimTarget.Trigger.TEXT_CHANGED)

## Handles TEXT_ENTERED trigger animations.
func _on_trigger_text_entered(_text: String) -> void:
	_trigger_animations(UiAnimTarget.Trigger.TEXT_ENTERED)

## Handles FOCUS_ENTERED trigger animations.
func _on_focus_entered() -> void:
	_trigger_animations(UiAnimTarget.Trigger.FOCUS_ENTERED)

## Handles FOCUS_EXITED trigger animations.
func _on_focus_exited() -> void:
	_trigger_animations(UiAnimTarget.Trigger.FOCUS_EXITED)

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
	UiReactActionTargetHelper.run_actions(self, "UiReactLineEdit", action_targets, trigger_type)

func _on_text_changed(new_text: String) -> void:
	# Trigger animations / actions if configured
	if animation_targets.size() > 0 or action_targets.size() > 0:
		_on_trigger_text_changed(new_text)
	
	if not text_state or _updating:
		return
	if text_state.get_value() == new_text:
		return
	_updating = true
	text_state.set_value(new_text)
	_updating = false

func _on_text_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _updating:
		return
	var new_text := _to_text(new_value)
	if text == new_text:
		return
	_updating = true
	text = new_text
	_updating = false

func _to_text(value: Variant) -> String:
	return UiReactStateBindingHelper.as_text_flat(value)

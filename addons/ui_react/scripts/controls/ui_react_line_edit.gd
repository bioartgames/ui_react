extends LineEdit
class_name UiReactLineEdit

const _UiReactExitTeardown := preload("res://addons/ui_react/scripts/internal/react/ui_react_control_exit_teardown.gd")

var _bind := UiReactTwoWayBindingDriver.new()
var _local_signal_scope: UiReactSubscriptionScope
var _text_state: UiStringState

## Two-way binding for text ([String]). **Assign** for reactive sync.
@export var text_state: UiStringState:
	get:
		return _text_state
	set(value):
		if _text_state == value:
			return
		if is_node_ready():
			_disconnect_all_states()
		_text_state = value
		if is_node_ready():
			_connect_all_states()

## **Optional** — Inspector-driven tweens (text, focus, hover). Leave empty for no automatic animations.
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
	UiReactHostWireTree.on_enter(self)


func _reactive_teardown() -> void:
	UiReactActionTargetHelper.teardown_for_control_exit(self)
	UiReactFeedbackTargetHelper.teardown_for_control_exit(self)
	_disconnect_local_control_signals()
	_UiReactExitTeardown.teardown_wire_host(
		Callable(self, "_disconnect_all_states"),
		func() -> void: UiReactHostWireTree.on_exit(self)
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
	_local_signal_scope.connect_bound(text_changed, _on_text_changed)
	_local_signal_scope.connect_bound(focus_entered, _on_focus_entered)
	_local_signal_scope.connect_bound(focus_exited, _on_focus_exited)
	_disconnect_all_states()
	_connect_all_states()
	_validate_animation_targets()
	UiReactStateBindingHelper.deferred_finish_initialization(self)


func _disconnect_all_states() -> void:
	if _text_state != null:
		UiReactControlStateWire.unbind_value_changed(self, _text_state, &"text_state", _on_text_state_changed)


func _connect_all_states() -> void:
	if _text_state != null:
		UiReactControlStateWire.bind_value_changed(self, _text_state, &"text_state", _on_text_state_changed)


## Validates animation targets and filters out invalid ones.
## Called automatically in [method _ready].
func _validate_animation_targets() -> void:
	var trigger_map: Dictionary = UiReactAnimTargetHelper.apply_validated_targets(self, "UiReactLineEdit")
	UiReactActionTargetHelper.apply_validated_actions_and_merge_triggers(self, "UiReactLineEdit", trigger_map)
	UiReactFeedbackTargetHelper.apply_validated_audio_and_haptic_and_merge_triggers(
		self, "UiReactLineEdit", trigger_map
	)

	# Connect signals based on which triggers are used
	if trigger_map.has(UiAnimTarget.Trigger.TEXT_ENTERED):
		_local_signal_scope.connect_bound(text_submitted, _on_trigger_text_entered)
	if trigger_map.has(UiAnimTarget.Trigger.HOVER_ENTER):
		_local_signal_scope.connect_bound(mouse_entered, _on_trigger_hover_enter)
	if trigger_map.has(UiAnimTarget.Trigger.HOVER_EXIT):
		_local_signal_scope.connect_bound(mouse_exited, _on_trigger_hover_exit)

	UiReactFeedbackTargetHelper.sync_initial_state(self, "UiReactLineEdit", audio_targets, haptic_targets)


## Finishes initialization, allowing animations to trigger on text changes.
func _finish_initialization() -> void:
	_bind.finish_initialization()


## Handles TEXT_CHANGED trigger animations.
func _on_trigger_text_changed(_new_text: String) -> void:
	# Skip animations during initialization
	if _bind.initializing:
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
	UiReactFeedbackTargetHelper.run_audio_feedback(self, "UiReactLineEdit", audio_targets, trigger_type)
	UiReactFeedbackTargetHelper.run_haptic_feedback(self, "UiReactLineEdit", haptic_targets, trigger_type)


func _on_text_changed(new_text: String) -> void:
	# Trigger animations / actions if configured
	if (
		animation_targets.size() > 0
		or action_targets.size() > 0
		or audio_targets.size() > 0
		or haptic_targets.size() > 0
	):
		_on_trigger_text_changed(new_text)

	if not _text_state or _bind.updating:
		return
	if _text_state.get_value() == new_text:
		return
	_bind.updating = true
	_text_state.set_value(new_text)
	_bind.updating = false


func _on_text_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _bind.updating:
		return
	var new_text := _to_text(new_value)
	if text == new_text:
		return
	_bind.updating = true
	text = new_text
	_bind.updating = false


func _to_text(value: Variant) -> String:
	return UiReactStateBindingHelper.as_text_flat(value)

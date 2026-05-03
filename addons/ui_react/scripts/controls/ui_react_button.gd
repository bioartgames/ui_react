extends Button
class_name UiReactButton

var _bind := UiReactTwoWayBindingDriver.new()
var _pressed_state: UiBoolState
var _disabled_state: UiBoolState
var _reactive: UiReactBaseButtonReactive

## Two-way binding for pressed state ([bool]). **Optional** — omit for a normal Button without external state sync.
@export var pressed_state: UiBoolState:
	get:
		return _pressed_state
	set(value):
		if _pressed_state == value:
			return
		if is_node_ready():
			_lazy_rx().disconnect_all_states()
		_pressed_state = value
		if is_node_ready():
			_lazy_rx().connect_all_states()

## Two-way binding for disabled state ([bool]). **Optional**.
@export var disabled_state: UiBoolState:
	get:
		return _disabled_state
	set(value):
		if _disabled_state == value:
			return
		if is_node_ready():
			_lazy_rx().disconnect_all_states()
		_disabled_state = value
		if is_node_ready():
			_lazy_rx().connect_all_states()

## **Optional** — Inspector-driven tweens (pressed, focus, hover, toggled). Leave empty for no automatic animations.
## Each [UiAnimTarget] sets Trigger, Target NodePath, and animation type; no extra resource files required.
@export var animation_targets: Array[UiAnimTarget] = []

## **Optional** — Action layer ([code]docs/ACTION_LAYER.md[/code]): focus, visibility, [code]mouse_filter[/code], bounded float ops, etc.
@export var action_targets: Array[UiReactActionTarget] = []

## **Optional** — Feedback ([code]docs/FEEDBACK_LAYER.md[/code]): one-shot audio / controller rumble on triggers.
@export var audio_targets: Array[UiReactAudioFeedbackTarget] = []

## **Optional** — Feedback ([code]docs/FEEDBACK_LAYER.md[/code]): [method Input.start_joy_vibration] on triggers.
@export var haptic_targets: Array[UiReactHapticFeedbackTarget] = []

## **Optional** — [UiTransactionalGroup] cohort (Apply/Cancel) via [UiReactTransactionalSession]. Same subresource [member UiReactTransactionalHostBinding.screen] on both buttons when sharing config.
@export var transactional_host: UiReactTransactionalHostBinding


func _lazy_rx() -> UiReactBaseButtonReactive:
	if _reactive == null:
		_reactive = UiReactBaseButtonReactive.new(self, "UiReactButton", _bind, false)
	return _reactive


func _enter_tree() -> void:
	_lazy_rx().on_enter_tree()


func _exit_tree() -> void:
	_lazy_rx().on_exit_tree()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_lazy_rx().on_predelete()


func _ready() -> void:
	_lazy_rx().on_ready()


func _finish_initialization() -> void:
	_lazy_rx().finish_initialization()

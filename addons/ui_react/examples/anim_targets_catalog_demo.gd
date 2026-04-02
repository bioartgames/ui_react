extends Control

## Catalog of every [UiAnimTarget.AnimationAction] plus a trigger playground for every [UiAnimTarget.Trigger].
## See scene layout under [code]HSplit[/code]; preview path must match [member _preview_panel_path].

var _catalog_labels: PackedStringArray = PackedStringArray([
	"EXPAND", "EXPAND_X", "EXPAND_Y", "FADE_IN",
	"SLIDE_FROM_LEFT", "SLIDE_FROM_RIGHT", "SLIDE_FROM_TOP", "SLIDE_FROM_BOTTOM",
	"FROM_LEFT_TO_CENTER", "FROM_RIGHT_TO_CENTER", "FROM_TOP_TO_CENTER", "FROM_BOTTOM_TO_CENTER",
	"BOUNCE_IN", "ELASTIC_IN", "ROTATE_IN", "POP", "PULSE", "SHAKE", "BREATHING", "WOBBLE", "FLOAT",
	"GLOW_PULSE", "COLOR_FLASH", "RESET",
])

const _CATALOG_ACTIONS: Array[UiAnimTarget.AnimationAction] = [
	UiAnimTarget.AnimationAction.EXPAND,
	UiAnimTarget.AnimationAction.EXPAND_X,
	UiAnimTarget.AnimationAction.EXPAND_Y,
	UiAnimTarget.AnimationAction.FADE_IN,
	UiAnimTarget.AnimationAction.SLIDE_FROM_LEFT,
	UiAnimTarget.AnimationAction.SLIDE_FROM_RIGHT,
	UiAnimTarget.AnimationAction.SLIDE_FROM_TOP,
	UiAnimTarget.AnimationAction.SLIDE_FROM_BOTTOM,
	UiAnimTarget.AnimationAction.FROM_LEFT_TO_CENTER,
	UiAnimTarget.AnimationAction.FROM_RIGHT_TO_CENTER,
	UiAnimTarget.AnimationAction.FROM_TOP_TO_CENTER,
	UiAnimTarget.AnimationAction.FROM_BOTTOM_TO_CENTER,
	UiAnimTarget.AnimationAction.BOUNCE_IN,
	UiAnimTarget.AnimationAction.ELASTIC_IN,
	UiAnimTarget.AnimationAction.ROTATE_IN,
	UiAnimTarget.AnimationAction.POP,
	UiAnimTarget.AnimationAction.PULSE,
	UiAnimTarget.AnimationAction.SHAKE,
	UiAnimTarget.AnimationAction.BREATHING,
	UiAnimTarget.AnimationAction.WOBBLE,
	UiAnimTarget.AnimationAction.FLOAT,
	UiAnimTarget.AnimationAction.GLOW_PULSE,
	UiAnimTarget.AnimationAction.COLOR_FLASH,
	UiAnimTarget.AnimationAction.RESET,
]

## Path from this root to [code]%PreviewPanel[/code] (must match scene).
const _PREVIEW_PANEL_PATH := NodePath("HSplit/RightColumn/PreviewPanel")

@export var progress_bar_value_state: UiFloatState

@onready var _catalog_list: ItemList = $HSplit/LeftColumn/CatalogList
@onready var _play_button: Button = $HSplit/LeftColumn/PlayButton
@onready var _reset_button: Button = $HSplit/LeftColumn/ResetButton
@onready var _fire_completed_button: Button = $HSplit/RightColumn/ScrollContainer/PlaygroundVBox/ProgressRow/FireCompletedButton


func _ready() -> void:
	assert(_catalog_labels.size() == _CATALOG_ACTIONS.size())
	for i in _catalog_labels.size():
		_catalog_list.add_item(_catalog_labels[i])
	_catalog_list.select(0)
	_play_button.pressed.connect(_on_play_pressed)
	_reset_button.pressed.connect(_on_manual_reset_pressed)
	_fire_completed_button.pressed.connect(_on_fire_completed_pressed)


func _on_fire_completed_pressed() -> void:
	if progress_bar_value_state:
		progress_bar_value_state.set_value(100.0)


func _on_manual_reset_pressed() -> void:
	await _run_reset_preview()


func _on_play_pressed() -> void:
	var selected: PackedInt32Array = _catalog_list.get_selected_items()
	if selected.is_empty():
		return
	var idx: int = int(selected[0])
	var action: UiAnimTarget.AnimationAction = _CATALOG_ACTIONS[idx]
	await _run_reset_preview()
	if action == UiAnimTarget.AnimationAction.RESET:
		return
	var t := UiAnimTarget.new()
	_configure_catalog_anim(t, action)
	await _await_anim_if_any(t.apply(self))


func _run_reset_preview() -> void:
	var reset_t := UiAnimTarget.new()
	reset_t.animation = UiAnimTarget.AnimationAction.RESET
	reset_t.target = _PREVIEW_PANEL_PATH
	reset_t.duration = UiAnimTarget.RESET_INSTANT_DURATION_SECONDS
	reset_t.easing = UiAnimTarget.Easing.EASE_OUT
	await _await_anim_if_any(reset_t.apply(self))


func _await_anim_if_any(sig: Signal) -> void:
	if sig.is_null():
		return
	await sig


func _configure_catalog_anim(anim: UiAnimTarget, action: UiAnimTarget.AnimationAction) -> void:
	anim.animation = action
	anim.target = _PREVIEW_PANEL_PATH
	anim.trigger = UiAnimTarget.Trigger.PRESSED
	anim.duration = 0.35 if action != UiAnimTarget.AnimationAction.RESET else UiAnimTarget.RESET_INSTANT_DURATION_SECONDS
	anim.easing = UiAnimTarget.Easing.EASE_OUT
	anim.repeat_count = 0
	anim.reverse = false
	anim.pivot_offset = UiAnimConstants.PIVOT_USE_CONTROL_DEFAULT
	match action:
		UiAnimTarget.AnimationAction.ROTATE_IN:
			anim.rotate_start_angle = -360.0
		UiAnimTarget.AnimationAction.POP:
			anim.pop_overshoot = 1.2
		UiAnimTarget.AnimationAction.PULSE:
			anim.pulse_amount = 1.1
			anim.pulse_count = 2
		UiAnimTarget.AnimationAction.SHAKE:
			anim.shake_intensity = 10.0
			anim.shake_count = 5
		UiAnimTarget.AnimationAction.COLOR_FLASH:
			anim.flash_color = Color.YELLOW
			anim.flash_intensity = 1.5
		_:
			pass

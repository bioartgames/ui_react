extends Control

@onready var _texture_button: TextureButton = $VBox/TextureButton
@onready var _pressed_label: Label = $VBox/PressedLabel
@onready var _disabled_label: Label = $VBox/DisabledLabel


func _ready() -> void:
	var ps: UiBoolState = _texture_button.pressed_state
	var ds: UiBoolState = _texture_button.disabled_state
	if ps and not ps.value_changed.is_connected(_refresh_labels):
		ps.value_changed.connect(_refresh_labels)
	if ds and not ds.value_changed.is_connected(_refresh_labels):
		ds.value_changed.connect(_refresh_labels)
	_refresh_labels(null, null)


func _refresh_labels(_a: Variant, _b: Variant) -> void:
	var ps: UiBoolState = _texture_button.pressed_state
	var ds: UiBoolState = _texture_button.disabled_state
	_pressed_label.text = "pressed_state: %s" % (str(ps.get_value()) if ps else "—")
	_disabled_label.text = "disabled_state: %s" % (str(ds.get_value()) if ds else "—")

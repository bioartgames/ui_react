extends Control

## Demonstrates **`UiReactRichTextLabel`**: BBCode comes only from **`text_state`** — never assign **`RichTextLabel.text`** directly when the wrapper is attached.

var _content: UiStringState

@onready var _status: Label = $VBox/StatusLabel
@onready var _rich: RichTextLabel = $VBox/RichBody


func _ready() -> void:
	_content = _rich.get("text_state") as UiStringState
	if _content == null:
		push_error("RichTextLabel must have text_state assigned (UiStringState).")
		return
	_content.value_changed.connect(_on_content_changed)
	_on_content_changed(_content.get_value(), _content.get_value())

	$VBox/Buttons/HeadingButton.pressed.connect(_on_heading_pressed)
	$VBox/Buttons/PlainButton.pressed.connect(_on_plain_pressed)
	$VBox/Buttons/AppendTimeButton.pressed.connect(_on_append_time_pressed)


func _on_content_changed(_new_value: Variant, _old_value: Variant) -> void:
	var raw := str(_content.get_value())
	var preview := raw.substr(0, mini(56, raw.length()))
	preview = preview.replace("\n", " ")
	_status.text = "Raw length: %d | preview: %s%s" % [raw.length(), preview, "…" if raw.length() > 56 else ""]


func _on_heading_pressed() -> void:
	_content.set_value(
		"[font_size=22][b]Reactive heading[/b][/font_size]\nBody with [color=cyan]accent[/color] and [i]italic[/i]."
	)


func _on_plain_pressed() -> void:
	_content.set_value(
		"Plain BBCode line. [i]Italic[/i]. Clock: [code]%s[/code]" % Time.get_time_string_from_system()
	)


func _on_append_time_pressed() -> void:
	var stamp := Time.get_time_string_from_system()
	_content.set_value(str(_content.get_value()) + "\n[right][color=gray]%s[/color][/right]" % stamp)

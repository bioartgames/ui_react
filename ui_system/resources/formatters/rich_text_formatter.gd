## Rich text formatter for BBCode formatting (bold, color, size).
## Used with RichTextLabel components.
@icon("res://icon.svg")
class_name RichTextFormatter
extends TextFormatter

## Whether to apply bold formatting.
@export var bold: bool = false

## Text color (if Color.WHITE, no color tag is applied).
@export var color: Color = Color.WHITE

## Font size (0 means no size tag).
@export var font_size: int = 0

## Formats a value with BBCode rich text formatting.
func format(value: Variant) -> String:
	var text = str(value)
	var result = text
	
	# Apply bold
	if bold:
		result = "[b]" + result + "[/b]"
	
	# Apply color
	if color != Color.WHITE:
		var color_hex = "#%02x%02x%02x" % [int(color.r * 255), int(color.g * 255), int(color.b * 255)]
		result = "[color=" + color_hex + "]" + result + "[/color]"
	
	# Apply font size
	if font_size > 0:
		result = "[font_size=" + str(font_size) + "]" + result + "[/font_size]"
	
	return result


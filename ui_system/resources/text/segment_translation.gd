## Translation segment for i18n support.
## Integrates with Godot's translation system.
@icon("res://icon.svg")
class_name SegmentTranslation
extends TextSegment

## Translation key (e.g., "ui.menu.start").
@export var translation_key: String = ""

## Fallback text if translation is missing.
@export var fallback_text: String = ""

## Returns the translated text using Godot's tr() function.
func build(context: SegmentContext) -> String:
	if translation_key.is_empty():
		return fallback_text
	
	# Use Godot's translation system
	var translated = tr(translation_key)
	
	# If translation is missing (returns key), use fallback
	if translated == translation_key:
		return fallback_text
	
	return translated


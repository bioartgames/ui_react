## A reactive rich text label that binds its content to a State resource with BBCode support.
##
## ReactiveRichTextLabel extends RichTextLabel to automatically update its displayed text
## when a bound State resource changes. Unlike ReactiveLabel, this control supports rich text
## formatting through BBCode tags, allowing for styled and interactive text content.
##
## The text_state property can contain:
## - Simple strings (with BBCode if bbcode_enabled is true)
## - Arrays of text segments for concatenation
## - Dictionaries with styling information (color, bold, italic, size, url, etc.)
## - Nested State objects for reactive sub-components
##
## Animation support is provided through AnimationReel resources, which can trigger on:
## - TEXT_CHANGED: When the text content updates
## - HOVER_ENTER: When mouse enters the control
## - HOVER_EXIT: When mouse exits the control
##
## This control is designed to be a drop-in replacement for RichTextLabel when you need
## reactive data binding with rich text formatting capabilities.
@tool
extends RichTextLabel
class_name ReactiveRichTextLabel

## State resource that drives the rich text content displayed by this label.
##
## The value can be:
## - String: Used directly as BBCode text (if bbcode_enabled is true)
## - Array: Sequence of segments to concatenate (strings, states, dictionaries)
## - Dictionary: Text with styling options (color, bold, italic, size, url, etc.)
## - State: Nested state object (unwrapped recursively)
## - null: Displays empty text
##
## Changes to the state automatically update the label's text property.
@export var text_state: State

## Animation reels to execute based on rich text label events.
##
## Drag AnimationReel resources here in the Inspector. Each reel can specify its trigger type
## (text changed, hover enter/exit), target controls to animate, and animation clips
## to execute. Supports automatic execution modes: single, multi-target, and sequences.
@export var animations: Array[AnimationReel] = []

var _updating: bool = false
var _nested_states: Array[State] = []
var _is_initializing: bool = true

## Initializes the reactive rich text label.
##
## In editor mode: Only validates animation reels to enable trigger filtering in the Inspector.
## At runtime: Binds to text_state changes, performs initial text sync, validates animation reels,
## and schedules initialization completion to allow animations to trigger after setup.
func _ready() -> void:
	if Engine.is_editor_hint():
		# In the editor, only validate reels so trigger options are filtered.
		_validate_animation_reels()
		return

	if text_state:
		text_state.value_changed.connect(_on_text_state_changed)
		_on_text_state_changed(text_state.value, text_state.value)

	_validate_animation_reels()
	# Finish initialization after all signals are processed
	call_deferred("_finish_initialization")

## Validates animation reels and filters out invalid ones.
## Called automatically in [method _ready].
##
## Sets the control type context on each reel for Inspector filtering and connects
## hover signals based on which animation triggers are actually used.
func _validate_animation_reels() -> void:
	var result = AnimationReel.validate_for_control(self, animations)
	animations = result.valid_reels

	# Set control context on each reel for Inspector filtering
	var control_type = _get_control_type_hint()
	for reel in animations:
		if reel:
			reel.control_type_context = control_type

	# Control-specific signal connections (stays in class)
	var has_hover_enter_targets = result.trigger_map.get(AnimationReel.Trigger.HOVER_ENTER, false)
	var has_hover_exit_targets = result.trigger_map.get(AnimationReel.Trigger.HOVER_EXIT, false)

	# Connect signals based on which triggers are used
	if has_hover_enter_targets:
		if not mouse_entered.is_connected(_on_trigger_hover_enter):
			mouse_entered.connect(_on_trigger_hover_enter)
	if has_hover_exit_targets:
		if not mouse_exited.is_connected(_on_trigger_hover_exit):
			mouse_exited.connect(_on_trigger_hover_exit)

## Finishes initialization, allowing animations to trigger on text changes.
##
## Called via call_deferred in _ready() to ensure all setup is complete before
## enabling animation triggers during state changes.
func _finish_initialization() -> void:
	_is_initializing = false

## Handles TEXT_CHANGED trigger animations.
##
## Called when text_state changes and animations are configured.
## Skips animations during initialization to prevent unwanted effects on startup.
func _on_trigger_text_changed(_new_value: Variant, _old_value: Variant) -> void:
	# Skip animations during initialization
	if _is_initializing:
		return

	_trigger_animations(AnimationReel.Trigger.TEXT_CHANGED)

## Handles HOVER_ENTER trigger animations.
##
## Called when the mouse enters the control area and hover animations are configured.
func _on_trigger_hover_enter() -> void:
	_trigger_animations(AnimationReel.Trigger.HOVER_ENTER)

## Handles HOVER_EXIT trigger animations.
##
## Called when the mouse exits the control area and hover animations are configured.
func _on_trigger_hover_exit() -> void:
	_trigger_animations(AnimationReel.Trigger.HOVER_EXIT)

## Triggers animations for reels matching the specified trigger type.
##
## Iterates through all configured animation reels and executes those
## that match the given trigger type on this control.
##
## [param trigger_type]: The AnimationReel.Trigger enum value to match.
func _trigger_animations(trigger_type) -> void:
	if animations.size() == 0:
		return

	# Apply animations for reels matching this trigger
	for reel in animations:
		if reel == null:
			continue

		if reel.trigger != trigger_type:
			continue

		# Note: respect_disabled is now per-clip, not per-reel
		reel.apply(self)

## Handles changes to the text_state value.
##
## Converts the new value to rich text, updates the label's text property,
## and triggers TEXT_CHANGED animations if configured. Uses the _updating flag
## to prevent recursive updates and only updates when the text actually changes.
##
## [param new_value]: The new value from text_state
## [param old_value]: The previous value from text_state
func _on_text_state_changed(new_value: Variant, old_value: Variant) -> void:
	if _updating:
		return
	_rebind_nested_states(new_value)
	var new_text := _to_rich_text(new_value)
	if text == new_text:
		return
	_updating = true

	text = new_text

	# Trigger animations if configured
	if animations.size() > 0:
		_on_trigger_text_changed(new_value, old_value)

	_updating = false

## Manages connections to nested State objects within the text_state value.
##
## Disconnects from previously tracked states, clears the tracking list,
## and establishes new connections for any State objects found in arrays
## or dictionary text fields. This enables reactive updates when nested
## states change.
##
## [param value]: The current text_state.value to scan for nested states
func _rebind_nested_states(value: Variant) -> void:
	for s in _nested_states:
		if is_instance_valid(s) and s.value_changed.is_connected(_on_nested_changed):
			s.value_changed.disconnect(_on_nested_changed)
	_nested_states.clear()
	if value is Array:
		for v in value:
			if v is State:
				var st: State = v
				if not st.value_changed.is_connected(_on_nested_changed):
					st.value_changed.connect(_on_nested_changed)
				_nested_states.append(st)
			elif v is Dictionary:
				# Check if the dictionary contains a "text" field that is a State
				if v.has("text") and v["text"] is State:
					var st: State = v["text"]
					if not st.value_changed.is_connected(_on_nested_changed):
						st.value_changed.connect(_on_nested_changed)
					_nested_states.append(st)
			elif v is Dictionary:
				# Check if the dictionary contains a "text" field that is a State
				if v.has("text") and v["text"] is State:
					var st: State = v["text"]
					if not st.value_changed.is_connected(_on_nested_changed):
						st.value_changed.connect(_on_nested_changed)
					_nested_states.append(st)

## Handles changes to nested State objects within the text_state value.
##
## Called when any tracked nested state changes. Triggers a full re-evaluation
## of the text_state to update the displayed rich text with the new nested values.
func _on_nested_changed(_new_value: Variant, _old_value: Variant) -> void:
	if text_state:
		_on_text_state_changed(text_state.value, text_state.value)

## Converts a value to rich text with BBCode formatting.
##
## Supported value shapes for `text_state.value`:
##
## 1. **`null`**: Produces an empty string.
##
## 2. **`String`**: Used directly as the `text` for the `RichTextLabel`.
##    Assumes `bbcode_enabled = true` on the `RichTextLabel` if the user wants BBCode.
##    The control does not escape or sanitize the string.
##
## 3. **`State`**: Treated as nested, and unwrapped by recursively calling `_to_rich_text(value.value)`.
##
## 4. **`Array`**: Treated as a sequence of segments to be concatenated.
##    Each element `segment` is interpreted as:
##    - If `segment` is a `State`: Process as `_to_rich_text(segment.value)` recursively.
##    - If `segment` is a `String`: Treated as a literal text segment (BBCode allowed).
##    - If `segment` is a `Dictionary`: See below.
##    - Any other type: Fall back to `str(segment)` and treat as plain text.
##
## 5. **`Dictionary`**: Dictionary-based segment with optional styling.
##    Must contain at least the key `"text"`.
##    `"text"` can be: `String`, `State`, or `Array` (recursively processed by `_to_rich_text`).
##    Optional formatting keys:
##    - `"bold": bool`
##    - `"italic": bool`
##    - `"underline": bool`
##    - `"color": Color` or `String` (hex code like `"#ff0000"`)
##    - `"size": int` (font size; used with `[size]` tags)
##    - `"url": String` (to wrap text in `[url]` tags)
##
##    Formatting is applied by wrapping the rendered text in BBCode tags in the following
##    fixed nesting order (outermost first):
##    1. `[url]` / `[/url]`
##    2. `[color]` / `[/color]`
##    3. `[size]` / `[/size]`
##    4. `[b]` / `[/b]`
##    5. `[i]` / `[/i]`
##    6. `[u]` / `[/u]`
##
##    Any keys not listed above are ignored (no effect).
##
## 6. **Other scalar types (int, float, bool, etc.)**: Converted via `str(value)` and treated as plain text.
func _to_rich_text(value: Variant) -> String:
	if value is State:
		return _to_rich_text(value.value)
	if value is Array:
		var parts: Array[String] = []
		for v in value:
			parts.append(_to_rich_text(v))
		return "".join(parts)
	if value is Dictionary:
		# Dictionary-based segment with optional styling
		var segment_text = ""
		var bbcode_parts: Array[String] = ["", ""]  # [open_tags, close_tags]

		# Extract text content
		if value.has("text"):
			segment_text = _to_rich_text(value["text"])

		# Apply styling in the fixed nesting order (outermost first)

		# 1. URL (outermost)
		if value.has("url") and value["url"] is String and not value["url"].is_empty():
			bbcode_parts[0] += "[url=" + value["url"] + "]"
			bbcode_parts[1] = "[/url]" + bbcode_parts[1]

		# 2. Color
		if value.has("color"):
			var color_str = ""
			if value["color"] is Color:
				color_str = value["color"].to_html(false)
			elif value["color"] is String:
				color_str = value["color"]  # Assumed valid hex code
			if not color_str.is_empty():
				bbcode_parts[0] += "[color=" + color_str + "]"
				bbcode_parts[1] = "[/color]" + bbcode_parts[1]

		# 3. Size
		if value.has("size") and value["size"] is int and value["size"] > 0:
			bbcode_parts[0] += "[size=" + str(value["size"]) + "]"
			bbcode_parts[1] = "[/size]" + bbcode_parts[1]

		# 4. Bold
		if value.get("bold", false) == true:
			bbcode_parts[0] += "[b]"
			bbcode_parts[1] = "[/b]" + bbcode_parts[1]

		# 5. Italic
		if value.get("italic", false) == true:
			bbcode_parts[0] += "[i]"
			bbcode_parts[1] = "[/i]" + bbcode_parts[1]

		# 6. Underline (innermost)
		if value.get("underline", false) == true:
			bbcode_parts[0] += "[u]"
			bbcode_parts[1] = "[/u]" + bbcode_parts[1]

		return bbcode_parts[0] + segment_text + bbcode_parts[1]

	return str(value)

## Gets the control type hint for this reactive control.
##
## Used to filter available animation triggers in the Inspector dropdown.
## Returns LABEL to show only text_changed and hover triggers for rich text labels.
func _get_control_type_hint() -> AnimationReel.ControlTypeHint:
	return AnimationReel.ControlTypeHint.LABEL

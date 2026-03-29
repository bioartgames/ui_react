## Editor theme overrides for the Ui React dock (static helpers).
class_name UiReactDockTheme
extends Object


static func editor_theme(plugin: EditorPlugin) -> Theme:
	if plugin == null:
		return null
	return plugin.get_editor_interface().get_editor_theme()


static func apply_richtext_content(rtl: RichTextLabel, plugin: EditorPlugin) -> void:
	var t := editor_theme(plugin)
	if t == null:
		return
	if t.has_color(&"default_color", &"RichTextLabel"):
		rtl.add_theme_color_override(&"default_color", t.get_color(&"default_color", &"RichTextLabel"))
	elif t.has_color(&"font_color", &"Label"):
		rtl.add_theme_color_override(&"default_color", t.get_color(&"font_color", &"Label"))
	if t.has_font_size(&"normal_font_size", &"RichTextLabel"):
		rtl.add_theme_font_size_override(
			&"normal_font_size", t.get_font_size(&"normal_font_size", &"RichTextLabel")
		)


static func apply_panelcontainer(panel: PanelContainer, plugin: EditorPlugin) -> void:
	var t := editor_theme(plugin)
	if t == null:
		return
	if t.has_stylebox(&"panel", &"PanelContainer"):
		panel.add_theme_stylebox_override(&"panel", t.get_stylebox(&"panel", &"PanelContainer"))


static func apply_split_bar(split: SplitContainer, plugin: EditorPlugin) -> void:
	var t := editor_theme(plugin)
	if t == null:
		return
	if t.has_stylebox(&"split_bar_background", &"SplitContainer"):
		split.add_theme_stylebox_override(
			&"split_bar_background", t.get_stylebox(&"split_bar_background", &"SplitContainer")
		)
		return
	var sb := StyleBoxFlat.new()
	var col := Color(0.42, 0.45, 0.52, 1.0)
	if t.has_color(&"contrast_1", &"Editor"):
		col = t.get_color(&"contrast_1", &"Editor")
	sb.bg_color = col
	sb.set_corner_radius_all(2)
	split.add_theme_stylebox_override(&"split_bar_background", sb)

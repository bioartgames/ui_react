## Dynamic tab list sync from a [UiState] holding an [Array] of tab descriptors.
class_name UiTabCollectionSync
extends RefCounted

## Applies tab data from [param tabs_array]. Returns a new [param _previous_tab_index] value when it must be synced, else [code]null[/code].
static func apply_tabs_from_array(tab_container: TabContainer, tabs_array: Array, tab_config: UiTabContainerCfg) -> Variant:
	var current_count = tab_container.get_tab_count()
	var new_count = tabs_array.size()

	if new_count < current_count:
		for i in range(current_count - 1, new_count - 1, -1):
			var child = tab_container.get_tab_control(i)
			if child:
				tab_container.remove_child(child)
				child.queue_free()

	for i in range(new_count):
		var tab_data = tabs_array[i]
		var tab_title: String = ""
		var tab_icon: Texture2D = null

		if tab_data is Dictionary:
			tab_title = tab_data.get("title", "")
			tab_icon = tab_data.get("icon", null)
		elif tab_data is String:
			tab_title = tab_data
		else:
			tab_title = str(tab_data)

		if i < current_count:
			tab_container.set_tab_title(i, tab_title)
			if tab_icon:
				tab_container.set_tab_icon(i, tab_icon)
		else:
			var child = Control.new()
			child.name = "Tab%d" % i
			tab_container.add_child(child)
			tab_container.set_tab_title(i, tab_title)
			if tab_icon:
				tab_container.set_tab_icon(i, tab_icon)

	if tab_container.current_tab >= new_count and new_count > 0:
		tab_container.current_tab = new_count - 1
		return tab_container.current_tab
	if tab_container.current_tab < 0 and new_count > 0:
		tab_container.current_tab = 0
		return 0

	if tab_config and tab_config.tab_content_states.size() < new_count:
		tab_config.tab_content_states.resize(new_count)

	return null

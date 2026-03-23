## Resolves external [State] values to tab indices for [TabContainer].
class_name TabSelectionBinding
extends RefCounted

static func resolve_tab_index(tab_container: TabContainer, new_value: Variant) -> int:
	var index := -1
	if new_value is int:
		index = int(new_value)
	elif new_value is String:
		for i in tab_container.get_tab_count():
			if tab_container.get_tab_title(i) == new_value:
				index = i
				break
	return index

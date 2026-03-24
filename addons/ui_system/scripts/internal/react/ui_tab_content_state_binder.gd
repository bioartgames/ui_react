## Binds per-tab [UiState] resources to reactive controls inside tab pages.
class_name UiTabContentStateBinder
extends RefCounted

const PROP_TEXT_STATE: StringName = &"text_state"
const PROP_VALUE_STATE: StringName = &"value_state"
const PROP_SELECTED_STATE: StringName = &"selected_state"
const PROP_CHECKED_STATE: StringName = &"checked_state"
const PROP_PRESSED_STATE: StringName = &"pressed_state"
const CHILD_PROPERTY_PREFIX: StringName = &"child_"

const STATE_PROPERTIES: Array[StringName] = [
	PROP_TEXT_STATE,
	PROP_VALUE_STATE,
	PROP_SELECTED_STATE,
	PROP_CHECKED_STATE,
	PROP_PRESSED_STATE,
]

static func bind_tab_content(tab_container: TabContainer, tab_config: UiTabContainerCfg, tab_index: int, on_content_changed: Callable) -> void:
	if not tab_config:
		return
	if tab_index < 0 or tab_index >= tab_config.tab_content_states.size():
		return

	var content_state = tab_config.tab_content_states[tab_index]
	if content_state == null:
		return

	var tab_child = tab_container.get_tab_control(tab_index)
	if tab_child == null:
		return

	for prop in STATE_PROPERTIES:
		if tab_child.has(prop):
			var child_state = tab_child.get(prop)
			if child_state is UiState:
				child_state.set_silent(content_state.value)
				var callable = on_content_changed.bind(tab_index, prop)
				if content_state.value_changed.is_connected(callable):
					content_state.value_changed.disconnect(callable)
				content_state.value_changed.connect(callable)
				return

	var first_child = tab_child.get_child(0) if tab_child.get_child_count() > 0 else null
	if first_child != null:
		for prop in STATE_PROPERTIES:
			if first_child.has(prop):
				var child_state = first_child.get(prop)
				if child_state is UiState:
					child_state.set_silent(content_state.value)
					var child_prop_key: StringName = StringName(String(CHILD_PROPERTY_PREFIX) + String(prop))
					var callable = on_content_changed.bind(tab_index, child_prop_key)
					if content_state.value_changed.is_connected(callable):
						content_state.value_changed.disconnect(callable)
					content_state.value_changed.connect(callable)
					return

static func propagate_content_change(tab_container: TabContainer, tab_index: int, property: StringName, new_value: Variant) -> void:
	var tab_child = tab_container.get_tab_control(tab_index)
	if tab_child == null:
		return

	var prop_str: String = String(property)
	if prop_str.begins_with(String(CHILD_PROPERTY_PREFIX)):
		var actual_prop = prop_str.substr(String(CHILD_PROPERTY_PREFIX).length())
		var first_child = tab_child.get_child(0) if tab_child.get_child_count() > 0 else null
		if first_child != null and first_child.has(StringName(actual_prop)):
			var child_state = first_child.get(StringName(actual_prop))
			if child_state is UiState:
				child_state.set_silent(new_value)
	else:
		if tab_child.has(property):
			var child_state = tab_child.get(property)
			if child_state is UiState:
				child_state.set_silent(new_value)

## Helper class for managing reactive tab container state and operations.
##
## Extracted from ReactiveTabContainer to separate concerns and improve maintainability.
## This class handles the complex logic for dynamic tab management, content binding,
## and state synchronization while keeping the main ReactiveTabContainer focused
## on control-specific behavior.
##
## Key responsibilities:
## - Dynamic tab creation, removal, and updates based on state changes
## - Automatic content binding for tab children to State resources
## - Tab enable/disable and visibility management
## - Reflection-based property discovery for flexible content binding
class_name TabContainerHelper

## Reference to the TabContainer being managed.
var _owner: TabContainer
## Reference to the configuration resource containing state bindings.
var _tab_config: TabContainerConfig

## Creates a new TabContainerHelper for managing the specified tab container.
## [param owner]: The TabContainer control to manage.
## [param tab_config]: The TabContainerConfig resource containing state bindings.
func _init(owner: TabContainer, tab_config: TabContainerConfig) -> void:
	_owner = owner
	_tab_config = tab_config

## Updates the tab container's tabs based on the provided array of tab data.
## This method handles dynamic tab management by comparing the current tab count
## with the new array and adding, removing, or updating tabs as necessary.
##
## Supported tab data formats:
## - Dictionary: {"title": "Tab Name", "icon": Texture2D}
## - String: "Tab Name" (icon will be null)
## - Other types: converted to string
##
## [param tabs_array]: Array of tab data (Dictionary, String, or convertible types).
func update_tabs_from_state(tabs_array: Array) -> void:
	var current_count = _owner.get_tab_count()
	var new_count = tabs_array.size()

	# Remove excess tabs (remove from end)
	if new_count < current_count:
		for i in range(current_count - 1, new_count - 1, -1):
			var child = _owner.get_tab_control(i)
			if child:
				_owner.remove_child(child)
				child.queue_free()

	# Add or update tabs
	for i in range(new_count):
		var tab_data = tabs_array[i]
		var tab_title: String = ""
		var tab_icon: Texture2D = null

		# Handle different data formats
		if tab_data is Dictionary:
			tab_title = tab_data.get("title", "")
			tab_icon = tab_data.get("icon", null)
		elif tab_data is String:
			tab_title = tab_data
		else:
			tab_title = str(tab_data)

		# Update existing tab or create new one
		if i < current_count:
			# Update existing tab
			_owner.set_tab_title(i, tab_title)
			if tab_icon:
				_owner.set_tab_icon(i, tab_icon)
		else:
			# Create new tab (TabContainer creates tabs for child nodes)
			# Create a placeholder Control if needed
			var child = Control.new()
			child.name = "Tab%d" % i
			_owner.add_child(child)
			_owner.set_tab_title(i, tab_title)
			if tab_icon:
				_owner.set_tab_icon(i, tab_icon)

	# Validate current_tab is still valid
	if _owner.current_tab >= new_count and new_count > 0:
		_owner.current_tab = new_count - 1
	elif _owner.current_tab < 0 and new_count > 0:
		_owner.current_tab = 0

	# Resize tab_content_states array to match tab count if needed
	if _tab_config and _tab_config.tab_content_states.size() < new_count:
		_tab_config.tab_content_states.resize(new_count)

## Binds the content of the specified tab to its corresponding State resource.
## This method automatically discovers State properties on the tab's child control
## and connects them to the appropriate State from the tab configuration.
##
## The method searches for common state property patterns:
## - Direct properties: text_state, value_state, selected_state, checked_state, pressed_state
## - Child properties: first child of the tab (for nested reactive controls)
##
## [param tab_index]: The index of the tab whose content should be bound.
func bind_tab_content_state(tab_index: int) -> void:
	if not _tab_config or tab_index < 0 or tab_index >= _tab_config.tab_content_states.size():
		return

	var content_state = _tab_config.tab_content_states[tab_index]
	if content_state == null:
		return

	# Get the tab's child control
	var tab_child = _owner.get_tab_control(tab_index)
	if tab_child == null:
		return

	# Try to find a State property in the child
	# Use reflection to find state properties dynamically
	var state_properties = _get_state_properties(tab_child)
	for prop in state_properties:
		if tab_child.has_method("set"):  # Check if property exists
			var child_state = tab_child.get(prop)
			if child_state is State:
				# Update the child's State with the content State's value
				child_state.set_silent(content_state.value)
				# Connect for future updates (disconnect first to avoid duplicates)
				var callable = _owner._on_tab_content_state_changed.bind(tab_index, prop)
				if content_state.value_changed.is_connected(callable):
					content_state.value_changed.disconnect(callable)
				content_state.value_changed.connect(callable)
				return  # Found and bound, exit

	# Also check direct children for reactive controls (first child only)
	var first_child = tab_child.get_child(0) if tab_child.get_child_count() > 0 else null
	if first_child != null:
		var child_state_properties = _get_state_properties(first_child)
		for prop in child_state_properties:
			if first_child.has_method("set"):
				var child_state = first_child.get(prop)
				if child_state is State:
					child_state.set_silent(content_state.value)
					var callable = _owner._on_tab_content_state_changed.bind(tab_index, "child_" + prop)
					if content_state.value_changed.is_connected(callable):
						content_state.value_changed.disconnect(callable)
					content_state.value_changed.connect(callable)
					return

## Discovers State properties on a control using reflection.
## This method uses Godot's property system to find all properties that end with "_state"
## and could potentially contain State resources. This provides flexible, dynamic binding
## without hard-coding specific property names.
##
## [param control]: The control to inspect for state properties.
## [return]: Array of property names that are likely State resources.
func _get_state_properties(control: Control) -> Array[String]:
	var properties: Array[String] = []

	# Common state property patterns
	var common_patterns = ["text_state", "value_state", "selected_state", "checked_state", "pressed_state"]

	# Check for common patterns first
	for pattern in common_patterns:
		if control.get_property_list().any(func(p): return p.name == pattern):
			properties.append(pattern)

	# Also check for any property ending with "_state" using reflection
	var property_list = control.get_property_list()
	for prop in property_list:
		var prop_name = prop.name
		if prop_name.ends_with("_state") and not properties.has(prop_name):
			properties.append(prop_name)

	return properties

## Updates the enabled/disabled state of tabs based on the provided array.
## Each element in the array corresponds to a tab index, with true meaning disabled.
##
## [param disabled_array]: Array of booleans indicating which tabs should be disabled.
func update_disabled_tabs(disabled_array: Array) -> void:
	if not disabled_array is Array:
		return

	for i in range(min(_owner.get_tab_count(), disabled_array.size())):
		var should_be_disabled = disabled_array[i] if i < disabled_array.size() else false
		_owner.set_tab_disabled(i, should_be_disabled)

## Updates the visibility of tabs based on the provided array.
## Each element in the array corresponds to a tab index, with true meaning visible.
##
## [param visible_array]: Array of booleans indicating which tabs should be visible.
func update_visible_tabs(visible_array: Array) -> void:
	if not visible_array is Array:
		return

	for i in range(min(_owner.get_tab_count(), visible_array.size())):
		var should_be_visible = visible_array[i] if i < visible_array.size() else true
		_owner.set_tab_hidden(i, not should_be_visible)

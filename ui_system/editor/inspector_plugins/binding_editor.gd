## Custom inspector plugin for unified binding configuration.
## Provides visual interface with auto-detection and status indicators.
@tool
extends EditorInspectorPlugin

func _can_handle(object: Variant) -> bool:
	return object is ReactiveBinding

func _parse_property(object: Variant, _type: Variant.Type, name: String, _hint_type: PropertyHint, _hint_string: String, _usage_flags: PropertyUsageFlags, _wide: bool) -> bool:
	if name == "status":
		# Use custom editor for status display
		var editor = BindingEditor.new()
		editor.setup(name)
		add_property_editor(name, editor)
		return true
	elif name == "control_property":
		# Use custom editor with dropdown for properties
		var editor = ControlPropertyEditor.new()
		editor.setup(name, object as ReactiveBinding)
		add_property_editor(name, editor)
		return true
	elif name == "control_signal":
		# Use custom editor with dropdown for signals (only show if TWO_WAY)
		var binding = object as ReactiveBinding
		if binding.mode == ReactiveBinding.BindingMode.TWO_WAY:
			var editor = ControlSignalEditor.new()
			editor.setup(name, binding)
			add_property_editor(name, editor)
			return true
	return false

## Custom property editor for binding configuration.
class BindingEditor:
	extends EditorProperty
	
	var _binding: ReactiveBinding = null
	var _container: VBoxContainer
	var _status_label: Label
	var _property_name: String = ""
	
	func setup(property_name: String) -> void:
		_property_name = property_name
	
	func _init() -> void:
		_container = VBoxContainer.new()
		add_child(_container)
		
		_status_label = Label.new()
		_status_label.add_theme_color_override("font_color", Color.YELLOW)
		_container.add_child(_status_label)
	
	func _update_property() -> void:
		_binding = get_edited_object() as ReactiveBinding
		if _binding == null:
			return
		
		_update_status_display()
	
	func _update_status_display() -> void:
		if _binding == null:
			return
		
		var status = _binding.status
		var status_text = ""
		var status_color = Color.WHITE
		
		match status:
			BindingStatus.Status.CONNECTED:
				status_text = "✓ Connected"
				status_color = Color.GREEN
			BindingStatus.Status.ERROR_INVALID_PATH:
				status_text = "✗ Error: Invalid Control Path"
				status_color = Color.RED
			BindingStatus.Status.ERROR_INVALID_PROPERTY:
				status_text = "✗ Error: Invalid Property"
				status_color = Color.RED
			BindingStatus.Status.ERROR_INVALID_SIGNAL:
				status_text = "✗ Error: Invalid Signal"
				status_color = Color.RED
			BindingStatus.Status.ERROR_TYPE_MISMATCH:
				status_text = "✗ Error: Type Mismatch"
				status_color = Color.RED
			BindingStatus.Status.DISCONNECTED:
				status_text = "○ Disconnected"
				status_color = Color.YELLOW
		
		_status_label.text = status_text
		_status_label.add_theme_color_override("font_color", status_color)

## Custom property editor for control property dropdown.
class ControlPropertyEditor:
	extends EditorProperty
	
	var _binding: ReactiveBinding = null
	var _picker: OptionButton
	var _last_control_path: NodePath = NodePath("")
	var _properties_loaded: bool = false
	
	func setup(_property_name: String, binding: ReactiveBinding) -> void:
		_binding = binding
		# Build dropdown list initially
		_build_properties_list()
	
	func _init() -> void:
		_picker = OptionButton.new()
		_picker.add_item("(Select Property)")
		add_child(_picker)
		add_focusable(_picker)
		_picker.item_selected.connect(_on_item_selected)
	
	func _build_properties_list() -> void:
		# Temporarily disconnect to prevent signal loops
		if _picker.item_selected.is_connected(_on_item_selected):
			_picker.item_selected.disconnect(_on_item_selected)
		
		_picker.clear()
		_picker.add_item("(Select Property)")
		_properties_loaded = false
		
		if _binding == null:
			_picker.add_item("(Error: Binding not set)")
			_reconnect_signal()
			return
		
		# Get owner control from owner_path
		var owner_control = _get_owner_control()
		if owner_control == null:
			_picker.add_item("(Error: Owner not found)")
			_reconnect_signal()
			return
		
		# Get target control
		var target = _get_target_control(owner_control)
		if target == null:
			_picker.add_item("(Error: Target not found - check control_path)")
			_reconnect_signal()
			return
		
		# Store the control_path we used for this list
		_last_control_path = _binding.control_path
		
		# Get available properties using ControlInspector
		var properties = ControlInspector.get_available_properties(target)
		
		for prop in properties:
			_picker.add_item(prop)
		
		_properties_loaded = true
		_reconnect_signal()
		
		# Update selection to match current property value
		_update_selection()
	
	func _update_selection() -> void:
		if not _properties_loaded or _binding == null:
			return
		
		var current_property = _binding.control_property
		if current_property.is_empty():
			_picker.selected = 0
			return
		
		# Find and select the current property
		for i in range(1, _picker.get_item_count()):
			if _picker.get_item_text(i) == current_property:
				_picker.selected = i
				return
		
		# Property not found in list
		_picker.selected = 0
	
	func _get_owner_control() -> Control:
		if _binding == null:
			return null
		
		# First try owner_path if it's set
		if not (_binding.owner_path == null or _binding.owner_path.is_empty()):
			var edited_scene = EditorInterface.get_edited_scene_root()
			if edited_scene != null:
				var owner = edited_scene.get_node_or_null(_binding.owner_path) as Control
				if owner != null:
					return owner
		
		# If owner_path not set, search for ReactiveControls that contain this binding
		# This handles the case where bindings are edited in the inspector before owner_path is set
		var edited_scene = EditorInterface.get_edited_scene_root()
		if edited_scene == null:
			return null
		
		# Search for ReactiveControls that have this binding
		var queue = [edited_scene]
		while not queue.is_empty():
			var node = queue.pop_front()
			
			if node is ReactiveControl:
				var control = node as ReactiveControl
				# Check if this binding is in the control's bindings array
				if _binding in control.bindings:
					return control
			
			# Add children to queue
			for child in node.get_children():
				queue.append(child)
		
		return null
	
	func _get_target_control(owner_control: Control) -> Control:
		if _binding == null or owner_control == null:
			return null
		
		var target_path = _binding.control_path
		
		if target_path == null or target_path.is_empty() or target_path == NodePath("."):
			return owner_control
		
		# Try to resolve the target
		var target = owner_control.get_node_or_null(target_path) as Control
		if target == null:
			# Try absolute path as fallback
			var edited_scene = EditorInterface.get_edited_scene_root()
			if edited_scene != null:
				target = edited_scene.get_node_or_null(target_path) as Control
		
		return target
	
	func _reconnect_signal() -> void:
		# Reconnect signal after refresh
		if not _picker.item_selected.is_connected(_on_item_selected):
			_picker.item_selected.connect(_on_item_selected)
	
	func _update_property() -> void:
		_binding = get_edited_object() as ReactiveBinding
		if _binding == null:
			return
		
		# Check if control_path changed - if so, rebuild the list
		if _binding.control_path != _last_control_path:
			_build_properties_list()
		else:
			# Only update selection, don't rebuild the list
			_update_selection()
	
	func _on_item_selected(index: int) -> void:
		var property_name = get_edited_property()
		if index == 0:
			emit_changed(property_name, "")
		else:
			var selected_property = _picker.get_item_text(index)
			emit_changed(property_name, selected_property)

## Custom property editor for control signal dropdown.
class ControlSignalEditor:
	extends EditorProperty
	
	var _binding: ReactiveBinding = null
	var _picker: OptionButton
	var _last_control_path: NodePath = NodePath("")
	var _signals_loaded: bool = false
	
	func setup(_property_name: String, binding: ReactiveBinding) -> void:
		_binding = binding
		# Build dropdown list initially
		_build_signals_list()
	
	func _init() -> void:
		_picker = OptionButton.new()
		_picker.add_item("(Select Signal)")
		add_child(_picker)
		add_focusable(_picker)
		_picker.item_selected.connect(_on_item_selected)
	
	func _build_signals_list() -> void:
		# Temporarily disconnect to prevent signal loops
		if _picker.item_selected.is_connected(_on_item_selected):
			_picker.item_selected.disconnect(_on_item_selected)
		
		_picker.clear()
		_picker.add_item("(Select Signal)")
		_signals_loaded = false
		
		if _binding == null:
			_picker.add_item("(Error: Binding not set)")
			_reconnect_signal()
			return
		
		# Get owner control from owner_path
		var owner_control = _get_owner_control()
		if owner_control == null:
			_picker.add_item("(Error: Owner not found)")
			_reconnect_signal()
			return
		
		# Get target control
		var target = _get_target_control(owner_control)
		if target == null:
			_picker.add_item("(Error: Target not found - check control_path)")
			_reconnect_signal()
			return
		
		# Store the control_path we used for this list
		_last_control_path = _binding.control_path
		
		# Get available signals using ControlInspector
		var signals = ControlInspector.get_available_signals(target)
		for sig in signals:
			_picker.add_item(sig)
		
		_signals_loaded = true
		_reconnect_signal()
		
		# Update selection to match current signal value
		_update_selection()
	
	func _update_selection() -> void:
		if not _signals_loaded or _binding == null:
			return
		
		var current_signal = _binding.control_signal
		if current_signal.is_empty():
			_picker.selected = 0
			return
		
		# Find and select the current signal
		for i in range(1, _picker.get_item_count()):
			if _picker.get_item_text(i) == current_signal:
				_picker.selected = i
				return
		
		# Signal not found in list
		_picker.selected = 0
	
	func _get_owner_control() -> Control:
		if _binding == null:
			return null
		
		# First try owner_path if it's set
		if not (_binding.owner_path == null or _binding.owner_path.is_empty()):
			var edited_scene = EditorInterface.get_edited_scene_root()
			if edited_scene != null:
				var owner = edited_scene.get_node_or_null(_binding.owner_path) as Control
				if owner != null:
					return owner
		
		# If owner_path not set, search for ReactiveControls that contain this binding
		# This handles the case where bindings are edited in the inspector before owner_path is set
		var edited_scene = EditorInterface.get_edited_scene_root()
		if edited_scene == null:
			return null
		
		# Search for ReactiveControls that have this binding
		var queue = [edited_scene]
		while not queue.is_empty():
			var node = queue.pop_front()
			
			if node is ReactiveControl:
				var control = node as ReactiveControl
				# Check if this binding is in the control's bindings array
				if _binding in control.bindings:
					return control
			
			# Add children to queue
			for child in node.get_children():
				queue.append(child)
		
		return null
	
	func _get_target_control(owner_control: Control) -> Control:
		if _binding == null or owner_control == null:
			return null
		
		var target_path = _binding.control_path
		
		if target_path == null or target_path.is_empty() or target_path == NodePath("."):
			return owner_control
		
		# Try to resolve the target
		var target = owner_control.get_node_or_null(target_path) as Control
		if target == null:
			# Try absolute path as fallback
			var edited_scene = EditorInterface.get_edited_scene_root()
			if edited_scene != null:
				target = edited_scene.get_node_or_null(target_path) as Control
		
		return target
	
	func _reconnect_signal() -> void:
		# Reconnect signal after refresh
		if not _picker.item_selected.is_connected(_on_item_selected):
			_picker.item_selected.connect(_on_item_selected)
	
	func _update_property() -> void:
		_binding = get_edited_object() as ReactiveBinding
		if _binding == null:
			return
		
		# Check if control_path changed - if so, rebuild the list
		if _binding.control_path != _last_control_path:
			_build_signals_list()
		else:
			# Only update selection, don't rebuild the list
			_update_selection()
	
	func _on_item_selected(index: int) -> void:
		var property_name = get_edited_property()
		if index == 0:
			emit_changed(property_name, "")
		else:
			var selected_signal = _picker.get_item_text(index)
			emit_changed(property_name, selected_signal)


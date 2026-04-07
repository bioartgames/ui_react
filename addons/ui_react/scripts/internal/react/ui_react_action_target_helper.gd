class_name UiReactActionTargetHelper
extends RefCounted

const _action_state_watch_debug := preload(
	"res://addons/ui_react/scripts/internal/react/ui_react_action_state_watch_debug.gd"
)

const _META_LOCKS := &"_ui_react_action_locks"
const _META_SW_BINDINGS := &"_ui_react_action_sw_bindings"

class _StateWatchBinding extends RefCounted:
	var _owner: WeakRef
	var _component: String
	var _rows: Array[UiReactActionTarget]
	var _indices: PackedInt32Array
	var _state: UiBoolState

	func _init(
		owner: Control,
		component: String,
		rows: Array[UiReactActionTarget],
		indices: PackedInt32Array,
		state: UiBoolState,
	) -> void:
		_owner = weakref(owner)
		_component = component
		_rows = rows
		_indices = indices
		_state = state

	func on_value_changed(_new_value: Variant, _old_value: Variant) -> void:
		var o: Control = _owner.get_ref() as Control
		_action_state_watch_debug.line(
			"binding on_value_changed state_id=%d new=%s old=%s owner=%s"
			% [_state.get_instance_id(), _new_value, _old_value, o.name if o else "<dead>"]
		)
		if o == null:
			return
		_action_state_watch_debug.line(
			"binding CALL dispatch rows=%d indices=%s component=%s"
			% [_rows.size(), str(_indices), _component]
		)
		UiReactActionTargetHelper._dispatch_state_indices(o, _component, _rows, _indices)


static func _locks_for(owner: Node) -> Dictionary:
	if owner.has_meta(_META_LOCKS):
		var d: Variant = owner.get_meta(_META_LOCKS)
		if d is Dictionary:
			return d as Dictionary
	var created: Dictionary = {}
	owner.set_meta(_META_LOCKS, created)
	return created


static func _with_reentry_guard(owner: Node, key: String, fn: Callable) -> void:
	var locks := _locks_for(owner)
	if locks.get(key, false):
		_action_state_watch_debug.line(
			"reentry BLOCKED key=%s owner=%s" % [key, owner.name]
		)
		push_warning(
			"UiReactActionTargetHelper: reentrant action dispatch ignored (%s on %s)"
			% [key, owner.name]
		)
		return
	locks[key] = true
	fn.call()
	locks[key] = false


static func validate_action_targets(
	owner: Control,
	component_name: String,
	action_targets: Array[UiReactActionTarget],
	allow_empty_target: Array[int] = [],
) -> Array[UiReactActionTarget]:
	var out: Array[UiReactActionTarget] = []
	# UiReactButton hosts use normal control-triggered + state_watch rules; coordinator has no trigger dispatch.
	var transactional_only_state: bool = owner is UiReactTransactionalActions

	for i in range(action_targets.size()):
		var row: UiReactActionTarget = action_targets[i]
		if row == null:
			continue
		if not row.enabled:
			out.append(row)
			continue

		if transactional_only_state and row.state_watch == null:
			UiReactStateBindingHelper.warn_setup(
				component_name,
				owner,
				"action_targets[%d]: control-triggered row not supported on UiReactTransactionalActions." % i,
				"Use state_watch-driven rows only, or move this row to a control that emits UiAnimTarget triggers."
			)
			continue

		if row.state_watch != null and row.trigger != UiAnimTarget.Trigger.PRESSED:
			UiReactStateBindingHelper.warn_setup(
				component_name,
				owner,
				"action_targets[%d]: state_watch set but trigger is not PRESSED (ignored at runtime)." % i,
				"Set trigger to PRESSED when using state_watch, or clear state_watch for control-driven rows."
			)

		match row.action:
			UiReactActionTarget.UiReactActionKind.SET_UI_BOOL_FLAG:
				if row.bool_flag_state == null:
					UiReactStateBindingHelper.warn_setup(
						component_name,
						owner,
						"action_targets[%d]: SET_UI_BOOL_FLAG needs bool_flag_state." % i,
						"Assign bool_flag_state or remove the row."
					)
					continue
				if row.state_watch != null and row.bool_flag_state == row.state_watch:
					push_error(
						"%s on '%s': action_targets[%d]: bool_flag_state is the same as state_watch (loop risk). Use a different UiBoolState for SET_UI_BOOL_FLAG."
						% [component_name, owner.name, i]
					)
					continue
			_:
				pass

		if row.action in [
			UiReactActionTarget.UiReactActionKind.GRAB_FOCUS,
			UiReactActionTarget.UiReactActionKind.SET_VISIBLE,
			UiReactActionTarget.UiReactActionKind.SET_MOUSE_FILTER,
		]:
			if row.target.is_empty() and not allow_empty_target.has(int(row.trigger)):
				UiReactStateBindingHelper.warn_setup(
					component_name,
					owner,
					"action_targets[%d]: action kind needs a non-empty target NodePath." % i,
					"Assign target in the Inspector."
				)
				continue
		elif row.action == UiReactActionTarget.UiReactActionKind.SET_UI_BOOL_FLAG:
			pass # already checked bool_flag_state

		out.append(row)

	return out


static func collect_control_trigger_map(action_targets: Array[UiReactActionTarget]) -> Dictionary:
	var trigger_map: Dictionary = {}
	for row in action_targets:
		if row == null or not row.enabled:
			continue
		if row.state_watch != null:
			continue
		trigger_map[row.trigger] = true
	return trigger_map


## Filters invalid rows back onto [param action_targets_property], merges control triggers into [param trigger_map], and wires [signal UiBoolState.value_changed].
static func apply_validated_actions_and_merge_triggers(
	owner: Control,
	component_name: String,
	trigger_map: Dictionary,
	action_targets_property: StringName = &"action_targets",
	allow_empty_target: Array[int] = [],
) -> void:
	var raw: Variant = owner.get(action_targets_property)
	var arr: Array[UiReactActionTarget] = raw as Array[UiReactActionTarget]
	var valid := validate_action_targets(owner, component_name, arr, allow_empty_target)
	owner.set(action_targets_property, valid)
	for row in valid:
		if row == null or not row.enabled or row.state_watch != null:
			continue
		trigger_map[row.trigger] = true
	_install_state_watch_bindings(owner, component_name, valid)


static func _install_state_watch_bindings(owner: Control, component_name: String, rows: Array[UiReactActionTarget]) -> void:
	_clear_state_watch_bindings(owner)
	var by_state: Dictionary = {} # UiBoolState -> PackedInt32Array
	for i in range(rows.size()):
		var row: UiReactActionTarget = rows[i]
		if row == null or not row.enabled or row.state_watch == null:
			continue
		var st: UiBoolState = row.state_watch
		if not by_state.has(st):
			by_state[st] = PackedInt32Array()
		# PackedInt32Array is value-typed: dictionary get returns a copy; append must be written back.
		var packed: PackedInt32Array = by_state[st]
		packed.append(i)
		by_state[st] = packed

	var bindings: Array = []
	for st in by_state.keys():
		var idx: PackedInt32Array = by_state[st]
		var binding := _StateWatchBinding.new(owner, component_name, rows, idx, st)
		bindings.append(binding)
		UiReactAnimTargetHelper.connect_if_absent(st.value_changed, binding.on_value_changed)
	owner.set_meta(_META_SW_BINDINGS, bindings)


static func _clear_state_watch_bindings(owner: Control) -> void:
	if not owner.has_meta(_META_SW_BINDINGS):
		return
	var old: Variant = owner.get_meta(_META_SW_BINDINGS)
	if old is Array:
		for b in old as Array:
			if b is _StateWatchBinding:
				var binding: _StateWatchBinding = b as _StateWatchBinding
				if binding._state.value_changed.is_connected(binding.on_value_changed):
					binding._state.value_changed.disconnect(binding.on_value_changed)
	owner.remove_meta(_META_SW_BINDINGS)


static func _dispatch_state_indices(
	owner: Control,
	component_name: String,
	rows: Array[UiReactActionTarget],
	indices: PackedInt32Array,
) -> void:
	_action_state_watch_debug.line(
		"dispatch ENTER owner=%s component=%s rows=%d indices=%s"
		% [owner.name, component_name, rows.size(), str(indices)]
	)
	if indices.is_empty():
		_action_state_watch_debug.line("dispatch EARLY indices.is_empty()")
		return
	var k0: int = int(indices[0])
	if k0 < 0 or k0 >= rows.size():
		_action_state_watch_debug.line(
			"dispatch EARLY k0 out of range k0=%d rows.size=%d" % [k0, rows.size()]
		)
		return
	var row0: UiReactActionTarget = rows[k0]
	if row0 == null or row0.state_watch == null:
		_action_state_watch_debug.line(
			"dispatch EARLY row0 or state_watch null row0=%s sw=%s"
			% [str(row0), str(row0.state_watch if row0 else "n/a")]
		)
		return
	var key := "sw:%d" % row0.state_watch.get_instance_id()
	_action_state_watch_debug.line(
		"dispatch owner=%s component=%s indices=%s key=%s"
		% [owner.name, component_name, str(indices), key]
	)
	_with_reentry_guard(owner, key, func() -> void:
		_action_state_watch_debug.line("dispatch INSIDE guard key=%s — applying row indices" % key)
		var sorted: Array = []
		for j in range(indices.size()):
			sorted.append(int(indices[j]))
		sorted.sort()
		for idx in sorted:
			if idx < 0 or idx >= rows.size():
				_action_state_watch_debug.line("dispatch SKIP idx out of range idx=%d rows=%d" % [idx, rows.size()])
				continue
			var row: UiReactActionTarget = rows[idx]
			_apply_row(owner, row, idx, component_name)
	)


static func sync_initial_state(owner: Control, component_name: String, action_targets: Array[UiReactActionTarget]) -> void:
	if not owner.is_inside_tree():
		return
	for i in range(action_targets.size()):
		var row: UiReactActionTarget = action_targets[i]
		if row == null or not row.enabled or row.state_watch == null:
			continue
		_apply_row(owner, row, i, component_name)


static func run_actions(
	owner: Control,
	component_name: String,
	action_targets: Array[UiReactActionTarget],
	trigger_type: UiAnimTarget.Trigger,
	respects_disabled: bool = false,
	is_disabled: bool = false,
) -> void:
	if action_targets.is_empty():
		return
	var key := "tr:%d" % int(trigger_type)
	_with_reentry_guard(owner, key, func() -> void:
		for i in range(action_targets.size()):
			var row: UiReactActionTarget = action_targets[i]
			if row == null or not row.enabled:
				continue
			if row.state_watch != null:
				continue
			if row.trigger != trigger_type:
				continue
			if respects_disabled and is_disabled:
				continue
			_apply_row(owner, row, i, component_name)
	)


static func _apply_row(owner: Control, row: UiReactActionTarget, row_index: int, component_name: String) -> void:
	if row == null or not row.enabled:
		return
	match row.action:
		UiReactActionTarget.UiReactActionKind.GRAB_FOCUS:
			var n: Node = owner.get_node_or_null(row.target)
			if n == null or not (n is Control):
				push_warning(
					"%s action_targets[%d] GRAB_FOCUS: target is missing or not Control."
					% [component_name, row_index]
				)
				return
			var c: Control = n as Control
			if c.is_inside_tree():
				c.grab_focus()
		UiReactActionTarget.UiReactActionKind.SET_VISIBLE:
			var n2: Node = owner.get_node_or_null(row.target)
			if n2 == null:
				push_warning(
					"%s action_targets[%d] SET_VISIBLE: target not found." % [component_name, row_index]
				)
				return
			if n2 is CanvasItem:
				var ci: CanvasItem = n2 as CanvasItem
				if row.state_watch != null:
					var b: bool = UiReactStateBindingHelper.coerce_bool(row.state_watch.get_value())
					var vis: bool = row.visible_when_true if b else row.visible_when_false
					ci.visible = vis
					_action_state_watch_debug.line(
						(
							"SET_VISIBLE row=%d sw_id=%d coerce_bool=%s -> visible=%s target=%s path=%s"
							% [row_index, row.state_watch.get_instance_id(), b, vis, n2.name, row.target]
						)
					)
				else:
					ci.visible = row.visible_value
			else:
				push_warning(
					"%s action_targets[%d] SET_VISIBLE: target is not CanvasItem/Control." % [component_name, row_index]
				)
		UiReactActionTarget.UiReactActionKind.SET_UI_BOOL_FLAG:
			if row.bool_flag_state == null:
				return
			row.bool_flag_state.set_value(row.bool_flag_value)
		UiReactActionTarget.UiReactActionKind.SET_MOUSE_FILTER:
			var n3: Node = owner.get_node_or_null(row.target)
			if n3 == null or not (n3 is Control):
				push_warning(
					"%s action_targets[%d] SET_MOUSE_FILTER: target is missing or not Control."
					% [component_name, row_index]
				)
				return
			var ctl: Control = n3 as Control
			if row.state_watch != null:
				var b: bool = UiReactStateBindingHelper.coerce_bool(row.state_watch.get_value())
				ctl.mouse_filter = row.mouse_filter_when_true if b else row.mouse_filter_when_false
			else:
				ctl.mouse_filter = row.mouse_filter
		UiReactActionTarget.UiReactActionKind.SUBTRACT_PRODUCT_FROM_FLOAT:
			UiReactStateOpService.subtract_product_from_accumulator(
				row.float_accumulator, row.float_factor_a, row.float_factor_b
			)

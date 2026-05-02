## Runtime helpers for [member Control.audio_targets] and [member Control.haptic_targets]: validation, [code]state_watch[/code] wiring, trigger dispatch.
## Reentry guards use per-owner meta distinct from [UiReactActionTargetHelper]. Call [method teardown_for_control_exit] with [UiReactActionTargetHelper.teardown_for_control_exit] ordering per control docs.
class_name UiReactFeedbackTargetHelper
extends RefCounted

const _META_LOCKS := &"_ui_react_feedback_locks"
const _META_SW_BINDINGS := &"_ui_react_feedback_sw_bindings"


class _FeedbackStateWatchBinding extends RefCounted:
	var _owner: WeakRef
	var _component_name: String
	var _audio_rows: Array[UiReactAudioFeedbackTarget]
	var _audio_indices: PackedInt32Array
	var _haptic_rows: Array[UiReactHapticFeedbackTarget]
	var _haptic_indices: PackedInt32Array
	var _state: UiBoolState

	func _init(
		owner: Control,
		component_name: String,
		audio_rows: Array[UiReactAudioFeedbackTarget],
		audio_indices: PackedInt32Array,
		haptic_rows: Array[UiReactHapticFeedbackTarget],
		haptic_indices: PackedInt32Array,
		state: UiBoolState,
	) -> void:
		_owner = weakref(owner)
		_component_name = component_name
		_audio_rows = audio_rows
		_audio_indices = audio_indices
		_haptic_rows = haptic_rows
		_haptic_indices = haptic_indices
		_state = state

	func on_value_changed(_new_value: Variant, _old_value: Variant) -> void:
		var o: Control = _owner.get_ref() as Control
		if o == null:
			return
		UiReactFeedbackTargetHelper._dispatch_state_watch(
			o,
			_component_name,
			_audio_rows,
			_audio_indices,
			_haptic_rows,
			_haptic_indices
		)


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
		push_warning(
			"UiReactFeedbackTargetHelper: reentrant feedback dispatch ignored (%s on %s)"
			% [key, owner.name]
		)
		return
	locks[key] = true
	fn.call()
	locks[key] = false


static func teardown_for_control_exit(owner: Control) -> void:
	if owner == null:
		return
	_clear_state_watch_bindings(owner)
	if owner.has_meta(_META_LOCKS):
		owner.remove_meta(_META_LOCKS)


static func validate_audio_targets(
	owner: Control,
	component_name: String,
	audio_targets: Array[UiReactAudioFeedbackTarget],
) -> Array[UiReactAudioFeedbackTarget]:
	var out: Array[UiReactAudioFeedbackTarget] = []
	for i in range(audio_targets.size()):
		var row: UiReactAudioFeedbackTarget = audio_targets[i]
		if row == null:
			continue
		if not row.enabled:
			out.append(row)
			continue
		if row.state_watch != null and row.trigger != UiAnimTarget.Trigger.PRESSED:
			UiReactStateBindingHelper.warn_setup(
				component_name,
				owner,
				"audio_targets[%d]: state_watch set but trigger is not PRESSED (ignored at runtime)." % i,
				"Set trigger to PRESSED when using state_watch, or clear state_watch for control-driven rows."
			)
		if row.player.is_empty():
			UiReactStateBindingHelper.warn_setup(
				component_name,
				owner,
				"audio_targets[%d]: needs a non-empty player NodePath." % i,
				"Assign an AudioStreamPlayer under this control, or remove the row."
			)
			continue
		var n: Node = owner.get_node_or_null(row.player)
		if n == null:
			UiReactStateBindingHelper.warn_setup(
				component_name,
				owner,
				"audio_targets[%d]: player path not found: %s." % [i, row.player],
				"Fix the path or pick the node again in the Inspector."
			)
			continue
		if not (n is AudioStreamPlayer):
			UiReactStateBindingHelper.warn_setup(
				component_name,
				owner,
				"audio_targets[%d]: player is not an AudioStreamPlayer." % i,
				"Point player at an AudioStreamPlayer node."
			)
			continue
		out.append(row)
	return out


static func validate_haptic_targets(
	owner: Control,
	component_name: String,
	haptic_targets: Array[UiReactHapticFeedbackTarget],
) -> Array[UiReactHapticFeedbackTarget]:
	var out: Array[UiReactHapticFeedbackTarget] = []
	for i in range(haptic_targets.size()):
		var row: UiReactHapticFeedbackTarget = haptic_targets[i]
		if row == null:
			continue
		if not row.enabled:
			out.append(row)
			continue
		if row.state_watch != null and row.trigger != UiAnimTarget.Trigger.PRESSED:
			UiReactStateBindingHelper.warn_setup(
				component_name,
				owner,
				"haptic_targets[%d]: state_watch set but trigger is not PRESSED (ignored at runtime)." % i,
				"Set trigger to PRESSED when using state_watch, or clear state_watch for control-driven rows."
			)
		if row.duration_sec <= 0.0:
			UiReactStateBindingHelper.warn_setup(
				component_name,
				owner,
				"haptic_targets[%d]: duration_sec must be > 0." % i,
				"Set a positive duration or remove the row."
			)
			continue
		out.append(row)
	return out


static func collect_control_trigger_map_audio(rows: Array[UiReactAudioFeedbackTarget]) -> Dictionary:
	var trigger_map: Dictionary = {}
	for row in rows:
		if row == null or not row.enabled:
			continue
		if row.state_watch != null:
			continue
		trigger_map[row.trigger] = true
	return trigger_map


static func collect_control_trigger_map_haptic(rows: Array[UiReactHapticFeedbackTarget]) -> Dictionary:
	var trigger_map: Dictionary = {}
	for row in rows:
		if row == null or not row.enabled:
			continue
		if row.state_watch != null:
			continue
		trigger_map[row.trigger] = true
	return trigger_map


static func apply_validated_audio_and_haptic_and_merge_triggers(
	owner: Control,
	component_name: String,
	trigger_map: Dictionary,
	audio_property: StringName = &"audio_targets",
	haptic_property: StringName = &"haptic_targets",
) -> void:
	var raw_a: Variant = owner.get(audio_property)
	var arr_a: Array[UiReactAudioFeedbackTarget] = raw_a as Array[UiReactAudioFeedbackTarget]
	var valid_a := validate_audio_targets(owner, component_name, arr_a)
	owner.set(audio_property, valid_a)

	var raw_h: Variant = owner.get(haptic_property)
	var arr_h: Array[UiReactHapticFeedbackTarget] = raw_h as Array[UiReactHapticFeedbackTarget]
	var valid_h := validate_haptic_targets(owner, component_name, arr_h)
	owner.set(haptic_property, valid_h)

	for row in valid_a:
		if row == null or not row.enabled or row.state_watch != null:
			continue
		trigger_map[row.trigger] = true
	for row in valid_h:
		if row == null or not row.enabled or row.state_watch != null:
			continue
		trigger_map[row.trigger] = true

	_install_state_watch_bindings(owner, component_name, valid_a, valid_h)


static func _install_state_watch_bindings(
	owner: Control,
	component_name: String,
	audio_rows: Array[UiReactAudioFeedbackTarget],
	haptic_rows: Array[UiReactHapticFeedbackTarget],
) -> void:
	_clear_state_watch_bindings(owner)
	var by_state: Dictionary = {}
	for i in range(audio_rows.size()):
		var row: UiReactAudioFeedbackTarget = audio_rows[i]
		if row == null or not row.enabled or row.state_watch == null:
			continue
		var st: UiBoolState = row.state_watch
		if not by_state.has(st):
			by_state[st] = {&"a": PackedInt32Array(), &"h": PackedInt32Array()}
		var pack: Dictionary = by_state[st]
		var pa: PackedInt32Array = pack[&"a"]
		pa.append(i)
		pack[&"a"] = pa
	for i in range(haptic_rows.size()):
		var row2: UiReactHapticFeedbackTarget = haptic_rows[i]
		if row2 == null or not row2.enabled or row2.state_watch == null:
			continue
		var st2: UiBoolState = row2.state_watch
		if not by_state.has(st2):
			by_state[st2] = {&"a": PackedInt32Array(), &"h": PackedInt32Array()}
		var pack2: Dictionary = by_state[st2]
		var ph: PackedInt32Array = pack2[&"h"]
		ph.append(i)
		pack2[&"h"] = ph

	var bindings: Array = []
	for st in by_state.keys():
		var pack3: Dictionary = by_state[st]
		var ai: PackedInt32Array = pack3.get(&"a", PackedInt32Array())
		var hi: PackedInt32Array = pack3.get(&"h", PackedInt32Array())
		var binding := _FeedbackStateWatchBinding.new(
			owner, component_name, audio_rows, ai, haptic_rows, hi, st
		)
		bindings.append(binding)
		UiReactAnimTargetHelper.connect_if_absent(st.value_changed, binding.on_value_changed)
	owner.set_meta(_META_SW_BINDINGS, bindings)


static func _clear_state_watch_bindings(owner: Control) -> void:
	if not owner.has_meta(_META_SW_BINDINGS):
		return
	var old: Variant = owner.get_meta(_META_SW_BINDINGS)
	if old is Array:
		for b in old as Array:
			if b is _FeedbackStateWatchBinding:
				var binding: _FeedbackStateWatchBinding = b as _FeedbackStateWatchBinding
				if binding._state.value_changed.is_connected(binding.on_value_changed):
					binding._state.value_changed.disconnect(binding.on_value_changed)
	owner.remove_meta(_META_SW_BINDINGS)


static func _dispatch_state_watch(
	owner: Control,
	component_name: String,
	audio_rows: Array[UiReactAudioFeedbackTarget],
	audio_indices: PackedInt32Array,
	haptic_rows: Array[UiReactHapticFeedbackTarget],
	haptic_indices: PackedInt32Array,
) -> void:
	if audio_indices.is_empty() and haptic_indices.is_empty():
		return
	var watch_state: UiBoolState = null
	if not audio_indices.is_empty():
		var k0 := int(audio_indices[0])
		if k0 >= 0 and k0 < audio_rows.size():
			var r0: UiReactAudioFeedbackTarget = audio_rows[k0]
			if r0 != null and r0.state_watch != null:
				watch_state = r0.state_watch
	if watch_state == null and not haptic_indices.is_empty():
		var k1 := int(haptic_indices[0])
		if k1 >= 0 and k1 < haptic_rows.size():
			var r1: UiReactHapticFeedbackTarget = haptic_rows[k1]
			if r1 != null and r1.state_watch != null:
				watch_state = r1.state_watch
	if watch_state == null:
		return
	var key := "fb-sw:%d" % watch_state.get_instance_id()
	_with_reentry_guard(owner, key, func() -> void:
		var sa: Array = []
		for j in range(audio_indices.size()):
			sa.append(int(audio_indices[j]))
		sa.sort()
		for idx in sa:
			if idx < 0 or idx >= audio_rows.size():
				continue
			var row_a: UiReactAudioFeedbackTarget = audio_rows[idx]
			_apply_audio_row(owner, row_a, idx, component_name)
		var sh: Array = []
		for j2 in range(haptic_indices.size()):
			sh.append(int(haptic_indices[j2]))
		sh.sort()
		for idx2 in sh:
			if idx2 < 0 or idx2 >= haptic_rows.size():
				continue
			var row_h: UiReactHapticFeedbackTarget = haptic_rows[idx2]
			_apply_haptic_row(owner, row_h, idx2, component_name)
	)


static func sync_initial_state(
	owner: Control,
	component_name: String,
	audio_rows: Array[UiReactAudioFeedbackTarget],
	haptic_rows: Array[UiReactHapticFeedbackTarget],
) -> void:
	if not owner.is_inside_tree():
		return
	for i in range(audio_rows.size()):
		var row: UiReactAudioFeedbackTarget = audio_rows[i]
		if row == null or not row.enabled or row.state_watch == null:
			continue
		_apply_audio_row(owner, row, i, component_name)
	for j in range(haptic_rows.size()):
		var row2: UiReactHapticFeedbackTarget = haptic_rows[j]
		if row2 == null or not row2.enabled or row2.state_watch == null:
			continue
		_apply_haptic_row(owner, row2, j, component_name)


static func run_audio_feedback(
	owner: Control,
	component_name: String,
	audio_rows: Array[UiReactAudioFeedbackTarget],
	trigger_type: UiAnimTarget.Trigger,
	respects_disabled: bool = false,
	is_disabled: bool = false,
) -> void:
	if audio_rows.is_empty():
		return
	var key := "fb-audio:tr:%d" % int(trigger_type)
	_with_reentry_guard(owner, key, func() -> void:
		for i in range(audio_rows.size()):
			var row: UiReactAudioFeedbackTarget = audio_rows[i]
			if row == null or not row.enabled:
				continue
			if row.state_watch != null:
				continue
			if row.trigger != trigger_type:
				continue
			if respects_disabled and is_disabled:
				continue
			_apply_audio_row(owner, row, i, component_name)
	)


static func run_haptic_feedback(
	owner: Control,
	component_name: String,
	haptic_rows: Array[UiReactHapticFeedbackTarget],
	trigger_type: UiAnimTarget.Trigger,
	respects_disabled: bool = false,
	is_disabled: bool = false,
) -> void:
	if haptic_rows.is_empty():
		return
	var key := "fb-haptic:tr:%d" % int(trigger_type)
	_with_reentry_guard(owner, key, func() -> void:
		for i in range(haptic_rows.size()):
			var row: UiReactHapticFeedbackTarget = haptic_rows[i]
			if row == null or not row.enabled:
				continue
			if row.state_watch != null:
				continue
			if row.trigger != trigger_type:
				continue
			if respects_disabled and is_disabled:
				continue
			_apply_haptic_row(owner, row, i, component_name)
	)


static func _resolve_joy_device(device_id: int) -> int:
	if device_id >= 0:
		return device_id
	var pads: PackedInt64Array = Input.get_connected_joypads()
	if pads.is_empty():
		return -1
	return int(pads[0])


static func _apply_audio_row(
	owner: Control, row: UiReactAudioFeedbackTarget, row_index: int, component_name: String
) -> void:
	if row == null or not row.enabled:
		return
	var n: Node = owner.get_node_or_null(row.player)
	if n == null or not (n is AudioStreamPlayer):
		push_warning(
			"%s audio_targets[%d]: player missing or not AudioStreamPlayer."
			% [component_name, row_index]
		)
		return
	var asp: AudioStreamPlayer = n as AudioStreamPlayer
	if asp.is_inside_tree():
		asp.play()


static func _apply_haptic_row(
	owner: Control, row: UiReactHapticFeedbackTarget, row_index: int, component_name: String
) -> void:
	if row == null or not row.enabled:
		return
	if row.duration_sec <= 0.0:
		return
	var dev := _resolve_joy_device(row.device_id)
	if dev < 0:
		return
	var w := clampf(row.weak_magnitude, 0.0, 1.0)
	var s := clampf(row.strong_magnitude, 0.0, 1.0)
	Input.start_joy_vibration(dev, w, s, row.duration_sec)

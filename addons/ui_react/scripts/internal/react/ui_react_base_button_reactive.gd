## Shared pressed/disabled wiring, animation triggers, actions, and transactional host registration for [UiReactButton] / [UiReactTextureButton].
class_name UiReactBaseButtonReactive
extends RefCounted

const _TxnSession := preload("res://addons/ui_react/scripts/internal/react/ui_react_transactional_session.gd")

var _host: BaseButton
var _component_name: String
var _bind: UiReactTwoWayBindingDriver
var _guard_toggled_connect: bool


func _init(host: BaseButton, component_name: String, bind_driver: UiReactTwoWayBindingDriver, guard_toggled_connect: bool) -> void:
	_host = host
	_component_name = component_name
	_bind = bind_driver
	_guard_toggled_connect = guard_toggled_connect


func on_enter_tree() -> void:
	var th: UiReactTransactionalHostBinding = _host.get(&"transactional_host") as UiReactTransactionalHostBinding
	if th != null and th.group != null and int(th.role) != int(UiReactTransactionalHostBinding.HostRole.NONE):
		_TxnSession.register_host(_host, th.group, int(th.role), th.screen)


func on_exit_tree() -> void:
	_TxnSession.unregister_host(_host)


func disconnect_all_states() -> void:
	var ps: UiBoolState = _host.get(&"pressed_state") as UiBoolState
	var ds: UiBoolState = _host.get(&"disabled_state") as UiBoolState
	if ps != null:
		UiReactControlStateWire.unbind_value_changed(_host, ps, &"pressed_state", _on_pressed_state_changed)
	if ds != null:
		UiReactControlStateWire.unbind_value_changed(_host, ds, &"disabled_state", _on_disabled_state_changed)


func connect_all_states() -> void:
	var ps: UiBoolState = _host.get(&"pressed_state") as UiBoolState
	var ds: UiBoolState = _host.get(&"disabled_state") as UiBoolState
	if ps != null:
		UiReactControlStateWire.bind_value_changed(_host, ps, &"pressed_state", _on_pressed_state_changed)
	if ds != null:
		UiReactControlStateWire.bind_value_changed(_host, ds, &"disabled_state", _on_disabled_state_changed)


func on_ready() -> void:
	if not _host.pressed.is_connected(_on_pressed):
		_host.pressed.connect(_on_pressed)
	if _host.has_signal(&"toggled") and not _host.toggled.is_connected(_on_toggled):
		_host.toggled.connect(_on_toggled)
	disconnect_all_states()
	connect_all_states()
	_validate_animation_targets()
	UiReactStateBindingHelper.deferred_finish_initialization(_host)


func _action_targets_from_host() -> Array[UiReactActionTarget]:
	var raw: Variant = _host.get(&"action_targets")
	if raw is Array[UiReactActionTarget]:
		return raw as Array[UiReactActionTarget]
	var out: Array[UiReactActionTarget] = []
	if raw is Array:
		for it in raw as Array:
			if it is UiReactActionTarget:
				out.append(it as UiReactActionTarget)
	return out


func _validate_animation_targets() -> void:
	var acts: Array[UiReactActionTarget] = _action_targets_from_host()
	var trigger_map: Dictionary = UiReactAnimTargetHelper.apply_validated_targets(_host, _component_name)
	UiReactActionTargetHelper.apply_validated_actions_and_merge_triggers(_host, _component_name, trigger_map)

	if trigger_map.has(UiAnimTarget.Trigger.PRESSED):
		UiReactAnimTargetHelper.connect_if_absent(_host.pressed, _on_trigger_pressed)
	if trigger_map.has(UiAnimTarget.Trigger.HOVER_ENTER):
		UiReactAnimTargetHelper.connect_if_absent(_host.mouse_entered, _on_trigger_hover_enter)
	if trigger_map.has(UiAnimTarget.Trigger.HOVER_EXIT):
		UiReactAnimTargetHelper.connect_if_absent(_host.mouse_exited, _on_trigger_hover_exit)
	var want_toggle := trigger_map.has(UiAnimTarget.Trigger.TOGGLED_ON) or trigger_map.has(UiAnimTarget.Trigger.TOGGLED_OFF)
	if want_toggle and (not _guard_toggled_connect or _host.has_signal(&"toggled")):
		UiReactAnimTargetHelper.connect_if_absent(_host.toggled, _on_trigger_toggled)

	UiReactActionTargetHelper.sync_initial_state(_host, _component_name, acts)


func _on_trigger_pressed() -> void:
	_trigger_animations(UiAnimTarget.Trigger.PRESSED)


func _on_trigger_hover_enter() -> void:
	_trigger_animations(UiAnimTarget.Trigger.HOVER_ENTER)


func _on_trigger_hover_exit() -> void:
	_trigger_animations(UiAnimTarget.Trigger.HOVER_EXIT)


func _on_trigger_toggled(active: bool) -> void:
	if _bind.initializing:
		return
	if active:
		_trigger_animations(UiAnimTarget.Trigger.TOGGLED_ON)
	else:
		_trigger_animations(UiAnimTarget.Trigger.TOGGLED_OFF)


func _animation_targets_from_host() -> Array[UiAnimTarget]:
	var raw: Variant = _host.get(&"animation_targets")
	if raw is Array[UiAnimTarget]:
		return raw as Array[UiAnimTarget]
	var out: Array[UiAnimTarget] = []
	if raw is Array:
		for it in raw as Array:
			if it is UiAnimTarget:
				out.append(it as UiAnimTarget)
	return out


func _trigger_animations(trigger_type: UiAnimTarget.Trigger) -> void:
	var anim: Array[UiAnimTarget] = _animation_targets_from_host()
	var acts: Array[UiReactActionTarget] = _action_targets_from_host()
	UiReactAnimTargetHelper.trigger_animations(_host, anim, trigger_type, true, _host.disabled)
	UiReactActionTargetHelper.run_actions(_host, _component_name, acts, trigger_type, true, _host.disabled)


func _on_pressed() -> void:
	var ps: UiBoolState = _host.get(&"pressed_state") as UiBoolState
	if not ps or _host.toggle_mode:
		return
	if _bind.updating:
		return
	_bind.updating = true
	ps.set_value(true)
	_bind.updating = false


func _on_toggled(active: bool) -> void:
	var ps: UiBoolState = _host.get(&"pressed_state") as UiBoolState
	if not ps or not _host.toggle_mode or _bind.updating:
		return
	if ps.get_value() == active:
		return
	_bind.updating = true
	ps.set_value(active)
	_bind.updating = false


func _on_pressed_state_changed(new_value: Variant, _old_value: Variant) -> void:
	if _bind.updating:
		return
	var desired := UiReactStateBindingHelper.coerce_bool(new_value)
	if _host.toggle_mode:
		if _host.button_pressed == desired:
			return
		_bind.updating = true
		_host.button_pressed = desired
		_bind.updating = false


func _on_disabled_state_changed(new_value: Variant, _old_value: Variant) -> void:
	var desired := UiReactStateBindingHelper.coerce_bool(new_value)
	if _host.disabled == desired:
		return
	_host.disabled = desired


func finish_initialization() -> void:
	_bind.finish_initialization()

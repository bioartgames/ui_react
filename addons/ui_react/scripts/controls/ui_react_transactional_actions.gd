@tool
## [deprecated] Use [UiReactButton] / [UiReactTextureButton] with [member UiReactButton.transactional_host] ([UiReactTransactionalHostBinding]) and [UiTransactionalScreenConfig], or keep this node for path-based Apply/Cancel only.
## Connects [BaseButton] **Apply** / **Cancel** to a [UiTransactionalGroup]: calls [method UiTransactionalGroup.apply_all] / [method UiTransactionalGroup.cancel_all] via [UiReactTransactionalSession].
## Optional [member begin_on_ready]: mapped into a [UiTransactionalScreenConfig] for [method UiTransactionalGroup.begin_edit_all] once when the cohort first registers (deferred one frame).
## Paths are relative to this control node.
class_name UiReactTransactionalActions
extends Control

const _TxnSession := preload("res://addons/ui_react/scripts/internal/react/ui_react_transactional_session.gd")

@export var group: UiTransactionalGroup
@export var apply_button_path: NodePath = NodePath("")
@export var cancel_button_path: NodePath = NodePath("")
@export var begin_on_ready: bool = true

## **Optional** — [b]State-driven[/b] action rows only (no [UiAnimTarget] triggers on this node). See [code]docs/ACTION_LAYER.md[/code].
@export var action_targets: Array[UiReactActionTarget] = []

## **Optional** — Wiring rules ([code]docs/WIRING_LAYER.md[/code] §5). Applied by [UiReactWireRuleHelper].
@export var wire_rules: Array[UiReactWireRule] = []


func _enter_tree() -> void:
	UiReactWireRuleHelper.schedule_attach(self)


func _ready() -> void:
	_register_transactional_session()
	_setup_action_targets()


func _exit_tree() -> void:
	UiReactWireRuleHelper.detach(self)
	_unregister_transactional_session()


func _register_transactional_session() -> void:
	if group == null:
		return
	const _TxnScr := preload("res://addons/ui_react/scripts/api/models/ui_transactional_screen_config.gd")
	var cfg: Resource = _TxnScr.new()
	cfg.set("begin_on_ready", begin_on_ready)
	var a := get_node_or_null(apply_button_path) as BaseButton
	var c := get_node_or_null(cancel_button_path) as BaseButton
	if a != null:
		_TxnSession.register_host(a, group, 1, cfg)
	else:
		if not apply_button_path.is_empty():
			push_warning(
				"UiReactTransactionalActions '%s': apply_button_path not found: %s" % [name, apply_button_path]
			)
	if c != null:
		_TxnSession.register_host(c, group, 2, cfg)
	else:
		if not cancel_button_path.is_empty():
			push_warning(
				"UiReactTransactionalActions '%s': cancel_button_path not found: %s" % [name, cancel_button_path]
			)


func _unregister_transactional_session() -> void:
	if group == null:
		return
	var a := get_node_or_null(apply_button_path) as BaseButton
	var c := get_node_or_null(cancel_button_path) as BaseButton
	if a != null:
		_TxnSession.unregister_host(a)
	if c != null:
		_TxnSession.unregister_host(c)


func _setup_action_targets() -> void:
	var trigger_map: Dictionary = {}
	UiReactActionTargetHelper.apply_validated_actions_and_merge_triggers(
		self, "UiReactTransactionalActions", trigger_map
	)
	UiReactActionTargetHelper.sync_initial_state(self, "UiReactTransactionalActions", action_targets)

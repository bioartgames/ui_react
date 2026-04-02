@tool
## Connects [BaseButton] **Apply** / **Cancel** to a [UiTransactionalGroup]: calls [method UiTransactionalGroup.apply_all] / [method UiTransactionalGroup.cancel_all].
## Optional [member begin_on_ready]: calls [method UiTransactionalGroup.begin_edit_all] once in [method _ready] when [member group] is set.
## Paths are relative to this control node.
class_name UiReactTransactionalActions
extends Control

@export var group: UiTransactionalGroup
@export var apply_button_path: NodePath = NodePath("")
@export var cancel_button_path: NodePath = NodePath("")
@export var begin_on_ready: bool = true


func _ready() -> void:
	if begin_on_ready and group != null:
		group.begin_edit_all()
	_wire_button(apply_button_path, _on_apply_pressed)
	_wire_button(cancel_button_path, _on_cancel_pressed)


func _exit_tree() -> void:
	_unwire_button(apply_button_path, _on_apply_pressed)
	_unwire_button(cancel_button_path, _on_cancel_pressed)


func _wire_button(path: NodePath, handler: Callable) -> void:
	if path == NodePath("") or not handler.is_valid():
		return
	var n: Node = get_node_or_null(path)
	if n == null:
		push_warning("UiReactTransactionalActions '%s': button path not found: %s" % [name, path])
		return
	if not (n is BaseButton):
		push_warning("UiReactTransactionalActions '%s': node is not BaseButton: %s" % [name, path])
		return
	var b := n as BaseButton
	if b.pressed.is_connected(handler):
		return
	b.pressed.connect(handler)


func _unwire_button(path: NodePath, handler: Callable) -> void:
	if path == NodePath("") or not handler.is_valid():
		return
	var n: Node = get_node_or_null(path)
	if n != null and n is BaseButton:
		var b := n as BaseButton
		if b.pressed.is_connected(handler):
			b.pressed.disconnect(handler)


func _on_apply_pressed() -> void:
	if group != null:
		group.apply_all()


func _on_cancel_pressed() -> void:
	if group != null:
		group.cancel_all()

## Shared [UiReactWireRuleHelper] tree hooks for [UiReact*] controls that export [member Control.wire_rules].
class_name UiReactHostWireTree
extends RefCounted


static func on_enter(host: Control) -> void:
	UiReactWireRuleHelper.schedule_attach(host)


static func on_exit(host: Control) -> void:
	UiReactWireRuleHelper.detach(host)

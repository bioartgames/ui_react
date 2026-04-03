## Base type for inspector-authored wiring rules ([code]docs/WIRING_LAYER.md[/code] §4).
## Subclasses override [method apply].
class_name UiReactWireRule
extends Resource

@export var rule_id: String = ""
@export var enabled: bool = true
## Trigger token aligned with [member UiAnimTarget.Trigger] for this rule’s source control ([code]docs/WIRING_LAYER.md[/code] §5).
@export var trigger: UiAnimTarget.Trigger = UiAnimTarget.Trigger.SELECTION_CHANGED


func apply(_source: Node) -> void:
	pass

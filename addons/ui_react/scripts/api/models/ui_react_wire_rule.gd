## Base type for inspector-authored wiring rules ([code]docs/WIRING_LAYER.md[/code] §4).
## Subclasses override [method apply].
class_name UiReactWireRule
extends Resource

## Integer values match legacy [enum UiAnimTarget.Trigger] ordinals so existing `.tres` / `.tscn` data stays valid.
enum TriggerKind { TEXT_CHANGED = 5, SELECTION_CHANGED = 6, TEXT_ENTERED = 13 }

@export var rule_id: String = ""
@export var enabled: bool = true
## When this rule’s source widget fires; see [code]docs/WIRING_LAYER.md[/code] §5.
@export var trigger: TriggerKind = TriggerKind.SELECTION_CHANGED


func apply(_source: Node) -> void:
	## Abstract: concrete rules implement [method apply] or pulse-driven entry points.
	pass

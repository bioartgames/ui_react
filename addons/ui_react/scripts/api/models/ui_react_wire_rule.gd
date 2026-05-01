## Base type for inspector-authored wiring rules ([code]docs/WIRING_LAYER.md[/code] §4).
## Subclasses override [method apply].
class_name UiReactWireRule
extends Resource

## Stable storage codes for [member trigger] in `.tres` / `.tscn`. They match wire serialization and historically align with [enum UiAnimTarget.Trigger] for the three text/selection events only; other resources may use different [code]trigger[/code] export numbering—do not assume a single global ordinal map.
const WIRE_TRIGGER_TEXT_CHANGED := 5
const WIRE_TRIGGER_SELECTION_CHANGED := 6
const WIRE_TRIGGER_TEXT_ENTERED := 13

## Same integer values as [code]WIRE_TRIGGER_*[/code] above (enum initializers cannot reference those consts in GDScript).
enum TriggerKind { TEXT_CHANGED = 5, SELECTION_CHANGED = 6, TEXT_ENTERED = 13 }

@export var rule_id: String = ""
@export var enabled: bool = true
## When [code]false[/code], [method UiReactWireRuleHelper.attach] skips the one-shot [method apply] after signal binding (avoids duplicate work if state already matches the UI).
@export var run_apply_on_attach: bool = true
## When this rule’s source widget fires; see [code]docs/WIRING_LAYER.md[/code] §5.
@export var trigger: TriggerKind = TriggerKind.SELECTION_CHANGED


func apply(_source: Node) -> void:
	## Abstract: concrete rules implement [method apply] or pulse-driven entry points.
	pass

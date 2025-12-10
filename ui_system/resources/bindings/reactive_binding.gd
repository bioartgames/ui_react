## Unified binding configuration resource.
## Supports both one-way and two-way binding via mode selection.
@icon("res://icon.svg")
class_name ReactiveBinding
extends Resource

## Binding mode enum.
enum BindingMode {
	ONE_WAY,  # ReactiveValue → Control property
	TWO_WAY   # ReactiveValue ↔ Control property
}

## The reactive value to bind to.
@export var reactive_value: ReactiveValue = null

## Binding direction mode.
@export var mode: BindingMode = BindingMode.ONE_WAY

## Path to the Control node (optional for ONE_WAY, defaults to "self"; required for TWO_WAY).
@export var control_path: NodePath = NodePath(".")

## Property name on Control (e.g., "text", "value").
@export var control_property: String = ""

## Signal name to listen to (required for TWO_WAY, ignored for ONE_WAY).
@export var control_signal: String = ""

## Optional converter Resource for value transformation.
@export var value_converter: ValueConverter = null

## Read-only status of binding (updated on validation).
var status: BindingStatus.Status = BindingStatus.Status.DISCONNECTED


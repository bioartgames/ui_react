## Navigation group resource.
## Defines a group of focusable components with a specific focus order.
@icon("res://icon.svg")
class_name ReactiveNavigationGroup
extends Resource

## The name of this navigation group.
@export var name: String = ""

## Array of NodePaths defining the focus order for this group.
@export var focus_order: Array[NodePath] = []

## Whether focus should wrap around (last -> first, first -> last).
@export var wrap_around: bool = true


## Encodes layout-specific navigation rules independently from input configuration.
##
## This resource allows designers to define how navigation behaves within a specific
## UI subtree, including default focus, ordered controls, and behavior flags.
extends Resource
class_name NavigationConfig

@export_group("Scope")
@export var root_control: NodePath

@export_group("Defaults")
@export var default_focus: NodePath
@export var focus_on_ready: bool = true

@export_group("Ordering")
@export var ordered_controls: Array[NodePath] = []
@export var use_ordered_vertical: bool = true
@export var wrap_vertical: bool = false
@export var wrap_horizontal: bool = false

@export_group("Advanced")
@export var respect_custom_neighbors: bool = true
@export var restrict_to_focusable_children: bool = true
@export var auto_disable_child_focus: bool = false

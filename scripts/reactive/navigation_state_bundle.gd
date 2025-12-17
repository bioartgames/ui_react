## Encapsulates input events expressed as State resources for external input systems.
##
## This resource provides a State-based interface for custom input systems to drive
## navigation without touching ReactiveUINavigator internals. Values should be set
## by external input logic and read by the navigator.
extends Resource
class_name NavigationStateBundle

@export_group("Movement")
@export var move_x: State  # -1 (left), 0, +1 (right)
@export var move_y: State  # -1 (up), 0, +1 (down)

@export_group("Actions")
@export var submit: State      # bool or edge-triggered
@export var cancel: State      # bool or edge-triggered

@export_group("Paging")
@export var page_next: State   # optional, edge-triggered for next page/tab
@export var page_prev: State   # optional, edge-triggered for previous page/tab

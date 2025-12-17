## Encapsulates all InputMap-related decisions in a Resource so designers can swap
## profiles without code changes.
##
## This resource defines which InputMap actions correspond to navigation concepts
## (up/down/left/right/accept/cancel) and provides configuration for repeat behavior.
extends Resource
class_name NavigationInputProfile

@export_group("Actions")
@export var action_up: StringName = &"ui_up"
@export var action_down: StringName = &"ui_down"
@export var action_left: StringName = &"ui_left"
@export var action_right: StringName = &"ui_right"
@export var action_accept: StringName = &"ui_accept"
@export var action_cancel: StringName = &"ui_cancel"

@export_group("Behavior")
@export var repeat_delay: float = 0.25
@export var repeat_interval: float = 0.1

@export_group("Analog / Diagonals")
@export var allow_diagonals: bool = false
@export var analog_deadzone: float = 0.4

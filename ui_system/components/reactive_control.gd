## Base reactive component class.
## Provides unified binding system (one-way and two-way) via ReactiveBindingManager.
extends Control
class_name ReactiveControl

## Array of bindings for this component.
@export var bindings: Array[ReactiveBinding] = []

## Binding manager (RefCounted) that handles all binding logic.
var _binding_manager: ReactiveBindingManager = null

func _ready() -> void:
	# Create and setup binding manager
	_binding_manager = ReactiveBindingManager.new()
	_binding_manager.setup(self, bindings)

func _exit_tree() -> void:
	# Cleanup binding manager
	if _binding_manager:
		_binding_manager.cleanup()
		_binding_manager = null


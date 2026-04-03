## Shared guard flags for [UiReact*] two-way [UiState] binding (one instance per control).
class_name UiReactTwoWayBindingDriver
extends RefCounted

var updating: bool = false
var initializing: bool = true


func finish_initialization() -> void:
	initializing = false

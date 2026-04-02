@tool
## Abstract base for reactive state resources used with [UiReact*] controls.
## Instantiate a concrete subclass ([UiBoolState], [UiIntState], [UiFloatState], [UiStringState], [UiArrayState], or [UiTransactionalState]) only.
## [code]@tool[/code] lets editor plugins call instance methods (e.g. scan-time preview). Subclasses skip [signal value_changed] while [method Engine.is_editor_hint] is true.
@abstract
class_name UiState
extends Resource

signal value_changed(new_value: Variant, old_value: Variant)


func get_value() -> Variant:
	push_error("UiState.get_value() must be overridden in subclass")
	return null


func set_value(_new_value: Variant) -> void:
	push_error("UiState.set_value() must be overridden in subclass")


func set_silent(_new_value: Variant) -> void:
	push_error("UiState.set_silent() must be overridden in subclass")

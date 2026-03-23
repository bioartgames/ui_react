## Base class for action configurations that define what happens when buttons or toggles are pressed.
##
## ActionConfig subclasses enable buttons or toggles to trigger actions on targets without writing
## code, providing designer-friendly action configuration through the Inspector. This makes it ideal
## for configuring button and toggle actions in the Inspector without code, creating reusable action
## configurations, enabling designers to set up UI interactions, and triggering multiple actions
## from a single button or toggle. Unlike manual signal connections, ActionConfig requires no code
## and can be configured in the Inspector, provides reusable action configurations, offers type-safe
## action selection, and supports both Control targets (UI components) and Resource targets (reactive
## values). Create a specific action config resource like PanelActionConfig or ButtonActionConfig and
## assign it to ControlTargetConfig.animation (AnimationTarget) or ValueTargetConfig.action. When the button or toggle
## is pressed, the action config's apply() method is called automatically. This class should not be
## instantiated directly. Use one of its subclasses: PanelActionConfig for show/hide/toggle panels,
## ButtonActionConfig for enable/disable/toggle buttons, LabelActionConfig for show/hide labels,
## InputActionConfig for enable/disable inputs, ToggleActionConfig for toggle switches, ListActionConfig
## for selecting items in lists, and ReactiveValueActionConfig
## for modifying reactive values.
@abstract
class_name ActionConfig
extends Resource

## Applies this action to the given target control.
##
## Called automatically when a button or toggle with this action config is pressed. Performs the
## configured action on the target control like showing a panel or enabling a button. The exact
## behavior depends on the action config subclass. Subclasses must override this method to implement
## their specific action logic.
##
## [param owner]: The node that owns the target config (for context).
## [param target]: The control component to apply the action to.
## [param is_on]: Optional boolean state (used by toggles to indicate ON/OFF state).
## [return]: Returns true if the action was applied successfully, false otherwise.
func apply(_owner: Node, _target: Control, _is_on: bool = true) -> bool:
	push_error("ActionConfig.apply() must be overridden in subclass")
	return false

## Applies this action to the given target resource (e.g., ReactiveInt, ReactiveFloat).
##
## Called automatically when a button or toggle with this action config targets a reactive resource
## instead of a Control. Performs the configured action on the target resource like incrementing a
## counter or toggling a bool. The exact behavior depends on the action config subclass. Not all
## action configs support resources. Default implementation returns false (not supported). Override
## in subclasses that support resources like ReactiveValueActionConfig.
##
## [param owner]: The node that owns the target config (for context).
## [param target]: The reactive resource to apply the action to.
## [param is_on]: Optional boolean state (used by toggles to indicate ON/OFF state).
## [return]: Returns true if the action was applied successfully, false otherwise.
func apply_to_resource(_owner: Node, _target: Resource, _is_on: bool = true) -> bool:
	return false

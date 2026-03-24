## Base class for target configurations that define what a button or toggle acts upon.
##
## UiTargetCfg subclasses enable buttons or toggles to control targets (UI components or reactive
## values) without writing code, providing designer-friendly target configuration through the Inspector.
## This makes it ideal for configuring button and toggle targets in the Inspector without code, creating
## reusable target configurations, enabling designers to set up UI interactions, and controlling multiple
## targets from a single button or toggle. Unlike manual signal connections, UiTargetCfg requires no
## code and can be configured in the Inspector, provides reusable target configurations, supports both
## Control targets and Resource targets in a unified array, and offers type-safe target selection.
## Both types extend this base class, allowing them to be used in a unified `targets` array. When the
## button or toggle is pressed, each target's action is applied automatically. This class should not
## be instantiated directly. Use [UiControlTargetCfg] for UI Controls (nodes in the scene tree).
## Pair [UiState] resources with reactive controls for data-driven UI; this base class covers control-target patterns.
##
## Example:
## [codeblock]
## # Configure targets in Inspector or code
## var targets: Array[UiTargetCfg] = []
## targets.append(UiControlTargetCfg.new())  # Control target (panel, button, etc.)
## 
## # Button automatically applies actions to all targets when pressed
## [/codeblock]
@abstract
class_name UiTargetCfg
extends Resource

## Applies the configured action to the target.
##
## Called automatically when a button or toggle with this target config is pressed. Resolves the
## target (Control or Resource) and applies the configured action to it. The exact behavior depends
## on the target config subclass and its action config. Subclasses must override this method to
## resolve the target and apply the action.
##
## [param owner]: The node that owns this config (used for context).
## [param is_on]: Optional boolean state (used by toggles to indicate ON/OFF state).
## [return]: Returns true if the action was applied successfully, false otherwise.
func apply(_owner: Node, _is_on: bool = true) -> bool:
	push_error("UiTargetCfg.apply() must be overridden in subclass")
	return false


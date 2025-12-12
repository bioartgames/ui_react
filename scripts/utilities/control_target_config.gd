## Configuration for targeting UI Controls (nodes in the scene tree) with actions.
##
## ControlTargetConfig enables buttons or toggles to control UI components and trigger animations
## without writing code, providing designer-friendly UI control through the Inspector. This makes it
## ideal for buttons that control multiple UI components, toggle switches that show or hide panels
## or labels, buttons that enable or disable other buttons, and any button or toggle that needs
## to control UI components or trigger animations. Unlike manual signal connections, ControlTargetConfig
## requires no code and can be configured in the Inspector, provides fine-grained control where each
## target component gets its own action setting, and supports drag-and-drop target selection.
##
## To set targets, drag and drop a node to target in the Inspector (easiest), or set target manually
## for advanced cases. Animation properties are configured directly in the Inspector with a dropdown
## menu - no separate resource files needed!
##
## Usage:
## [codeblock]
## # Create config for animating a panel
## var config = ControlTargetConfig.new()
## config.target = NodePath("../MyPanel")  # Drag-and-drop or manual path
## config.animation.action = AnimationConfig.AnimationAction.EXPAND
## config.animation.duration = 0.3
## 
## # Add to button's targets array
## button.targets.append(config)
## [/codeblock]
class_name ControlTargetConfig
extends TargetConfig


## The target control component.
##
## **How to set:**
## - **Drag and drop** (recommended): Drag a node from the scene tree to this field
## - **Manual path**: Type a NodePath (e.g., "../MyPanel", "$Container/MyButton")
@export var target: NodePath = NodePath()

## Inline animation configuration (no resource file needed).
## Configure animation properties directly in the Inspector with a dropdown menu.
## All animation settings are available here - no need to create separate resource files!
@export var animation: AnimationConfig = AnimationConfig.new()

## Resolves the target Control node.
##
## **When it's called:**
## Called automatically when a button/toggle with this target config is pressed.
##
## [param owner]: The node that owns this config (used to resolve relative paths).
## [return]: Returns the resolved Control node, or null if not found.
func get_target(owner: Node) -> Control:
	if not target.is_empty():
		var node = owner.get_node_or_null(target)
		if node is Control:
			return node as Control
	return null

## Applies the configured animation to the target.
## [param owner]: The node that owns this config (used to resolve the target path).
## [param is_on]: Optional boolean state (used by toggles to indicate ON/OFF state).
## Returns true if the action was applied successfully, false otherwise.
func apply(owner: Node, is_on: bool = true) -> bool:
	var target_node = get_target(owner)
	if target_node == null:
		var owner_name: String = "null"
		if owner != null:
			owner_name = owner.name
		push_warning("ControlTargetConfig: Could not resolve target for owner '%s'. Checked: target='%s'. Tip: Ensure the target node exists in the scene tree. Drag a node to target in the Inspector." % [owner_name, target])
		return false
	
	# Apply animation using the inline config
	var animation_signal = animation.apply_to_control(owner, target_node)
	# Note: We can't await in a Resource method, so the animation will run asynchronously
	return true


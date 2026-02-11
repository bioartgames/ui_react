## Static utility for setting up state-driven visibility with optional show/hide animations.
##
## Binds a State resource to a control's visibility and optionally runs AnimationReels when
## showing or hiding. Any control needing this behavior should call setup_visibility_binding
## from _ready. Skips reels on initial sync to avoid animating on load.
##
## Uses composition pattern - controls call into this utility rather than inheriting from it.
extends RefCounted
class_name ReactiveVisibilitySetup

## Binds visible_state to control.visible with optional show/hide AnimationReels.
## Reels use apply_to_control so no targets need to be set on the reels.
## [param control]: The control whose visibility is driven by state.
## [param visible_state]: State resource (bool) - when value changes, control.visible updates.
## [param show_reels]: Reels to run when becoming visible (applied via apply_to_control).
## [param hide_reels]: Reels to run when becoming hidden (applied via apply_to_control).
static func setup_visibility_binding(
	control: Control,
	visible_state: State,
	show_reels: Array,
	hide_reels: Array
) -> void:
	if not visible_state:
		return
	if not control:
		return

	var callback = func(new_value: Variant, old_value: Variant) -> void:
		var should_show: bool = bool(new_value)
		if should_show == control.visible:
			return
		if old_value == null:
			control.visible = should_show
			return
		var owner_node: Node = control.get_parent() if control.get_parent() else control
		if should_show:
			for reel in show_reels:
				if reel:
					reel.apply_to_control(owner_node, control)
			control.visible = true
		else:
			for reel in hide_reels:
				if reel:
					reel.apply_to_control(owner_node, control)
			control.visible = false

	visible_state.value_changed.connect(callback)
	callback.call(visible_state.value, null)

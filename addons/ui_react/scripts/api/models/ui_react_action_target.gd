@tool
## One inspector row for the Action layer: [b]when[/b] ([member trigger] or [member state_watch]) and [b]what[/b] ([member action] preset fields).
## Motion belongs on [UiAnimTarget] rows only — never call tween APIs from here.
class_name UiReactActionTarget
extends Resource

enum UiReactActionKind {
	GRAB_FOCUS,
	SET_VISIBLE,
	SET_UI_BOOL_FLAG,
	SET_MOUSE_FILTER,
	## [code]accumulator -= factor_a * factor_b[/code] when affordable ([code]UiReactStateOpService[/code]).
	SUBTRACT_PRODUCT_FROM_FLOAT,
}

@export var enabled: bool = true

## When set, this row runs from [signal UiBoolState.value_changed] and [method UiReactActionTargetHelper.sync_initial_state] only — [member trigger] is ignored at runtime.
@export var state_watch: UiBoolState

## Used only when [member state_watch] is [code]null[/code]. Reuses [enum UiAnimTarget.Trigger] vocabulary (Action layer spec in [code]docs/ACTION_LAYER.md[/code]).
@export var trigger: UiAnimTarget.Trigger = UiAnimTarget.Trigger.PRESSED

@export var action: UiReactActionKind = UiReactActionKind.GRAB_FOCUS:
	set(value):
		if action == value:
			return
		action = value
		notify_property_list_changed()

## NodePath for [code]GRAB_FOCUS[/code], [code]SET_VISIBLE[/code], and [code]SET_MOUSE_FILTER[/code].
@export_node_path("Control") var target: NodePath = NodePath()

## Used only when [member action] is [code]SET_VISIBLE[/code] and [member state_watch] is [code]null[/code] (control-triggered rows).
@export var visible_value: bool = true

## Used only when [member action] is [code]SET_VISIBLE[/code] and [member state_watch] is set (state-driven rows). Runtime reads [method UiBoolState.get_value] coerced to [code]bool[/code] ([code]UiReactActionTargetHelper[/code]).
@export var visible_when_true: bool = true
## See [member visible_when_true].
@export var visible_when_false: bool = false

@export var bool_flag_state: UiBoolState
@export var bool_flag_value: bool = true

@export var mouse_filter: Control.MouseFilter = Control.MOUSE_FILTER_STOP
@export var mouse_filter_when_true: Control.MouseFilter = Control.MOUSE_FILTER_STOP
@export var mouse_filter_when_false: Control.MouseFilter = Control.MOUSE_FILTER_IGNORE

@export var float_accumulator: UiFloatState
@export var float_factor_a: UiFloatState
@export var float_factor_b: UiFloatState


func _validate_property(property: Dictionary) -> void:
	var pname: StringName = property.name
	if pname == &"enabled" or pname == &"state_watch" or pname == &"action":
		return
	var sw_set: bool = state_watch != null
	if pname == &"trigger":
		if sw_set:
			property.usage = PROPERTY_USAGE_STORAGE
		else:
			property.usage = PROPERTY_USAGE_DEFAULT
		return

	match action:
		UiReactActionKind.GRAB_FOCUS:
			if pname == &"target":
				return
		UiReactActionKind.SET_VISIBLE:
			if pname == &"target":
				return
			if sw_set:
				if pname in [&"visible_when_true", &"visible_when_false"]:
					return
			else:
				if pname == &"visible_value":
					return
		UiReactActionKind.SET_UI_BOOL_FLAG:
			if pname in [&"bool_flag_state", &"bool_flag_value"]:
				return
		UiReactActionKind.SET_MOUSE_FILTER:
			if pname == &"target":
				return
			if sw_set:
				if pname in [&"mouse_filter_when_true", &"mouse_filter_when_false"]:
					return
			else:
				if pname == &"mouse_filter":
					return
		UiReactActionKind.SUBTRACT_PRODUCT_FROM_FLOAT:
			if pname in [&"float_accumulator", &"float_factor_a", &"float_factor_b"]:
				return
	property.usage = PROPERTY_USAGE_STORAGE

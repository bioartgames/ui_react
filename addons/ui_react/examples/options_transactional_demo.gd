extends Control
## P1 anchor: options-style **draft → apply / cancel** using [UiTransactionalState].
## Orchestration (**[method UiTransactionalGroup.begin_edit_all]**, **Apply**, **Cancel**) is handled by **[UiReactTransactionalActions]** on the **TxnActions** child node.
## The status line is **reactive**: this script updates a **[UiStringState]** bound to **[UiReactLabel.text_state]** (no direct [Label] assignment).

@export var master_volume_state: UiTransactionalState
@export var mute_state: UiTransactionalState
@export var transactional_group: UiTransactionalGroup
@export var status_text_state: UiStringState


func _ready() -> void:
	_connect_draft_signals()
	_refresh_status()


func _connect_draft_signals() -> void:
	if master_volume_state:
		if not master_volume_state.value_changed.is_connected(_on_draft_changed):
			master_volume_state.value_changed.connect(_on_draft_changed)
		if not master_volume_state.changed.is_connected(_refresh_status):
			master_volume_state.changed.connect(_refresh_status)
	if mute_state:
		if not mute_state.value_changed.is_connected(_on_draft_changed):
			mute_state.value_changed.connect(_on_draft_changed)
		if not mute_state.changed.is_connected(_refresh_status):
			mute_state.changed.connect(_refresh_status)


func _on_draft_changed(_new_value: Variant, _old_value: Variant) -> void:
	_refresh_status()


func _refresh_status() -> void:
	if status_text_state == null:
		return
	var d_vol: Variant = master_volume_state.get_draft_value() if master_volume_state else null
	var c_vol: Variant = master_volume_state.get_committed_value() if master_volume_state else null
	var d_mute: Variant = mute_state.get_draft_value() if mute_state else null
	var c_mute: Variant = mute_state.get_committed_value() if mute_state else null
	var pending: bool
	if transactional_group != null:
		pending = transactional_group.has_pending_changes()
	else:
		pending = (master_volume_state != null and master_volume_state.has_pending_changes()) or (
			mute_state != null and mute_state.has_pending_changes()
		)
	status_text_state.set_value(
		_format_options_status(d_vol, d_mute, c_vol, c_mute, pending)
	)


static func _format_options_status(
	d_vol: Variant,
	d_mute: Variant,
	c_vol: Variant,
	c_mute: Variant,
	pending: bool,
) -> String:
	return (
		"Draft: volume=%s mute=%s | Committed: volume=%s mute=%s%s"
		% [str(d_vol), str(d_mute), str(c_vol), str(c_mute), (" | *unsaved*" if pending else "")]
	)

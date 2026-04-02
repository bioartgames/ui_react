@tool
## Demo-only [UiComputedStringState] for [code]options_transactional_demo.tscn[/code]. [member sources] order: [code][volume_txn, mute_txn][/code] ([UiTransactionalState]).
extends "res://addons/ui_react/scripts/api/models/ui_computed_string_state.gd"


func compute_string() -> String:
	var vol: UiTransactionalState = _txn(0)
	var mute: UiTransactionalState = _txn(1)
	var d_vol: Variant = vol.get_draft_value() if vol else null
	var c_vol: Variant = vol.get_committed_value() if vol else null
	var d_mute: Variant = mute.get_draft_value() if mute else null
	var c_mute: Variant = mute.get_committed_value() if mute else null
	var pending: bool = (vol != null and vol.has_pending_changes()) or (
		mute != null and mute.has_pending_changes()
	)
	return (
		"Draft: volume=%s mute=%s | Committed: volume=%s mute=%s%s"
		% [str(d_vol), str(d_mute), str(c_vol), str(c_mute), (" | *unsaved*" if pending else "")]
	)


func _txn(index: int) -> UiTransactionalState:
	if index < 0 or index >= sources.size():
		return null
	var s: UiState = sources[index]
	return s as UiTransactionalState if s is UiTransactionalState else null

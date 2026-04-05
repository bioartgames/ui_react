@tool
## [UiComputedStringState] that formats draft vs committed [UiTransactionalState] rows ([code]sources[0][/code], [code]sources[1][/code]).
class_name UiComputedTransactionalStatusString
extends UiComputedStringState


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

## Validates [UiReactAudioFeedbackTarget] / [UiReactHapticFeedbackTarget] rows on [UiReact*] controls (dock diagnostics).
class_name UiReactFeedbackValidator
extends RefCounted


static func validate_feedback_targets(
	component: String, owner: Control, node_path: NodePath
) -> Array[UiReactDiagnosticModel.DiagnosticIssue]:
	var out: Array[UiReactDiagnosticModel.DiagnosticIssue] = []
	if owner == null:
		return out
	out.append_array(_validate_audio_array(component, owner, node_path))
	out.append_array(_validate_haptic_array(component, owner, node_path))
	return out


static func _validate_audio_array(
	component: String, owner: Control, node_path: NodePath
) -> Array[UiReactDiagnosticModel.DiagnosticIssue]:
	var issues: Array[UiReactDiagnosticModel.DiagnosticIssue] = []
	if not &"audio_targets" in owner:
		return issues
	var arr_v: Variant = owner.get(&"audio_targets")
	if arr_v == null or not (arr_v is Array):
		return issues
	var arr: Array = arr_v as Array
	for i in range(arr.size()):
		var row_v: Variant = arr[i]
		if row_v == null:
			issues.append(
				UiReactDiagnosticModel.DiagnosticIssue.make_structured(
					UiReactDiagnosticModel.Severity.WARNING,
					component,
					str(owner.name),
					"Audio feedback row %d is empty (null)." % i,
					"In the Inspector, remove that row or assign a UiReactAudioFeedbackTarget resource.",
					node_path,
					&"audio_targets",
					&"",
					UiReactDiagnosticModel.IssueKind.GENERIC,
					"",
				)
			)
			continue
		if not (row_v is UiReactAudioFeedbackTarget):
			continue
		var row: UiReactAudioFeedbackTarget = row_v as UiReactAudioFeedbackTarget
		if not row.enabled:
			continue
		if row.state_watch != null and row.trigger != UiAnimTarget.Trigger.PRESSED:
			issues.append(
				UiReactDiagnosticModel.DiagnosticIssue.make_structured(
					UiReactDiagnosticModel.Severity.WARNING,
					component,
					str(owner.name),
					(
						"audio_targets[%d]: state_watch set but trigger is not PRESSED (trigger ignored at runtime)."
						% i
					),
					"Set trigger to PRESSED when using state_watch, or clear state_watch for control-driven rows.",
					node_path,
					&"audio_targets",
					&"",
					UiReactDiagnosticModel.IssueKind.GENERIC,
					"",
				)
			)
		if row.state_watch == null:
			if not UiReactValidatorCommon.is_anim_trigger_allowed(component, row.trigger):
				issues.append(
					UiReactDiagnosticModel.DiagnosticIssue.make_structured(
						UiReactDiagnosticModel.Severity.WARNING,
						component,
						str(owner.name),
						(
							"audio_targets[%d] uses trigger %s, but this control does not fire that signal."
							% [i, UiReactValidatorCommon.format_anim_trigger_name(row.trigger)]
						),
						(
							"For %s, use one of the supported triggers: %s."
							% [component, UiReactValidatorCommon.format_allowed_anim_triggers_hint(component)]
						),
						node_path,
						&"audio_targets",
						&"",
						UiReactDiagnosticModel.IssueKind.GENERIC,
						"",
					)
				)
		if row.player.is_empty():
			issues.append(
				UiReactDiagnosticModel.DiagnosticIssue.make_structured(
					UiReactDiagnosticModel.Severity.WARNING,
					component,
					str(owner.name),
					"audio_targets[%d] has no AudioStreamPlayer path." % i,
					"Assign player to an AudioStreamPlayer under this control.",
					node_path,
					&"audio_targets",
					&"",
					UiReactDiagnosticModel.IssueKind.GENERIC,
					"",
				)
			)
			continue
		var tn: Node = owner.get_node_or_null(row.player)
		if tn == null:
			issues.append(
				UiReactDiagnosticModel.DiagnosticIssue.make_structured(
					UiReactDiagnosticModel.Severity.ERROR,
					component,
					str(owner.name),
					"audio_targets[%d] player path not found: %s." % [i, row.player],
					"Fix the path or pick the node again in the Inspector.",
					node_path,
					&"audio_targets",
					&"",
					UiReactDiagnosticModel.IssueKind.GENERIC,
					"",
				)
			)
			continue
		if not (tn is AudioStreamPlayer):
			issues.append(
				UiReactDiagnosticModel.DiagnosticIssue.make_structured(
					UiReactDiagnosticModel.Severity.ERROR,
					component,
					str(owner.name),
					"audio_targets[%d] player is not an AudioStreamPlayer." % i,
					"Point player at an AudioStreamPlayer node.",
					node_path,
					&"audio_targets",
					&"",
					UiReactDiagnosticModel.IssueKind.GENERIC,
					"",
				)
			)
	return issues


static func _validate_haptic_array(
	component: String, owner: Control, node_path: NodePath
) -> Array[UiReactDiagnosticModel.DiagnosticIssue]:
	var issues: Array[UiReactDiagnosticModel.DiagnosticIssue] = []
	if not &"haptic_targets" in owner:
		return issues
	var arr_v: Variant = owner.get(&"haptic_targets")
	if arr_v == null or not (arr_v is Array):
		return issues
	var arr: Array = arr_v as Array
	for i in range(arr.size()):
		var row_v: Variant = arr[i]
		if row_v == null:
			issues.append(
				UiReactDiagnosticModel.DiagnosticIssue.make_structured(
					UiReactDiagnosticModel.Severity.WARNING,
					component,
					str(owner.name),
					"Haptic feedback row %d is empty (null)." % i,
					"In the Inspector, remove that row or assign a UiReactHapticFeedbackTarget resource.",
					node_path,
					&"haptic_targets",
					&"",
					UiReactDiagnosticModel.IssueKind.GENERIC,
					"",
				)
			)
			continue
		if not (row_v is UiReactHapticFeedbackTarget):
			continue
		var row: UiReactHapticFeedbackTarget = row_v as UiReactHapticFeedbackTarget
		if not row.enabled:
			continue
		if row.state_watch != null and row.trigger != UiAnimTarget.Trigger.PRESSED:
			issues.append(
				UiReactDiagnosticModel.DiagnosticIssue.make_structured(
					UiReactDiagnosticModel.Severity.WARNING,
					component,
					str(owner.name),
					(
						"haptic_targets[%d]: state_watch set but trigger is not PRESSED (trigger ignored at runtime)."
						% i
					),
					"Set trigger to PRESSED when using state_watch, or clear state_watch for control-driven rows.",
					node_path,
					&"haptic_targets",
					&"",
					UiReactDiagnosticModel.IssueKind.GENERIC,
					"",
				)
			)
		if row.state_watch == null:
			if not UiReactValidatorCommon.is_anim_trigger_allowed(component, row.trigger):
				issues.append(
					UiReactDiagnosticModel.DiagnosticIssue.make_structured(
						UiReactDiagnosticModel.Severity.WARNING,
						component,
						str(owner.name),
						(
							"haptic_targets[%d] uses trigger %s, but this control does not fire that signal."
							% [i, UiReactValidatorCommon.format_anim_trigger_name(row.trigger)]
						),
						(
							"For %s, use one of the supported triggers: %s."
							% [component, UiReactValidatorCommon.format_allowed_anim_triggers_hint(component)]
						),
						node_path,
						&"haptic_targets",
						&"",
						UiReactDiagnosticModel.IssueKind.GENERIC,
						"",
					)
				)
		if row.duration_sec <= 0.0:
			issues.append(
				UiReactDiagnosticModel.DiagnosticIssue.make_structured(
					UiReactDiagnosticModel.Severity.WARNING,
					component,
					str(owner.name),
					"haptic_targets[%d]: duration_sec must be > 0." % i,
					"Set a positive duration or remove the row.",
					node_path,
					&"haptic_targets",
					&"",
					UiReactDiagnosticModel.IssueKind.GENERIC,
					"",
				)
			)
		if row.weak_magnitude < 0.0 or row.weak_magnitude > 1.0:
			issues.append(
				UiReactDiagnosticModel.DiagnosticIssue.make_structured(
					UiReactDiagnosticModel.Severity.WARNING,
					component,
					str(owner.name),
					"haptic_targets[%d]: weak_magnitude should be in [0, 1] (runtime clamps)." % i,
					"Clamp weak_magnitude to 0..1 for predictable rumble.",
					node_path,
					&"haptic_targets",
					&"",
					UiReactDiagnosticModel.IssueKind.GENERIC,
					"",
				)
			)
		if row.strong_magnitude < 0.0 or row.strong_magnitude > 1.0:
			issues.append(
				UiReactDiagnosticModel.DiagnosticIssue.make_structured(
					UiReactDiagnosticModel.Severity.WARNING,
					component,
					str(owner.name),
					"haptic_targets[%d]: strong_magnitude should be in [0, 1] (runtime clamps)." % i,
					"Clamp strong_magnitude to 0..1 for predictable rumble.",
					node_path,
					&"haptic_targets",
					&"",
					UiReactDiagnosticModel.IssueKind.GENERIC,
					"",
				)
			)
	return issues

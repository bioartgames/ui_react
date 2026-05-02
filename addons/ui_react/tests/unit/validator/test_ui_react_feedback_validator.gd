extends GutTest


func test_audio_row_bad_trigger_emits_warning() -> void:
	var host: UiReactButton = autoqfree(UiReactButton.new())
	host.name = "Host"
	var row := UiReactAudioFeedbackTarget.new()
	row.enabled = true
	row.trigger = UiAnimTarget.Trigger.SELECTION_CHANGED
	row.player = NodePath("Sfx")
	var sfx := AudioStreamPlayer.new()
	host.add_child(sfx)
	sfx.name = "Sfx"
	host.audio_targets = [row]
	var issues := UiReactFeedbackValidator.validate_feedback_targets("UiReactButton", host, NodePath("."))
	var warns := 0
	for it in issues:
		if it.severity == UiReactDiagnosticModel.Severity.WARNING:
			warns += 1
	assert_true(warns >= 1)

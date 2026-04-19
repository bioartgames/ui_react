extends GutTest


func test_set_float_literal_missing_target_emits_warning() -> void:
	var host: UiReactButton = autoqfree(UiReactButton.new()) as UiReactButton
	host.name = "Host"
	var row := UiReactActionTarget.new()
	row.enabled = true
	row.action = UiReactActionTarget.UiReactActionKind.SET_FLOAT_LITERAL
	row.state_watch = UiBoolState.new(false)
	row.trigger = UiAnimTarget.Trigger.PRESSED
	row.float_literal_target = null
	host.action_targets = [row]
	var issues := UiReactActionValidator.validate_action_targets("UiReactButton", host, NodePath("."))
	assert_true(issues.size() >= 1)

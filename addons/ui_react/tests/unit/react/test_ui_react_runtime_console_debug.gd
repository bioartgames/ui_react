extends GutTest


func after_each() -> void:
	UiReactRuntimeConsoleDebug.clear_test_capture()
	UiReactRuntimeConsoleDebug.set_force_enabled_for_tests(false)
	ProjectSettings.set_setting(
		UiReactDockConfig.KEY_RUNTIME_CONSOLE_DEBUG_ENABLED, false
	)


func test_effective_force_bypasses_all() -> void:
	UiReactRuntimeConsoleDebug.set_force_enabled_for_tests(true)
	assert_true(UiReactRuntimeConsoleDebug.effective_enabled())


func test_effective_without_force_respects_gate() -> void:
	UiReactRuntimeConsoleDebug.set_force_enabled_for_tests(false)
	var key := UiReactDockConfig.KEY_RUNTIME_CONSOLE_DEBUG_ENABLED
	ProjectSettings.set_setting(key, true)
	if Engine.is_editor_hint():
		assert_false(
			UiReactRuntimeConsoleDebug.effective_enabled(),
			"editor-hint contexts skip traces unless force_tests is used"
		)
		return
	if not OS.is_debug_build():
		push_warning(
			"test_effective_without_force_respects_gate: skipping non-debug GUT runner"
		)
		return
	ProjectSettings.set_setting(key, false)
	assert_false(UiReactRuntimeConsoleDebug.effective_enabled())
	ProjectSettings.set_setting(key, true)
	assert_true(UiReactRuntimeConsoleDebug.effective_enabled())


func test_maybe_wire_capture_under_force() -> void:
	var host: Control = autoqfree(Control.new())
	add_child_autofree(host)
	var rule := UiReactWireSortArrayByKey.new()
	rule.rule_id = "probe_rule"
	rule.enabled = true
	UiReactRuntimeConsoleDebug.clear_test_capture()
	UiReactRuntimeConsoleDebug.set_force_enabled_for_tests(true)
	UiReactRuntimeConsoleDebug.maybe_wire_apply(host, rule)
	var cap := UiReactRuntimeConsoleDebug.get_test_capture_snapshot()
	assert_eq(cap.size(), 1)
	var line := cap[0]
	assert_true(line.contains("[UiReact:d]"), line)
	assert_true(line.contains("WIRE"), line)
	assert_true(line.contains("probe_rule"), line)


func test_truncation_on_long_rule_id_under_force() -> void:
	var host: Control = autoqfree(Control.new())
	add_child_autofree(host)
	var long_id := "q".repeat(301)
	var rule := UiReactWireSortArrayByKey.new()
	rule.rule_id = long_id
	rule.enabled = true
	UiReactRuntimeConsoleDebug.clear_test_capture()
	UiReactRuntimeConsoleDebug.set_force_enabled_for_tests(true)
	UiReactRuntimeConsoleDebug.maybe_wire_apply(host, rule)
	var cap := UiReactRuntimeConsoleDebug.get_test_capture_snapshot()
	assert_eq(cap.size(), 1)
	assert_true(cap[0].ends_with("…") or cap[0].contains("…"), cap[0])

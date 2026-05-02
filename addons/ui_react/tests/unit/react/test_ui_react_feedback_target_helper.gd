extends GutTest

const CMP := "UiReactLabel"


func _host_label() -> UiReactLabel:
	return autoqfree(UiReactLabel.new())


func _attach_min_stream(player: AudioStreamPlayer) -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 44100
	player.stream = gen


func _audio_row_player(path: NodePath, trig: UiAnimTarget.Trigger = UiAnimTarget.Trigger.PRESSED) -> UiReactAudioFeedbackTarget:
	var r := UiReactAudioFeedbackTarget.new()
	r.player = path
	r.trigger = trig
	return r


func _haptic_row(trig: UiAnimTarget.Trigger = UiAnimTarget.Trigger.PRESSED) -> UiReactHapticFeedbackTarget:
	var r := UiReactHapticFeedbackTarget.new()
	r.trigger = trig
	r.duration_sec = 0.1
	return r


func test_validate_audio_preserves_disabled_row() -> void:
	var owner := _host_label()
	var row := _audio_row_player(NodePath(""))
	row.enabled = false
	var arr: Array[UiReactAudioFeedbackTarget] = [row]
	var out := UiReactFeedbackTargetHelper.validate_audio_targets(owner, CMP, arr)
	assert_eq(out.size(), 1)
	assert_same(out[0], row)


func test_validate_audio_skips_null() -> void:
	var owner := _host_label()
	var arr: Array[UiReactAudioFeedbackTarget] = []
	arr.resize(1)
	var out := UiReactFeedbackTargetHelper.validate_audio_targets(owner, CMP, arr)
	assert_true(out.is_empty())


func test_validate_audio_drops_empty_player() -> void:
	var owner := _host_label()
	var row := _audio_row_player(NodePath(""))
	var arr: Array[UiReactAudioFeedbackTarget] = [row]
	var out := UiReactFeedbackTargetHelper.validate_audio_targets(owner, CMP, arr)
	assert_engine_error(1)
	assert_true(out.is_empty())


func test_validate_audio_keeps_child_stream_player() -> void:
	var owner := _host_label()
	add_child_autofree(owner)
	var sfx := AudioStreamPlayer.new()
	owner.add_child(sfx)
	sfx.name = "Sfx"
	var row := _audio_row_player(NodePath("Sfx"))
	var arr: Array[UiReactAudioFeedbackTarget] = [row]
	var out := UiReactFeedbackTargetHelper.validate_audio_targets(owner, CMP, arr)
	assert_eq(out.size(), 1)


func test_validate_haptic_drops_bad_duration() -> void:
	var owner := _host_label()
	var row := _haptic_row()
	row.duration_sec = 0.0
	var arr: Array[UiReactHapticFeedbackTarget] = [row]
	var out := UiReactFeedbackTargetHelper.validate_haptic_targets(owner, CMP, arr)
	assert_engine_error(1)
	assert_true(out.is_empty())


func test_collect_audio_skips_state_watch() -> void:
	var row_a := _audio_row_player(NodePath("X"))
	row_a.state_watch = UiBoolState.new()
	row_a.trigger = UiAnimTarget.Trigger.PRESSED
	var row_b := _audio_row_player(NodePath("Y"))
	row_b.trigger = UiAnimTarget.Trigger.HOVER_ENTER
	var rows: Array[UiReactAudioFeedbackTarget] = [row_a, row_b]
	var tm := UiReactFeedbackTargetHelper.collect_control_trigger_map_audio(rows)
	assert_eq(tm.size(), 1)
	assert_true(tm.has(UiAnimTarget.Trigger.HOVER_ENTER))


func test_merge_expands_trigger_map_for_both_arrays() -> void:
	var host := _host_label()
	add_child_autofree(host)
	var sfx := AudioStreamPlayer.new()
	host.add_child(sfx)
	sfx.name = "Sfx"
	var ar := _audio_row_player(NodePath("Sfx"), UiAnimTarget.Trigger.HOVER_ENTER)
	var hr := _haptic_row(UiAnimTarget.Trigger.HOVER_ENTER)
	host.audio_targets = [ar]
	host.haptic_targets = [hr]
	var trigger_map: Dictionary = {}
	UiReactFeedbackTargetHelper.apply_validated_audio_and_haptic_and_merge_triggers(host, CMP, trigger_map)
	assert_true(trigger_map.has(UiAnimTarget.Trigger.HOVER_ENTER))


func test_sync_initial_state_skips_audio_when_state_watch_false() -> void:
	var host := _host_label()
	add_child_autofree(host)
	var sfx := AudioStreamPlayer.new()
	host.add_child(sfx)
	sfx.name = "Sfx"
	_attach_min_stream(sfx)
	var watch := UiBoolState.new(false)
	var row := UiReactAudioFeedbackTarget.new()
	row.state_watch = watch
	row.trigger = UiAnimTarget.Trigger.PRESSED
	row.player = NodePath("Sfx")
	host.audio_targets = [row]
	host.haptic_targets = []
	var trigger_map: Dictionary = {}
	UiReactFeedbackTargetHelper.apply_validated_audio_and_haptic_and_merge_triggers(host, CMP, trigger_map)
	UiReactFeedbackTargetHelper.sync_initial_state(host, CMP, host.audio_targets, host.haptic_targets)
	assert_false(sfx.playing)


func test_sync_initial_state_plays_audio_when_state_watch_true() -> void:
	var host := _host_label()
	add_child_autofree(host)
	var sfx := AudioStreamPlayer.new()
	host.add_child(sfx)
	sfx.name = "Sfx"
	_attach_min_stream(sfx)
	var watch := UiBoolState.new(true)
	var row := UiReactAudioFeedbackTarget.new()
	row.state_watch = watch
	row.trigger = UiAnimTarget.Trigger.PRESSED
	row.player = NodePath("Sfx")
	host.audio_targets = [row]
	host.haptic_targets = []
	var trigger_map: Dictionary = {}
	UiReactFeedbackTargetHelper.apply_validated_audio_and_haptic_and_merge_triggers(host, CMP, trigger_map)
	UiReactFeedbackTargetHelper.sync_initial_state(host, CMP, host.audio_targets, host.haptic_targets)
	assert_true(sfx.playing)


func test_state_watch_rising_edge_dispatches_audio_only_on_false_to_true() -> void:
	var host := _host_label()
	add_child_autofree(host)
	var sfx := AudioStreamPlayer.new()
	host.add_child(sfx)
	sfx.name = "Sfx"
	_attach_min_stream(sfx)
	var watch := UiBoolState.new(false)
	var row := UiReactAudioFeedbackTarget.new()
	row.state_watch = watch
	row.trigger = UiAnimTarget.Trigger.PRESSED
	row.player = NodePath("Sfx")
	host.audio_targets = [row]
	host.haptic_targets = []
	var trigger_map: Dictionary = {}
	UiReactFeedbackTargetHelper.apply_validated_audio_and_haptic_and_merge_triggers(host, CMP, trigger_map)
	UiReactFeedbackTargetHelper.sync_initial_state(host, CMP, host.audio_targets, host.haptic_targets)
	assert_false(sfx.playing)
	watch.set_value(true)
	assert_true(sfx.playing)
	sfx.stop()
	assert_false(sfx.playing)
	watch.set_value(false)
	assert_false(sfx.playing)
	watch.set_value(true)
	assert_true(sfx.playing)


func test_teardown_clears_feedback_state_watch_bindings() -> void:
	var host: UiReactCheckBox = autoqfree(UiReactCheckBox.new())
	add_child_autofree(host)
	var sfx := AudioStreamPlayer.new()
	host.add_child(sfx)
	sfx.name = "Sfx"
	var watch := UiBoolState.new()
	var row := UiReactAudioFeedbackTarget.new()
	row.state_watch = watch
	row.trigger = UiAnimTarget.Trigger.PRESSED
	row.player = NodePath("Sfx")
	host.audio_targets = [row]
	host.haptic_targets = []
	var trigger_map: Dictionary = {}
	UiReactFeedbackTargetHelper.apply_validated_audio_and_haptic_and_merge_triggers(host, "UiReactCheckBox", trigger_map)
	assert_true(watch.value_changed.get_connections().size() > 0)
	UiReactFeedbackTargetHelper.teardown_for_control_exit(host)
	assert_eq(watch.value_changed.get_connections().size(), 0)

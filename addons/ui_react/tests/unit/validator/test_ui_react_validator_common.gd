extends GutTest

const KNOWN_COMPONENT := "UiReactButton"
const UNKNOWN_COMPONENT := "__UiReactValidatorCommonTestUnknown__"
const SECOND_KNOWN_COMPONENT := "UiReactOptionButton"


# --- variant_type_name ---


func test_variant_type_name_null() -> void:
	var v = null
	assert_eq(UiReactValidatorCommon.variant_type_name(v), str(typeof(v)))


func test_variant_type_name_int() -> void:
	var v := 7
	assert_eq(UiReactValidatorCommon.variant_type_name(v), str(typeof(v)))


func test_variant_type_name_bool_state_resource() -> void:
	var v := UiBoolState.new()
	assert_eq(UiReactValidatorCommon.variant_type_name(v), v.get_class())


func test_variant_type_name_string_primitive() -> void:
	var v := "hello"
	assert_eq(UiReactValidatorCommon.variant_type_name(v), str(typeof(v)))


# --- get_allowed_anim_triggers ---


func test_get_allowed_unknown_returns_empty() -> void:
	var out := UiReactValidatorCommon.get_allowed_anim_triggers(UNKNOWN_COMPONENT)
	assert_true(out is Array)
	assert_true(out.is_empty())


func test_get_allowed_button_includes_pressed() -> void:
	var out := UiReactValidatorCommon.get_allowed_anim_triggers(KNOWN_COMPONENT)
	assert_true(out is Array)
	assert_false(out.is_empty())
	assert_true(out.has(UiAnimTarget.Trigger.PRESSED))


# --- is_anim_trigger_allowed ---


func test_is_anim_allowed_unknown_component_always_true() -> void:
	assert_true(
		UiReactValidatorCommon.is_anim_trigger_allowed(
			UNKNOWN_COMPONENT,
			UiAnimTarget.Trigger.TEXT_CHANGED,
		)
	)


func test_is_anim_allowed_button_pressed_true() -> void:
	assert_true(
		UiReactValidatorCommon.is_anim_trigger_allowed(
			KNOWN_COMPONENT,
			UiAnimTarget.Trigger.PRESSED,
		)
	)


func test_is_anim_allowed_button_text_changed_false() -> void:
	assert_false(
		UiReactValidatorCommon.is_anim_trigger_allowed(
			KNOWN_COMPONENT,
			UiAnimTarget.Trigger.TEXT_CHANGED,
		)
	)


func test_is_anim_allowed_button_focus_entered_true() -> void:
	assert_true(
		UiReactValidatorCommon.is_anim_trigger_allowed(
			KNOWN_COMPONENT,
			UiAnimTarget.Trigger.FOCUS_ENTERED,
		)
	)


func test_is_anim_allowed_button_focus_exited_true() -> void:
	assert_true(
		UiReactValidatorCommon.is_anim_trigger_allowed(
			KNOWN_COMPONENT,
			UiAnimTarget.Trigger.FOCUS_EXITED,
		)
	)


func test_is_anim_allowed_checkbox_focus_entered_true() -> void:
	assert_true(
		UiReactValidatorCommon.is_anim_trigger_allowed(
			"UiReactCheckBox",
			UiAnimTarget.Trigger.FOCUS_ENTERED,
		)
	)


# --- format_anim_trigger_name ---


func test_format_anim_trigger_name_pressed() -> void:
	assert_eq(
		UiReactValidatorCommon.format_anim_trigger_name(UiAnimTarget.Trigger.PRESSED),
		"PRESSED",
	)


func test_format_anim_trigger_name_text_changed() -> void:
	assert_eq(
		UiReactValidatorCommon.format_anim_trigger_name(UiAnimTarget.Trigger.TEXT_CHANGED),
		"TEXT_CHANGED",
	)


# --- format_allowed_anim_triggers_hint ---


func test_format_hint_unknown_plain_language_placeholder() -> void:
	var hint := UiReactValidatorCommon.format_allowed_anim_triggers_hint(UNKNOWN_COMPONENT)
	assert_true(hint.contains("No motion triggers"))
	assert_true(hint.contains("addon"))


func test_format_hint_option_button_contains_selection_changed() -> void:
	var hint := UiReactValidatorCommon.format_allowed_anim_triggers_hint(SECOND_KNOWN_COMPONENT)
	assert_true(hint.contains("SELECTION_CHANGED"))
	assert_true(hint.contains(","))


func test_format_hint_button_contains_pressed() -> void:
	var hint := UiReactValidatorCommon.format_allowed_anim_triggers_hint(KNOWN_COMPONENT)
	assert_true(hint.contains("PRESSED"))
	assert_true(hint.contains("FOCUS_ENTERED"))

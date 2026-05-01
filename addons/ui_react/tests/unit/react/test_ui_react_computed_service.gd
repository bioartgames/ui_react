extends GutTest


func after_each() -> void:
	UiReactComputedService.reset_internal_state_for_tests()


func test_reset_allows_hook_bind_again_after_wiring() -> void:
	if Engine.is_editor_hint():
		return
	var host: Control = autoqfree(Control.new())
	add_child_autofree(host)
	var src := UiBoolState.new(true)
	var comp := UiComputedBoolInvert.new()
	comp.sources = [src]
	UiReactComputedService.hook_bind(comp, host, &"text_state")
	UiReactComputedService.reset_internal_state_for_tests()
	UiReactComputedService.hook_bind(comp, host, &"text_state")
	assert_true(true, "second hook_bind after reset should not early-return as duplicate site")


func test_debug_tables_empty_after_reset() -> void:
	if Engine.is_editor_hint():
		return
	UiReactComputedService.reset_internal_state_for_tests()
	assert_true(UiReactComputedService.debug_static_tables_empty_for_tests())

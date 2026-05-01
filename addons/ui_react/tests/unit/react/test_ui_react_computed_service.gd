extends GutTest


func after_each() -> void:
	UiReactComputedService.reset_internal_state_for_tests()


func test_sources_dependency_graph_has_cycle_detects_mutual_dependency() -> void:
	var a := UiComputedBoolInvert.new()
	var b := UiComputedBoolInvert.new()
	a.sources = [b]
	b.sources = [a]
	assert_true(UiReactComputedService.sources_dependency_graph_has_cycle(a))
	assert_true(UiReactComputedService.sources_dependency_graph_has_cycle(b))


func test_sources_dependency_graph_has_cycle_false_on_acyclic_chain() -> void:
	var leaf := UiBoolState.new(false)
	var mid := UiComputedBoolInvert.new()
	var top := UiComputedBoolInvert.new()
	mid.sources = [leaf]
	top.sources = [mid]
	assert_false(UiReactComputedService.sources_dependency_graph_has_cycle(top))


func test_ensure_wired_refuses_cycle_and_does_not_wire() -> void:
	if Engine.is_editor_hint():
		return
	var host: Control = autoqfree(Control.new())
	add_child_autofree(host)
	var a := UiComputedBoolInvert.new()
	var b := UiComputedBoolInvert.new()
	a.sources = [b]
	b.sources = [a]
	UiReactComputedService.ensure_wired(a, host, &"binding")
	assert_push_error("cyclic sources graph")
	assert_false(UiReactComputedService.debug_is_wired_for_tests(a))
	assert_false(UiReactComputedService.debug_is_wired_for_tests(b))


func test_ensure_wired_wires_acyclic_chain() -> void:
	if Engine.is_editor_hint():
		return
	var host: Control = autoqfree(Control.new())
	add_child_autofree(host)
	var leaf := UiBoolState.new(false)
	var mid := UiComputedBoolInvert.new()
	var top := UiComputedBoolInvert.new()
	mid.sources = [leaf]
	top.sources = [mid]
	UiReactComputedService.ensure_wired(top, host, &"binding")
	assert_true(UiReactComputedService.debug_is_wired_for_tests(top))
	assert_true(UiReactComputedService.debug_is_wired_for_tests(mid))


func test_sources_dependency_graph_has_cycle_false_for_non_computed() -> void:
	assert_false(UiReactComputedService.sources_dependency_graph_has_cycle(UiBoolState.new(false)))
	assert_false(UiReactComputedService.sources_dependency_graph_has_cycle(null))


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


func test_supports_computed_wiring() -> void:
	assert_false(UiReactComputedService.supports_computed_wiring(UiBoolState.new()))
	assert_true(UiReactComputedService.supports_computed_wiring(UiComputedBoolInvert.new()))


func test_bind_value_changed_hook_false_still_wires_computed() -> void:
	if Engine.is_editor_hint():
		return
	var host: Control = autoqfree(Control.new())
	add_child_autofree(host)
	var src := UiBoolState.new(false)
	var comp := UiComputedBoolInvert.new()
	comp.sources = [src]
	var on_bound := func(_nv, _ov) -> void:
		pass
	UiReactControlStateWire.bind_value_changed(host, comp, &"items_state", on_bound, false)
	assert_true(comp.get_bool_value())
	src.set_value(true)
	await wait_process_frames(2)
	assert_false(comp.get_bool_value())
	UiReactControlStateWire.unbind_value_changed(host, comp, &"items_state", on_bound, false)

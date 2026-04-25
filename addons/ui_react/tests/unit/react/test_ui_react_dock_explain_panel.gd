extends GutTest

const _ExplainPanelScript := preload("res://addons/ui_react/editor_plugin/dock/ui_react_dock_explain_panel.gd")
const _SnapScript := preload("res://addons/ui_react/editor_plugin/models/ui_react_explain_graph_snapshot.gd")


func test_find_first_wire_flow_edge_index_for_rule_returns_first_match() -> void:
	var layout := {
		&"draw_edges": [
			{
				&"kind": _SnapScript.EdgeKind.BINDING,
				&"wire_rule_index": 2,
			},
			{
				&"kind": _SnapScript.EdgeKind.WIRE_FLOW,
				&"wire_rule_index": 2,
			},
			{
				&"kind": _SnapScript.EdgeKind.WIRE_FLOW,
				&"wire_rule_index": 2,
			},
		]
	}
	var idx := int(
		(_ExplainPanelScript as Object).call(&"find_first_wire_flow_edge_index_for_rule", layout, 2)
	)
	assert_eq(idx, 1)


func test_find_first_wire_flow_edge_index_for_rule_respects_visibility_filter() -> void:
	var layout := {
		&"draw_edges": [
			{
				&"kind": _SnapScript.EdgeKind.WIRE_FLOW,
				&"wire_rule_index": 9,
			},
			{
				&"kind": _SnapScript.EdgeKind.WIRE_FLOW,
				&"wire_rule_index": 9,
			},
		]
	}
	var only_second_visible: Callable = func(i: int) -> bool:
		return i == 1
	var idx := int(
		(_ExplainPanelScript as Object).call(
			&"find_first_wire_flow_edge_index_for_rule",
			layout,
			9,
			only_second_visible
		)
	)
	assert_eq(idx, 1)


func test_find_first_wire_flow_edge_index_for_rule_returns_minus_one_when_missing() -> void:
	var layout := {
		&"draw_edges": [
			{
				&"kind": _SnapScript.EdgeKind.WIRE_FLOW,
				&"wire_rule_index": 3,
			},
		]
	}
	var idx := int(
		(_ExplainPanelScript as Object).call(&"find_first_wire_flow_edge_index_for_rule", layout, 77)
	)
	assert_eq(idx, -1)

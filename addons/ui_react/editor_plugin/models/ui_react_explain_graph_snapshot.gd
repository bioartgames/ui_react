## Immutable snapshot for [UiReactExplainGraphBuilder] (editor-only explain graph).
class_name UiReactExplainGraphSnapshot
extends RefCounted

enum NodeKind {
	CONTROL,
	UI_STATE,
	UI_COMPUTED,
}

enum EdgeKind {
	BINDING,
	COMPUTED_SOURCE,
	WIRE_FLOW,
}

## Keys: [code]id[/code] [String], [code]kind[/code] [int NodeKind], [code]label[/code] [String]
var nodes: Array[Dictionary] = []

## Keys: [code]from_id[/code], [code]to_id[/code], [code]kind[/code] [int EdgeKind], [code]label[/code] [String]
var edges: Array[Dictionary] = []

## Keys: [code]node_ids[/code] [code]PackedStringArray[/code], [code]summary[/code] [String]
var cycle_candidates: Array[Dictionary] = []

## [code]PackedStringArray[/code] node ids (state/computed), upstream of focus control.
var upstream_ids: PackedStringArray = PackedStringArray()

## [code]PackedStringArray[/code] node ids, downstream of focus-bound states.
var downstream_ids: PackedStringArray = PackedStringArray()

## Human-readable lines for dock BBCode (pre-built by builder).
var upstream_lines: PackedStringArray = PackedStringArray()
var downstream_lines: PackedStringArray = PackedStringArray()
var bound_state_lines: PackedStringArray = PackedStringArray()

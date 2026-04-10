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

## Layout scope for the graph centered on the refresh host (not the current narrative anchor).
## [code]PackedStringArray[/code] node ids (state/computed), upstream of that host’s bindings.
var upstream_ids: PackedStringArray = PackedStringArray()

## Layout scope: node ids downstream of states bound to that host.
var downstream_ids: PackedStringArray = PackedStringArray()

## Legacy fields; narrative lines are produced by [method UiReactExplainGraphBuilder.compute_narrative].
## Human-readable lines for dock BBCode (pre-built by builder).
var upstream_lines: PackedStringArray = PackedStringArray()
var downstream_lines: PackedStringArray = PackedStringArray()
var bound_state_lines: PackedStringArray = PackedStringArray()

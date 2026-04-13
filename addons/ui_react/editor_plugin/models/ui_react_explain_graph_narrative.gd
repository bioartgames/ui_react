## Per-anchor narrative for the Dependency Graph details pane ([code]CB-018A.5[/code]).
## Layout scope remains on [UiReactExplainGraphSnapshot] [code]upstream_ids[/code] / [code]downstream_ids[/code].
class_name UiReactExplainGraphNarrative
extends RefCounted

var anchor_id: String = ""
var bound_state_lines: PackedStringArray = PackedStringArray()
var upstream_lines: PackedStringArray = PackedStringArray()
## When true, details pane skips printing the Upstream block (same ids still in [member upstream_node_ids]).
var omit_upstream_in_details: bool = false
var downstream_state_lines: PackedStringArray = PackedStringArray()
var downstream_control_lines: PackedStringArray = PackedStringArray()
## Ids included in upstream narrative (for canvas mismatch checks).
var upstream_node_ids: PackedStringArray = PackedStringArray()
## Ids included in downstream narrative.
var downstream_node_ids: PackedStringArray = PackedStringArray()

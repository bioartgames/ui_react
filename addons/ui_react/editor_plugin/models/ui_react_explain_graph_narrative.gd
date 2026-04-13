## Per-anchor narrative for the Dependency Graph details pane ([code]CB-018A.5[/code]).
## Layout scope remains on [UiReactExplainGraphSnapshot] [code]upstream_ids[/code] / [code]downstream_ids[/code].
class_name UiReactExplainGraphNarrative
extends RefCounted

var anchor_id: String = ""
var bound_state_lines: PackedStringArray = PackedStringArray()
## Legacy id+label lines; details pane uses [member upstream_display_lines] / [member downstream_*_display_lines] instead.
var upstream_lines: PackedStringArray = PackedStringArray()
## Deprecated; details pane always shows Upstream with human lines or an empty confirmation.
var omit_upstream_in_details: bool = false
var downstream_state_lines: PackedStringArray = PackedStringArray()
var downstream_control_lines: PackedStringArray = PackedStringArray()
## Binding source state ids for a [code]ctrl:[/code] anchor (sorted); empty for state/computed anchors.
var seed_state_ids: PackedStringArray = PackedStringArray()
## Human-only bullets (label text only) for the Upstream section.
var upstream_display_lines: PackedStringArray = PackedStringArray()
## Human-only Downstream bullets after filtering seeds / self (control) or anchor (state/computed).
var downstream_state_display_lines: PackedStringArray = PackedStringArray()
var downstream_control_display_lines: PackedStringArray = PackedStringArray()
## Ids included in upstream narrative (for canvas mismatch checks).
var upstream_node_ids: PackedStringArray = PackedStringArray()
## Ids included in downstream narrative.
var downstream_node_ids: PackedStringArray = PackedStringArray()

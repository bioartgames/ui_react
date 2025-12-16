## Configuration resource for ReactiveTabContainer tab management.
## Groups all tab-related State bindings into a single, reusable resource.
extends Resource
class_name TabContainerConfig

@export_group("Tab Management")
## Dynamic tab management: Array of tab data (Dictionary with "title", "icon", etc., or just Strings).
## When this State changes, tabs are automatically added/removed/updated.
## Example: tabs_state.value = [{"title": "Weapons", "icon": icon1}, {"title": "Armor"}]
## Or simple: tabs_state.value = ["Tab1", "Tab2", "Tab3"]
@export var tabs_state: State

@export_group("Content Binding")
## Tab content state binding: One State per tab for reactive content.
## When a tab is selected, its child content automatically binds to the corresponding State.
## Array size should match tab count. Empty/null entries are ignored.
@export var tab_content_states: Array[State] = []

@export_group("Tab States")
## Per-tab enable/disable: Array of booleans (one per tab).
## When this State changes, tabs are enabled/disabled accordingly.
## Example: disabled_tabs_state.value = [false, false, true, false]
@export var disabled_tabs_state: State

## Tab visibility control: Array of booleans (one per tab).
## When this State changes, tabs are shown/hidden accordingly.
## Example: visible_tabs_state.value = [true, true, false, true]
@export var visible_tabs_state: State


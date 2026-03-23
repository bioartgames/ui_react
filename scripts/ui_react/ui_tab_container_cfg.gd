## Configuration resource for UiReactTabContainer tab management.
## Groups all tab-related UiState bindings into a single, reusable resource.
extends Resource
class_name UiTabContainerCfg

## Dynamic tab management: Array of tab data (Dictionary with "title", "icon", etc., or just Strings).
## When this UiState changes, tabs are automatically added/removed/updated.
## Example: tabs_state.value = [{"title": "Weapons", "icon": icon1}, {"title": "Armor"}]
## Or simple: tabs_state.value = ["Tab1", "Tab2", "Tab3"]
@export var tabs_state: UiState

## Tab content state binding: One UiState per tab for reactive content.
## When a tab is selected, its child content automatically binds to the corresponding UiState.
## Array size should match tab count. Empty/null entries are ignored.
@export var tab_content_states: Array[UiState] = []

## Per-tab enable/disable: Array of booleans (one per tab).
## When this UiState changes, tabs are enabled/disabled accordingly.
## Example: disabled_tabs_state.value = [false, false, true, false]
@export var disabled_tabs_state: UiState

## Tab visibility control: Array of booleans (one per tab).
## When this UiState changes, tabs are shown/hidden accordingly.
## Example: visible_tabs_state.value = [true, true, false, true]
@export var visible_tabs_state: UiState


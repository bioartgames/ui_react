## Configuration resource for [UiReactTabContainer] tab management.
## Groups all tab-related [UiState] bindings into a single, reusable resource.
extends Resource
class_name UiTabContainerCfg

## Dynamic tab management: [Array] of tab data ([Dictionary] with [code]title[/code], [code]icon[/code], etc., or plain [String]s).
## When this state changes, tabs are automatically added/removed/updated.
## Example: [code]tabs_state.set_value([{"title": "Weapons", "icon": icon1}, {"title": "Armor"}])[/code]
## Or simple: [code]tabs_state.set_value(["Tab1", "Tab2", "Tab3"])[/code]
@export var tabs_state: UiArrayState

## Tab content state binding: One [UiState] per tab for reactive content.
## When a tab is selected, its child content automatically binds to the corresponding [UiState].
## Array size should match tab count. Empty/null entries are ignored.
@export var tab_content_states: Array[UiState] = []

## Per-tab enable/disable: [Array] of booleans (one per tab).
## When this state changes, tabs are enabled/disabled accordingly.
## Example: [code]disabled_tabs_state.set_value([false, false, true, false])[/code]
@export var disabled_tabs_state: UiArrayState

## Tab visibility control: [Array] of booleans (one per tab).
## When this state changes, tabs are shown/hidden accordingly.
## Example: [code]visible_tabs_state.set_value([true, true, false, true])[/code]
@export var visible_tabs_state: UiArrayState

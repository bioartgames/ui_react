## Configuration resource for ReactiveGridContainer.
##
## Defines how the grid should render and behave, including cell scene,
## layout options, and empty cell handling.
extends Resource
class_name GridContainerConfig

## The scene to instantiate for each cell (e.g., an item slot).
##
## Each instance is expected to conform to a simple "cell contract":
## - Optionally implement set_item(data: Variant) to receive item data
## - Optionally implement set_selected(is_selected: bool) for selection state
## - Should be a Control that can receive focus for navigation
@export var cell_scene: PackedScene

## Override for the number of columns in the grid.
##
## 0 means use GridContainer.columns from the grid control itself.
## > 0 allows this config to override the number of columns if desired.
@export var columns_override: int = 0

## Whether to allow rendering empty cells.
##
## If false, cells are only created for actual items.
## If true, grid can render empty slots up to a target size.
@export var allow_empty_cells: bool = true

## Target number of cells to render.
##
## 0 means "size matches item count".
## > 0 means pad with empty cells up to target_cell_count.
@export var target_cell_count: int = 0

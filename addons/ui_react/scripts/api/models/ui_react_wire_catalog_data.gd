## Serializable catalog rows for [UiReactWireRefreshItemsFromCatalog]. Game data lives in the project ([code]docs/WIRING_LAYER.md[/code] §6).
class_name UiReactWireCatalogData
extends Resource

@export var rows: Array[Dictionary] = []


## Called by [UiReactWireRefreshItemsFromCatalog] before reading [member rows]. Override to lazy-load editor/runtime data.
func ensure_rows_loaded() -> void:
	pass

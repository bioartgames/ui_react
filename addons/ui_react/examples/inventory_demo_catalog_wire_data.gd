## Demo [UiReactWireCatalogData]: fills [member rows] from [InventoryDemoCatalog] when empty (runtime + editor).
extends UiReactWireCatalogData
class_name InventoryDemoCatalogWireData


func ensure_rows_loaded() -> void:
	if not rows.is_empty():
		return
	for entry in InventoryDemoCatalog.CATALOG:
		rows.append((entry as Dictionary).duplicate())

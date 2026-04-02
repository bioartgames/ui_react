extends Control

@onready var _tree: Tree = $VBox/Tree
@onready var _status: Label = $VBox/StatusLabel


func _ready() -> void:
	_build_tree.call_deferred()


func _build_tree() -> void:
	_tree.clear()
	_tree.hide_root = true
	var r: TreeItem = _tree.create_item()
	r.set_text(0, "Catalog")
	var weapons: TreeItem = _tree.create_item(r)
	weapons.set_text(0, "Weapons")
	var sword: TreeItem = _tree.create_item(weapons)
	sword.set_text(0, "Sword")
	var armor: TreeItem = _tree.create_item(r)
	armor.set_text(0, "Armor")
	var helm: TreeItem = _tree.create_item(armor)
	helm.set_text(0, "Helm")

	var st: UiIntState = _tree.selected_state as UiIntState
	if st == null:
		return
	if not st.value_changed.is_connected(_on_sel_changed):
		st.value_changed.connect(_on_sel_changed)
	_on_sel_changed(st.get_value(), st.get_value())


func _on_sel_changed(_new_val: Variant, _old_val: Variant) -> void:
	var st := _tree.selected_state as UiIntState
	if st == null:
		return
	_status.text = "selected_state index: %d (-1 = none). With hide_root, expected row order: Weapons=0, Sword=1, Armor=2, Helm=3." % int(
		st.get_value()
	)

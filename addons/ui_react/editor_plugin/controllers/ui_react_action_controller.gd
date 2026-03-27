## Undo/redo-safe assignments for editor plugin actions.
class_name UiReactActionController
extends RefCounted

var _undo_redo: EditorUndoRedoManager


func _init(p_undo_redo: EditorUndoRedoManager) -> void:
	_undo_redo = p_undo_redo


func assign_resource_property(node: Node, property_name: StringName, new_value: Resource) -> void:
	if node == null or property_name == &"":
		return
	var old_val: Variant = node.get(property_name)
	_undo_redo.create_action("Assign %s" % property_name)
	_undo_redo.add_do_property(node, property_name, new_value)
	_undo_redo.add_undo_property(node, property_name, old_val)
	_undo_redo.commit_action()

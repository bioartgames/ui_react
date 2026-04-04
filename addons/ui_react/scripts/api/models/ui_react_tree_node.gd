@tool
## Row descriptor for [member UiReactTree.tree_items_state].
## The array value must contain only [UiReactTreeNode] entries (v1 — no Dictionary rows).
## [member children] is always present; leaves use an empty array.
class_name UiReactTreeNode
extends Resource

## Column 0 label text.
@export var text: String = ""

## Column 0 icon. Assign a texture in the Inspector; the editor validator reports if unset.
@export var icon: Texture2D

## Child rows. Use an empty array for leaves.
@export var children: Array[UiReactTreeNode] = []

## Parameters for add item action.
@icon("res://icon.svg")
class_name AddItemParams
extends ActionParams

## The item to add.
@export var item: Variant = null

## Index to insert at (-1 for append to end).
@export var index: int = -1


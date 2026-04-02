extends Control
## CB-006 example: **Buy** subtracts **price × quantity** from **gold** when the player can afford it.
## Reactive afford/disabled UI stays on **`UiState`**; this script only handles the one-shot **pressed** path (see README **Imperative actions**).

@export var gold_state: UiFloatState
@export var price_state: UiFloatState
@export var quantity_state: UiFloatState
@export var buy_button_path: NodePath = NodePath("VBox/BuyButton")


func _ready() -> void:
	var b: Node = get_node_or_null(buy_button_path)
	if b is BaseButton:
		(b as BaseButton).pressed.connect(_on_buy_pressed)


func _on_buy_pressed() -> void:
	if gold_state == null or price_state == null or quantity_state == null:
		return
	var gold: float = float(gold_state.get_value())
	var price: float = float(price_state.get_value())
	var qty: float = float(quantity_state.get_value())
	var total: float = price * qty
	if gold < total:
		return
	gold_state.set_value(gold - total)

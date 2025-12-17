extends Node

@onready var navigator: Node = get_parent().get_node("ReactiveUINavigator")
@onready var nav_states: Resource = navigator.nav_states

var move_timer := 0.0
var submit_timer := 0.0

func _process(delta: float) -> void:
	if not nav_states:
		return

	# Simulate navigation by toggling move_y every 2 seconds
	move_timer += delta
	if move_timer >= 2.0:
		move_timer = 0.0
		var current_move = nav_states.move_y.value
		nav_states.move_y.value = 1 if current_move != 1 else -1
		print("State-driven navigation: move_y = ", nav_states.move_y.value)

	# Simulate submit every 5 seconds
	submit_timer += delta
	if submit_timer >= 5.0:
		submit_timer = 0.0
		nav_states.submit.value = true
		# Reset after a brief moment to simulate button press
		await get_tree().create_timer(0.1).timeout
		nav_states.submit.value = false
		print("State-driven navigation: submit pressed")

func _ready() -> void:
	print("State-driven navigation test controller ready")
	print("Use arrow keys to manually test, or watch for automatic state changes")

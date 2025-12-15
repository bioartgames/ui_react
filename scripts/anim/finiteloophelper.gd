## Helper node for executing finite animation loops.
class_name FiniteLoopHelper
extends Node

signal sequence_finished

func execute_sequence(sequence) -> void:
	await sequence.play()
	sequence_finished.emit()
	queue_free()

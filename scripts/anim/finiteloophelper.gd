## Helper node for executing finite animation loops.
class_name FiniteLoopHelper
extends Node

var sequence_finished = Signal()

func execute_sequence(sequence) -> void:
	await sequence.play()
	sequence_finished.emit()
	queue_free()

## Static utility class for common cleanup operations.
## Used by all managers and components for consistent cleanup.
class_name ReactiveLifecycleManager

## Disconnects all signal connections in the array.
static func cleanup_signal_connections(connections: Array[SignalConnection]) -> void:
	for connection in connections:
		if connection == null:
			continue
		if connection.connection_active:
			# Try to disconnect via Signal object
			if connection.signal_ref != null:
				connection.signal_ref.disconnect(connection.callable)
			# Or disconnect via node and signal name
			elif connection.target_node != null and not connection.signal_name.is_empty():
				if is_instance_valid(connection.target_node) and connection.target_node.has_signal(connection.signal_name):
					connection.target_node.disconnect(connection.signal_name, connection.callable)
			connection.connection_active = false
	connections.clear()

## Kills all active Tweens in the array.
static func cleanup_tweens(tweens: Array[Tween]) -> void:
	for tween in tweens:
		if tween != null and is_instance_valid(tween):
			tween.kill()
	tweens.clear()


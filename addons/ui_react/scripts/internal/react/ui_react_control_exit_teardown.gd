extends RefCounted

## Mirrors [member Node.notification] [constant NOTIFICATION_PREDELETE] with [method Node._exit_tree] for reactive [UiReact*] controls.

static func teardown_wire_host(disconnect_states: Callable, wire_exit: Callable) -> void:
	disconnect_states.call()
	wire_exit.call()


static func teardown_no_wire(disconnect_states: Callable) -> void:
	disconnect_states.call()

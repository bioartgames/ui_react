## Typed signal connection Resource for tracking signal connections.
## Used for cleanup operations.
class_name SignalConnection
extends RefCounted

## The signal being connected (if available).
var signal_ref: Signal

## The callable connected to the signal.
var callable: Callable

## The target node (for disconnection by signal name).
var target_node: Node

## The signal name (for disconnection by signal name).
var signal_name: String

## Whether the connection is currently active.
var connection_active: bool = false

## Creates a new SignalConnection from a Signal object.
static func create(sig: Signal, callback: Callable) -> SignalConnection:
	var conn = SignalConnection.new()
	conn.signal_ref = sig
	conn.callable = callback
	conn.connection_active = true
	return conn

## Creates a new SignalConnection from node and signal name.
static func create_from_node(node: Node, sig_name: String, callback: Callable) -> SignalConnection:
	var conn = SignalConnection.new()
	conn.target_node = node
	conn.signal_name = sig_name
	conn.callable = callback
	conn.connection_active = true
	return conn

## Event that emits a signal when triggered.
## Can be used to trigger custom signals during animations.
@icon("res://icon.svg")
class_name SignalEvent
extends AnimationEvent

## The signal name to emit on the target Control.
@export var signal_name: String = ""

## Optional arguments to pass to the signal.
@export var arguments: Array[Variant] = []

## Triggers the event by emitting the signal.
func trigger(context: AnimationEventContext) -> void:
	if context.target == null:
		return
	if signal_name.is_empty():
		return
	
	# Check if target has the signal
	if not context.target.has_signal(signal_name):
		push_warning("SignalEvent: Target '%s' does not have signal '%s'" % [context.target.name, signal_name])
		return
	
	# Emit signal with arguments
	# Note: emit_signal doesn't support callv, so we need to match on argument count
	if arguments.is_empty():
		context.target.emit_signal(signal_name)
	else:
		match arguments.size():
			1:
				context.target.emit_signal(signal_name, arguments[0])
			2:
				context.target.emit_signal(signal_name, arguments[0], arguments[1])
			3:
				context.target.emit_signal(signal_name, arguments[0], arguments[1], arguments[2])
			4:
				context.target.emit_signal(signal_name, arguments[0], arguments[1], arguments[2], arguments[3])
			5:
				context.target.emit_signal(signal_name, arguments[0], arguments[1], arguments[2], arguments[3], arguments[4])
			_:
				# For more than 5 arguments, emit without arguments and log warning
				push_warning("SignalEvent: More than 5 arguments not supported for signal '%s', emitting without arguments" % signal_name)
				context.target.emit_signal(signal_name)


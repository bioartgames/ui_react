## Enum for binding status.
class_name BindingStatus

enum Status {
	CONNECTED,              # Binding is active and working
	ERROR_INVALID_PATH,     # Control path does not exist
	ERROR_INVALID_PROPERTY, # Property does not exist on Control
	ERROR_INVALID_SIGNAL,   # Signal does not exist on Control (TWO_WAY only)
	ERROR_TYPE_MISMATCH,    # Type mismatch between ReactiveValue and Control property
	DISCONNECTED            # Binding is not connected (initial state)
}


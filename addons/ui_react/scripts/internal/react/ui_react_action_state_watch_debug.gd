extends RefCounted
## Temporary tracing for [code]state_watch[/code] action dispatch ([code]value_changed[/code] → [code]SET_VISIBLE[/code] / etc.).
## Set [member enabled] to [code]false[/code] to silence. When finished: delete this file and remove [method line] calls (search [code]ui_react_action_state_watch_debug[/code]).
static var enabled: bool = true


static func line(msg: String) -> void:
	if not enabled:
		return
	print("[UiReactActionStateWatch] ", msg)

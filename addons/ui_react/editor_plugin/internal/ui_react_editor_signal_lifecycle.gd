@tool
## Owns a [UiReactSubscriptionScope] for @tool panels; disposes on [signal Node.tree_exiting] (one-shot) and idempotently via [method dispose].
## Still call [method dispose] from [method Node._exit_tree] when you have an explicit teardown path (double-safe).
class_name UiReactEditorSignalLifecycle
extends RefCounted

var scope: UiReactSubscriptionScope

var _disposed: bool = false


func _init(owner: Node) -> void:
	scope = UiReactSubscriptionScope.new()
	owner.tree_exiting.connect(_on_owner_tree_exiting, CONNECT_ONE_SHOT)


func _on_owner_tree_exiting() -> void:
	dispose()


func dispose() -> void:
	if _disposed:
		return
	_disposed = true
	if scope != null:
		scope.dispose()
		scope = null

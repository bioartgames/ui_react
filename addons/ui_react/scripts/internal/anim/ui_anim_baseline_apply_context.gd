## Stack for [UiAnimTarget] apply scope: whether unified baseline snapshots are taken/released for motion/state animations.
## Empty stack: baseline capture is **enabled** (default for direct [UiAnimUtils] callers).
class_name UiAnimBaselineApplyContext
extends RefCounted

static var _stack: Array[bool] = []


static func push(use_unified_baseline: bool) -> void:
	_stack.push_back(use_unified_baseline)


static func pop() -> void:
	if _stack.is_empty():
		push_warning("UiAnimBaselineApplyContext.pop(): stack underflow")
		return
	_stack.pop_back()


## When the stack is empty, returns true. Otherwise returns the [member UiAnimTarget.use_unified_baseline] from the innermost apply.
static func is_enabled() -> bool:
	if _stack.is_empty():
		return true
	return _stack[_stack.size() - 1]

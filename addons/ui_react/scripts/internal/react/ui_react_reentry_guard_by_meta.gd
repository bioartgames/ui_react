## Per-owner reentry locks stored in [method Node.set_meta] under a fixed [param meta_key] dictionary.
## GDScript has no [code]finally[/code]: if [param fn] aborts in an exceptional way the lock may remain set until the node is freed—acceptable for typical UI callbacks.
class_name UiReactReentryGuardByMeta
extends RefCounted


## Returns the mutable [Dictionary] at [param meta_key], creating [code]{}[/code] and calling [method Node.set_meta] when missing.
static func locks_dictionary_for(owner: Node, meta_key: StringName) -> Dictionary:
	if owner.has_meta(meta_key):
		var d: Variant = owner.get_meta(meta_key)
		if d is Dictionary:
			return d as Dictionary
	var created: Dictionary = {}
	owner.set_meta(meta_key, created)
	return created


## Runs [param fn] under a per-[param owner] / per-[param lock_key] lock within the dictionary at [param meta_key].
## When reentrant, calls [param reentry_warn_fn] if valid, then returns without running [param fn].
static func with_guard(
	owner: Node,
	meta_key: StringName,
	lock_key: String,
	fn: Callable,
	reentry_warn_fn: Callable = Callable(),
) -> void:
	var locks := locks_dictionary_for(owner, meta_key)
	if locks.get(lock_key, false):
		if reentry_warn_fn.is_valid():
			reentry_warn_fn.call()
		return
	locks[lock_key] = true
	fn.call()
	locks[lock_key] = false

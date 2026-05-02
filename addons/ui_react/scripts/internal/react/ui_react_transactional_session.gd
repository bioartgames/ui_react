## Tree-scoped registration for [UiTransactionalGroup] **Apply** / **Cancel** via [BaseButton.pressed].
## Used by [UiReactButton] / [UiReactTextureButton] for [UiTransactionalGroup] Apply/Cancel registration.
## Keyed by [code](SceneTree, UiTransactionalGroup)[/code] instance ids — separate open scenes do not share refcount.
class_name UiReactTransactionalSession
extends RefCounted

## Match [member UiReactTransactionalHostBinding.role] (1 = apply, 2 = cancel) on [UiReactButton] / [UiReactTextureButton].
enum Role { NONE = 0, APPLY_ALL = 1, CANCEL_ALL = 2 }

const _META_CB := &"_ui_react_txn_pressed_cb"
const _META_KEY := &"_ui_react_txn_session_key"

## key String -> { "refcount": int, "group": UiTransactionalGroup }
static var _cohorts: Dictionary = {}


static func _cohort_key(tree: SceneTree, group: UiTransactionalGroup) -> String:
	return "%d_%d" % [tree.get_instance_id(), group.get_instance_id()]


## Registers [param host] for transactional Apply/Cancel. [param screen] may be [code]null[/code]; when absent or when [member UiTransactionalScreenConfig.begin_on_ready] is [code]true[/code], cohort begin is scheduled as today.
static func register_host(
	host: BaseButton, group: UiTransactionalGroup, role: int, screen: UiTransactionalScreenConfig
) -> void:
	if host == null or group == null or role == int(Role.NONE):
		return
	var tree := host.get_tree()
	if tree == null:
		return
	if host.has_meta(_META_CB):
		return
	var key := _cohort_key(tree, group)
	var entry: Dictionary = _cohorts.get(key, {})
	var cohort_new := entry.is_empty()
	if cohort_new:
		entry = {"refcount": 0, "group": group}
		_cohorts[key] = entry
	entry["refcount"] = int(entry["refcount"]) + 1
	if cohort_new:
		var do_begin := true
		if screen != null:
			do_begin = screen.begin_on_ready
		if do_begin:
			tree.process_frame.connect(func () -> void: _deferred_begin_edit(key), CONNECT_ONE_SHOT)
	var cb: Callable
	if role == int(Role.APPLY_ALL):
		cb = func () -> void:
			if is_instance_valid(group):
				group.apply_all()
	elif role == int(Role.CANCEL_ALL):
		cb = func () -> void:
			if is_instance_valid(group):
				group.cancel_all()
	else:
		return
	if not host.pressed.is_connected(cb):
		host.pressed.connect(cb)
	host.set_meta(_META_CB, cb)
	host.set_meta(_META_KEY, key)


static func _deferred_begin_edit(key: String) -> void:
	var entry: Variant = _cohorts.get(key)
	if entry == null or not (entry is Dictionary):
		return
	var g: Variant = (entry as Dictionary).get("group")
	if g is UiTransactionalGroup and is_instance_valid(g):
		(g as UiTransactionalGroup).begin_edit_all()


static func unregister_host(host: BaseButton) -> void:
	if host == null or not host.has_meta(_META_CB):
		return
	var cb: Callable = host.get_meta(_META_CB)
	var key: String = str(host.get_meta(_META_KEY, ""))
	if cb.is_valid() and host.pressed.is_connected(cb):
		host.pressed.disconnect(cb)
	host.remove_meta(_META_CB)
	if host.has_meta(_META_KEY):
		host.remove_meta(_META_KEY)
	if key.is_empty():
		return
	var entry: Variant = _cohorts.get(key)
	if entry == null or not (entry is Dictionary):
		return
	var d := entry as Dictionary
	var n := int(d.get("refcount", 1)) - 1
	if n <= 0:
		_cohorts.erase(key)
	else:
		d["refcount"] = n

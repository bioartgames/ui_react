extends RefCounted
class_name UiReactLiveDebugEventKinds

enum Kind {
	STATE_VALUE_CHANGED,
	COMPUTED_RECOMPUTE,
	WIRE_RULE_APPLY,
	ACTION_APPLY,
}

const META_KIND := &"kind"
const META_SEQ := &"seq"
const META_USEC := &"usec"
const META_STATE_ID := &"state_id"
const META_RESOURCE_PATH := &"resource_path"
const META_NEW_VALUE_STR := &"new_value_str"
const META_OLD_VALUE_STR := &"old_value_str"
const META_HOST_PATH_OPTIONAL := &"host_path_optional"
const META_PROPERTY_HINT := &"property_hint"
const META_INSTANCE_ID := &"instance_id"
const META_RULE_ID := &"rule_id"
const META_HOST_PATH := &"host_path"
const META_RULE_SCRIPT_BASENAME := &"rule_script_basename"
const META_ROW_INDEX := &"row_index"
const META_ACTION_KIND := &"action_kind"
const META_VIA := &"via"


static func make_row(seq: int, kind: Kind, meta: Dictionary) -> Dictionary:
	var d := {}
	d[META_KIND] = int(kind)
	d[META_SEQ] = seq
	d[META_USEC] = Time.get_ticks_usec()
	for k in meta:
		d[k] = meta[k]
	return d

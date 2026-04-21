## Small shared helpers for validator modules.
class_name UiReactValidatorCommon
extends RefCounted


static func variant_type_name(v: Variant) -> String:
	if v is Object and v:
		return v.get_class()
	return str(typeof(v))


static func get_allowed_anim_triggers(component: String) -> Array:
	var raw: Variant = UiReactComponentRegistry.ANIM_TRIGGERS_BY_COMPONENT.get(component, null)
	if raw == null:
		return []
	return raw as Array


## Returns [code]true[/code] if [param trigger] is listed for [param component], or if the component has no registry entry (unknown — do not warn in the dock).
static func is_anim_trigger_allowed(component: String, trigger: UiAnimTarget.Trigger) -> bool:
	var allowed: Array = get_allowed_anim_triggers(component)
	if allowed.is_empty():
		return true
	return allowed.has(trigger)


static func format_anim_trigger_name(trigger: UiAnimTarget.Trigger) -> String:
	var k: Variant = UiAnimTarget.Trigger.find_key(trigger)
	return str(k) if k != null else str(int(trigger))


static func format_allowed_anim_triggers_hint(component: String) -> String:
	var allowed: Array = get_allowed_anim_triggers(component)
	if allowed.is_empty():
		return "No motion triggers are registered for this control in the addon; animation rows may still be allowed."
	var parts: PackedStringArray = PackedStringArray()
	for t in allowed:
		parts.append(format_anim_trigger_name(t as UiAnimTarget.Trigger))
	return ", ".join(parts)

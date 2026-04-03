## Small shared helpers for validator modules.
class_name UiReactValidatorCommon
extends RefCounted


static func variant_type_name(v: Variant) -> String:
	if v is Object and v:
		return v.get_class()
	return str(typeof(v))

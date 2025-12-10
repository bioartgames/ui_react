## Reflection utility for auto-detecting Control properties and signals.
## Caches results by Control type for performance.
@tool
class_name ControlInspector
extends RefCounted

## Cache structure: Dictionary[String (class name), Dictionary]
## Inner Dictionary contains: "properties": Array[String], "signals": Array[String], "property_types": Dictionary[String, Variant.Type]
static var _cache: Dictionary = {}

## Gets available properties on a Control node.
## Returns array of property names.
static func get_available_properties(control: Control) -> Array[String]:
	var class_type = control.get_class()
	var cache_key = class_type
	
	# Check cache
	if _cache.has(cache_key) and _cache[cache_key].has("properties"):
		return _cache[cache_key]["properties"].duplicate()
	
	# Use reflection to get properties
	var properties: Array[String] = []
	var property_list = control.get_property_list()
	
	for prop in property_list:
		var prop_name = prop["name"] as String
		# Skip internal properties (starting with _)
		if prop_name.begins_with("_"):
			continue
		
		# Skip if it's a method
		if control.has_method(prop_name):
			continue
		
		# Get usage flags
		var usage = prop.get("usage", 0) as int
		
		# Include properties that are:
		# - Stored (PROPERTY_USAGE_STORAGE) - native properties
		# - Editable in editor (PROPERTY_USAGE_EDITOR) - editor properties
		# - Script variables (PROPERTY_USAGE_SCRIPT_VARIABLE) - script properties
		# Exclude:
		# - Methods (PROPERTY_USAGE_METHOD)
		# - Groups (PROPERTY_USAGE_GROUP)
		# - Categories (PROPERTY_USAGE_CATEGORY)
		if (usage & PROPERTY_USAGE_STORAGE) != 0 or \
		   (usage & PROPERTY_USAGE_EDITOR) != 0 or \
		   (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0:
			properties.append(prop_name)
	
	# Cache result
	if not _cache.has(cache_key):
		_cache[cache_key] = {}
	_cache[cache_key]["properties"] = properties
	
	return properties.duplicate()

## Gets available signals on a Control node.
## Returns array of signal names.
static func get_available_signals(control: Control) -> Array[String]:
	var class_type = control.get_class()
	var cache_key = class_type
	
	# Check cache
	if _cache.has(cache_key) and _cache[cache_key].has("signals"):
		return _cache[cache_key]["signals"].duplicate()
	
	# Use reflection to get signals
	var signals: Array[String] = []
	var signal_list = control.get_signal_list()
	
	for sig in signal_list:
		var sig_name = sig["name"] as String
		signals.append(sig_name)
	
	# Cache result
	if not _cache.has(cache_key):
		_cache[cache_key] = {}
	_cache[cache_key]["signals"] = signals
	
	return signals.duplicate()

## Gets the type of a property on a Control node.
## Returns Variant.Type.
static func get_property_type(control: Control, property: String) -> Variant.Type:
	var class_type = control.get_class()
	var cache_key = class_type
	
	# Check cache
	if _cache.has(cache_key) and _cache[cache_key].has("property_types"):
		var property_types = _cache[cache_key]["property_types"]
		if property_types.has(property):
			return property_types[property]
	
	# Use reflection to get property type
	var property_list = control.get_property_list()
	
	for prop in property_list:
		var prop_name = prop["name"] as String
		if prop_name == property:
			var prop_type = prop["type"] as Variant.Type
			
			# Cache result
			if not _cache.has(cache_key):
				_cache[cache_key] = {}
			if not _cache[cache_key].has("property_types"):
				_cache[cache_key]["property_types"] = {}
			_cache[cache_key]["property_types"][property] = prop_type
			
			return prop_type
	
	# Property not found
	return TYPE_NIL

## Clears the entire cache.
## Called when editor reloads or on demand.
static func clear_cache() -> void:
	_cache.clear()


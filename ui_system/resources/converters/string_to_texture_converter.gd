## Converter that converts file path strings to Texture2D resources.
## Caches loaded textures to avoid reloading.
@icon("res://icon.svg")
class_name StringToTextureConverter
extends ValueConverter

## Cache of loaded textures (keyed by path).
static var _texture_cache: Dictionary = {}

## Whether to enable texture caching.
@export var enable_caching: bool = true

## Converts a file path string to a Texture2D.
func convert(value: Variant) -> Variant:
	if value == null:
		return null
	
	var path: String = str(value)
	if path.is_empty():
		return null
	
	# Check cache first if caching is enabled
	if enable_caching and _texture_cache.has(path):
		var cached_texture = _texture_cache[path]
		if cached_texture != null and is_instance_valid(cached_texture):
			return cached_texture
	
	# Try to load the texture
	var texture: Texture2D = null
	if ResourceLoader.exists(path):
		var resource = ResourceLoader.load(path)
		if resource is Texture2D:
			texture = resource as Texture2D
		else:
			# Log error if resource exists but isn't a texture
			# Use push_error for now (Logger API may not be available in all Godot versions)
			push_error("StringToTextureConverter: Path exists but is not a Texture2D: %s" % path)
	else:
		# Log error if path doesn't exist
		# Use push_error for now (Logger API may not be available in all Godot versions)
		push_error("StringToTextureConverter: Texture path does not exist: %s" % path)
	
	# Cache the texture if caching is enabled and texture was loaded successfully
	if enable_caching and texture != null:
		_texture_cache[path] = texture
	
	return texture

## Clears the texture cache (static method for manual cache management).
static func clear_cache() -> void:
	_texture_cache.clear()


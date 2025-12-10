## Action that changes the current scene.
@icon("res://icon.svg")
class_name ActionChangeScene
extends ReactiveAction

## Validates that params is ChangeSceneParams and scene path exists.
func validate_before_execute(target: ReactiveValue, params: ActionParams) -> bool:
	if not super.validate_before_execute(target, params):
		return false
	
	if not (params is ChangeSceneParams):
		return false
	
	var change_scene_params = params as ChangeSceneParams
	if change_scene_params == null:
		return false
	
	# Validate scene path exists
	if change_scene_params.scene_path.is_empty():
		return false
	
	if not ResourceLoader.exists(change_scene_params.scene_path):
		push_error("ActionChangeScene: Scene path does not exist: %s" % change_scene_params.scene_path)
		return false
	
	return true

## Changes the scene to the path specified in params.
func execute(target: ReactiveValue, params: ActionParams) -> bool:
	if not validate_before_execute(target, params):
		return false
	
	var change_scene_params = params as ChangeSceneParams
	if change_scene_params == null:
		return false
	
	# Get the scene tree
	# Since this is a Resource, we need to get the scene tree from the engine
	var scene_tree = Engine.get_main_loop()
	if scene_tree == null or not (scene_tree is SceneTree):
		push_error("ActionChangeScene: Cannot get scene tree")
		return false
	
	(scene_tree as SceneTree).change_scene_to_file(change_scene_params.scene_path)
	return true


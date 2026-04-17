extends GutTest

## GUT runs tests in a played scene (not inside the editor UI), so game-side code
## sees Engine.is_editor_hint() == false. Ui*State emits value_changed only when
## not editor hint — see UiState subclasses.
## OS.has_feature("editor") may still be true when using an editor binary (F5 / GUT);
## it is false for exported games — see Godot Engine.is_editor_hint() docs.


func test_is_editor_hint_false_during_gut_run() -> void:
	assert_false(Engine.is_editor_hint())

extends GutTest

const RAG_PROMPT_BUILDER = preload("res://addons/ai_assistant_hub/rag/rag_prompt_builder.gd")


func test_prompt_builder_includes_markers_and_user_prompt() -> void:
	var builder = RAG_PROMPT_BUILDER.new()
	var scored_chunks: Array[Dictionary] = [
		{
			"score": 20,
			"chunk": {
				"path": "res://foo.gd",
				"start_line": 1,
				"end_line": 10,
				"kind": "script",
				"symbol": "func test()",
				"text": "func test():\n\tpass"
			}
		}
	]

	var prompt := builder.build_augmented_prompt("How does this work?", scored_chunks)
	assert_true(prompt.contains("[[PROJECT_CONTEXT_BEGIN]]"))
	assert_true(prompt.contains("[CHUNK 1 | score=20 | path=res://foo.gd | lines=1-10 | kind=script | symbol=func test()]"))
	assert_true(prompt.contains("[[USER_PROMPT_BEGIN]]\nHow does this work?\n[[USER_PROMPT_END]]"))


func test_prompt_builder_writes_no_match_line() -> void:
	var builder = RAG_PROMPT_BUILDER.new()
	var prompt := builder.build_augmented_prompt("Question", [])
	assert_true(prompt.contains("No relevant project chunks matched the query."))

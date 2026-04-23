extends GutTest

const RAG_RETRIEVER = preload("res://addons/ai_assistant_hub/rag/rag_retriever.gd")


func test_retriever_ranks_by_score_then_path_then_line() -> void:
	var retriever = RAG_RETRIEVER.new()
	var chunks: Array[Dictionary] = [
		{
			"path": "res://b_file.gd",
			"start_line": 10,
			"text_lc": "func update_health(): pass",
			"tokens": PackedStringArray(["func", "update_health", "pass"]),
			"symbol": "func update_health()"
		},
		{
			"path": "res://a_file.gd",
			"start_line": 20,
			"text_lc": "func update_health(): pass",
			"tokens": PackedStringArray(["func", "update_health", "pass"]),
			"symbol": "func update_health()"
		},
		{
			"path": "res://z_file.gd",
			"start_line": 1,
			"text_lc": "signal ui_ready",
			"tokens": PackedStringArray(["signal", "ui_ready"]),
			"symbol": "signal ui_ready"
		}
	]

	var results := retriever.retrieve("update health", chunks, 3)
	assert_eq(results.size(), 2)
	assert_eq(results[0].path, "res://a_file.gd")
	assert_eq(results[1].path, "res://b_file.gd")


func test_retriever_returns_empty_when_no_match() -> void:
	var retriever = RAG_RETRIEVER.new()
	var chunks: Array[Dictionary] = [
		{
			"path": "res://x.gd",
			"start_line": 1,
			"text_lc": "class_name Foo",
			"tokens": PackedStringArray(["class_name", "foo"]),
			"symbol": "class_name Foo"
		}
	]
	var results := retriever.retrieve("unrelated words", chunks, 5)
	assert_eq(results.size(), 0)

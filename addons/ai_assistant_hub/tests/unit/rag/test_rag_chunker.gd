extends GutTest

const RAG_CHUNKER = preload("res://addons/ai_assistant_hub/rag/rag_chunker.gd")


func test_chunk_file_produces_expected_line_windows_and_overlap() -> void:
	var chunker = RAG_CHUNKER.new()
	var lines: Array[String] = []
	for i in range(1, 91):
		lines.append("line_%d" % i)
	var text := "\n".join(lines)
	var chunks := chunker.chunk_file("res://script.gd", text, 10)

	assert_eq(chunks.size(), 3)
	assert_eq(chunks[0].start_line, 1)
	assert_eq(chunks[0].end_line, 40)
	assert_eq(chunks[1].start_line, 33)
	assert_eq(chunks[1].end_line, 72)
	assert_eq(chunks[2].start_line, 65)
	assert_eq(chunks[2].end_line, 90)

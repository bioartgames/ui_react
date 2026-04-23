@tool
class_name RAGPromptBuilder
extends RefCounted

## Builds the final user prompt with injected project context.
func build_augmented_prompt(original_prompt: String, scored_chunks: Array[Dictionary]) -> String:
	var header := "[[PROJECT_CONTEXT_BEGIN]]\n"
	header += "RAG_VERSION: mvp1\n"
	header += "QUERY: %s\n" % original_prompt
	header += "MATCH_COUNT: %d\n\n" % scored_chunks.size()

	var context := header
	if scored_chunks.is_empty():
		context += "No relevant project chunks matched the query.\n"
	else:
		for index in range(scored_chunks.size()):
			var scored := scored_chunks[index]
			var chunk: Dictionary = scored.get("chunk", {})
			var score := int(scored.get("score", 0))
			var path := String(chunk.get("path", ""))
			var start_line := int(chunk.get("start_line", 0))
			var end_line := int(chunk.get("end_line", 0))
			var kind := String(chunk.get("kind", "other"))
			var symbol := String(chunk.get("symbol", ""))
			if symbol.is_empty():
				symbol = "-"

			var body := String(chunk.get("text", ""))
			if body.length() > RAGConfig.MAX_SINGLE_CHUNK_CHARS:
				body = body.substr(0, RAGConfig.MAX_SINGLE_CHUNK_CHARS)

			var section := "[CHUNK %d | score=%d | path=%s | lines=%d-%d | kind=%s | symbol=%s]\n%s\n\n" % [
				index + 1,
				score,
				path,
				start_line,
				end_line,
				kind,
				symbol,
				body
			]

			if (context + section).length() > RAGConfig.MAX_CONTEXT_CHARS:
				break
			context += section

	context += "[[PROJECT_CONTEXT_END]]\n\n"
	context += "[[USER_PROMPT_BEGIN]]\n%s\n[[USER_PROMPT_END]]" % original_prompt
	return context

@tool
class_name RAGRetriever
extends RefCounted

var _token_regex: RegEx


func _init() -> void:
	_token_regex = RegEx.new()
	_token_regex.compile("[a-z0-9_]+")


## Retrieves ranked chunks with deterministic scoring and tie-breaking.
func retrieve(query: String, chunks: Array[Dictionary], top_k: int) -> Array[Dictionary]:
	var normalized_query := query.strip_edges().to_lower()
	var query_tokens := _tokenize_query(query)
	if normalized_query.is_empty() and query_tokens.is_empty():
		return []

	var scored: Array[Dictionary] = []
	for chunk in chunks:
		var score := _score_chunk(normalized_query, query_tokens, chunk)
		if score > 0:
			scored.append(RAGTypes.make_scored_chunk(chunk, score))

	scored.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var score_a := int(a.get("score", 0))
		var score_b := int(b.get("score", 0))
		if score_a != score_b:
			return score_a > score_b
		var path_a := String(a.get("path", ""))
		var path_b := String(b.get("path", ""))
		if path_a != path_b:
			return path_a < path_b
		return int(a.get("start_line", 0)) < int(b.get("start_line", 0))
	)

	var bounded_top_k := max(1, top_k)
	if scored.size() > bounded_top_k:
		return scored.slice(0, bounded_top_k)
	return scored


func _score_chunk(normalized_query: String, query_tokens: PackedStringArray, chunk: Dictionary) -> int:
	var text_lc := String(chunk.get("text_lc", ""))
	var path_lc := String(chunk.get("path", "")).to_lower()
	var symbol_lc := String(chunk.get("symbol", "")).to_lower()
	var token_set: Dictionary = {}
	for token in PackedStringArray(chunk.get("tokens", PackedStringArray())):
		token_set[token] = true

	var score := 0
	if normalized_query.length() >= 8 and text_lc.find(normalized_query) >= 0:
		score += RAGConfig.SCORE_PHRASE_MATCH

	var path_bonus := 0
	for token in query_tokens:
		if token_set.has(token):
			score += RAGConfig.SCORE_TOKEN_PRESENT
		var frequency := _count_occurrences(text_lc, token)
		score += min(frequency, RAGConfig.MAX_TOKEN_FREQUENCY_BONUS)
		if path_lc.find(token) >= 0 and path_bonus < RAGConfig.MAX_PATH_BONUS:
			path_bonus += RAGConfig.SCORE_TOKEN_PATH
		if not symbol_lc.is_empty() and symbol_lc.find(token) >= 0:
			score += RAGConfig.SCORE_SYMBOL_MATCH

	score += min(path_bonus, RAGConfig.MAX_PATH_BONUS)
	return score


func _tokenize_query(query: String) -> PackedStringArray:
	var matches := _token_regex.search_all(query.to_lower())
	var tokens: PackedStringArray = []
	var seen: Dictionary = {}
	for result in matches:
		var token := String(result.get_string())
		if token.length() < 2:
			continue
		if seen.has(token):
			continue
		seen[token] = true
		tokens.append(token)
	return tokens


func _count_occurrences(haystack: String, needle: String) -> int:
	if needle.is_empty():
		return 0
	var count := 0
	var from_index := 0
	while true:
		var found := haystack.find(needle, from_index)
		if found < 0:
			break
		count += 1
		from_index = found + needle.length()
	return count

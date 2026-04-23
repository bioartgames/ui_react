@tool
class_name RAGChunker
extends RefCounted

var _token_regex: RegEx


func _init() -> void:
	_token_regex = RegEx.new()
	_token_regex.compile("[a-z0-9_]+")


## Splits file text into deterministic line-based chunks.
func chunk_file(path: String, text: String, mtime: int) -> Array[Dictionary]:
	var cleaned_text := _clean_text_for_chunking(text)
	var lines: PackedStringArray = cleaned_text.split("\n")
	var out: Array[Dictionary] = []
	if lines.is_empty():
		return out

	var kind := _infer_kind(path)
	var total_lines := lines.size()
	var cursor := 0
	while cursor < total_lines:
		var start_line := cursor + 1
		var end_index := min(cursor + RAGConfig.CHUNK_LINES, total_lines)
		var end_line := end_index
		var slice := lines.slice(cursor, end_index)
		var chunk_text := "\n".join(slice)
		var chunk_text_lc := chunk_text.to_lower()
		var symbol := _extract_symbol(kind, chunk_text)
		var tokens := _tokenize(chunk_text)
		var id := "%s#L%d-L%d" % [path, start_line, end_line]
		out.append(
			RAGTypes.make_chunk(
				id,
				path,
				start_line,
				end_line,
				chunk_text,
				chunk_text_lc,
				tokens,
				kind,
				symbol,
				mtime
			)
		)
		if end_index >= total_lines:
			break
		cursor += RAGConfig.CHUNK_STEP

	return out


func _infer_kind(path: String) -> String:
	match path.get_extension().to_lower():
		"gd":
			return "script"
		"tscn":
			return "scene"
		"tres":
			return "resource"
		"cfg", "json":
			return "config"
		"md":
			return "doc"
		"txt":
			return "text"
		_:
			return "other"


func _extract_symbol(kind: String, chunk_text: String) -> String:
	var lines := chunk_text.split("\n")
	if kind == "script":
		for line in lines:
			var trimmed := line.strip_edges()
			if trimmed.begins_with("class_name "):
				return trimmed
		for line in lines:
			var trimmed := line.strip_edges()
			if trimmed.begins_with("func "):
				return trimmed
		for line in lines:
			var trimmed := line.strip_edges()
			if trimmed.begins_with("signal "):
				return trimmed
	elif kind == "scene":
		for line in lines:
			var trimmed := line.strip_edges()
			if trimmed.begins_with("[node name="):
				return trimmed
	return ""


func _clean_text_for_chunking(text: String) -> String:
	var normalized := text.replace("\r\n", "\n").replace("\r", "\n").replace("\t", " ")
	var lines := normalized.split("\n")
	var collapsed: Array[String] = []
	var blank_run := 0
	for line in lines:
		if line.strip_edges().is_empty():
			blank_run += 1
			if blank_run <= 2:
				collapsed.append("")
		else:
			blank_run = 0
			collapsed.append(line)
	return "\n".join(collapsed)


func _tokenize(text: String) -> PackedStringArray:
	var normalized := text.to_lower()
	var matches := _token_regex.search_all(normalized)
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

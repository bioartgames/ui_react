@tool
class_name RAGTypes
extends RefCounted

## Builds a deterministic chunk dictionary.
static func make_chunk(
	id: String,
	path: String,
	start_line: int,
	end_line: int,
	text: String,
	text_lc: String,
	tokens: PackedStringArray,
	kind: String,
	symbol: String,
	mtime: int
) -> Dictionary:
	return {
		"id": id,
		"path": path,
		"start_line": start_line,
		"end_line": end_line,
		"text": text,
		"text_lc": text_lc,
		"tokens": tokens,
		"kind": kind,
		"symbol": symbol,
		"mtime": mtime
	}


## Wraps a chunk with score data for ranking and prompt assembly.
static func make_scored_chunk(chunk: Dictionary, score: int) -> Dictionary:
	return {
		"chunk": chunk,
		"score": score,
		"path": String(chunk.get("path", "")),
		"start_line": int(chunk.get("start_line", 0))
	}

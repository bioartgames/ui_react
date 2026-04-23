@tool
class_name RAGIndexStore
extends RefCounted

var _chunker: RAGChunker
var _chunks: Array[Dictionary] = []
var _file_mtimes: Dictionary = {}
var _raw_file_cache: Dictionary = {}
var _indexed_paths: Array[String] = []


func _init(chunker: RAGChunker) -> void:
	_chunker = chunker


## Rebuilds the full in-memory index from the provided paths.
func rebuild_full(file_paths: Array[String]) -> void:
	_chunks.clear()
	_file_mtimes.clear()
	_raw_file_cache.clear()
	_indexed_paths = file_paths.duplicate()

	for path in file_paths:
		var file_read := _read_file_text(path)
		if not bool(file_read.get("ok", false)):
			continue
		var text := String(file_read.get("text", ""))
		var mtime := int(FileAccess.get_modified_time(path))
		_file_mtimes[path] = mtime
		_raw_file_cache[path] = text
		var file_chunks := _chunker.chunk_file(path, text, mtime)
		_chunks.append_array(file_chunks)

	AIHubPlugin.print_msg("RAG index rebuild finished. chunks=%d files=%d" % [_chunks.size(), _file_mtimes.size()])


## Refreshes index if files changed, were removed, or the tracked path list differs.
func maybe_refresh(file_paths: Array[String]) -> void:
	if _must_rebuild(file_paths):
		rebuild_full(file_paths)


func get_chunks() -> Array[Dictionary]:
	return _chunks


func get_raw_file_cache() -> Dictionary:
	return _raw_file_cache


func _must_rebuild(file_paths: Array[String]) -> bool:
	if file_paths.size() != _indexed_paths.size():
		return true
	for i in range(file_paths.size()):
		if file_paths[i] != _indexed_paths[i]:
			return true
	for path in file_paths:
		var mtime := int(FileAccess.get_modified_time(path))
		if int(_file_mtimes.get(path, -1)) != mtime:
			return true
	return false


func _read_file_text(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		AIHubPlugin.print_msg("RAG index warning: file does not exist %s" % path, true)
		return {"ok": false, "text": ""}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		AIHubPlugin.print_msg("RAG index warning: failed reading %s" % path, true)
		return {"ok": false, "text": ""}
	return {"ok": true, "text": file.get_as_text()}

@tool
class_name RAGFileWalker
extends RefCounted

## Collects project files from res:// using deterministic include/exclude rules.
func collect_project_files(max_files: int) -> Array[String]:
	var bounded_max := max(1, max_files)
	var files: Array[String] = []
	var dirs: Array[String] = ["res://"]
	AIHubPlugin.print_msg("RAG scan started. max_files=%d" % bounded_max)

	while not dirs.is_empty() and files.size() < bounded_max:
		var dir_path := dirs.pop_back()
		if _is_excluded_dir(dir_path):
			continue
		var dir := DirAccess.open(dir_path)
		if dir == null:
			AIHubPlugin.print_msg("RAG scan warning: failed to open directory %s" % dir_path, true)
			continue

		var entries: Array[Dictionary] = []
		dir.list_dir_begin()
		var name := dir.get_next()
		while not name.is_empty():
			if name != "." and name != "..":
				entries.append({"name": name, "is_dir": dir.current_is_dir()})
			name = dir.get_next()
		dir.list_dir_end()

		entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return String(a.get("name", "")) < String(b.get("name", ""))
		)

		for entry in entries:
			var entry_name := String(entry.get("name", ""))
			var full_path := "%s/%s" % [dir_path.trim_suffix("/"), entry_name]
			if bool(entry.get("is_dir", false)):
				if not _is_excluded_dir(full_path):
					dirs.append(full_path)
			else:
				if _is_included_file(full_path) and not _is_excluded_file(full_path):
					files.append(full_path)
					if files.size() >= bounded_max:
						break

	if files.size() >= bounded_max:
		AIHubPlugin.print_msg("RAG scan truncated at file limit (%d)." % bounded_max)

	files.sort()
	AIHubPlugin.print_msg("RAG scan completed. indexed_files=%d" % files.size())
	return files


func _is_excluded_dir(path: String) -> bool:
	var normalized := path if path.ends_with("/") else "%s/" % path
	for prefix in RAGConfig.EXCLUDED_PREFIXES:
		if normalized.begins_with(prefix):
			return true
	return false


func _is_included_file(path: String) -> bool:
	var ext := path.get_extension().to_lower()
	return RAGConfig.INCLUDED_EXTENSIONS.has(ext)


func _is_excluded_file(path: String) -> bool:
	for suffix in RAGConfig.EXCLUDED_SUFFIXES:
		if path.ends_with(suffix):
			return true
	return false

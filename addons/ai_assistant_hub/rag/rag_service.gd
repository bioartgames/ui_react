@tool
class_name RAGService
extends RefCounted

var _plugin: EditorPlugin
var _walker: RAGFileWalker
var _chunker: RAGChunker
var _index_store: RAGIndexStore
var _retriever: RAGRetriever
var _prompt_builder: RAGPromptBuilder


func _init(plugin: EditorPlugin) -> void:
	_plugin = plugin
	_walker = RAGFileWalker.new()
	_chunker = RAGChunker.new()
	_index_store = RAGIndexStore.new(_chunker)
	_retriever = RAGRetriever.new()
	_prompt_builder = RAGPromptBuilder.new()


func initialize() -> void:
	AIHubPlugin.print_msg("RAG service initialized.")


## Builds an augmented user prompt by retrieving project context and injecting it.
func build_augmented_user_prompt(prompt: String) -> String:
	if prompt.strip_edges().is_empty():
		return prompt

	var max_files := RAGConfig.max_files()
	var t0 := Time.get_ticks_msec()
	var files := _walker.collect_project_files(max_files)
	var t1 := Time.get_ticks_msec()

	_index_store.maybe_refresh(files)
	var t2 := Time.get_ticks_msec()

	var scored_chunks := _retriever.retrieve(prompt, _index_store.get_chunks(), RAGConfig.top_k())
	var t3 := Time.get_ticks_msec()

	AIHubPlugin.print_msg(
		"RAG timings (ms): walk=%d index=%d retrieve=%d results=%d" % [
			t1 - t0,
			t2 - t1,
			t3 - t2,
			scored_chunks.size()
		]
	)
	return _prompt_builder.build_augmented_prompt(prompt, scored_chunks)

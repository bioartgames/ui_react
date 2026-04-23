@tool
class_name RAGConfig
extends RefCounted

## Project Settings keys for plugin-side RAG.
const PREF_ENABLED := "plugins/ai_assistant_hub/rag/enabled"
const PREF_MAX_FILES := "plugins/ai_assistant_hub/rag/max_files"
const PREF_TOP_K := "plugins/ai_assistant_hub/rag/top_k"

## Traversal limits.
const DEFAULT_MAX_FILES_INDEXED := 1500

## Deterministic chunking rules.
const CHUNK_LINES := 40
const CHUNK_OVERLAP_LINES := 8
const CHUNK_STEP := CHUNK_LINES - CHUNK_OVERLAP_LINES

## Retrieval defaults.
const DEFAULT_TOP_K := 6

## Prompt budget.
const MAX_CONTEXT_CHARS := 7000
const MAX_SINGLE_CHUNK_CHARS := 1400

## Deterministic scoring weights.
const SCORE_PHRASE_MATCH := 12
const SCORE_TOKEN_PRESENT := 3
const SCORE_TOKEN_PATH := 2
const SCORE_SYMBOL_MATCH := 2
const MAX_TOKEN_FREQUENCY_BONUS := 4
const MAX_PATH_BONUS := 6

## File filtering.
const INCLUDED_EXTENSIONS := [
	"gd",
	"gdshader",
	"tscn",
	"tres",
	"cfg",
	"json",
	"md",
	"txt"
]

const EXCLUDED_PREFIXES := [
	"res://.godot/",
	"res://.git/",
	"res://.import/",
	"res://addons/gut/"
]

const EXCLUDED_SUFFIXES := [
	".uid",
	".import",
	".translation"
]


static func rag_enabled() -> bool:
	return ProjectSettings.get_setting(PREF_ENABLED, true)


static func max_files() -> int:
	return int(ProjectSettings.get_setting(PREF_MAX_FILES, DEFAULT_MAX_FILES_INDEXED))


static func top_k() -> int:
	return int(ProjectSettings.get_setting(PREF_TOP_K, DEFAULT_TOP_K))

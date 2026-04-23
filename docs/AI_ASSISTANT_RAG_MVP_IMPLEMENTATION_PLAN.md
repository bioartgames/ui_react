# AI Assistant Hub — MVP Plugin-Side RAG Implementation Plan

## Scope and non-negotiables

This plan implements RAG **only in the Godot plugin layer** (`addons/ai_assistant_hub`) and treats the LLM provider as a stateless text generator. No model-side retrieval, indexing, memory, tools, or file access are assumed.

This plan is grounded in the current plugin architecture:

- User prompt entry and pre-send preparation happen in `AIChat` (`_input`, `_engineer_prompt`, `_submit_prompt`).
- Message history assembly happens in `AIConversation.build()`.
- LLM transmission happens through `LLMInterface.send_chat_request(...)` in `_submit_prompt`.
- Response handling is already centralized in `_on_http_request_completed` and `AIAnswerHandler.handle(...)`.

---

## 1) System Architecture

### 1.1 Modules to add

Create a new folder:

- `addons/ai_assistant_hub/rag/`

Create these scripts:

1. `rag_config.gd`
   - Single source of configuration constants (include/exclude extensions, chunk sizing, retrieval limits, context budget, scoring weights).

2. `rag_types.gd`
   - Typed helper constructors for dictionaries (chunk records and retrieval results) to keep shape deterministic.

3. `rag_file_walker.gd`
   - Deterministic traversal of `res://` with include/exclude rules.
   - Returns sorted file path list.

4. `rag_chunker.gd`
   - Deterministic line-window chunking.
   - Optional lightweight symbol extraction metadata from filename/text patterns.

5. `rag_index_store.gd`
   - In-memory chunk index + per-file mtime cache.
   - Rebuild/refresh logic and normalized searchable fields.

6. `rag_retriever.gd`
   - Query tokenization + keyword scoring + rank + top-K selection.

7. `rag_prompt_builder.gd`
   - Assembles final injected context block with strict formatting and truncation budget.

8. `rag_service.gd`
   - Facade orchestrator called by `AIChat`: refresh index if needed, retrieve, build augmented prompt.

### 1.2 Existing modules to modify

1. `addons/ai_assistant_hub/ai_chat.gd`
   - Instantiate and initialize `RAGService` once in `initialize(...)`.
   - In `_submit_prompt(...)`, convert raw user prompt to augmented prompt before `_conversation.add_user_prompt(...)`.
   - Keep chat UI rendering unchanged (display raw user prompt only).

2. `addons/ai_assistant_hub/ai_hub_plugin.gd`
   - Add project settings for RAG enable/disable + optional max files/chunks budget.
   - Register these in `initialize_project_settings()`.

### 1.3 Responsibility split (strict)

- Plugin RAG modules: file access, indexing, retrieval, prompt assembly.
- `LLMInterface` implementations: unchanged; receive already-augmented text.
- Model/server: generation only.

### 1.4 Data flow (text diagram)

1. User enters prompt in `AIChat`.
2. `AIChat._engineer_prompt` applies existing `{CODE}` replacement.
3. `AIChat._submit_prompt` calls `RAGService.build_augmented_user_prompt(engineered_prompt)`.
4. `RAGService` ensures index freshness (`res://` walk → chunk → cache).
5. `RAGRetriever` ranks chunks for query.
6. `RAGPromptBuilder` creates deterministic `[[PROJECT_CONTEXT]]` block.
7. `AIChat` appends augmented prompt to `AIConversation` and sends `AIConversation.build()` to LLM.
8. Existing HTTP response and post-processing flow remains unchanged.

---

## 2) File System Design

### 2.1 New files (exact paths)

- `addons/ai_assistant_hub/rag/rag_config.gd`
- `addons/ai_assistant_hub/rag/rag_types.gd`
- `addons/ai_assistant_hub/rag/rag_file_walker.gd`
- `addons/ai_assistant_hub/rag/rag_chunker.gd`
- `addons/ai_assistant_hub/rag/rag_index_store.gd`
- `addons/ai_assistant_hub/rag/rag_retriever.gd`
- `addons/ai_assistant_hub/rag/rag_prompt_builder.gd`
- `addons/ai_assistant_hub/rag/rag_service.gd`

### 2.2 Naming conventions

- Class names in PascalCase prefixed with `RAG` (e.g., `RAGFileWalker`).
- Methods in snake_case with verb-first naming.
- Constants uppercase snake case in `RAGConfig` only.

### 2.3 Integration points

- `AIChat` holds one `_rag_service: RAGService` member.
- `AIHubPlugin` stores project settings under `plugins/ai_assistant_hub/rag/*`.

---

## 3) File Walker Implementation

### 3.1 Traversal strategy

Implement recursive DFS from `res://` using `DirAccess.open`, `list_dir_begin`, `get_next`.

Algorithm (strict order):
1. Start with stack = `['res://']`.
2. Pop directory path.
3. Enumerate entries.
4. Skip `.` and `..`.
5. If directory and name not excluded, push full path.
6. If file and extension in include list and not excluded path pattern, add.
7. After traversal, sort absolute `res://` paths lexicographically.

### 3.2 Include file extensions

Include only:
- `.gd`, `.gdshader`, `.tscn`, `.tres`, `.cfg`, `.json`, `.md`, `.txt`

### 3.3 Exclusion rules

Exclude if path starts with:
- `res://.godot/`
- `res://.git/`
- `res://.import/`
- `res://addons/gut/`

Exclude if filename ends with:
- `.uid`
- `.import`
- `.translation`

### 3.4 Error handling

- If directory open fails: log warning via `AIHubPlugin.print_msg(...)` and continue.
- If file open/read fails: log warning and skip file.
- Never throw hard failure from walker.

### 3.5 Performance constraints

- Hard cap `MAX_FILES_INDEXED` from config (default 1500).
- Stop scanning after cap and log truncation warning.
- Sort output once at end only.

---

## 4) Chunking Strategy

### 4.1 Deterministic splitting

Line-based fixed windows:
- `CHUNK_LINES = 40`
- `CHUNK_OVERLAP_LINES = 8`
- Step = `CHUNK_LINES - CHUNK_OVERLAP_LINES = 32`

For each file text split by `\n`:
- Chunk 0: lines 1–40
- Chunk 1: lines 33–72
- Continue until EOF.
- Final chunk allowed shorter.

### 4.2 Per-chunk metadata shape

Dictionary keys (mandatory):
- `id` (String): `<path>#L<start>-L<end>`
- `path` (String)
- `start_line` (int)
- `end_line` (int)
- `text` (String)
- `text_lc` (String lowercase for scoring)
- `tokens` (PackedStringArray unique normalized tokens)
- `kind` (String: `script|scene|resource|config|doc|text|other`)
- `symbol` (String, optional best-effort)
- `mtime` (int file modified unix time)

### 4.3 File-kind mapping

- `.gd` => `script`
- `.tscn` => `scene`
- `.tres` => `resource`
- `.cfg`/`.json` => `config`
- `.md` => `doc`
- `.txt` => `text`
- else => `other`

### 4.4 Symbol extraction (deterministic heuristics)

- For `.gd`: first matching line in chunk preferring `class_name`, then `func`, then `signal`.
- For `.tscn`: first `[node name="..."]` line if present.
- For others: empty string.

### 4.5 Cleaning and normalization

Before tokenization:
- Replace tabs with one space.
- Normalize CRLF to LF.
- Collapse >2 consecutive blank lines to 2.

Tokenization:
- Lowercase.
- Split on `[^a-z0-9_]+`.
- Drop empty tokens.
- Drop tokens length < 2.
- De-duplicate preserving first appearance order.

---

## 5) Retrieval Algorithm (MVP)

### 5.1 Query preprocessing

Given user query:
- Normalize with same tokenizer rules.
- Also keep full lowercased trimmed query string.

### 5.2 Scoring function

For each chunk:

`score = phrase_score + token_presence_score + token_frequency_score + path_bonus + symbol_bonus`

Where:

1. `phrase_score`
   - +12 if full normalized query (length >= 8 chars) appears in `text_lc`.

2. `token_presence_score`
   - For each unique query token appearing in chunk token set: +3.

3. `token_frequency_score`
   - For each query token, count substring occurrences in `text_lc`; add `min(count, 4)`.

4. `path_bonus`
   - +2 for each query token found in lowercased `path` (cap +6).

5. `symbol_bonus`
   - +2 if non-empty symbol contains any query token.

### 5.3 Ranking and tie-breakers

- Keep chunks with `score > 0`.
- Sort by:
  1. score descending
  2. `path` ascending
  3. `start_line` ascending

### 5.4 Top-K selection

- `RETRIEVAL_TOP_K = 6` pre-truncation candidates.
- Prompt builder may include fewer due to budget.

### 5.5 Fallback behavior

If no chunk with `score > 0`:
- Return empty retrieval set.
- Prompt builder inserts explicit marker: `No relevant project chunks matched the query.`
- Still send user prompt normally.

No embeddings, no vector DB, no ML ranking.

---

## 6) Prompt Injection Layer

### 6.1 Exact injected block format

Augmented user message:

```
[[PROJECT_CONTEXT_BEGIN]]
RAG_VERSION: mvp1
QUERY: <original user prompt>
MATCH_COUNT: <n>

[CHUNK 1 | score=<score> | path=<res://...> | lines=<start>-<end> | kind=<kind> | symbol=<symbol_or_dash>]
<chunk text>

[CHUNK 2 | ...]
...
[[PROJECT_CONTEXT_END]]

[[USER_PROMPT_BEGIN]]
<original user prompt>
[[USER_PROMPT_END]]
```

### 6.2 Ordering rules

- Chunks appear in retrieval rank order.
- For each chunk, metadata header line then raw chunk text.
- Preserve original prompt verbatim at end.

### 6.3 Budget strategy

Character-based deterministic budget:
- `MAX_CONTEXT_CHARS = 7000`
- `MAX_SINGLE_CHUNK_CHARS = 1400`

Process:
1. Build fixed preamble.
2. Iterate top-ranked chunks; each chunk text hard-trimmed to max single-chunk chars.
3. Append until total context chars would exceed max; stop before overflow.
4. Always include `[[USER_PROMPT_BEGIN...END]]` section even if zero chunks.

### 6.4 System/user merge policy

- Do **not** modify system prompt.
- Do **not** modify LLM API payload structure.
- Only mutate the user message content passed to `_conversation.add_user_prompt(...)`.

---

## 7) Integration Points (exact hooks)

### 7.1 `ai_chat.gd`

Add member:
- `var _rag_service: RAGService`

In `initialize(...)`, after `_plugin` and `_assistant_settings` are set and before first `_submit_prompt` call:
- `_rag_service = RAGService.new(_plugin)`
- `_rag_service.initialize()`

In `_submit_prompt(prompt, quick_prompt)`:
1. Keep function signature unchanged.
2. Before `_conversation.add_user_prompt(prompt)`, compute:
   - `var final_prompt := prompt`
   - if plugin setting `plugins/ai_assistant_hub/rag/enabled` true, then `final_prompt = _rag_service.build_augmented_user_prompt(prompt)`.
3. Call `_conversation.add_user_prompt(final_prompt)`.
4. Keep all other flow unchanged.

Important UI behavior:
- `_add_to_chat(prompt, Caller.You)` remains unchanged, so user sees only raw prompt.

### 7.2 `ai_hub_plugin.gd`

Add constants:
- `const PREF_RAG_ENABLED := "plugins/ai_assistant_hub/rag/enabled"`
- `const PREF_RAG_MAX_FILES := "plugins/ai_assistant_hub/rag/max_files"`
- `const PREF_RAG_TOP_K := "plugins/ai_assistant_hub/rag/top_k"`

In `initialize_project_settings()`:
- Register defaults:
  - enabled = `true`
  - max_files = `1500`
  - top_k = `6`
- Add property info so values are visible in Project Settings.

### 7.3 No changes required

- `AIConversation` structure and `build()` logic remain unchanged.
- All LLM API scripts remain unchanged.
- `AIAnswerHandler` and response rendering remain unchanged.

---

## 8) Strict Sequential Implementation Steps

### Step 1 — Create RAG folder and config/types files

1. Create `addons/ai_assistant_hub/rag/`.
2. Implement `rag_config.gd` with all constants centralized.
3. Implement `rag_types.gd` with helper constructors:
   - `make_chunk(...) -> Dictionary`
   - `make_scored_chunk(chunk:Dictionary, score:int) -> Dictionary`

### Step 2 — Implement file walking module

1. Create `rag_file_walker.gd` with:
   - `func collect_project_files(max_files:int) -> Array[String]`
   - private helpers `_is_excluded_dir`, `_is_included_file`, `_is_excluded_file`.
2. Ensure sorted deterministic output.
3. Add logging for scan start/end and truncation.

### Step 3 — Implement chunker

1. Create `rag_chunker.gd` with:
   - `func chunk_file(path:String, text:String, mtime:int) -> Array[Dictionary]`
   - `_infer_kind(path) -> String`
   - `_extract_symbol(kind:String, chunk_text:String) -> String`
   - `_normalize_for_tokens(text:String) -> String`
   - `_tokenize(text:String) -> PackedStringArray`
2. Enforce fixed line-window chunking and metadata schema.

### Step 4 — Implement index store

1. Create `rag_index_store.gd` with members:
   - `_chunks:Array[Dictionary]`
   - `_file_mtimes:Dictionary` (path->mtime)
   - `_file_chunk_ranges:Dictionary` (path->Vector2i begin/end indexes or list of chunk ids)
2. Methods:
   - `func rebuild_full(file_paths:Array[String]) -> void`
   - `func maybe_refresh(file_paths:Array[String]) -> void` (compare mtimes, refresh changed files only)
   - `func get_chunks() -> Array[Dictionary]`
3. Read files with `FileAccess.open(path, FileAccess.READ)`.

### Step 5 — Implement retriever

1. Create `rag_retriever.gd` with:
   - `func retrieve(query:String, chunks:Array[Dictionary], top_k:int) -> Array[Dictionary]`
   - private `_tokenize_query`, `_score_chunk`.
2. Implement scoring and tie-breaking exactly as defined.

### Step 6 — Implement prompt builder

1. Create `rag_prompt_builder.gd` with:
   - `func build_augmented_prompt(original_prompt:String, scored_chunks:Array[Dictionary]) -> String`
2. Enforce exact marker format and char budgets.
3. Ensure fallback marker when no matches.

### Step 7 — Implement RAG service facade

1. Create `rag_service.gd` with dependencies:
   - `RAGFileWalker`, `RAGChunker`, `RAGIndexStore`, `RAGRetriever`, `RAGPromptBuilder`.
2. Public methods:
   - `func _init(plugin:EditorPlugin)`
   - `func initialize() -> void`
   - `func build_augmented_user_prompt(prompt:String) -> String`
3. Workflow in `build_augmented_user_prompt`:
   - collect files (bounded)
   - refresh index
   - retrieve top-k
   - build prompt
   - return prompt
4. Add concise timing logs for scan/index/retrieve stages.

### Step 8 — Integrate in `AIHubPlugin`

1. Add RAG project setting constants.
2. Register setting defaults and property info in `initialize_project_settings()`.

### Step 9 — Integrate in `AIChat`

1. Add `_rag_service` member.
2. Instantiate and initialize in `initialize(...)`.
3. Modify `_submit_prompt(...)` to augment prompt before conversation append, gated by RAG enabled setting.

### Step 10 — Add focused tests (GUT)

Create new tests under:
- `addons/ai_assistant_hub/tests/unit/rag/`

Files:
1. `test_rag_chunker.gd`
   - verifies line windows and overlap determinism.
2. `test_rag_retriever.gd`
   - verifies ranking and tie-breakers with synthetic chunk fixtures.
3. `test_rag_prompt_builder.gd`
   - verifies marker format and max char truncation.

### Step 11 — Manual editor validation

1. Open project in Godot.
2. Ensure plugin enabled.
3. Ask a prompt referencing known symbol/path.
4. Confirm request still succeeds and response flow unchanged.
5. Enable debug mode and verify retrieval logs emitted.

---

## 9) Validation Criteria

### 9.1 File walking checks

Pass criteria:
- Returned file list contains only allowed extensions.
- Excluded folders/files absent.
- List is lexicographically sorted.
- Total files <= configured max.

### 9.2 Chunking checks

Pass criteria:
- Each chunk has required metadata keys.
- Chunk line ranges follow 40/8 overlap rule exactly.
- `id` format stable and unique.
- Tokenization deterministic for same input.

### 9.3 Retrieval checks

Pass criteria:
- Query with exact phrase boosts corresponding chunk above others.
- Tie chunk ordering respects path then line.
- `top_k` respected.
- No-match query returns empty result set.

### 9.4 Prompt injection checks

Pass criteria:
- Augmented prompt always includes context markers and user prompt markers.
- Context never exceeds configured char budget.
- No-match case includes explicit no-match line.
- Original user prompt appears verbatim in `[[USER_PROMPT_BEGIN]]` section.

### 9.5 End-to-end plugin checks

Pass criteria:
- Existing chat send/receive behavior remains functional.
- AI answer rendering and quick-prompt post-processing unchanged.
- With RAG disabled setting, prompt sent equals pre-RAG behavior.

---

## Implementation guardrails for the implementing agent

- Keep code modular and single-responsibility per file.
- Add docstrings for each public method.
- Use centralized constants from `rag_config.gd`; no hardcoded numeric literals outside that file except trivial local counters.
- Log all recoverable errors and continue.
- Ensure deterministic output ordering at every stage (walker, retrieval, prompt assembly).
- Do not introduce external dependencies or network calls for retrieval/indexing.

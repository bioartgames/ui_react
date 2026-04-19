## BBCode/plain helpers for the Dependency Graph details pane ([UiReactDockExplainPanel]).
class_name UiReactDockExplainDetailsPresenter
extends RefCounted


static func normalize_details_newlines(s: String) -> String:
	var t := s
	while t.contains("\n\n\n"):
		t = t.replace("\n\n\n", "\n\n")
	return t


static func plain_from_bbcode_line(line: String) -> String:
	var t := line
	t = t.replace("[b]", "").replace("[/b]", "")
	t = t.replace("[i]", "").replace("[/i]", "")
	t = t.replace("[code]", "").replace("[/code]", "")
	return t


static func details_run_in_bb_plain(title: String, body_bb: String, body_plain: String) -> PackedStringArray:
	var bb := "[b]%s[/b] — %s\n" % [title, body_bb]
	var plain := "%s — %s\n" % [title, body_plain]
	return PackedStringArray([bb, plain])


static func details_block_head_bb_plain(title: String) -> PackedStringArray:
	return PackedStringArray(["[b]%s[/b]\n" % title, "%s\n" % title])


static func details_append_major(bb: String, plain: String, chunk_bb: String, chunk_plain: String) -> PackedStringArray:
	if chunk_bb.is_empty() and chunk_plain.is_empty():
		return PackedStringArray([bb, plain])
	var cbb := chunk_bb.lstrip("\n")
	var cpp := chunk_plain.lstrip("\n")
	if bb.is_empty() and plain.is_empty():
		return PackedStringArray([cbb, cpp])
	return PackedStringArray([bb.rstrip("\n") + "\n\n" + cbb, plain.rstrip("\n") + "\n\n" + cpp])

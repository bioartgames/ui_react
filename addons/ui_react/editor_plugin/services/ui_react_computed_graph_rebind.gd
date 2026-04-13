## Resolves [code]computed_context[/code] paths from [Dependency Graph] (**CB-058** slice 3) and commits [code]sources[i][/code] on [UiComputedStringState] / [UiComputedBoolState] with undo via [UiReactActionController].
class_name UiReactComputedGraphRebind
extends RefCounted

const _MAX_COMPUTED_SOURCES := 32


static func try_resolve_computed(host: Control, computed_context: String) -> Variant:
	if host == null or computed_context.is_empty():
		return null
	var cur: Variant = follow_path(host, computed_context)
	if cur is UiComputedStringState or cur is UiComputedBoolState:
		return cur
	return null


static func follow_path(start: Variant, path: String) -> Variant:
	var cur: Variant = start
	var s := path
	var first := true
	while not s.is_empty():
		var step: Dictionary
		if first and cur is Control:
			step = _parse_control_prefix(cur as Control, s)
		else:
			step = _pop_segment_deep(cur, s)
		first = false
		if step.is_empty() or not bool(step.get(&"ok", false)):
			return null
		cur = step[&"next"]
		s = str(step.get(&"rest", ""))
	return cur


static func try_commit_replace_source(
	host: Control,
	computed_context: String,
	source_index: int,
	new_src: UiState,
	actions: UiReactActionController,
) -> bool:
	if new_src == null:
		return false
	return _try_commit_sources_index(
		host,
		computed_context,
		source_index,
		new_src,
		actions,
		"Ui React: computed sources[%d] (%s)" % [source_index, computed_context],
	)


## Clears [code]sources[source_index][/code] to [code]null[/code] (**[code]CB-058[/code]** slice 1 graph disconnect).
static func try_commit_clear_source(
	host: Control,
	computed_context: String,
	source_index: int,
	actions: UiReactActionController,
) -> bool:
	return _try_commit_sources_index(
		host,
		computed_context,
		source_index,
		null,
		actions,
		"Ui React: Clear computed sources[%d] (%s)" % [source_index, computed_context],
	)


static func _try_commit_sources_index(
	host: Control,
	computed_context: String,
	source_index: int,
	new_value: Variant,
	actions: UiReactActionController,
	undo_label: String,
) -> bool:
	if host == null or actions == null or computed_context.is_empty():
		return false
	var c0: Variant = try_resolve_computed(host, computed_context)
	if c0 == null:
		push_warning("Ui React: could not resolve computed at context: %s" % computed_context)
		return false
	var raw: Variant = c0.get(&"sources")
	if typeof(raw) != TYPE_ARRAY:
		return false
	var arr: Array = raw as Array
	if source_index < 0 or source_index >= arr.size():
		push_warning("Ui React: computed sources index out of range: %d" % source_index)
		return false

	var head: Dictionary = _parse_control_prefix(host, computed_context)
	if head.is_empty() or not bool(head.get(&"ok", false)):
		push_warning("Ui React: invalid computed_context for commit: %s" % computed_context)
		return false
	var rest: String = str(head.get(&"rest", ""))
	var first_child: Variant = head[&"next"]
	if first_child == null and not rest.is_empty():
		push_warning("Ui React: null path segment in computed_context: %s" % computed_context)
		return false

	var new_subtree: Variant
	if rest.is_empty():
		new_subtree = _patch_computed_leaf(first_child, source_index, new_value)
	else:
		new_subtree = _mutate_path(first_child, rest, source_index, new_value)
	if new_subtree == null:
		return false

	var kind: StringName = head[&"kind"]
	match kind:
		&"bind":
			var prop: StringName = head[&"export"]
			actions.assign_property_variant(host, prop, new_subtree, undo_label)
			return true
		&"wire":
			var wi: int = int(head[&"rule_index"])
			var wp: StringName = head[&"rule_prop"]
			return _commit_wire_field(host, wi, wp, new_subtree, source_index, computed_context, actions)
		&"tab_config":
			return _commit_tab_config_field(host, head, new_subtree, source_index, computed_context, actions)
		&"anim":
			return _commit_array_element(
				host,
				head[&"export"],
				int(head[&"array_index"]),
				new_subtree,
				source_index,
				computed_context,
				actions
			)
		&"action":
			return _commit_array_element(
				host,
				head[&"export"],
				int(head[&"array_index"]),
				new_subtree,
				source_index,
				computed_context,
				actions
			)
		_:
			return false


## Swaps [code]sources[index_a][/code] and [code]sources[index_b][/code] (**[code]CB-058[/code]** follow-on).
static func try_commit_swap_sources(
	host: Control,
	computed_context: String,
	index_a: int,
	index_b: int,
	actions: UiReactActionController,
) -> bool:
	var ul := "Ui React: Swap computed sources (%s)" % computed_context
	var mut_swap: Callable = func(arr: Array) -> bool:
		if index_a < 0 or index_b < 0 or index_a >= arr.size() or index_b >= arr.size():
			return false
		if index_a == index_b:
			return false
		var t: Variant = arr[index_a]
		arr[index_a] = arr[index_b]
		arr[index_b] = t
		return true
	return _try_commit_sources_array_mutation(host, computed_context, actions, ul, mut_swap)


## Removes [code]sources[source_index][/code] and compacts the array (**[code]CB-058[/code]** follow-on).
static func try_commit_remove_source_at(
	host: Control,
	computed_context: String,
	source_index: int,
	actions: UiReactActionController,
) -> bool:
	var ul2 := "Ui React: Remove computed source slot (%s)" % computed_context
	var mut_rm: Callable = func(arr: Array) -> bool:
		if source_index < 0 or source_index >= arr.size():
			return false
		arr.remove_at(source_index)
		return true
	return _try_commit_sources_array_mutation(host, computed_context, actions, ul2, mut_rm)


static func _try_commit_sources_array_mutation(
	host: Control,
	computed_context: String,
	actions: UiReactActionController,
	undo_label: String,
	mutator: Callable,
) -> bool:
	if host == null or actions == null or computed_context.is_empty() or not mutator.is_valid():
		return false
	var c0: Variant = try_resolve_computed(host, computed_context)
	if c0 == null:
		push_warning("Ui React: could not resolve computed at context: %s" % computed_context)
		return false
	var raw0: Variant = c0.get(&"sources")
	if typeof(raw0) != TYPE_ARRAY:
		return false

	var head: Dictionary = _parse_control_prefix(host, computed_context)
	if head.is_empty() or not bool(head.get(&"ok", false)):
		push_warning("Ui React: invalid computed_context for commit: %s" % computed_context)
		return false
	var rest: String = str(head.get(&"rest", ""))
	var first_child: Variant = head[&"next"]
	if first_child == null and not rest.is_empty():
		push_warning("Ui React: null path segment in computed_context: %s" % computed_context)
		return false

	var new_subtree: Variant
	if rest.is_empty():
		new_subtree = _patch_computed_leaf_sources_mutate(first_child, mutator)
	else:
		new_subtree = _mutate_path_sources_mutate(first_child, rest, mutator)
	if new_subtree == null:
		return false

	var kind: StringName = head[&"kind"]
	match kind:
		&"bind":
			var prop: StringName = head[&"export"]
			actions.assign_property_variant(host, prop, new_subtree, undo_label)
			return true
		&"wire":
			var wi: int = int(head[&"rule_index"])
			var wp: StringName = head[&"rule_prop"]
			return _commit_wire_field(
				host, wi, wp, new_subtree, 0, computed_context, actions, undo_label
			)
		&"tab_config":
			return _commit_tab_config_field(
				host, head, new_subtree, 0, computed_context, actions, undo_label
			)
		&"anim":
			return _commit_array_element(
				host,
				head[&"export"],
				int(head[&"array_index"]),
				new_subtree,
				0,
				computed_context,
				actions,
				undo_label,
			)
		&"action":
			return _commit_array_element(
				host,
				head[&"export"],
				int(head[&"array_index"]),
				new_subtree,
				0,
				computed_context,
				actions,
				undo_label,
			)
		_:
			return false


static func _patch_computed_leaf_sources_mutate(cur: Variant, mutator: Callable) -> Variant:
	if not (cur is UiComputedStringState or cur is UiComputedBoolState):
		return null
	var c: Resource = cur as Resource
	var c2: Resource = c.duplicate(true)
	if c2 == null:
		return null
	var raw2: Variant = c2.get(&"sources")
	if typeof(raw2) != TYPE_ARRAY:
		return null
	var arr: Array = (raw2 as Array).duplicate()
	if not bool(mutator.call(arr)):
		return null
	c2.set(&"sources", arr)
	return c2


static func _mutate_path_sources_mutate(cur: Variant, path: String, mutator: Callable) -> Variant:
	if path.is_empty():
		return _patch_computed_leaf_sources_mutate(cur, mutator)
	var step: Dictionary = _pop_segment_deep(cur, path)
	if step.is_empty() or not bool(step.get(&"ok", false)):
		return null
	var child_val: Variant = step[&"next"]
	var rest: String = str(step.get(&"rest", ""))
	var inner_new: Variant = _mutate_path_sources_mutate(child_val, rest, mutator)
	if inner_new == null:
		return null
	return _replace_child(cur, step, inner_new)


## Fills first null / non-[UiState] [code]sources[/code] slot, or appends if all slots hold [UiState] and size [i]<[/i] [_MAX_COMPUTED_SOURCES] (**[code]CB-058[/code]** phase 2b).
static func try_commit_append_or_fill_source(
	host: Control,
	computed_context: String,
	new_src: UiState,
	actions: UiReactActionController,
) -> bool:
	if host == null or actions == null or computed_context.is_empty() or new_src == null:
		return false
	var c0: Variant = try_resolve_computed(host, computed_context)
	if c0 == null:
		push_warning("Ui React: could not resolve computed at context: %s" % computed_context)
		return false
	var raw: Variant = c0.get(&"sources")
	if typeof(raw) != TYPE_ARRAY:
		return false
	var arr: Array = raw as Array
	var idx := _source_index_for_fill_or_append(arr)
	if idx < 0:
		push_warning("Ui React: computed sources full or invalid (max %d)." % _MAX_COMPUTED_SOURCES)
		return false

	var head: Dictionary = _parse_control_prefix(host, computed_context)
	if head.is_empty() or not bool(head.get(&"ok", false)):
		push_warning("Ui React: invalid computed_context for commit: %s" % computed_context)
		return false
	var rest: String = str(head.get(&"rest", ""))
	var first_child: Variant = head[&"next"]
	if first_child == null and not rest.is_empty():
		push_warning("Ui React: null path segment in computed_context: %s" % computed_context)
		return false

	var new_subtree: Variant
	if rest.is_empty():
		new_subtree = _patch_computed_leaf_write_index(first_child, idx, new_src as Variant)
	else:
		new_subtree = _mutate_path_write_index(first_child, rest, idx, new_src as Variant)
	if new_subtree == null:
		return false

	var kind: StringName = head[&"kind"]
	match kind:
		&"bind":
			var prop: StringName = head[&"export"]
			actions.assign_property_variant(
				host,
				prop,
				new_subtree,
				"Ui React: computed sources[%d] append/fill (%s)" % [idx, computed_context]
			)
			return true
		&"wire":
			var wi: int = int(head[&"rule_index"])
			var wp: StringName = head[&"rule_prop"]
			return _commit_wire_field(host, wi, wp, new_subtree, idx, computed_context, actions)
		&"tab_config":
			return _commit_tab_config_field(host, head, new_subtree, idx, computed_context, actions)
		&"anim":
			return _commit_array_element(
				host,
				head[&"export"],
				int(head[&"array_index"]),
				new_subtree,
				idx,
				computed_context,
				actions
			)
		&"action":
			return _commit_array_element(
				host,
				head[&"export"],
				int(head[&"array_index"]),
				new_subtree,
				idx,
				computed_context,
				actions
			)
		_:
			return false


static func can_fill_or_append_computed_sources(host: Control, computed_context: String) -> bool:
	if host == null or computed_context.is_empty():
		return false
	var c0: Variant = try_resolve_computed(host, computed_context)
	if c0 == null:
		return false
	var raw: Variant = c0.get(&"sources")
	if typeof(raw) != TYPE_ARRAY:
		return false
	return _source_index_for_fill_or_append(raw as Array) >= 0


static func _source_index_for_fill_or_append(arr: Array) -> int:
	for i in range(arr.size()):
		if not (arr[i] is UiState):
			return i
	if arr.size() < _MAX_COMPUTED_SOURCES:
		return arr.size()
	return -1


static func _patch_computed_leaf_write_index(cur: Variant, source_index: int, new_src: Variant) -> Variant:
	if not (cur is UiComputedStringState or cur is UiComputedBoolState):
		return null
	var c: Resource = cur as Resource
	var c2: Resource = c.duplicate(true)
	if c2 == null:
		return null
	var raw2: Variant = c2.get(&"sources")
	if typeof(raw2) != TYPE_ARRAY:
		return null
	var arr: Array = (raw2 as Array).duplicate()
	if source_index == arr.size():
		arr.append(new_src)
	elif source_index >= 0 and source_index < arr.size():
		arr[source_index] = new_src
	else:
		return null
	c2.set(&"sources", arr)
	return c2


static func _mutate_path_write_index(cur: Variant, path: String, source_index: int, new_src: Variant) -> Variant:
	if path.is_empty():
		return _patch_computed_leaf_write_index(cur, source_index, new_src)
	var step: Dictionary = _pop_segment_deep(cur, path)
	if step.is_empty() or not bool(step.get(&"ok", false)):
		return null
	var child_val: Variant = step[&"next"]
	var rest: String = str(step.get(&"rest", ""))
	var inner_new: Variant = _mutate_path_write_index(child_val, rest, source_index, new_src)
	if inner_new == null:
		return null
	return _replace_child(cur, step, inner_new)


static func _rx_wire() -> RegEx:
	var r := RegEx.new()
	r.compile("^wire\\[(\\d+)\\]\\.([A-Za-z_][A-Za-z0-9_]*)")
	return r


static func _rx_tab_content() -> RegEx:
	var r := RegEx.new()
	r.compile("^tab_config\\.content\\[(\\d+)\\]")
	return r


static func _rx_array_head() -> RegEx:
	var r := RegEx.new()
	r.compile("^([a-zA-Z_][a-zA-Z0-9_]*)\\[(\\d+)\\]")
	return r


static func _rx_src() -> RegEx:
	var r := RegEx.new()
	r.compile("^src\\[(\\d+)\\]")
	return r


static func _parse_control_prefix(host: Control, full_path: String) -> Dictionary:
	if full_path.begins_with("bind:"):
		var dot_src := full_path.find(".src[")
		var seg := full_path if dot_src == -1 else full_path.substr(0, dot_src)
		var rest := "" if dot_src == -1 else full_path.substr(dot_src + 1)
		var prop_sn := StringName(seg.substr(5))
		if not prop_sn in host:
			return {}
		return {
			&"ok": true,
			&"kind": &"bind",
			&"export": prop_sn,
			&"rest": rest,
			&"next": host.get(prop_sn),
		}
	if full_path.begins_with("wire["):
		var m: RegExMatch = _rx_wire().search(full_path)
		if m == null or not (&"wire_rules" in host):
			return {}
		var wi := int(m.get_string(1))
		var wp := StringName(m.get_string(2))
		var rest_w := full_path.substr(m.get_end()).trim_prefix(".")
		var wr: Variant = host.get(&"wire_rules")
		if wr == null or not (wr is Array):
			return {}
		var a: Array = wr as Array
		if wi < 0 or wi >= a.size():
			return {}
		var rule: Variant = a[wi]
		if rule == null or not (rule is UiReactWireRule):
			return {}
		return {
			&"ok": true,
			&"kind": &"wire",
			&"rule_index": wi,
			&"rule_prop": wp,
			&"rest": rest_w,
			&"next": rule.get(wp),
		}
	if full_path.begins_with("tab_config.tabs"):
		var rest_t := full_path.substr(15).trim_prefix(".")
		return _tab_cfg_prefix(host, &"tabs_state", rest_t)
	if full_path.begins_with("tab_config.disabled"):
		var rest_d := full_path.substr(18).trim_prefix(".")
		return _tab_cfg_prefix(host, &"disabled_tabs_state", rest_d)
	if full_path.begins_with("tab_config.visible"):
		var rest_v := full_path.substr(17).trim_prefix(".")
		return _tab_cfg_prefix(host, &"visible_tabs_state", rest_v)
	if full_path.begins_with("tab_config.content["):
		var mc: RegExMatch = _rx_tab_content().search(full_path)
		if mc == null:
			return {}
		var ci := int(mc.get_string(1))
		var rest_c := full_path.substr(mc.get_end()).trim_prefix(".")
		if not (&"tab_config" in host):
			return {}
		var cfg: Variant = host.get(&"tab_config")
		if cfg == null or not (cfg is UiTabContainerCfg):
			return {}
		var tcfg := cfg as UiTabContainerCfg
		if ci < 0 or ci >= tcfg.tab_content_states.size():
			return {}
		return {
			&"ok": true,
			&"kind": &"tab_config",
			&"field": &"content",
			&"content_index": ci,
			&"rest": rest_c,
			&"next": tcfg.tab_content_states[ci],
		}
	if full_path.begins_with("animation_targets"):
		return _array_export_prefix(host, &"animation_targets", &"anim", full_path)
	if full_path.begins_with("action_targets"):
		return _array_export_prefix(host, &"action_targets", &"action", full_path)
	return {}


static func _tab_cfg_prefix(host: Control, field: StringName, rest: String) -> Dictionary:
	if not (&"tab_config" in host):
		return {}
	var cfg: Variant = host.get(&"tab_config")
	if cfg == null or not (cfg is UiTabContainerCfg):
		return {}
	return {
		&"ok": true,
		&"kind": &"tab_config",
		&"field": field,
		&"rest": rest,
		&"next": cfg.get(field),
	}


static func _array_export_prefix(
	host: Control, export_sn: StringName, kind: StringName, full_path: String
) -> Dictionary:
	var m: RegExMatch = _rx_array_head().search(full_path)
	if m == null or not export_sn in host:
		return {}
	var ai := int(m.get_string(2))
	var rest := full_path.substr(m.get_end()).trim_prefix(".")
	var arr_v: Variant = host.get(export_sn)
	if arr_v == null or not (arr_v is Array):
		return {}
	var ar: Array = arr_v as Array
	if ai < 0 or ai >= ar.size():
		return {}
	return {
		&"ok": true,
		&"kind": kind,
		&"export": export_sn,
		&"array_index": ai,
		&"rest": rest,
		&"next": ar[ai],
	}


static func _patch_computed_leaf(cur: Variant, source_index: int, new_src: Variant) -> Variant:
	if not (cur is UiComputedStringState or cur is UiComputedBoolState):
		return null
	var c: Resource = cur as Resource
	var c2: Resource = c.duplicate(true)
	if c2 == null:
		return null
	var raw2: Variant = c2.get(&"sources")
	if typeof(raw2) != TYPE_ARRAY:
		return null
	var arr: Array = (raw2 as Array).duplicate()
	if source_index < 0 or source_index >= arr.size():
		return null
	arr[source_index] = new_src
	c2.set(&"sources", arr)
	return c2


static func _mutate_path(cur: Variant, path: String, source_index: int, new_src: Variant) -> Variant:
	if path.is_empty():
		return _patch_computed_leaf(cur, source_index, new_src)
	var step: Dictionary = _pop_segment_deep(cur, path)
	if step.is_empty() or not bool(step.get(&"ok", false)):
		return null
	var child_val: Variant = step[&"next"]
	var rest: String = str(step.get(&"rest", ""))
	var inner_new: Variant = _mutate_path(child_val, rest, source_index, new_src)
	if inner_new == null:
		return null
	return _replace_child(cur, step, inner_new)


static func _replace_child(parent: Variant, step: Dictionary, inner_new: Variant) -> Variant:
	var typ: StringName = step[&"type"]
	match typ:
		&"computed_src":
			var c: Resource = parent as Resource
			var d: Resource = c.duplicate(true)
			if d == null:
				return null
			var idx: int = int(step[&"idx"])
			var raw: Variant = d.get(&"sources")
			if typeof(raw) != TYPE_ARRAY:
				return null
			var arr: Array = (raw as Array).duplicate()
			if idx < 0 or idx >= arr.size():
				return null
			arr[idx] = inner_new
			d.set(&"sources", arr)
			return d
		&"dict":
			var dict: Dictionary = (parent as Dictionary).duplicate(true)
			var k: String = str(step[&"key"])
			dict[k] = inner_new
			return dict
		&"resource_prop":
			var r: Resource = parent as Resource
			var d2: Resource = r.duplicate(true)
			if d2 == null:
				return null
			d2.set(step[&"prop"], inner_new)
			return d2
	return null


static func _pop_segment_deep(cur: Variant, path: String) -> Dictionary:
	if path.begins_with("src["):
		var m: RegExMatch = _rx_src().search(path)
		if m == null or not (cur is UiComputedStringState or cur is UiComputedBoolState):
			return {}
		var idx := int(m.get_string(1))
		var rest := path.substr(m.get_end()).trim_prefix(".")
		var raw: Variant = cur.get(&"sources")
		if typeof(raw) != TYPE_ARRAY:
			return {}
		var arr: Array = raw as Array
		if idx < 0 or idx >= arr.size():
			return {}
		return {
			&"ok": true,
			&"type": &"computed_src",
			&"idx": idx,
			&"next": arr[idx],
			&"rest": rest,
		}
	if cur is Dictionary:
		var dot := path.find(".")
		var seg := path if dot == -1 else path.substr(0, dot)
		var rest2 := "" if dot == -1 else path.substr(dot + 1)
		var d := cur as Dictionary
		if not d.has(seg):
			return {}
		return {&"ok": true, &"type": &"dict", &"key": seg, &"next": d[seg], &"rest": rest2}
	if cur is Resource:
		var dot2 := path.find(".")
		var brk := path.find("[")
		var cut := path.length()
		if dot2 >= 0:
			cut = mini(cut, dot2)
		if brk >= 0:
			cut = mini(cut, brk)
		var prop_str := path.substr(0, cut)
		if prop_str.is_empty():
			return {}
		var prop_sn := StringName(prop_str)
		if not prop_sn in cur:
			return {}
		var rest3 := path.substr(cut).trim_prefix(".")
		return {
			&"ok": true,
			&"type": &"resource_prop",
			&"prop": prop_sn,
			&"next": cur.get(prop_sn),
			&"rest": rest3,
		}
	return {}


static func _commit_wire_field(
	host: Control,
	rule_index: int,
	rule_prop: StringName,
	new_subtree: Variant,
	source_index: int,
	computed_context: String,
	actions: UiReactActionController,
	p_undo_label: String = "",
) -> bool:
	var wr: Variant = host.get(&"wire_rules")
	if wr == null:
		return false
	var arr: Array[UiReactWireRule] = []
	if wr is Array[UiReactWireRule]:
		arr = (wr as Array[UiReactWireRule]).duplicate()
	else:
		for it in wr as Array:
			if it is UiReactWireRule:
				arr.append(it as UiReactWireRule)
	if rule_index < 0 or rule_index >= arr.size():
		return false
	var old_rule: Variant = arr[rule_index]
	if old_rule == null or not (old_rule is UiReactWireRule):
		return false
	var dup_r: Resource = (old_rule as Resource).duplicate(true)
	if dup_r == null or not (dup_r is UiReactWireRule):
		return false
	dup_r.set(rule_prop, new_subtree)
	arr[rule_index] = dup_r as UiReactWireRule
	var ul := (
		p_undo_label
		if not p_undo_label.is_empty()
		else "Ui React: computed sources[%d] (%s)" % [source_index, computed_context]
	)
	actions.assign_property_variant(host, &"wire_rules", arr, ul)
	return true


static func _commit_tab_config_field(
	host: Control,
	head: Dictionary,
	new_subtree: Variant,
	source_index: int,
	computed_context: String,
	actions: UiReactActionController,
	p_undo_label: String = "",
) -> bool:
	if not (&"tab_config" in host):
		return false
	var cfg0: Variant = host.get(&"tab_config")
	if cfg0 == null or not (cfg0 is UiTabContainerCfg):
		return false
	var cfg: UiTabContainerCfg = cfg0.duplicate(true) as UiTabContainerCfg
	if cfg == null:
		return false
	var fld: StringName = head[&"field"]
	match fld:
		&"tabs_state", &"disabled_tabs_state", &"visible_tabs_state":
			cfg.set(fld, new_subtree)
		&"content":
			var ci: int = int(head[&"content_index"])
			if ci < 0 or ci >= cfg.tab_content_states.size():
				return false
			cfg.tab_content_states[ci] = new_subtree
		_:
			return false
	var ul2 := (
		p_undo_label
		if not p_undo_label.is_empty()
		else "Ui React: computed sources[%d] (%s)" % [source_index, computed_context]
	)
	actions.assign_property_variant(host, &"tab_config", cfg, ul2)
	return true


static func _commit_array_element(
	host: Control,
	export_sn: StringName,
	array_index: int,
	new_subtree: Variant,
	source_index: int,
	computed_context: String,
	actions: UiReactActionController,
	p_undo_label: String = "",
) -> bool:
	if not export_sn in host:
		return false
	var raw: Variant = host.get(export_sn)
	if raw == null or not (raw is Array):
		return false
	var a: Array = (raw as Array).duplicate()
	if array_index < 0 or array_index >= a.size():
		return false
	a[array_index] = new_subtree
	var ul3 := (
		p_undo_label
		if not p_undo_label.is_empty()
		else "Ui React: computed sources[%d] (%s)" % [source_index, computed_context]
	)
	actions.assign_property_variant(host, export_sn, a, ul3)
	return true

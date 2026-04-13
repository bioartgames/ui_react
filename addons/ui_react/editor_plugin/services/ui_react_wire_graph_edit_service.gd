## Undo-safe [member Control.wire_rules] edits for Dependency Graph (**[code]CB-058[/code]** follow-on): rebind, disconnect, [rule_id], [enabled], [trigger], greenfield append.
class_name UiReactWireGraphEditService
extends RefCounted

const _WireRuleCatalogScript := preload("res://addons/ui_react/editor_plugin/services/ui_react_wire_rule_catalog.gd")


static func _is_valid_trigger_ordinal(ord: int) -> bool:
	return (
		ord == UiReactWireRule.TriggerKind.TEXT_CHANGED
		or ord == UiReactWireRule.TriggerKind.SELECTION_CHANGED
		or ord == UiReactWireRule.TriggerKind.TEXT_ENTERED
	)


## Ordinals for [member UiReactWireRule.trigger] in stable UI order (see [code]WIRING_LAYER.md[/code] §5).
static func wire_trigger_kind_ordinals_in_ui_order() -> PackedInt32Array:
	return PackedInt32Array(
		[
			UiReactWireRule.TriggerKind.TEXT_CHANGED,
			UiReactWireRule.TriggerKind.SELECTION_CHANGED,
			UiReactWireRule.TriggerKind.TEXT_ENTERED,
		]
	)


static func wire_trigger_kind_label(kind_ord: int) -> String:
	match kind_ord:
		UiReactWireRule.TriggerKind.TEXT_CHANGED:
			return "TEXT_CHANGED"
		UiReactWireRule.TriggerKind.SELECTION_CHANGED:
			return "SELECTION_CHANGED"
		UiReactWireRule.TriggerKind.TEXT_ENTERED:
			return "TEXT_ENTERED"
		_:
			return "trigger(%d)" % kind_ord


static func duplicate_wire_rules_array(host: Control) -> Array[UiReactWireRule]:
	var wr: Variant = host.get(&"wire_rules")
	if wr == null:
		return []
	if wr is Array[UiReactWireRule]:
		return (wr as Array[UiReactWireRule]).duplicate()
	var plain: Array = wr as Array
	var out: Array[UiReactWireRule] = []
	for it in plain:
		if it is UiReactWireRule:
			out.append(it as UiReactWireRule)
	return out


static func try_mutate_wire_rule_at_index(
	host: Control,
	rule_index: int,
	mutator: Callable,
	actions: UiReactActionController,
	undo_label: String,
) -> bool:
	if host == null or actions == null or not mutator.is_valid():
		return false
	if not (&"wire_rules" in host):
		push_warning("Ui React: host has no wire_rules: %s" % host.get_path())
		return false
	var arr := duplicate_wire_rules_array(host)
	if rule_index < 0 or rule_index >= arr.size():
		push_warning("Ui React: wire_rules index out of range: %d" % rule_index)
		return false
	var old_rule: Variant = arr[rule_index]
	if old_rule == null or not (old_rule is UiReactWireRule):
		push_warning("Ui React: wire_rules[%d] is not a UiReactWireRule." % rule_index)
		return false
	var dup_res: Resource = (old_rule as Resource).duplicate(true)
	if dup_res == null or not (dup_res is UiReactWireRule):
		push_warning("Ui React: could not duplicate wire rule at index %d." % rule_index)
		return false
	var new_rule := dup_res as UiReactWireRule
	if not bool(mutator.call(new_rule)):
		return false
	arr[rule_index] = new_rule
	actions.assign_property_variant(host, &"wire_rules", arr, undo_label)
	return true


static func try_commit_wire_slot_rebind(
	host: Control,
	rule_index: int,
	wprop: StringName,
	ui_st: UiState,
	actions: UiReactActionController,
) -> bool:
	var mut: Callable = func(rule: UiReactWireRule) -> bool:
		if not wprop in rule:
			push_warning("Ui React: rule has no export %s" % str(wprop))
			return false
		rule.set(wprop, ui_st)
		return true
	return try_mutate_wire_rule_at_index(
		host,
		rule_index,
		mut,
		actions,
		"Ui React: wire_rules[%d] %s" % [rule_index, str(wprop)],
	)


static func try_commit_wire_edge_disconnect(
	host: Control,
	rule_index: int,
	in_prop: StringName,
	out_prop: StringName,
	actions: UiReactActionController,
) -> bool:
	var mut2: Callable = func(rule: UiReactWireRule) -> bool:
		if not in_prop in rule or not out_prop in rule:
			if not in_prop in rule:
				push_warning("Ui React: rule has no export %s" % str(in_prop))
			if not out_prop in rule:
				push_warning("Ui React: rule has no export %s" % str(out_prop))
			return false
		if rule.get(in_prop) == null and rule.get(out_prop) == null:
			return false
		rule.set(in_prop, null)
		rule.set(out_prop, null)
		return true
	return try_mutate_wire_rule_at_index(
		host,
		rule_index,
		mut2,
		actions,
		"Ui React: Clear wire link wire_rules[%d]" % rule_index,
	)


static func try_commit_wire_rule_id(
	host: Control,
	rule_index: int,
	new_id: String,
	actions: UiReactActionController,
) -> bool:
	var trimmed := new_id.strip_edges()
	var mut3: Callable = func(rule: UiReactWireRule) -> bool:
		if rule.rule_id == trimmed:
			return false
		rule.rule_id = trimmed
		return true
	return try_mutate_wire_rule_at_index(
		host,
		rule_index,
		mut3,
		actions,
		"Ui React: wire_rules[%d] rule_id" % rule_index,
	)


static func try_commit_wire_rule_enabled(
	host: Control,
	rule_index: int,
	enabled: bool,
	actions: UiReactActionController,
) -> bool:
	var mut_en: Callable = func(rule: UiReactWireRule) -> bool:
		if rule.enabled == enabled:
			return false
		rule.enabled = enabled
		return true
	return try_mutate_wire_rule_at_index(
		host,
		rule_index,
		mut_en,
		actions,
		"Ui React: wire_rules[%d] enabled" % rule_index,
	)


static func try_commit_wire_rule_trigger(
	host: Control,
	rule_index: int,
	trigger_ordinal: int,
	actions: UiReactActionController,
) -> bool:
	if not _is_valid_trigger_ordinal(trigger_ordinal):
		push_warning("Ui React: invalid wire rule trigger ordinal: %d" % trigger_ordinal)
		return false
	var ord_copy := trigger_ordinal
	var mut_tr: Callable = func(rule: UiReactWireRule) -> bool:
		var target_k: UiReactWireRule.TriggerKind = ord_copy as UiReactWireRule.TriggerKind
		if rule.trigger == target_k:
			return false
		rule.trigger = target_k
		return true
	return try_mutate_wire_rule_at_index(
		host,
		rule_index,
		mut_tr,
		actions,
		"Ui React: wire_rules[%d] trigger" % rule_index,
	)


## First [code]list_io[/code] [b]in[/b] export on a freshly instantiated rule (all inputs empty).
static func first_wire_in_property(rule: UiReactWireRule) -> StringName:
	if rule == null:
		return &""
	for ref in UiReactWireRuleIntrospection.list_io(rule):
		if ref.get(&"role", &"") != &"in":
			continue
		var prop: Variant = ref.get(&"property", &"")
		var prop_sn: StringName = prop if prop is StringName else StringName(str(prop))
		if prop_sn == &"" or not prop_sn in rule:
			continue
		return prop_sn
	return &""


static func try_commit_append_wire_rule_with_in(
	host: Control,
	rule_template_index: int,
	donor: UiState,
	actions: UiReactActionController,
) -> bool:
	if host == null or actions == null or donor == null:
		return false
	if not (&"wire_rules" in host):
		return false
	var rule: UiReactWireRule = _WireRuleCatalogScript.instantiate_rule(rule_template_index)
	if rule == null:
		return false
	var in_prop := first_wire_in_property(rule)
	if in_prop == &"":
		push_warning("Ui React: wire rule has no input export to assign.")
		return false
	var arr := duplicate_wire_rules_array(host)
	if rule.rule_id.is_empty():
		rule.rule_id = "rule_%d" % arr.size()
	rule.set(in_prop, donor)
	arr.append(rule)
	actions.assign_property_variant(host, &"wire_rules", arr, "Ui React: Add wire rule (graph)")
	return true

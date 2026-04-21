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
	# Undo needs a distinct rule instance in the array, but deep duplicate(true) clones nested
	# UiState sub-resources and breaks Dependency Graph ids (embedded states use instance_id in
	# UiReactExplainGraphBuilder._state_id), dropping WIRE_FLOW from layout scope and clearing the dock list.
	var dup_res: Resource = (old_rule as Resource).duplicate(false)
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


const _SHALLOW_STRING_EXPORT_MAX_LEN := 2048
const _SHALLOW_FIELD_KIND_STRING := &"string"
const _SHALLOW_FIELD_KIND_BOOL := &"bool"
const _SHALLOW_FIELD_APPLY_EXPLICIT := &"explicit"
const _SHALLOW_FIELD_APPLY_IMMEDIATE := &"immediate"

## Descriptor map for in-tab wire payload edits (CB-058 Milestone 2). Complex/nested fields stay Inspector-only.
const _SHALLOW_FIELD_DESCRIPTORS_BY_CLASS: Dictionary = {
	&"UiReactWireCopySelectionDetail": [
		{
			&"prop": &"text_no_selection",
			&"label": "text_no_selection",
			&"display_label": "Text when nothing is selected",
			&"designer_help": "Message shown when the bound list has no selection. Use it for empty-state hints or instructions.",
			&"kind": _SHALLOW_FIELD_KIND_STRING,
			&"apply_mode": _SHALLOW_FIELD_APPLY_EXPLICIT,
			&"max_len": _SHALLOW_STRING_EXPORT_MAX_LEN,
			&"help": "Shown when there is no list selection.",
		},
		{
			&"prop": &"clear_suffix_on_selection_change",
			&"label": "clear_suffix_on_selection_change",
			&"display_label": "Clear suffix when selection changes",
			&"designer_help": "When enabled, the suffix note clears whenever the selected row changes so stale suffix text does not linger.",
			&"kind": _SHALLOW_FIELD_KIND_BOOL,
			&"apply_mode": _SHALLOW_FIELD_APPLY_IMMEDIATE,
			&"help": "When true, clears suffix_note_state whenever selected_state changes.",
		},
	],
	&"UiReactWireSetStringOnBoolPulse": [
		{
			&"prop": &"template_rising",
			&"label": "template_rising",
			&"display_label": "Text when pulse is true",
			&"designer_help": "Template written when the watched bool becomes true. Placeholders {name}, {kind}, and {qty} come from the selected list row.",
			&"kind": _SHALLOW_FIELD_KIND_STRING,
			&"apply_mode": _SHALLOW_FIELD_APPLY_EXPLICIT,
			&"max_len": _SHALLOW_STRING_EXPORT_MAX_LEN,
			&"help": "Placeholders: {name}, {kind}, {qty} from selected row.",
		},
		{
			&"prop": &"template_no_selection",
			&"label": "template_no_selection",
			&"display_label": "Text when no row is selected",
			&"designer_help": "Used only when no list row is selected and this field is not empty. Lets you show a different message than the rising-edge template.",
			&"kind": _SHALLOW_FIELD_KIND_STRING,
			&"apply_mode": _SHALLOW_FIELD_APPLY_EXPLICIT,
			&"max_len": _SHALLOW_STRING_EXPORT_MAX_LEN,
			&"help": "Used when no row is selected and this template is non-empty.",
		},
		{
			&"prop": &"require_rising_edge",
			&"label": "require_rising_edge",
			&"display_label": "Only on false → true",
			&"designer_help": "When enabled, the rule runs only when the bool goes from false to true (a rising edge), not on every frame while it stays true.",
			&"kind": _SHALLOW_FIELD_KIND_BOOL,
			&"apply_mode": _SHALLOW_FIELD_APPLY_IMMEDIATE,
			&"help": "When true, runs only on false→true pulse transitions.",
		},
	],
	&"UiReactWireSyncBoolStateDebugLine": [
		{
			&"prop": &"line_prefix",
			&"label": "line_prefix",
			&"display_label": "Line prefix",
			&"designer_help": "Optional text placed before the bool value when syncing into the target string state. Helps label debug lines.",
			&"kind": _SHALLOW_FIELD_KIND_STRING,
			&"apply_mode": _SHALLOW_FIELD_APPLY_EXPLICIT,
			&"max_len": _SHALLOW_STRING_EXPORT_MAX_LEN,
			&"help": "Text prepended to the bool value in target_string_state.",
		}
	],
	&"UiReactWireRefreshItemsFromCatalog": [
		{
			&"prop": &"first_row_icon_path",
			&"label": "first_row_icon_path",
			&"display_label": "First row icon path",
			&"designer_help": "Optional texture path for the icon on the first catalog row that passes the current filters. Leave empty to use the default.",
			&"kind": _SHALLOW_FIELD_KIND_STRING,
			&"apply_mode": _SHALLOW_FIELD_APPLY_EXPLICIT,
			&"max_len": _SHALLOW_STRING_EXPORT_MAX_LEN,
			&"help": "Optional icon path for the first row that passes current filters.",
		}
	],
}


static func _rule_script_class_name(rule: UiReactWireRule) -> StringName:
	var sc: Script = rule.get_script() as Script
	if sc == null:
		return &""
	var gn: StringName = sc.get_global_name()
	return gn if String(gn) != "" else &""


static func shallow_field_descriptors_for_class(rule_class_name: StringName) -> Array:
	var out: Array = []
	if rule_class_name == &"":
		return out
	var raw: Variant = _SHALLOW_FIELD_DESCRIPTORS_BY_CLASS.get(rule_class_name, null)
	if raw is not Array:
		return out
	for it: Variant in raw as Array:
		if it is Dictionary:
			out.append((it as Dictionary).duplicate())
	return out


static func shallow_field_descriptors_for_rule(rule: UiReactWireRule) -> Array:
	if rule == null:
		return []
	return shallow_field_descriptors_for_class(_rule_script_class_name(rule))


static func _find_shallow_field_descriptor(
	expected_class_name: StringName,
	prop: StringName
) -> Dictionary:
	if expected_class_name == &"" or prop == &"":
		return {}
	for d: Dictionary in shallow_field_descriptors_for_class(expected_class_name):
		var dprop: Variant = d.get(&"prop", &"")
		var dprop_sn: StringName = dprop if dprop is StringName else StringName(str(dprop))
		if dprop_sn == prop:
			return d
	return {}


## Undo-safe assign of descriptor-allowlisted shallow field on a duplicated wire rule (CB-058 Milestone 2).
static func try_commit_wire_rule_shallow_field(
	host: Control,
	rule_index: int,
	expected_class_name: StringName,
	prop: StringName,
	value: Variant,
	actions: UiReactActionController,
) -> bool:
	var desc := _find_shallow_field_descriptor(expected_class_name, prop)
	if desc.is_empty():
		push_warning("Ui React: shallow field not allowlisted: %s.%s" % [expected_class_name, prop])
		return false
	var kind := String(desc.get(&"kind", "")).strip_edges()
	var max_len := int(desc.get(&"max_len", _SHALLOW_STRING_EXPORT_MAX_LEN))
	if kind == _SHALLOW_FIELD_KIND_STRING:
		if typeof(value) != TYPE_STRING:
			push_warning("Ui React: shallow field expects String for %s." % prop)
			return false
		var t: String = str(value).strip_edges()
		if t.length() > max_len:
			push_warning(
				"Ui React: wire_rules[%d] %s exceeds max length (%d)."
				% [rule_index, prop, max_len]
			)
			return false
		var t_copy := t
		var mut_s: Callable = func(rule: UiReactWireRule) -> bool:
			if _rule_script_class_name(rule) != expected_class_name:
				return false
			if not prop in rule:
				return false
			if str(rule.get(prop)) == t_copy:
				return false
			rule.set(prop, t_copy)
			return true
		return try_mutate_wire_rule_at_index(
			host,
			rule_index,
			mut_s,
			actions,
			"Ui React: wire_rules[%d] %s" % [rule_index, prop],
		)
	if kind == _SHALLOW_FIELD_KIND_BOOL:
		if typeof(value) != TYPE_BOOL:
			push_warning("Ui React: shallow field expects bool for %s." % prop)
			return false
		var b: bool = bool(value)
		var b_copy := b
		var mut_b: Callable = func(rule: UiReactWireRule) -> bool:
			if _rule_script_class_name(rule) != expected_class_name:
				return false
			if not prop in rule:
				return false
			if bool(rule.get(prop)) == b_copy:
				return false
			rule.set(prop, b_copy)
			return true
		return try_mutate_wire_rule_at_index(
			host,
			rule_index,
			mut_b,
			actions,
			"Ui React: wire_rules[%d] %s" % [rule_index, prop],
		)
	push_warning("Ui React: unsupported shallow field kind for %s.%s: %s" % [expected_class_name, prop, kind])
	return false


## Back-compat wrapper for prior shallow-export callers.
static func try_commit_wire_rule_shallow_export(
	host: Control,
	rule_index: int,
	expected_class_name: StringName,
	prop: StringName,
	value: Variant,
	actions: UiReactActionController,
) -> bool:
	return try_commit_wire_rule_shallow_field(
		host, rule_index, expected_class_name, prop, value, actions
	)


static func try_commit_wire_rule_id(
	host: Control,
	rule_index: int,
	new_id: String,
	actions: UiReactActionController,
) -> bool:
	var trimmed := new_id.strip_edges()
	if trimmed.is_empty():
		push_warning("Ui React: rule_id cannot be empty after trim.")
		return false
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


static func _export_resource_hint_string(obj: Object, prop: StringName) -> String:
	if obj == null or prop == &"":
		return ""
	var ps := String(prop)
	for d: Dictionary in obj.get_property_list():
		if str(d.get(&"name", "")) != ps:
			continue
		if int(d.get(&"hint", PROPERTY_HINT_NONE)) == PROPERTY_HINT_RESOURCE_TYPE:
			return str(d.get(&"hint_string", ""))
	return ""


static func _donor_matches_export_hint(donor: UiState, hint: String) -> bool:
	if donor == null or hint.is_empty():
		return false
	var ds: Script = donor.get_script() as Script
	while ds != null:
		if String(ds.get_global_name()) == hint:
			return true
		ds = ds.get_base_script() as Script
	return false


## Catalog indices whose first wire [b]in[/b] export accepts [param donor] (typed [code]@export[/code] hint).
static func filter_rule_template_indices_for_donor(donor: UiState) -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	if donor == null:
		return out
	var n: int = _WireRuleCatalogScript.rule_script_entries().size()
	for i: int in range(n):
		var rule: UiReactWireRule = _WireRuleCatalogScript.instantiate_rule(i)
		if rule == null:
			continue
		var in_prop := first_wire_in_property(rule)
		if in_prop == &"":
			continue
		var hint := _export_resource_hint_string(rule, in_prop)
		if hint.is_empty():
			continue
		if _donor_matches_export_hint(donor, hint):
			out.append(i)
	return out

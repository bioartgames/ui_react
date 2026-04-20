## Dock quick-edit strip for allowlisted [code]wire_rules[/code] string/bool exports (**[code]CB-058[/code]**), under the rule list.
class_name UiReactDockWireRuleShallowEditor
extends VBoxContainer

const _CLASS_COPY := &"UiReactWireCopySelectionDetail"
const _CLASS_PULSE := &"UiReactWireSetStringOnBoolPulse"

var _actions: UiReactActionController
var _after_wire_mutated: Callable = Callable()

var _host: Control = null
var _rule_index: int = -1

var _title_lbl: Label
var _class_lbl: Label
var _rule_id_edit: LineEdit
var _rule_id_apply: Button

var _sep: HSeparator
var _block_copy: VBoxContainer
var _text_no_sel_edit: LineEdit
var _text_no_sel_apply: Button
var _clear_suffix_cb: CheckBox

var _block_pulse: VBoxContainer
var _tpl_rising_edit: LineEdit
var _tpl_rising_apply: Button
var _tpl_no_sel_edit: LineEdit
var _tpl_no_sel_apply: Button
var _rising_edge_cb: CheckBox

var _syncing := false


func setup(
	actions: UiReactActionController,
	after_wire_mutated: Callable = Callable(),
) -> void:
	_actions = actions
	_after_wire_mutated = after_wire_mutated
	_build_ui()


func clear() -> void:
	_host = null
	_rule_index = -1
	visible = false
	_syncing = true
	if _rule_id_edit:
		_rule_id_edit.text = ""
	if _text_no_sel_edit:
		_text_no_sel_edit.text = ""
	if _tpl_rising_edit:
		_tpl_rising_edit.text = ""
	if _tpl_no_sel_edit:
		_tpl_no_sel_edit.text = ""
	_syncing = false


func set_context(host: Control, _root: Node, rule_index: int) -> void:
	_host = host
	_rule_index = rule_index
	if host == null or rule_index < 0:
		clear()
		return
	var wr: Variant = host.get(&"wire_rules")
	var arr: Array = wr as Array if wr is Array else []
	if rule_index < 0 or rule_index >= arr.size():
		clear()
		return
	var item: Variant = arr[rule_index]
	if item == null or not (item is UiReactWireRule):
		clear()
		return
	var rule := item as UiReactWireRule
	var sc: Script = rule.get_script() as Script
	var gname := &""
	if sc != null:
		var gn: StringName = sc.get_global_name()
		if String(gn) != "":
			gname = gn
	visible = true
	_syncing = true
	_class_lbl.text = "Quick edit — %s" % String(gname) if gname != &"" else "Quick edit — (rule)"
	_rule_id_edit.text = rule.rule_id
	_block_copy.visible = rule is UiReactWireCopySelectionDetail
	_block_pulse.visible = rule is UiReactWireSetStringOnBoolPulse
	if rule is UiReactWireCopySelectionDetail:
		var cd := rule as UiReactWireCopySelectionDetail
		_text_no_sel_edit.text = cd.text_no_selection
		_clear_suffix_cb.set_block_signals(true)
		_clear_suffix_cb.button_pressed = cd.clear_suffix_on_selection_change
		_clear_suffix_cb.set_block_signals(false)
	if rule is UiReactWireSetStringOnBoolPulse:
		var bp := rule as UiReactWireSetStringOnBoolPulse
		_tpl_rising_edit.text = bp.template_rising
		_tpl_no_sel_edit.text = bp.template_no_selection
		_rising_edge_cb.set_block_signals(true)
		_rising_edge_cb.button_pressed = bp.require_rising_edge
		_rising_edge_cb.set_block_signals(false)
	_syncing = false


func _build_ui() -> void:
	add_theme_constant_override(&"separation", 6)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	visible = false

	_title_lbl = Label.new()
	_title_lbl.text = "Quick edit (selected rule)"
	_title_lbl.tooltip_text = "Subset of wire rule fields; full editing stays in the Inspector."
	add_child(_title_lbl)

	_class_lbl = Label.new()
	_class_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_class_lbl)

	var rid_row := HBoxContainer.new()
	rid_row.add_theme_constant_override(&"separation", 6)
	rid_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rid_lbl := Label.new()
	rid_lbl.text = "rule_id"
	rid_lbl.custom_minimum_size = Vector2(100, 0)
	rid_row.add_child(rid_lbl)
	_rule_id_edit = LineEdit.new()
	_rule_id_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rule_id_edit.placeholder_text = "Stable rule id"
	rid_row.add_child(_rule_id_edit)
	_rule_id_apply = Button.new()
	_rule_id_apply.text = "Apply"
	_rule_id_apply.tooltip_text = "Apply rule_id (undoable). Cannot be empty."
	_rule_id_apply.pressed.connect(_on_rule_id_apply_pressed)
	rid_row.add_child(_rule_id_apply)
	add_child(rid_row)

	_sep = HSeparator.new()
	add_child(_sep)

	_block_copy = VBoxContainer.new()
	_block_copy.add_theme_constant_override(&"separation", 4)
	_block_copy.visible = false
	_block_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_block_copy)

	var row_tns := HBoxContainer.new()
	row_tns.add_theme_constant_override(&"separation", 6)
	row_tns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tns_lbl := Label.new()
	tns_lbl.text = "text_no_selection"
	tns_lbl.custom_minimum_size = Vector2(140, 0)
	row_tns.add_child(tns_lbl)
	_text_no_sel_edit = LineEdit.new()
	_text_no_sel_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text_no_sel_edit.tooltip_text = "Shown when there is no list selection."
	row_tns.add_child(_text_no_sel_edit)
	_text_no_sel_apply = Button.new()
	_text_no_sel_apply.text = "Apply"
	_text_no_sel_apply.pressed.connect(_on_text_no_selection_apply)
	row_tns.add_child(_text_no_sel_apply)
	_block_copy.add_child(row_tns)

	_clear_suffix_cb = CheckBox.new()
	_clear_suffix_cb.text = "clear_suffix_on_selection_change"
	_clear_suffix_cb.tooltip_text = (
		"When true, clears suffix_note_state whenever selected_state changes before recomputing detail."
	)
	_clear_suffix_cb.toggled.connect(_on_clear_suffix_toggled)
	_block_copy.add_child(_clear_suffix_cb)

	_block_pulse = VBoxContainer.new()
	_block_pulse.add_theme_constant_override(&"separation", 4)
	_block_pulse.visible = false
	_block_pulse.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_block_pulse)

	var row_tr := HBoxContainer.new()
	row_tr.add_theme_constant_override(&"separation", 6)
	row_tr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tr_lbl := Label.new()
	tr_lbl.text = "template_rising"
	tr_lbl.custom_minimum_size = Vector2(140, 0)
	row_tr.add_child(tr_lbl)
	_tpl_rising_edit = LineEdit.new()
	_tpl_rising_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tpl_rising_edit.tooltip_text = "Placeholders: {name}, {kind}, {qty} from selected row."
	row_tr.add_child(_tpl_rising_edit)
	_tpl_rising_apply = Button.new()
	_tpl_rising_apply.text = "Apply"
	_tpl_rising_apply.pressed.connect(_on_template_rising_apply)
	row_tr.add_child(_tpl_rising_apply)
	_block_pulse.add_child(row_tr)

	var row_tns2 := HBoxContainer.new()
	row_tns2.add_theme_constant_override(&"separation", 6)
	row_tns2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tns2_lbl := Label.new()
	tns2_lbl.text = "template_no_selection"
	tns2_lbl.custom_minimum_size = Vector2(140, 0)
	row_tns2.add_child(tns2_lbl)
	_tpl_no_sel_edit = LineEdit.new()
	_tpl_no_sel_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_tns2.add_child(_tpl_no_sel_edit)
	_tpl_no_sel_apply = Button.new()
	_tpl_no_sel_apply.text = "Apply"
	_tpl_no_sel_apply.pressed.connect(_on_template_no_selection_apply)
	row_tns2.add_child(_tpl_no_sel_apply)
	_block_pulse.add_child(row_tns2)

	_rising_edge_cb = CheckBox.new()
	_rising_edge_cb.text = "require_rising_edge"
	_rising_edge_cb.tooltip_text = "When true, only runs on false→true pulse_bool transition."
	_rising_edge_cb.toggled.connect(_on_rising_edge_toggled)
	_block_pulse.add_child(_rising_edge_cb)


func _notify_mutated() -> void:
	if _after_wire_mutated.is_valid():
		_after_wire_mutated.call()


func _on_rule_id_apply_pressed() -> void:
	if _host == null or _actions == null or _rule_index < 0:
		return
	if not UiReactWireGraphEditService.try_commit_wire_rule_id(
		_host, _rule_index, _rule_id_edit.text, _actions
	):
		return
	_notify_mutated()


func _on_text_no_selection_apply() -> void:
	if _host == null or _actions == null or _rule_index < 0:
		return
	if not UiReactWireGraphEditService.try_commit_wire_rule_shallow_export(
		_host, _rule_index, _CLASS_COPY, &"text_no_selection", _text_no_sel_edit.text, _actions
	):
		return
	_notify_mutated()


func _on_clear_suffix_toggled(on: bool) -> void:
	if _syncing or _host == null or _actions == null or _rule_index < 0:
		return
	if not UiReactWireGraphEditService.try_commit_wire_rule_shallow_export(
		_host, _rule_index, _CLASS_COPY, &"clear_suffix_on_selection_change", on, _actions
	):
		_syncing = true
		_clear_suffix_cb.set_block_signals(true)
		_clear_suffix_cb.button_pressed = not on
		_clear_suffix_cb.set_block_signals(false)
		return
	_notify_mutated()


func _on_template_rising_apply() -> void:
	if _host == null or _actions == null or _rule_index < 0:
		return
	if not UiReactWireGraphEditService.try_commit_wire_rule_shallow_export(
		_host, _rule_index, _CLASS_PULSE, &"template_rising", _tpl_rising_edit.text, _actions
	):
		return
	_notify_mutated()


func _on_template_no_selection_apply() -> void:
	if _host == null or _actions == null or _rule_index < 0:
		return
	if not UiReactWireGraphEditService.try_commit_wire_rule_shallow_export(
		_host, _rule_index, _CLASS_PULSE, &"template_no_selection", _tpl_no_sel_edit.text, _actions
	):
		return
	_notify_mutated()


func _on_rising_edge_toggled(on: bool) -> void:
	if _syncing or _host == null or _actions == null or _rule_index < 0:
		return
	if not UiReactWireGraphEditService.try_commit_wire_rule_shallow_export(
		_host, _rule_index, _CLASS_PULSE, &"require_rising_edge", on, _actions
	):
		_syncing = true
		_rising_edge_cb.set_block_signals(true)
		_rising_edge_cb.button_pressed = not on
		_rising_edge_cb.set_block_signals(false)
		return
	_notify_mutated()

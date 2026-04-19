## ID bands for [UiReactDockExplainPanel] [PopupMenu] handlers and related workflow state.
## Bands: 0–2 selection kind; 1100s selection actions; 3000s empty-canvas; 3300s presets; 3500s scope; 3600s nested submenu roots.
## Rule: add new ids only in unused ranges within the same band; never reuse a released id.
class_name UiReactDockExplainMenuIds
extends Object

## Graph selection kind (not a menu row id).
const _SEL_NONE := 0
const _SEL_NODE := 1
const _SEL_EDGE := 2

## Rebind file-picker workflow ([member UiReactDockExplainPanel._rebind_kind]).
const _REBIND_NONE := 0
const _REBIND_BINDING := 1
const _REBIND_WIRE_IN := 2
const _REBIND_WIRE_OUT := 3
const _REBIND_COMPUTED_SOURCE := 4

## Selection [PopupMenu] ids — fill / [code]id_pressed[/code].
const _SEL_ACT_REBIND_BINDING := 1101
const _SEL_ACT_REBIND_WIRE_IN := 1102
const _SEL_ACT_REBIND_WIRE_OUT := 1103
const _SEL_ACT_REBIND_COMPUTED_SRC := 1104
const _SEL_ACT_CLEAR_OPT_BINDING := 1110
const _SEL_ACT_REMOVE_COMPUTED_DEP := 1111
const _SEL_ACT_CLEAR_WIRE_LINK := 1112
const _SEL_ACT_MOVE_SRC_UP := 1120
const _SEL_ACT_MOVE_SRC_DOWN := 1121
const _SEL_ACT_REMOVE_SRC_SLOT := 1122
const _SEL_ACT_CREATE_ASSIGN_BINDING := 1130
const _SEL_ACT_CREATE_BIND_BASE := 1240
const _SEL_SUB_NODE_ROOT := 1260
const _SEL_SUB_WIRE_ROOT := 1261
const _SEL_SUB_EDGE_EDIT_ROOT := 1262
const _SEL_SUB_SCOPE_ROOT := 1263
const _SEL_SUB_CREATE_BIND_ROOT := 1264
const _SEL_ACT_FOCUS_INSPECTOR := 1180
const _SEL_ACT_WIRE_ADD_BASE := 1210
const _SEL_ACT_WIRE_REFRESH_LIST := 1220
const _SEL_ACT_WIRE_COPY_RULE_REPORT := 1221
const _SEL_ACT_COPY_DETAILS := 1199

## Empty-canvas [PopupMenu] ids.
const _CV_REFRESH := 3001
const _CV_FIT := 3002
const _CV_CREATE_STATE_BASE := 3100
const _CV_TOGGLE_FULL_LISTS := 3201
const _CV_TOGGLE_BINDING := 3202
const _CV_TOGGLE_COMPUTED := 3203
const _CV_TOGGLE_WIRE := 3204
const _CV_TOGGLE_EDGE_LABELS := 3205
const _CV_TOGGLE_LEGEND := 3206
const _CV_PRESET_DEFAULT := 3300
const _CV_PRESET_NAMED_BASE := 3310
const _CV_SCOPE_SAVE := 3500
const _CV_SCOPE_MANAGE := 3501
const _CV_SCOPE_PIN := 3502
const _CV_SCOPE_UPDATE := 3503
const _CV_SUB_CREATE_ROOT := 3601
const _CV_SUB_VIEW_ROOT := 3602
const _CV_SUB_SCOPE_ROOT := 3603
const _CV_SUB_PRESETS_LIST := 3604

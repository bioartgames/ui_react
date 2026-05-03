extends GutTest


const UiReactGraphNodeIds := preload(
	"res://addons/ui_react/scripts/internal/react/ui_react_graph_node_ids.gd"
)


func test_control_id_stable() -> void:
	assert_eq(UiReactGraphNodeIds.control_id(NodePath(^"HBox/Leaf")), "ctrl:HBox/Leaf")


func test_host_path_from_root_under_tree() -> void:
	var root := Control.new()
	root.name = "Root"
	var child := Control.new()
	child.name = "Row"
	root.add_child(child)
	assert_true(root.is_ancestor_of(child))
	var hp := UiReactGraphNodeIds.host_path_from_root(root, child)
	assert_eq(str(hp), "Row")


func test_state_stable_id_embedded_matches_pattern() -> void:
	var st := UiBoolState.new(true)
	var hp := NodePath(^"Deck/Inventory")
	var ctx := &"bind:selected_state"
	var sid := UiReactGraphNodeIds.state_stable_id(hp, ctx, st)
	var iid := st.get_instance_id()
	assert_string_contains(sid, "state:emb:")
	assert_string_contains(sid, "Deck/Inventory")
	assert_string_contains(sid, str(ctx))
	assert_string_contains(sid, str(iid))
	assert_eq(st.resource_path, "")
	assert_true(sid.ends_with("#%d" % iid))


func test_state_stable_id_when_resource_has_path() -> void:
	var st := load("res://addons/ui_react/ui_resources/bool.tres") as UiBoolState
	assert_not_null(st)
	var sid := UiReactGraphNodeIds.state_stable_id(NodePath(^""), "", st)
	assert_eq(sid, "state:%s" % str(st.resource_path))
	assert_false(st.resource_path.is_empty())


func test_snapshot_extra_presence() -> void:
	var st_emb := UiBoolState.new()
	var hp := NodePath(^"X")
	var ex_emb := UiReactGraphNodeIds.state_snapshot_extra(hp, "ctx", st_emb)
	assert_eq(str(ex_emb.get(&"embedded_host_path")), "X")
	assert_eq(str(ex_emb.get(&"embedded_context")), "ctx")
	var st_rp := load("res://addons/ui_react/ui_resources/bool.tres") as UiBoolState
	var ex_rp := UiReactGraphNodeIds.state_snapshot_extra(hp, "ctx", st_rp)
	assert_eq(str(ex_rp.get(&"state_file_path")), str(st_rp.resource_path))

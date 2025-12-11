extends Resource
class_name UIAnimClip

@export var root: UIAnimGroup
@export_enum("none", "repeat", "infinite", "ping_pong") var loop_mode: String = "none"
@export_range(1, 9999, 1) var loop_count: int = 1


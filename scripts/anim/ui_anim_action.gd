extends Resource
class_name UIAnimAction

@export var property_path: String = ""
@export var from_value: Variant = null
@export var to_value: Variant = null
@export var is_relative: bool = false
@export_range(0.0, 120.0, 0.01) var duration: float = 0.3
@export_range(0.0, 120.0, 0.01) var delay: float = 0.0
@export_enum("linear", "quad_in", "quad_out", "quad_in_out", "cubic_in", "cubic_out", "cubic_in_out") var easing: String = "cubic_in_out"


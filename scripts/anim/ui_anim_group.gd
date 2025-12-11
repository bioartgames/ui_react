extends Resource
class_name UIAnimGroup

@export_enum("sequence", "parallel") var mode: String = "sequence"
@export var children: Array[Resource] = []


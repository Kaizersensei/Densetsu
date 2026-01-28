extends Resource
class_name CollisionData

@export var id: String = ""
@export var tags: PackedStringArray = []
@export var layers: int = 0
@export var mask: int = 0
# Optional friendly names for layers/masks (comma-separated)
@export var layer_names: PackedStringArray = []

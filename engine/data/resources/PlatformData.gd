extends Resource
class_name PlatformData

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var scene: PackedScene
@export var platform_type: String = "solid"
@export var slope_direction: String = ""
@export var speed: float = 0.0
@export var movement_path_id: String = ""
@export var allow_projectile_collision: bool = true
@export var tint: Color = Color(1, 1, 1, 1)

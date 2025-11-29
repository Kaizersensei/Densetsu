extends Resource
class_name ProjectileData

@export var id: String = ""
@export var description: String = ""
@export var sprite: Texture2D
@export var scene: PackedScene
@export var speed: float = 300.0
@export var gravity: float = 0.0
@export var damage: int = 1
@export var knockback: Vector2 = Vector2.ZERO
@export var lifetime: float = 3.0
@export var pierce_count: int = 0
@export var element: int = 0
@export var collision_layer: int = 1
@export var collision_mask: int = 1
@export var owner_team: String = ""

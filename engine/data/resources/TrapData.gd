extends Resource
class_name TrapData

@export var id: String = ""
@export var description: String = ""
@export var sprite: Texture2D
@export var scene: PackedScene
@export var damage: int = 1
@export var knockback: Vector2 = Vector2.ZERO
@export var element: int = 0
@export var cooldown: float = 0.0
@export var active: bool = true
@export var one_shot: bool = false
@export var collision_layer: int = 1
@export var collision_mask: int = 1

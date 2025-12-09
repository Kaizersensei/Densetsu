extends Resource
class_name SpriteData

@export var id: String = ""
@export var description: String = ""
@export var frames: SpriteFrames
@export var default_animation: String = "Idle"
@export var playback_speed: float = 1.0
@export var tint: Color = Color(1, 1, 1, 1)
@export var offset: Vector2 = Vector2.ZERO
@export var flip_h: bool = false
@export var flip_v: bool = false


extends Resource
class_name TeleporterData

@export var id: String = ""
@export var tags: PackedStringArray = []
@export var exit_only: bool = false
@export_enum("collision", "input") var activation_mode: String = "collision"
@export var activation_action: String = "interact"
@export var destination_scene: PackedScene
@export_enum("left_edge", "right_edge", "top_edge", "bottom_edge") var dropoff_mode: String = "right_edge"
@export var dropoff_target: String = ""
# Margin used for edge dropoffs to keep arrivals off the teleporter; in pixels.
@export var dropoff_margin: float = 64.0
@export var tint: Color = Color(0.4, 0.6, 1.0, 0.25)

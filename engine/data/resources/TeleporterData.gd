extends Resource
class_name TeleporterData

@export var id: String = ""
@export var tags: PackedStringArray = []
@export var exit_only: bool = false
@export_enum("collision", "input") var activation_mode: String = "collision"
@export var activation_action: String = "interact"
@export var destination_scene: PackedScene
@export_enum("teleporter", "left_edge", "right_edge") var dropoff_mode: String = "teleporter"
@export var dropoff_target: String = ""
# Margin used for edge dropoffs to keep camera from showing void; defaults to half-screen when applied.
@export var dropoff_margin: float = 960.0
@export var tint: Color = Color(0.4, 0.6, 1.0, 0.25)

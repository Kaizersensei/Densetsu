extends Resource
class_name CameraRigData3D

@export_category("Identity")
@export var id: String = ""
@export var description: String = ""
@export var tags: PackedStringArray = PackedStringArray()

@export_category("Follow")
@export var follow_distance: float = 4.0
@export var follow_height: float = 1.6
@export var follow_smooth: float = 10.0

@export_category("Orbit")
@export var yaw_sensitivity: float = 2.0
@export var pitch_sensitivity: float = 2.0
@export var pitch_min: float = -50.0
@export var pitch_max: float = 70.0

@export_category("Aim")
@export var aim_distance: float = 2.5
@export var shoulder_offset: Vector3 = Vector3(0.5, 0.4, 0.0)

@export_category("Zoom")
@export var min_distance: float = 2.0
@export var max_distance: float = 6.0

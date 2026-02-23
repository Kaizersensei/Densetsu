extends Resource
class_name CameraRigData3D

@export_category("Identity")
## Controls id.
@export var id: String = ""
## Controls description.
@export var description: String = ""
## Controls tags.
@export var tags: PackedStringArray = PackedStringArray()

@export_category("Follow")
## Distance for follow.
@export var follow_distance: float = 4.0
## Height for follow.
@export var follow_height: float = 1.6
## Controls follow smooth.
@export var follow_smooth: float = 10.0

@export_category("Orbit")
## Controls yaw sensitivity.
@export var yaw_sensitivity: float = 2.0
## Controls pitch sensitivity.
@export var pitch_sensitivity: float = 2.0
## Minimum value for pitch.
@export var pitch_min: float = -50.0
## Maximum value for pitch.
@export var pitch_max: float = 70.0

@export_category("Aim")
## Distance for aim.
@export var aim_distance: float = 2.5
## Offset for shoulder.
@export var shoulder_offset: Vector3 = Vector3(0.5, 0.4, 0.0)

@export_category("Zoom")
## Distance for min.
@export var min_distance: float = 2.0
## Distance for max.
@export var max_distance: float = 6.0

@export_category("Collision")
## Enable collision.
@export var collision_enabled: bool = true
## Controls collision mask.
@export var collision_mask: int = 1
## Controls collision margin.
@export var collision_margin: float = 0.2
## Radius for collision.
@export var collision_radius: float = 0.2

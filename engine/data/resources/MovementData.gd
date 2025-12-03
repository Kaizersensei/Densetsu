extends Resource
class_name MovementData

@export var id: String = ""
@export var description: String = ""
@export var tags: PackedStringArray = []

# Base kinematics
@export var gravity: float = 980.0
@export var move_speed: float = 140.0
@export var acceleration: float = 900.0
@export var friction_ground: float = 900.0
@export var friction_air: float = 300.0
@export var max_fall_speed: float = 900.0
@export var slope_penalty: float = 0.5

# Jumping
@export var jump_speed: float = -720.0
@export var air_jump_speed: float = -720.0
@export var max_jumps: int = 2
@export var min_jump_height: float = 44.0
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12
@export var jump_release_gravity_scale: float = 2.0
@export var jump_release_cut: float = 0.35
@export var drop_through_time: float = 0.25

# Wall interaction
@export var wall_slide_gravity_scale: float = 0.4
@export var wall_jump_speed_x: float = 200.0
@export var wall_jump_speed_y: float = -320.0

# Glide
@export var enable_glide: bool = false
@export var glide_gravity_scale: float = 0.3
@export var glide_max_fall_speed: float = 300.0

# Flight
@export var enable_flight: bool = false
@export var flight_acceleration: float = 600.0
@export var flight_max_speed: float = 400.0
@export var flight_drag: float = 8.0
